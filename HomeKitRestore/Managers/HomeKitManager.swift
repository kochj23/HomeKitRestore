//
//  HomeKitManager.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//
//  Note: HomeKit framework is not available on native macOS apps.
//  This manager provides a placeholder for device inventory that can be
//  populated from network discovery or manual entry.
//

import Foundation
import Combine

/// Manages device inventory (without direct HomeKit integration on macOS)
/// Devices are populated from network discovery or manual entry
class HomeKitManager: NSObject, ObservableObject {
    static let shared = HomeKitManager()

    @Published var homes: [String] = []
    @Published var allAccessories: [AccessoryInfo] = []
    @Published var isAuthorized: Bool = true
    @Published var authorizationStatus: String = "Manual Entry Mode"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let accessoriesKey = "stored_accessories"
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        loadAccessories()
    }

    /// Load accessories from storage
    private func loadAccessories() {
        if let data = UserDefaults.standard.data(forKey: accessoriesKey) {
            do {
                let decoder = JSONDecoder()
                allAccessories = try decoder.decode([AccessoryInfo].self, from: data)
                updateHomes()
            } catch {
                errorMessage = "Failed to load accessories: \(error.localizedDescription)"
            }
        }
    }

    /// Save accessories to storage
    private func saveAccessories() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(allAccessories)
            UserDefaults.standard.set(data, forKey: accessoriesKey)
        } catch {
            errorMessage = "Failed to save accessories: \(error.localizedDescription)"
        }
    }

    /// Update homes list from accessories
    private func updateHomes() {
        let homeNames = Set(allAccessories.compactMap { $0.home })
        homes = Array(homeNames).sorted()
    }

    /// Refresh data (reload from storage)
    func refreshData() {
        isLoading = true
        loadAccessories()
        isLoading = false
    }

    /// Add a new accessory manually
    func addAccessory(_ accessory: AccessoryInfo) {
        if let index = allAccessories.firstIndex(where: { $0.id == accessory.id }) {
            allAccessories[index] = accessory
        } else {
            allAccessories.append(accessory)
        }
        allAccessories.sort { $0.name < $1.name }
        updateHomes()
        saveAccessories()
    }

    /// Add accessory from discovered device
    func addAccessory(from device: DiscoveredDevice, home: String = "Home", room: String? = nil) {
        let accessory = AccessoryInfo(
            name: device.name,
            manufacturer: device.manufacturer ?? "Unknown",
            model: device.model ?? "Unknown",
            room: room,
            home: home,
            category: categoryFromServiceType(device.serviceType),
            isReachable: true,
            ipAddress: device.ipAddress
        )
        addAccessory(accessory)
    }

    /// Remove an accessory
    func removeAccessory(_ accessory: AccessoryInfo) {
        allAccessories.removeAll { $0.id == accessory.id }
        updateHomes()
        saveAccessories()
    }

    /// Update an existing accessory
    func updateAccessory(_ accessory: AccessoryInfo) {
        addAccessory(accessory)
    }

    private func categoryFromServiceType(_ serviceType: String) -> String {
        switch serviceType {
        case "_hap._tcp": return "HomeKit Device"
        case "_matterc._udp": return "Matter Device (Unpaired)"
        case "_matter._tcp": return "Matter Device"
        default: return "Unknown"
        }
    }

    /// Get accessories grouped by home
    var accessoriesByHome: [String: [AccessoryInfo]] {
        Dictionary(grouping: allAccessories) { $0.home ?? "Unknown Home" }
    }

    /// Get accessories grouped by room
    var accessoriesByRoom: [String: [AccessoryInfo]] {
        Dictionary(grouping: allAccessories) { $0.room ?? "Unassigned" }
    }

    /// Get accessories grouped by manufacturer
    var accessoriesByManufacturer: [String: [AccessoryInfo]] {
        Dictionary(grouping: allAccessories) { $0.manufacturer }
    }

    /// Get accessories grouped by category
    var accessoriesByCategory: [String: [AccessoryInfo]] {
        Dictionary(grouping: allAccessories) { $0.category }
    }

    /// Get count of accessories by category
    var categoryCounts: [(category: String, count: Int)] {
        accessoriesByCategory.map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    /// Get count of accessories by manufacturer
    var manufacturerCounts: [(manufacturer: String, count: Int)] {
        accessoriesByManufacturer.map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    /// Total accessory count
    var totalAccessoryCount: Int {
        allAccessories.count
    }

    /// Count of reachable accessories
    var reachableCount: Int {
        allAccessories.filter { $0.isReachable }.count
    }

    /// Count of unreachable accessories
    var unreachableCount: Int {
        allAccessories.filter { !$0.isReachable }.count
    }

    /// Find an accessory by UUID
    func accessory(withUUID uuid: UUID) -> AccessoryInfo? {
        allAccessories.first { $0.homeKitUUID == uuid }
    }

    /// Find accessories by manufacturer
    func accessories(byManufacturer manufacturer: String) -> [AccessoryInfo] {
        allAccessories.filter {
            $0.manufacturer.lowercased().contains(manufacturer.lowercased())
        }
    }

    /// Find accessories by name
    func accessories(matching searchText: String) -> [AccessoryInfo] {
        guard !searchText.isEmpty else { return allAccessories }
        let lowercased = searchText.lowercased()
        return allAccessories.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.manufacturer.lowercased().contains(lowercased) ||
            $0.model.lowercased().contains(lowercased) ||
            ($0.room?.lowercased().contains(lowercased) ?? false)
        }
    }
}
