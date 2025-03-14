import SwiftUI

struct ColorPreviewCircle: View {
    var temperature: Double
    var brightness: Double
    var isOn: Bool
    private func colorForTemperature(_ kelvin: Double) -> Color {
        let normalizedTemp = (kelvin - 2700) / (6500 - 2700) // 0 bis 1
        if normalizedTemp <= 0.5 {
            let factor = normalizedTemp * 2 // 0 bis 1
            return Color(
                red: 1.0,
                green: 0.9 + (factor * 0.1), // 0.9 zu 1.0
                blue: 0.7 + (factor * 0.3) // 0.7 zu 1.0
            )
        } else {
            let factor = (normalizedTemp - 0.5) * 2 // 0 bis 1
            return Color(
                red: 1.0 - (factor * 0.1), // 1.0 zu 0.9
                green: 1.0,
                blue: 1.0
            )
        }
    }

    var body: some View {
        let baseColor = colorForTemperature(temperature)
        let brightnessValue = brightness / 100.0
        return ZStack {
            Circle()
                .stroke(isOn ? Color.blue : Color.gray.opacity(0.5), lineWidth: 1.5)
                .frame(width: 24, height: 24)
            Circle()
                .fill(baseColor)
                .opacity(brightnessValue)
                .frame(width: 20, height: 20)
        }
    }
}
