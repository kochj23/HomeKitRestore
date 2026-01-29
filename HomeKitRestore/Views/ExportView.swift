//
//  ExportView.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ExportView: View {
    @EnvironmentObject var homeKitManager: HomeKitManager
    @EnvironmentObject var codeVaultManager: CodeVaultManager

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)

                    Text("Export Your Data")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Export your HomeKit device inventory and saved setup codes")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                // Statistics
                HStack(spacing: 32) {
                    StatCard(
                        title: "Devices",
                        value: "\(homeKitManager.totalAccessoryCount)",
                        icon: "house.fill",
                        color: .blue
                    )

                    StatCard(
                        title: "Saved Codes",
                        value: "\(codeVaultManager.totalCodes)",
                        icon: "lock.shield.fill",
                        color: .green
                    )

                    StatCard(
                        title: "With Photos",
                        value: "\(codeVaultManager.codesWithPhotos)",
                        icon: "camera.fill",
                        color: .orange
                    )
                }

                Divider()
                    .padding(.horizontal, 32)

                // Export Options
                VStack(spacing: 16) {
                    Text("Export Formats")
                        .font(.headline)

                    HStack(spacing: 24) {
                        ExportOptionCard(
                            title: "CSV",
                            description: "Spreadsheet format for Excel, Numbers, Google Sheets",
                            icon: "tablecells",
                            action: exportCSV
                        )

                        ExportOptionCard(
                            title: "JSON",
                            description: "Structured data for developers and automation",
                            icon: "curlybraces",
                            action: exportJSON
                        )

                        ExportOptionCard(
                            title: "PDF",
                            description: "Printable document for physical backup",
                            icon: "doc.richtext",
                            action: exportPDF
                        )
                    }
                }

                Divider()
                    .padding(.horizontal, 32)

                // What's Included
                VStack(alignment: .leading, spacing: 16) {
                    Text("What's Included")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        IncludedItem(text: "Device names, manufacturers, and models")
                        IncludedItem(text: "Room and home assignments")
                        IncludedItem(text: "Category information")
                        IncludedItem(text: "Saved setup codes")
                        IncludedItem(text: "Code location notes")
                        IncludedItem(text: "Custom notes for each device")
                    }
                }
                .frame(maxWidth: 400, alignment: .leading)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Export")
    }

    private func exportCSV() {
        ExportManager.shared.exportToCSV(
            accessories: homeKitManager.allAccessories,
            codes: codeVaultManager.allCodes
        )
    }

    private func exportJSON() {
        ExportManager.shared.exportToJSON(
            accessories: homeKitManager.allAccessories,
            codes: codeVaultManager.allCodes
        )
    }

    private func exportPDF() {
        ExportManager.shared.exportToPDF(
            accessories: homeKitManager.allAccessories,
            codes: codeVaultManager.allCodes
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 120, height: 120)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ExportOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)

                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 200, height: 160)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct IncludedItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
        }
    }
}

#Preview {
    ExportView()
        .environmentObject(HomeKitManager.shared)
        .environmentObject(CodeVaultManager.shared)
}
