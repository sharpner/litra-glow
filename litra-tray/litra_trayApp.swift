import AppKit
import SwiftUI

@main
struct LitraTrayApp: App {
    @StateObject private var litra = LitraController()
    var body: some Scene {
        MenuBarExtra(content: {
            LitraMenuView(litra: litra)
        }, label: {
            if litra.isOn {
                Image(systemName: "lightbulb.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "lightbulb")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.gray)
            }
        })
        .menuBarExtraStyle(.window)
    }
}

struct LitraMenuView: View {
    @ObservedObject var litra: LitraController
    @StateObject private var webcamDetector: WebcamDetector
    init(litra: LitraController) {
        self.litra = litra
        _webcamDetector = StateObject(wrappedValue: WebcamDetector(litraController: litra))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Global")
                .font(.headline)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .padding(.horizontal)
            HStack {
                Text("Litra Light")
                    .font(.system(size: 14))
                Spacer()
                ColorPreviewCircle(
                    temperature: litra.temperature,
                    brightness: litra.brightness,
                    isOn: litra.isOn
                )
                .padding(.trailing, 8)
                CircularToggleButton(isOn: $litra.isOn) { newValue in
                    if newValue {
                        litra.turnOn()
                    } else {
                        litra.turnOff()
                        webcamDetector.disableAutoMode()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            HStack {
                Text("Webcam Activation")
                    .font(.system(size: 14))
                Spacer()
                if webcamDetector.isWebcamActive {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .padding(.trailing, 5)
                }
                Button(action: {
                    webcamDetector.toggleAutoMode()
                }) {
                    ZStack {
                        Circle()
                            .fill(webcamDetector.isAutoModeEnabled ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 30, height: 30)
                        Image(systemName: "video")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(webcamDetector.isAutoModeEnabled ? .white : .gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            Divider()
                .padding(.vertical, 8)
            VStack(alignment: .leading, spacing: 4) {
                Text("Brightness: \(Int(litra.brightness))%")
                    .font(.headline)
                    .padding(.bottom, 8)
                    .foregroundColor(.secondary)
                SystemStyleSliderView(
                    value: $litra.brightness,
                    minValue: 1,
                    maxValue: 100,
                    onChange: { newValue in
                        litra.setBrightness(Int(newValue))
                    }
                )
                .frame(height: 20) // Höhe für bessere Darstellung
                HStack {
                    Text("1%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("100%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            VStack(alignment: .leading, spacing: 4) {
                Text("Temperature: \(Int(litra.temperature))K")
                    .font(.headline)
                    .padding(.bottom, 8)
                    .foregroundColor(.secondary)
                SteppedSystemStyleSliderView(
                    value: $litra.temperature,
                    minValue: 2700,
                    maxValue: 6500,
                    step: 100,
                    onChange: { newValue in
                        litra.setTemperature(Int(newValue))
                    }
                )
                .frame(height: 20) // Höhe für bessere Darstellung
                HStack {
                    Text("2.700")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("6.500")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            Divider()
                .padding(.vertical, 8)
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 8)
        }
        .frame(width: 240)
    }
}
