//
//  DeviceDetailView.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI
import AppKit

struct DeviceDetailView: View {
    let accessory: AccessoryInfo
    @EnvironmentObject var codeVaultManager: CodeVaultManager

    @State private var setupCode: String = ""
    @State private var codeLocation: String = ""
    @State private var notes: String = ""
    @State private var selectedPhoto: NSImage?
    @State private var showingPhotoPanel: Bool = false
    @State private var showingCodeHints: Bool = false

    var existingCode: SetupCode? {
        codeVaultManager.code(forAccessoryName: accessory.name)
    }

    var codeHint: CodeLocationHint? {
        CodeLocationHint.hints(for: accessory.manufacturer)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Device Info Header
                deviceInfoSection

                Divider()

                // Setup Code Section
                setupCodeSection

                // Code Location Hints
                if codeHint != nil {
                    Divider()
                    codeHintsSection
                }

                // Photo Section
                Divider()
                photoSection

                // Notes Section
                Divider()
                notesSection

                Spacer()
            }
            .padding()
        }
        .onAppear {
            loadExistingCode()
        }
        .onChange(of: accessory.id) { _, _ in
            loadExistingCode()
        }
    }

    // MARK: - Device Info Section

    private var deviceInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: categoryIcon)
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(accessory.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("\(accessory.manufacturer) \(accessory.model)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Spacer()

                statusBadge
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                InfoRow(label: "Category", value: accessory.category)
                InfoRow(label: "Room", value: accessory.room ?? "Unassigned")
                InfoRow(label: "Home", value: accessory.home ?? "Unknown")
                InfoRow(label: "Last Seen", value: formatDate(accessory.lastSeen))

                if let firmware = accessory.firmwareVersion {
                    InfoRow(label: "Firmware", value: firmware)
                }

                if let ip = accessory.ipAddress {
                    InfoRow(label: "IP Address", value: ip)
                }
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(accessory.isReachable ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(accessory.isReachable ? "Reachable" : "Unreachable")
                .font(.caption)
                .foregroundColor(accessory.isReachable ? .green : .orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((accessory.isReachable ? Color.green : Color.orange).opacity(0.15))
        )
    }

    // MARK: - Setup Code Section

    private var setupCodeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Setup Code")
                    .font(.headline)

                Spacer()

                if existingCode != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Saved")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            HStack {
                TextField("XXX-XX-XXX", text: $setupCode)
                    .font(.system(.title, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                    .onChange(of: setupCode) { _, newValue in
                        setupCode = formatSetupCode(newValue)
                    }

                Button(action: saveCode) {
                    Label("Save Code", systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(setupCode.isEmpty)

                if existingCode != nil {
                    Button(role: .destructive, action: deleteCode) {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }

            Text("Enter the 8-digit HomeKit setup code (format: XXX-XX-XXX)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Code Hints Section

    private var codeHintsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Where to Find the Code")
                    .font(.headline)

                Spacer()

                Button(action: { showingCodeHints.toggle() }) {
                    Image(systemName: showingCodeHints ? "chevron.up" : "chevron.down")
                }
            }

            if showingCodeHints, let hint = codeHint {
                VStack(alignment: .leading, spacing: 8) {
                    Text("For \(hint.manufacturer) devices:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Locations:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        ForEach(hint.locations, id: \.self) { location in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.caption)
                                Text(location)
                                    .font(.caption)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tips:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        ForEach(hint.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text(tip)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
            } else if codeHint != nil {
                Button(action: { showingCodeHints = true }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Show code location hints for \(accessory.manufacturer)")
                    }
                }
                .buttonStyle(.link)
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Code Photo")
                .font(.headline)

            if let photo = selectedPhoto {
                VStack {
                    Image(nsImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)

                    HStack {
                        Button("Replace Photo") {
                            selectPhoto()
                        }
                        Button("Remove Photo", role: .destructive) {
                            selectedPhoto = nil
                            if var code = existingCode {
                                codeVaultManager.deletePhoto(for: code.id)
                            }
                        }
                    }
                }
            } else {
                Button(action: selectPhoto) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title)
                        Text("Add Photo of Setup Code")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            Text("Take a photo of the setup code label for backup")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)

            TextEditor(text: $notes)
                .font(.body)
                .frame(minHeight: 80)
                .border(Color.secondary.opacity(0.3), width: 1)

            HStack {
                Spacer()
                Button("Save Notes") {
                    saveCode()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Helper Methods

    private func loadExistingCode() {
        if let code = codeVaultManager.code(forAccessoryName: accessory.name) {
            setupCode = code.code
            codeLocation = code.codeLocation ?? ""
            notes = code.notes ?? ""
            selectedPhoto = codeVaultManager.loadPhoto(for: code)
        } else {
            setupCode = accessory.setupCode ?? ""
            codeLocation = ""
            notes = ""
            selectedPhoto = nil
        }
    }

    private func saveCode() {
        var photoPath: String?
        if let photo = selectedPhoto {
            photoPath = codeVaultManager.savePhoto(for: existingCode?.id ?? UUID(), image: photo)
        }

        let code = SetupCode(
            id: existingCode?.id ?? UUID(),
            accessoryId: accessory.homeKitUUID,
            accessoryName: accessory.name,
            manufacturer: accessory.manufacturer,
            model: accessory.model,
            code: setupCode,
            codeFormat: .numeric,
            photoPath: photoPath ?? existingCode?.photoPath,
            codeLocation: codeLocation.isEmpty ? nil : codeLocation,
            notes: notes.isEmpty ? nil : notes,
            createdAt: existingCode?.createdAt ?? Date(),
            updatedAt: Date()
        )

        codeVaultManager.saveCode(code)
    }

    private func deleteCode() {
        if let code = existingCode {
            codeVaultManager.deleteCode(code)
            setupCode = ""
            codeLocation = ""
            notes = ""
            selectedPhoto = nil
        }
    }

    private func selectPhoto() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            selectedPhoto = NSImage(contentsOf: url)
        }
    }

    private func formatSetupCode(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }

        var formatted = ""
        for (index, char) in digits.prefix(8).enumerated() {
            if index == 3 || index == 5 {
                formatted += "-"
            }
            formatted.append(char)
        }
        return formatted
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var categoryIcon: String {
        switch accessory.category {
        case "Lightbulb": return "lightbulb.fill"
        case "Switch": return "switch.2"
        case "Outlet": return "poweroutlet.type.b.fill"
        case "Thermostat": return "thermometer"
        case "Door": return "door.left.hand.closed"
        case "Door Lock": return "lock.fill"
        case "Garage Door Opener": return "door.garage.closed"
        case "Fan": return "fan.fill"
        case "Sensor": return "sensor.fill"
        case "Security System": return "shield.fill"
        case "Camera": return "camera.fill"
        case "Video Doorbell": return "video.doorbell.fill"
        case "Window": return "window.horizontal.closed"
        case "Window Covering": return "blinds.horizontal.closed"
        case "Bridge": return "network"
        default: return "house.fill"
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

#Preview {
    DeviceDetailView(accessory: AccessoryInfo(
        name: "Living Room Light",
        manufacturer: "Philips",
        model: "Hue Bulb",
        room: "Living Room",
        home: "Home",
        category: "Lightbulb"
    ))
    .environmentObject(CodeVaultManager.shared)
}
