import SwiftUI

struct CircularToggleButton: View {
    @Binding var isOn: Bool
    var action: (Bool) -> Void
    var body: some View {
        Button(action: {
            isOn.toggle()
            action(isOn)
        }) {
            ZStack {
                Circle()
                    .fill(isOn ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
                Image(systemName: "power")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isOn ? .white : .gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
