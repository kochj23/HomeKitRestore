//
//  NetworkScannerManager.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import Network
import Combine

/// Manages network discovery for HomeKit (HAP) and Matter devices
class NetworkScannerManager: ObservableObject {
    @Published var discoveredDevices: [DiscoveredDevice] = []
    @Published var isScanning: Bool = false
    @Published var scanProgress: String = ""
    @Published var errorMessage: String?

    private var browsers: [NWBrowser] = []
    private var cancellables = Set<AnyCancellable>()

    /// Service types to scan for
    private let serviceTypes: [(type: String, name: String)] = [
        ("_hap._tcp", "HomeKit (HAP)"),
        ("_matterc._udp", "Matter Commissioning"),
        ("_matter._tcp", "Matter Operational")
    ]

    init() {}

    // MARK: - Scanning

    /// Start scanning for all service types
    func startScan() {
        stopScan()

        isScanning = true
        discoveredDevices = []
        errorMessage = nil
        scanProgress = "Starting scan..."

        for (serviceType, serviceName) in serviceTypes {
            startBrowser(for: serviceType, name: serviceName)
        }

        // Auto-stop after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            if self?.isScanning == true {
                self?.stopScan()
                self?.scanProgress = "Scan complete"
            }
        }
    }

    /// Stop all scanning
    func stopScan() {
        for browser in browsers {
            browser.cancel()
        }
        browsers = []
        isScanning = false
    }

    private func startBrowser(for serviceType: String, name: String) {
        let descriptor = NWBrowser.Descriptor.bonjour(type: serviceType, domain: "local.")
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        let browser = NWBrowser(for: descriptor, using: parameters)

        browser.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.scanProgress = "Scanning for \(name)..."
                case .failed(let error):
                    self?.errorMessage = "Browser error for \(name): \(error.localizedDescription)"
                case .cancelled:
                    break
                default:
                    break
                }
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, changes in
            DispatchQueue.main.async {
                self?.handleBrowseResults(results, serviceType: serviceType)
            }
        }

        browsers.append(browser)
        browser.start(queue: .main)
    }

    private func handleBrowseResults(_ results: Set<NWBrowser.Result>, serviceType: String) {
        for result in results {
            switch result.endpoint {
            case .service(let name, let type, let domain, _):
                // Resolve the service to get more details
                resolveService(name: name, type: type, domain: domain, serviceType: serviceType)
            default:
                break
            }
        }
    }

    private func resolveService(name: String, type: String, domain: String, serviceType: String) {
        // Check if we already have this device
        if discoveredDevices.contains(where: { $0.name == name && $0.serviceType == serviceType }) {
            return
        }

        // Create connection to resolve the service
        let endpoint = NWEndpoint.service(name: name, type: type, domain: domain, interface: nil)
        let parameters = NWParameters.tcp
        let connection = NWConnection(to: endpoint, using: parameters)

        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                if let innerEndpoint = connection.currentPath?.remoteEndpoint {
                    DispatchQueue.main.async {
                        self?.addDiscoveredDevice(
                            name: name,
                            serviceType: serviceType,
                            endpoint: innerEndpoint,
                            metadata: connection.metadata(definition: NWProtocolTCP.definition) as? NWProtocolTCP.Metadata
                        )
                    }
                }
                connection.cancel()
            case .failed(_), .cancelled:
                // Still add the device even if we couldn't connect
                DispatchQueue.main.async {
                    self?.addDiscoveredDevice(
                        name: name,
                        serviceType: serviceType,
                        endpoint: nil,
                        metadata: nil
                    )
                }
            default:
                break
            }
        }

        connection.start(queue: .global())

        // Timeout for resolution
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            if connection.state != .cancelled {
                connection.cancel()
            }
        }
    }

    private func addDiscoveredDevice(name: String, serviceType: String, endpoint: NWEndpoint?, metadata: NWProtocolTCP.Metadata?) {
        // Avoid duplicates
        if discoveredDevices.contains(where: { $0.name == name && $0.serviceType == serviceType }) {
            return
        }

        var ipAddress: String?
        var port: Int?

        if case .hostPort(let host, let p) = endpoint {
            ipAddress = "\(host)"
            port = Int(p.rawValue)
        }

        // Parse manufacturer from name if possible
        let manufacturer = parseManufacturer(from: name)

        // Determine if paired based on service type
        let isPaired = serviceType == "_matter._tcp"

        let device = DiscoveredDevice(
            name: name,
            serviceType: serviceType,
            ipAddress: ipAddress,
            port: port,
            txtRecord: [:],
            manufacturer: manufacturer,
            model: nil,
            setupCode: nil,
            isPaired: isPaired
        )

        discoveredDevices.append(device)
        scanProgress = "Found \(discoveredDevices.count) device(s)..."
    }

    private func parseManufacturer(from name: String) -> String? {
        let knownPrefixes = ["Eve", "Lutron", "Hue", "Nanoleaf", "Ecobee", "Aqara", "LIFX", "Wemo", "Meross", "VOCOlinc"]

        for prefix in knownPrefixes {
            if name.lowercased().contains(prefix.lowercased()) {
                return prefix
            }
        }

        return nil
    }

    // MARK: - Filtering

    /// Get only HAP (HomeKit) devices
    var hapDevices: [DiscoveredDevice] {
        discoveredDevices.filter { $0.serviceType == "_hap._tcp" }
    }

    /// Get only Matter commissioning (unpaired) devices
    var matterCommissioningDevices: [DiscoveredDevice] {
        discoveredDevices.filter { $0.serviceType == "_matterc._udp" }
    }

    /// Get only Matter operational (paired) devices
    var matterOperationalDevices: [DiscoveredDevice] {
        discoveredDevices.filter { $0.serviceType == "_matter._tcp" }
    }

    /// Get unpaired devices (commissioning mode)
    var unpairedDevices: [DiscoveredDevice] {
        discoveredDevices.filter { !$0.isPaired }
    }

    /// Get devices by manufacturer
    func devices(byManufacturer manufacturer: String) -> [DiscoveredDevice] {
        discoveredDevices.filter {
            $0.manufacturer?.lowercased().contains(manufacturer.lowercased()) ?? false
        }
    }

    /// Search devices by name
    func searchDevices(_ searchText: String) -> [DiscoveredDevice] {
        guard !searchText.isEmpty else { return discoveredDevices }
        let lowercased = searchText.lowercased()
        return discoveredDevices.filter {
            $0.name.lowercased().contains(lowercased) ||
            ($0.manufacturer?.lowercased().contains(lowercased) ?? false) ||
            ($0.ipAddress?.contains(searchText) ?? false)
        }
    }
}
