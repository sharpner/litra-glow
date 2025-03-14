import AppKit
import SwiftUI

struct SystemStyleSliderView: NSViewRepresentable {
    @Binding var value: Double
    var minValue: Double
    var maxValue: Double
    var onChange: (Double) -> Void
    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider(value: value,
                              minValue: minValue,
                              maxValue: maxValue,
                              target: context.coordinator,
                              action: #selector(Coordinator.valueChanged(_:)))
        slider.isContinuous = true
        slider.sliderType = .linear
        return slider
    }

    func updateNSView(_ nsView: NSSlider, context _: Context) {
        nsView.doubleValue = value
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: SystemStyleSliderView
        init(_ parent: SystemStyleSliderView) {
            self.parent = parent
        }

        @objc func valueChanged(_ sender: NSSlider) {
            parent.value = sender.doubleValue
            parent.onChange(sender.doubleValue)
        }
    }
}

struct SteppedSystemStyleSliderView: NSViewRepresentable {
    @Binding var value: Double
    var minValue: Double
    var maxValue: Double
    var step: Double
    var onChange: (Double) -> Void
    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider(value: value,
                              minValue: minValue,
                              maxValue: maxValue,
                              target: context.coordinator,
                              action: #selector(Coordinator.valueChanged(_:)))
        slider.isContinuous = true
        slider.sliderType = .linear
        return slider
    }

    func updateNSView(_ nsView: NSSlider, context _: Context) {
        let roundedValue = round(value / step) * step
        nsView.doubleValue = roundedValue
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: SteppedSystemStyleSliderView
        init(_ parent: SteppedSystemStyleSliderView) {
            self.parent = parent
        }

        @objc func valueChanged(_ sender: NSSlider) {
            let rawValue = sender.doubleValue
            let roundedValue = round(rawValue / parent.step) * parent.step
            if abs(sender.doubleValue - roundedValue) > 0.01 {
                sender.doubleValue = roundedValue
            }
            parent.value = roundedValue
            parent.onChange(roundedValue)
        }
    }
}
