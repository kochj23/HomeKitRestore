//
//  HomeKitRestoreApp.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

@main
struct HomeKitRestoreApp: App {
    @StateObject private var homeKitManager = HomeKitManager.shared
    @StateObject private var codeVaultManager = CodeVaultManager.shared
    @StateObject private var networkScanner = NetworkScannerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(homeKitManager)
                .environmentObject(codeVaultManager)
                .environmentObject(networkScanner)
                .frame(minWidth: 1000, minHeight: 600)
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Refresh HomeKit Data") {
                    homeKitManager.refreshData()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Scan Network") {
                    networkScanner.startScan()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Divider()

                Button("Export to CSV...") {
                    ExportManager.shared.exportToCSV(
                        accessories: homeKitManager.allAccessories,
                        codes: codeVaultManager.allCodes
                    )
                }
                .keyboardShortcut("e", modifiers: .command)

                Button("Export to JSON...") {
                    ExportManager.shared.exportToJSON(
                        accessories: homeKitManager.allAccessories,
                        codes: codeVaultManager.allCodes
                    )
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }
}
