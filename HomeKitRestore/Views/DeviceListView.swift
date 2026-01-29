//
//  DeviceListView.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject var homeKitManager: HomeKitManager
    @EnvironmentObject var codeVaultManager: CodeVaultManager

    let searchText: String
    @State private var selectedAccessory: AccessoryInfo?
    @State private var groupBy: GroupBy = .room

    enum GroupBy: String, CaseIterable {
        case room = "Room"
        case manufacturer = "Manufacturer"
        case category = "Category"
        case home = "Home"
    }

    var filteredAccessories: [AccessoryInfo] {
        homeKitManager.accessories(matching: searchText)
    }

    var groupedAccessories: [(key: String, value: [AccessoryInfo])] {
        let grouped: [String: [AccessoryInfo]]
        switch groupBy {
        case .room:
            grouped = Dictionary(grouping: filteredAccessories) { $0.room ?? "Unassigned" }
        case .manufacturer:
            grouped = Dictionary(grouping: filteredAccessories) { $0.manufacturer }
        case .category:
            grouped = Dictionary(grouping: filteredAccessories) { $0.category }
        case .home:
            grouped = Dictionary(grouping: filteredAccessories) { $0.home ?? "Unknown Home" }
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        HSplitView {
            // Device List
            VStack(spacing: 0) {
                // Header with stats
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(homeKitManager.totalAccessoryCount) Devices")
                            .font(.headline)
                        Text("\(homeKitManager.reachableCount) reachable, \(homeKitManager.unreachableCount) unreachable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Picker("Group by", selection: $groupBy) {
                        ForEach(GroupBy.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)

                    Button(action: { homeKitManager.refreshData() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh HomeKit Data")
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                // Device list
                if homeKitManager.isLoading {
                    ProgressView("Loading HomeKit data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if homeKitManager.allAccessories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No HomeKit Devices Found")
                            .font(.title2)
                        Text("Make sure you have HomeKit accessories set up and authorized this app to access HomeKit.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if let error = homeKitManager.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button("Refresh") {
                            homeKitManager.refreshData()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(selection: $selectedAccessory) {
                        ForEach(groupedAccessories, id: \.key) { group in
                            Section(header: Text(group.key)) {
                                ForEach(group.value) { accessory in
                                    DeviceRow(accessory: accessory)
                                        .tag(accessory)
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 400)

            // Detail View
            if let accessory = selectedAccessory {
                DeviceDetailView(accessory: accessory)
                    .frame(minWidth: 400)
            } else {
                VStack {
                    Image(systemName: "square.dashed")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a device to view details")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Device Inventory")
    }
}

struct DeviceRow: View {
    let accessory: AccessoryInfo
    @EnvironmentObject var codeVaultManager: CodeVaultManager

    var hasSetupCode: Bool {
        codeVaultManager.code(forAccessoryName: accessory.name) != nil ||
        accessory.setupCode != nil
    }

    var body: some View {
        HStack {
            Image(systemName: categoryIcon)
                .font(.title2)
                .foregroundColor(accessory.isReachable ? .accentColor : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(accessory.name)
                        .fontWeight(.medium)

                    if !accessory.isReachable {
                        Image(systemName: "wifi.slash")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Text("\(accessory.manufacturer) \(accessory.model)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if hasSetupCode {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                    .help("Setup code saved")
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .help("No setup code saved")
            }
        }
        .padding(.vertical, 4)
    }

    var categoryIcon: String {
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

#Preview {
    DeviceListView(searchText: "")
        .environmentObject(HomeKitManager.shared)
        .environmentObject(CodeVaultManager.shared)
}
