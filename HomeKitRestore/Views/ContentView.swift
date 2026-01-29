//
//  ContentView.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var homeKitManager: HomeKitManager
    @EnvironmentObject var codeVaultManager: CodeVaultManager
    @EnvironmentObject var networkScanner: NetworkScannerManager

    @State private var selectedTab: SidebarTab = .devices
    @State private var searchText: String = ""

    enum SidebarTab: String, CaseIterable, Identifiable {
        case devices = "Devices"
        case codeVault = "Code Vault"
        case networkScan = "Network Scan"
        case export = "Export"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .devices: return "house.fill"
            case .codeVault: return "lock.shield.fill"
            case .networkScan: return "network"
            case .export: return "square.and.arrow.up"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(SidebarTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationTitle("HomeKit Restore")
            .frame(minWidth: 200)
        } detail: {
            mainContent
                .searchable(text: $searchText, prompt: "Search...")
        }
        .onAppear {
            homeKitManager.refreshData()
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case .devices:
            DeviceListView(searchText: searchText)
        case .codeVault:
            CodeVaultView(searchText: searchText)
        case .networkScan:
            NetworkScannerView()
        case .export:
            ExportView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HomeKitManager.shared)
        .environmentObject(CodeVaultManager.shared)
        .environmentObject(NetworkScannerManager())
}
