//
//  AccessoryModel.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

/// Represents a HomeKit accessory with its associated metadata
struct AccessoryInfo: Identifiable, Codable, Hashable {
    let id: UUID
    var homeKitUUID: UUID?
    var name: String
    var manufacturer: String
    var model: String
    var firmwareVersion: String?
    var serialNumber: String?
    var room: String?
    var home: String?
    var category: String
    var isReachable: Bool
    var ipAddress: String?
    var macAddress: String?
    var lastSeen: Date
    var setupCode: String?
    var setupCodePhotoPath: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        homeKitUUID: UUID? = nil,
        name: String,
        manufacturer: String = "Unknown",
        model: String = "Unknown",
        firmwareVersion: String? = nil,
        serialNumber: String? = nil,
        room: String? = nil,
        home: String? = nil,
        category: String = "Unknown",
        isReachable: Bool = true,
        ipAddress: String? = nil,
        macAddress: String? = nil,
        lastSeen: Date = Date(),
        setupCode: String? = nil,
        setupCodePhotoPath: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.homeKitUUID = homeKitUUID
        self.name = name
        self.manufacturer = manufacturer
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.serialNumber = serialNumber
        self.room = room
        self.home = home
        self.category = category
        self.isReachable = isReachable
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.lastSeen = lastSeen
        self.setupCode = setupCode
        self.setupCodePhotoPath = setupCodePhotoPath
        self.notes = notes
    }

    static func categoryName(from categoryType: String) -> String {
        switch categoryType {
        case "lightbulb": return "Lightbulb"
        case "switch": return "Switch"
        case "outlet": return "Outlet"
        case "thermostat": return "Thermostat"
        case "door": return "Door"
        case "doorlock": return "Door Lock"
        case "garagedoor": return "Garage Door Opener"
        case "fan": return "Fan"
        case "sensor": return "Sensor"
        case "security": return "Security System"
        case "camera": return "Camera"
        case "doorbell": return "Video Doorbell"
        case "window": return "Window"
        case "windowcovering": return "Window Covering"
        case "programmableswitch": return "Programmable Switch"
        case "bridge": return "Bridge"
        case "airpurifier": return "Air Purifier"
        case "airconditioner": return "Air Conditioner"
        case "airdehumidifier": return "Air Dehumidifier"
        case "airheater": return "Air Heater"
        case "airhumidifier": return "Air Humidifier"
        case "sprinkler": return "Sprinkler"
        case "faucet": return "Faucet"
        case "showerhead": return "Shower Head"
        default: return "Other"
        }
    }
}

/// Represents a discovered network device
struct DiscoveredDevice: Identifiable, Hashable {
    let id: UUID
    var name: String
    var serviceType: String
    var ipAddress: String?
    var port: Int?
    var txtRecord: [String: String]
    var manufacturer: String?
    var model: String?
    var setupCode: String?
    var isPaired: Bool
    var discoveredAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        serviceType: String,
        ipAddress: String? = nil,
        port: Int? = nil,
        txtRecord: [String: String] = [:],
        manufacturer: String? = nil,
        model: String? = nil,
        setupCode: String? = nil,
        isPaired: Bool = false,
        discoveredAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.serviceType = serviceType
        self.ipAddress = ipAddress
        self.port = port
        self.txtRecord = txtRecord
        self.manufacturer = manufacturer
        self.model = model
        self.setupCode = setupCode
        self.isPaired = isPaired
        self.discoveredAt = discoveredAt
    }

    var serviceTypeFriendly: String {
        switch serviceType {
        case "_hap._tcp": return "HomeKit (HAP)"
        case "_matterc._udp": return "Matter (Commissioning)"
        case "_matter._tcp": return "Matter (Operational)"
        default: return serviceType
        }
    }
}
