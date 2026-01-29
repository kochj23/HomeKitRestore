//
//  CodeVaultManager.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import Security
import AppKit

/// Manages secure storage and retrieval of HomeKit setup codes
class CodeVaultManager: ObservableObject {
    static let shared = CodeVaultManager()

    @Published var allCodes: [SetupCode] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let keychainService = "com.digitalnoise.homekitrestore.codes"
    private let codesKey = "stored_codes"
    private let photoDirectory: URL

    private init() {
        // Setup photo storage directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        photoDirectory = appSupport.appendingPathComponent("HomeKitRestore/Photos", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: photoDirectory, withIntermediateDirectories: true)

        // Load codes from storage
        loadCodes()
    }

    // MARK: - Code Management

    /// Load all codes from secure storage
    func loadCodes() {
        isLoading = true
        errorMessage = nil

        if let data = loadFromKeychain() {
            do {
                let decoder = JSONDecoder()
                allCodes = try decoder.decode([SetupCode].self, from: data)
            } catch {
                errorMessage = "Failed to decode codes: \(error.localizedDescription)"
                allCodes = []
            }
        } else {
            allCodes = []
        }

        isLoading = false
    }

    /// Save a new setup code
    func saveCode(_ code: SetupCode) {
        var updatedCodes = allCodes

        // Check for existing code with same accessory
        if let existingIndex = updatedCodes.firstIndex(where: { $0.id == code.id }) {
            updatedCodes[existingIndex] = code
        } else {
            updatedCodes.append(code)
        }

        if saveToKeychain(codes: updatedCodes) {
            allCodes = updatedCodes
        } else {
            errorMessage = "Failed to save code to secure storage"
        }
    }

    /// Update an existing code
    func updateCode(_ code: SetupCode) {
        var updated = code
        updated = SetupCode(
            id: code.id,
            accessoryId: code.accessoryId,
            accessoryName: code.accessoryName,
            manufacturer: code.manufacturer,
            model: code.model,
            code: code.code,
            codeFormat: code.codeFormat,
            photoPath: code.photoPath,
            codeLocation: code.codeLocation,
            notes: code.notes,
            createdAt: code.createdAt,
            updatedAt: Date()
        )
        saveCode(updated)
    }

    /// Delete a code
    func deleteCode(_ code: SetupCode) {
        var updatedCodes = allCodes.filter { $0.id != code.id }

        // Delete associated photo if exists
        if let photoPath = code.photoPath {
            try? FileManager.default.removeItem(atPath: photoPath)
        }

        if saveToKeychain(codes: updatedCodes) {
            allCodes = updatedCodes
        } else {
            errorMessage = "Failed to delete code from secure storage"
        }
    }

    /// Delete all codes
    func deleteAllCodes() {
        // Delete all photos
        for code in allCodes {
            if let photoPath = code.photoPath {
                try? FileManager.default.removeItem(atPath: photoPath)
            }
        }

        if saveToKeychain(codes: []) {
            allCodes = []
        } else {
            errorMessage = "Failed to clear codes from secure storage"
        }
    }

    // MARK: - Photo Management

    /// Save a photo for a code and return the path
    func savePhoto(for codeId: UUID, image: NSImage) -> String? {
        let filename = "\(codeId.uuidString).png"
        let fileURL = photoDirectory.appendingPathComponent(filename)

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            errorMessage = "Failed to convert image to PNG"
            return nil
        }

        do {
            try pngData.write(to: fileURL)
            return fileURL.path
        } catch {
            errorMessage = "Failed to save photo: \(error.localizedDescription)"
            return nil
        }
    }

    /// Load a photo for a code
    func loadPhoto(for code: SetupCode) -> NSImage? {
        guard let photoPath = code.photoPath else { return nil }
        return NSImage(contentsOfFile: photoPath)
    }

    /// Delete a photo for a code
    func deletePhoto(for codeId: UUID) {
        let filename = "\(codeId.uuidString).png"
        let fileURL = photoDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Search & Filter

    /// Search codes by name, manufacturer, or model
    func searchCodes(_ searchText: String) -> [SetupCode] {
        guard !searchText.isEmpty else { return allCodes }
        let lowercased = searchText.lowercased()
        return allCodes.filter {
            $0.accessoryName.lowercased().contains(lowercased) ||
            $0.manufacturer.lowercased().contains(lowercased) ||
            $0.model.lowercased().contains(lowercased) ||
            $0.code.contains(searchText)
        }
    }

    /// Get codes for a specific manufacturer
    func codes(forManufacturer manufacturer: String) -> [SetupCode] {
        allCodes.filter {
            $0.manufacturer.lowercased().contains(manufacturer.lowercased())
        }
    }

    /// Find code for an accessory
    func code(forAccessoryId accessoryId: UUID) -> SetupCode? {
        allCodes.first { $0.accessoryId == accessoryId }
    }

    /// Find code by accessory name
    func code(forAccessoryName name: String) -> SetupCode? {
        allCodes.first { $0.accessoryName.lowercased() == name.lowercased() }
    }

    // MARK: - Keychain Operations

    private func loadFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: codesKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func saveToKeychain(codes: [SetupCode]) -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(codes)

            // Try to update existing item first
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: codesKey
            ]

            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]

            var status = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)

            if status == errSecItemNotFound {
                // Create new item
                var addQuery = updateQuery
                addQuery[kSecValueData as String] = data
                status = SecItemAdd(addQuery as CFDictionary, nil)
            }

            return status == errSecSuccess
        } catch {
            errorMessage = "Failed to encode codes: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Statistics

    /// Total number of stored codes
    var totalCodes: Int { allCodes.count }

    /// Number of codes with photos
    var codesWithPhotos: Int {
        allCodes.filter { $0.photoPath != nil }.count
    }

    /// Number of codes by manufacturer
    var codesByManufacturer: [(manufacturer: String, count: Int)] {
        let grouped = Dictionary(grouping: allCodes) { $0.manufacturer }
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }
}
