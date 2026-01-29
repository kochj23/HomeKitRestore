//
//  ExportManager.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

/// Manages export of device inventory and codes to various formats
class ExportManager {
    static let shared = ExportManager()

    private init() {}

    // MARK: - CSV Export

    /// Export accessories and codes to CSV format
    func exportToCSV(accessories: [AccessoryInfo], codes: [SetupCode]) {
        let panel = NSSavePanel()
        panel.title = "Export to CSV"
        panel.nameFieldStringValue = "homekit_inventory_\(dateString()).csv"
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.canCreateDirectories = true

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.writeCSV(to: url, accessories: accessories, codes: codes)
        }
    }

    private func writeCSV(to url: URL, accessories: [AccessoryInfo], codes: [SetupCode]) {
        var csvContent = "Name,Manufacturer,Model,Category,Room,Home,Setup Code,Code Location,Reachable,Last Seen,Notes\n"

        for accessory in accessories {
            // Find associated code
            let code = codes.first { $0.accessoryId == accessory.homeKitUUID || $0.accessoryName == accessory.name }

            let row = [
                escapeCSV(accessory.name),
                escapeCSV(accessory.manufacturer),
                escapeCSV(accessory.model),
                escapeCSV(accessory.category),
                escapeCSV(accessory.room ?? ""),
                escapeCSV(accessory.home ?? ""),
                escapeCSV(code?.code ?? accessory.setupCode ?? ""),
                escapeCSV(code?.codeLocation ?? ""),
                accessory.isReachable ? "Yes" : "No",
                formatDate(accessory.lastSeen),
                escapeCSV(accessory.notes ?? code?.notes ?? "")
            ]

            csvContent += row.joined(separator: ",") + "\n"
        }

        // Add any codes without matching accessories
        let unmatchedCodes = codes.filter { code in
            !accessories.contains { $0.homeKitUUID == code.accessoryId || $0.name == code.accessoryName }
        }

        for code in unmatchedCodes {
            let row = [
                escapeCSV(code.accessoryName),
                escapeCSV(code.manufacturer),
                escapeCSV(code.model),
                "",
                "",
                "",
                escapeCSV(code.code),
                escapeCSV(code.codeLocation ?? ""),
                "",
                formatDate(code.createdAt),
                escapeCSV(code.notes ?? "")
            ]

            csvContent += row.joined(separator: ",") + "\n"
        }

        do {
            try csvContent.write(to: url, atomically: true, encoding: .utf8)
            showSuccessAlert(message: "CSV exported successfully to:\n\(url.path)")
        } catch {
            showErrorAlert(message: "Failed to export CSV: \(error.localizedDescription)")
        }
    }

    // MARK: - JSON Export

    /// Export accessories and codes to JSON format
    func exportToJSON(accessories: [AccessoryInfo], codes: [SetupCode]) {
        let panel = NSSavePanel()
        panel.title = "Export to JSON"
        panel.nameFieldStringValue = "homekit_inventory_\(dateString()).json"
        panel.allowedContentTypes = [UTType.json]
        panel.canCreateDirectories = true

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.writeJSON(to: url, accessories: accessories, codes: codes)
        }
    }

    private func writeJSON(to url: URL, accessories: [AccessoryInfo], codes: [SetupCode]) {
        let export = ExportData(
            exportDate: Date(),
            accessories: accessories,
            codes: codes.map { code in
                ExportCode(
                    accessoryName: code.accessoryName,
                    manufacturer: code.manufacturer,
                    model: code.model,
                    code: code.code,
                    codeFormat: code.codeFormat.rawValue,
                    codeLocation: code.codeLocation,
                    notes: code.notes,
                    createdAt: code.createdAt
                )
            }
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(export)
            try data.write(to: url)
            showSuccessAlert(message: "JSON exported successfully to:\n\(url.path)")
        } catch {
            showErrorAlert(message: "Failed to export JSON: \(error.localizedDescription)")
        }
    }

    // MARK: - PDF Export

    /// Export accessories and codes to PDF format
    func exportToPDF(accessories: [AccessoryInfo], codes: [SetupCode]) {
        let panel = NSSavePanel()
        panel.title = "Export to PDF"
        panel.nameFieldStringValue = "homekit_inventory_\(dateString()).pdf"
        panel.allowedContentTypes = [UTType.pdf]
        panel.canCreateDirectories = true

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.writePDF(to: url, accessories: accessories, codes: codes)
        }
    }

    private func writePDF(to url: URL, accessories: [AccessoryInfo], codes: [SetupCode]) {
        // Create PDF content as text
        var content = "HomeKit Device Inventory\n"
        content += "========================\n\n"
        content += "Generated: \(formatDate(Date()))\n\n"

        // Group accessories by home
        let groupedByHome = Dictionary(grouping: accessories) { $0.home ?? "Unknown Home" }

        for (home, homeAccessories) in groupedByHome.sorted(by: { $0.key < $1.key }) {
            content += "\n\(home)\n"
            content += String(repeating: "-", count: 40) + "\n\n"

            for accessory in homeAccessories {
                content += "\(accessory.name)\n"
                content += "  Manufacturer: \(accessory.manufacturer)\n"
                content += "  Model: \(accessory.model)\n"
                content += "  Room: \(accessory.room ?? "Unassigned")\n"
                content += "  Category: \(accessory.category)\n"

                // Find associated code
                if let code = codes.first(where: { $0.accessoryId == accessory.homeKitUUID || $0.accessoryName == accessory.name }) {
                    content += "  Setup Code: \(code.formattedCode)\n"
                    if let location = code.codeLocation {
                        content += "  Code Location: \(location)\n"
                    }
                }

                content += "\n"
            }
        }

        // Add codes section
        content += "\n\nSaved Setup Codes\n"
        content += "=================\n\n"

        for code in codes {
            content += "\(code.accessoryName)\n"
            content += "  Code: \(code.formattedCode)\n"
            content += "  Manufacturer: \(code.manufacturer)\n"
            if let location = code.codeLocation {
                content += "  Location: \(location)\n"
            }
            content += "\n"
        }

        // Write as text file (simple PDF alternative)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            showSuccessAlert(message: "Exported successfully to:\n\(url.path)")
        } catch {
            showErrorAlert(message: "Failed to export: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    private func escapeCSV(_ string: String) -> String {
        var escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            escaped = "\"\(escaped)\""
        }
        return escaped
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func showSuccessAlert(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Export Successful"
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func showErrorAlert(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Export Failed"
            alert.informativeText = message
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

// MARK: - Export Data Structures

struct ExportData: Codable {
    let exportDate: Date
    let accessories: [AccessoryInfo]
    let codes: [ExportCode]
}

struct ExportCode: Codable {
    let accessoryName: String
    let manufacturer: String
    let model: String
    let code: String
    let codeFormat: String
    let codeLocation: String?
    let notes: String?
    let createdAt: Date
}
