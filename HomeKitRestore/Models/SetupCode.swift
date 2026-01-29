//
//  SetupCode.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

/// Represents a stored HomeKit setup code
struct SetupCode: Identifiable, Codable, Hashable {
    let id: UUID
    var accessoryId: UUID?
    var accessoryName: String
    var manufacturer: String
    var model: String
    var code: String
    var codeFormat: CodeFormat
    var photoPath: String?
    var codeLocation: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    enum CodeFormat: String, Codable, CaseIterable {
        case numeric = "XXX-XX-XXX"
        case qrCode = "QR Code"
        case nfc = "NFC Tag"
        case unknown = "Unknown"
    }

    init(
        id: UUID = UUID(),
        accessoryId: UUID? = nil,
        accessoryName: String,
        manufacturer: String = "Unknown",
        model: String = "Unknown",
        code: String,
        codeFormat: CodeFormat = .numeric,
        photoPath: String? = nil,
        codeLocation: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.accessoryId = accessoryId
        self.accessoryName = accessoryName
        self.manufacturer = manufacturer
        self.model = model
        self.code = code
        self.codeFormat = codeFormat
        self.photoPath = photoPath
        self.codeLocation = codeLocation
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Validates the setup code format (XXX-XX-XXX)
    var isValidFormat: Bool {
        let pattern = "^\\d{3}-\\d{2}-\\d{3}$"
        return code.range(of: pattern, options: .regularExpression) != nil
    }

    /// Returns the code formatted as XXX-XX-XXX
    var formattedCode: String {
        let digits = code.filter { $0.isNumber }
        guard digits.count == 8 else { return code }
        let index1 = digits.index(digits.startIndex, offsetBy: 3)
        let index2 = digits.index(digits.startIndex, offsetBy: 5)
        return "\(digits[..<index1])-\(digits[index1..<index2])-\(digits[index2...])"
    }
}

/// Code location hints for different manufacturers
struct CodeLocationHint: Identifiable {
    let id = UUID()
    let manufacturer: String
    let products: [String]
    let locations: [String]
    let tips: [String]

    static let allHints: [CodeLocationHint] = [
        CodeLocationHint(
            manufacturer: "Eve",
            products: ["Eve Door & Window", "Eve Motion", "Eve Energy", "Eve Room", "Eve Aqua", "Eve Thermo", "Eve Weather", "Eve Light Switch", "Eve Flare", "Eve Cam"],
            locations: [
                "On the back of the device",
                "On the bottom of the device",
                "Inside the battery compartment",
                "On a sticker near the serial number"
            ],
            tips: [
                "Eve products typically have the HomeKit code printed on a small label",
                "The code is usually near the serial number on the back",
                "For Eve Energy, check the side of the plug",
                "Eve Cam has the code inside the stand base",
                "Check the original packaging if you still have it"
            ]
        ),
        CodeLocationHint(
            manufacturer: "Lutron",
            products: ["Caseta Smart Bridge", "Caseta Dimmer", "Caseta Switch", "Aurora Dimmer", "Serena Shades"],
            locations: [
                "On the Caseta Smart Bridge (bottom)",
                "Printed on the packaging",
                "In the Lutron app setup flow",
                "On the quick start guide card"
            ],
            tips: [
                "Lutron uses a bridge-based system - only the bridge needs a HomeKit code",
                "The code is on the bottom of the Smart Bridge",
                "Individual Caseta devices don't have HomeKit codes - they connect through the bridge",
                "Check the original Smart Bridge packaging",
                "The code may also be in your Lutron app account"
            ]
        ),
        CodeLocationHint(
            manufacturer: "Philips Hue",
            products: ["Hue Bridge", "Hue Bulbs", "Hue Light Strip", "Hue Play", "Hue Bloom", "Hue Go"],
            locations: [
                "On the bottom of the Hue Bridge",
                "On the back of the Hue Bridge",
                "Printed on the packaging",
                "In the Hue app under Settings > Hue Bridges"
            ],
            tips: [
                "Only the Hue Bridge has a HomeKit code - individual bulbs connect through the bridge",
                "The 8-digit code is on a sticker on the bottom of the bridge",
                "Newer bridges show the code in the Hue app",
                "If the sticker is worn, check the original box",
                "The code format is XXX-XX-XXX"
            ]
        ),
        CodeLocationHint(
            manufacturer: "Nanoleaf",
            products: ["Shapes", "Canvas", "Light Panels", "Elements", "Essentials"],
            locations: [
                "On the controller unit",
                "On the power supply brick",
                "Inside the packaging",
                "On the quick start guide"
            ],
            tips: [
                "Nanoleaf codes are on the controller, not individual panels",
                "Check the side of the power supply unit",
                "Newer products have QR codes for easy scanning",
                "The code is required for first-time HomeKit setup"
            ]
        ),
        CodeLocationHint(
            manufacturer: "Ecobee",
            products: ["Ecobee Smart Thermostat", "Ecobee3 Lite", "Ecobee SmartSensor"],
            locations: [
                "On the back of the thermostat (remove from wall plate)",
                "In the ecobee app under Settings",
                "On the original packaging"
            ],
            tips: [
                "You need to remove the thermostat from the wall plate to see the code",
                "The code is printed on a label on the back",
                "SmartSensors connect through the thermostat - no separate code needed",
                "Check the ecobee app - the code may be displayed there"
            ]
        ),
        CodeLocationHint(
            manufacturer: "Aqara",
            products: ["Aqara Hub", "Aqara Camera", "Aqara Door/Window Sensor", "Aqara Motion Sensor"],
            locations: [
                "On the bottom of the Hub",
                "Inside the device packaging",
                "On the device sticker (back/bottom)"
            ],
            tips: [
                "Aqara Hub is required for most Aqara accessories",
                "The HomeKit code is on the hub, not individual sensors",
                "Newer Aqara cameras have independent HomeKit codes",
                "Check the Aqara Home app for code display"
            ]
        ),
        CodeLocationHint(
            manufacturer: "LIFX",
            products: ["LIFX A19", "LIFX Mini", "LIFX Z", "LIFX Beam", "LIFX Tile"],
            locations: [
                "On the bulb itself (small print)",
                "On the product packaging",
                "In the LIFX app during setup"
            ],
            tips: [
                "LIFX bulbs connect directly to HomeKit - no bridge needed",
                "Each bulb has its own HomeKit code",
                "The code is printed in very small text on the bulb base",
                "Check the cardboard insert in the original packaging"
            ]
        ),
        CodeLocationHint(
            manufacturer: "Wemo",
            products: ["Wemo Smart Plug", "Wemo Mini", "Wemo Dimmer", "Wemo Stage"],
            locations: [
                "On the side of the plug",
                "On a label inside the packaging",
                "In the Wemo app"
            ],
            tips: [
                "Wemo devices connect directly to HomeKit",
                "The code is on a sticker on the device",
                "Some older Wemo devices require a firmware update for HomeKit",
                "Check the Wemo app for HomeKit setup options"
            ]
        )
    ]

    static func hints(for manufacturer: String) -> CodeLocationHint? {
        allHints.first { hint in
            manufacturer.lowercased().contains(hint.manufacturer.lowercased()) ||
            hint.manufacturer.lowercased().contains(manufacturer.lowercased())
        }
    }
}
