//
//  CodeVaultView.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct CodeVaultView: View {
    @EnvironmentObject var codeVaultManager: CodeVaultManager

    let searchText: String
    @State private var selectedCode: SetupCode?
    @State private var showingAddCode: Bool = false
    @State private var showingDeleteConfirmation: Bool = false

    var filteredCodes: [SetupCode] {
        codeVaultManager.searchCodes(searchText)
    }

    var body: some View {
        HSplitView {
            // Code List
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(codeVaultManager.totalCodes) Codes Stored")
                            .font(.headline)
                        Text("\(codeVaultManager.codesWithPhotos) with photos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: { showingAddCode = true }) {
                        Label("Add Code", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                // Code list
                if codeVaultManager.allCodes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Codes Stored")
                            .font(.title2)
                        Text("Add setup codes manually or select a device from the Devices tab to save its code.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Add First Code") {
                            showingAddCode = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredCodes, selection: $selectedCode) { code in
                        CodeRow(code: code)
                            .tag(code)
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 350)

            // Detail View
            if let code = selectedCode {
                CodeDetailView(code: code, onDelete: {
                    showingDeleteConfirmation = true
                })
                .frame(minWidth: 400)
            } else {
                VStack {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a code to view details")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingAddCode) {
            AddCodeView()
        }
        .alert("Delete Code?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let code = selectedCode {
                    codeVaultManager.deleteCode(code)
                    selectedCode = nil
                }
            }
        } message: {
            Text("This will permanently delete this setup code. This action cannot be undone.")
        }
        .navigationTitle("Code Vault")
    }
}

struct CodeRow: View {
    let code: SetupCode

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(code.accessoryName)
                    .fontWeight(.medium)

                Text("\(code.manufacturer) \(code.model)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(code.formattedCode)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.accentColor)

            if code.photoPath != nil {
                Image(systemName: "camera.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CodeDetailView: View {
    let code: SetupCode
    let onDelete: () -> Void
    @EnvironmentObject var codeVaultManager: CodeVaultManager

    var photo: NSImage? {
        codeVaultManager.loadPhoto(for: code)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(code.accessoryName)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("\(code.manufacturer) \(code.model)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                // Setup Code Display
                VStack(spacing: 16) {
                    Text("Setup Code")
                        .font(.headline)

                    Text(code.formattedCode)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentColor)
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)

                    HStack {
                        Button(action: copyCode) {
                            Label("Copy Code", systemImage: "doc.on.doc")
                        }

                        Button(action: generateQRCode) {
                            Label("Show QR Code", systemImage: "qrcode")
                        }
                    }
                }

                Divider()

                // Details
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    InfoRow(label: "Format", value: code.codeFormat.rawValue)
                    InfoRow(label: "Added", value: formatDate(code.createdAt))
                    InfoRow(label: "Updated", value: formatDate(code.updatedAt))

                    if let location = code.codeLocation {
                        InfoRow(label: "Code Location", value: location)
                    }
                }

                // Photo
                if let photo = photo {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Code Photo")
                            .font(.headline)

                        Image(nsImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(8)
                    }
                }

                // Notes
                if let notes = code.notes, !notes.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)

                        Text(notes)
                            .font(.body)
                    }
                }

                Divider()

                // Actions
                HStack {
                    Spacer()
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Code", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code.formattedCode, forType: .string)
    }

    private func generateQRCode() {
        // TODO: Implement QR code generation
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AddCodeView: View {
    @EnvironmentObject var codeVaultManager: CodeVaultManager
    @Environment(\.dismiss) private var dismiss

    @State private var accessoryName: String = ""
    @State private var manufacturer: String = ""
    @State private var model: String = ""
    @State private var setupCode: String = ""
    @State private var codeLocation: String = ""
    @State private var notes: String = ""

    var isValid: Bool {
        !accessoryName.isEmpty && !setupCode.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Text("Add Setup Code")
                    .font(.headline)

                Spacer()

                Button("Save") {
                    saveCode()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding()

            Divider()

            // Form
            Form {
                Section("Device Information") {
                    TextField("Accessory Name", text: $accessoryName)
                    TextField("Manufacturer", text: $manufacturer)
                    TextField("Model", text: $model)
                }

                Section("Setup Code") {
                    TextField("XXX-XX-XXX", text: $setupCode)
                        .font(.system(.title2, design: .monospaced))
                        .onChange(of: setupCode) { _, newValue in
                            setupCode = formatSetupCode(newValue)
                        }

                    TextField("Where is the code located?", text: $codeLocation)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .formStyle(.grouped)
            .padding()
        }
        .frame(width: 500, height: 450)
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

    private func saveCode() {
        let code = SetupCode(
            accessoryName: accessoryName,
            manufacturer: manufacturer.isEmpty ? "Unknown" : manufacturer,
            model: model.isEmpty ? "Unknown" : model,
            code: setupCode,
            codeFormat: .numeric,
            codeLocation: codeLocation.isEmpty ? nil : codeLocation,
            notes: notes.isEmpty ? nil : notes
        )

        codeVaultManager.saveCode(code)
        dismiss()
    }
}

#Preview {
    CodeVaultView(searchText: "")
        .environmentObject(CodeVaultManager.shared)
}
