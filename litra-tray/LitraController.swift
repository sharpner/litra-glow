import Foundation
import IOKit
import IOKit.hid

class LitraController: ObservableObject {
    @Published var brightness: Double = 80
    @Published var temperature: Double = 5500
    @Published var isOn: Bool = false
    private let vendorId: Int32 = 0x046D
    private let lightOffCode: UInt8 = 0x00
    private let lightOnCode: UInt8 = 0x01
    private let minBrightness: UInt8 = 0x14
    private let maxBrightness: UInt8 = 0xFA
    private struct LitraDevice {
        let name: String
        let productId: Int32
    }

    private let litraProducts = [
        LitraDevice(name: "Glow", productId: 0xC900),
        LitraDevice(name: "Beam", productId: 0xC901),
    ]
    private var firstRun: Bool = true
    init() {}

    private func findDevices() -> [IOHIDDevice] {
        var devices = [IOHIDDevice]()
        let managerRef = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        for product in litraProducts {
            let matchingDict = [
                kIOHIDVendorIDKey: vendorId,
                kIOHIDProductIDKey: product.productId,
            ] as CFDictionary
            IOHIDManagerSetDeviceMatching(managerRef, matchingDict)
            IOHIDManagerOpen(managerRef, IOOptionBits(kIOHIDOptionsTypeNone))
            if let hidDeviceSet = IOHIDManagerCopyDevices(managerRef) as? Set<IOHIDDevice> {
                for device in hidDeviceSet {
                    devices.append(device)
                    if firstRun {
                        print("Found \(product.name) device")
                    }
                }
            }
        }
        firstRun = false
        return devices
    }

    private func commandDevices(_ bytes: [UInt8]) {
        let devices = findDevices()
        guard !devices.isEmpty else {
            print("No Litra devices found. Command skipped.")
            return
        }
        for device in devices {
            let reportId: UInt8 = 0x11
            let data = Data(bytes)
            _ = data.withUnsafeBytes { ptr in
                IOHIDDeviceSetReport(
                    device,
                    kIOHIDReportTypeOutput, // Wichtig: Output-Typ für Steuerbefehle
                    CFIndex(reportId), // Report-ID: 0x11
                    ptr.baseAddress!,
                    bytes.count
                )
            }
        }
    }

    func turnOn() {
        let bytes: [UInt8] = [0x11, 0xFF, 0x04, 0x1C, lightOnCode, 0x00, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        commandDevices(bytes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setBrightness(Int(self.brightness))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setTemperature(Int(self.temperature))
            }
        }
        DispatchQueue.main.async {
            self.isOn = true
        }
    }

    func turnOff() {
        let bytes: [UInt8] = [0x11, 0xFF, 0x04, 0x1C, lightOffCode, 0x00, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        commandDevices(bytes)
        DispatchQueue.main.async {
            self.isOn = false
        }
    }

    func setBrightness(_ level: Int) {
        let safeLevel = min(100, max(0, level))
        let adjustedLevel = minBrightness + UInt8(Double(safeLevel) / 100.0 * Double(maxBrightness - minBrightness))
        let bytes: [UInt8] = [0x11, 0xFF, 0x04, 0x4C, 0x00, adjustedLevel, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        commandDevices(bytes)
        DispatchQueue.main.async {
            self.brightness = Double(safeLevel)
        }
    }

    func setTemperature(_ temp: Int) {
        let safeTemp = min(6500, max(2700, temp))
        let high = UInt8((safeTemp >> 8) & 0xFF)
        let low = UInt8(safeTemp & 0xFF)
        let bytes: [UInt8] = [0x11, 0xFF, 0x04, 0x9C, high, low, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        commandDevices(bytes)
        DispatchQueue.main.async {
            self.temperature = Double(safeTemp)
        }
    }

    func increaseBrightness(by increment: Int = 5) {
        let newBrightness = min(100, Int(brightness) + increment)
        setBrightness(newBrightness)
    }

    func decreaseBrightness(by decrement: Int = 5) {
        let newBrightness = max(0, Int(brightness) - decrement)
        setBrightness(newBrightness)
    }

    func increaseTemperature(by increment: Int = 100) {
        let newTemperature = min(6500, Int(temperature) + increment)
        setTemperature(newTemperature)
    }

    func decreaseTemperature(by decrement: Int = 100) {
        let newTemperature = max(2700, Int(temperature) - decrement)
        setTemperature(newTemperature)
    }
}
