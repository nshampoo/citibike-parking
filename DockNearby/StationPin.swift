import SwiftUI

/// Plenty, few, none (of docks or bikes) — softer than the system traffic-light colors.
func availabilityColor(_ count: Int) -> Color {
    switch count {
    case 0: Color(red: 0.86, green: 0.30, blue: 0.31)       // muted red
    case 1...3: Color(red: 0.93, green: 0.62, blue: 0.20)   // amber
    default: Color(red: 0.20, green: 0.64, blue: 0.44)      // deep green
    }
}

/// A map pin: a white dot ringed in the availability color with the count (docks or
/// bikes) inside, or just a small colored dot when zoomed out, where numbers would be noise.
struct StationPin: View {
    let count: Int
    let isFavorite: Bool
    let isSelected: Bool
    var isDimmed = false
    var isCompact = false

    var body: some View {
        Group {
            if isCompact {
                Circle()
                    .fill(availabilityColor(count))
                    .frame(width: 11, height: 11)
                    .overlay(Circle().stroke(Color(uiColor: .tertiarySystemBackground), lineWidth: 1.5))
            } else {
                Text("\(count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .frame(width: 28, height: 28)
                    // White in light mode; a raised grey (not black) in dark, so pins sit on the map.
                    .background(Color(uiColor: .tertiarySystemBackground), in: .circle)
                    .overlay(Circle().strokeBorder(availabilityColor(count), lineWidth: 3))
                    .overlay(alignment: .topTrailing) {
                        if isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(.yellow, in: .circle)
                                .offset(x: 6, y: -6)
                        }
                    }
            }
        }
        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
        .opacity(isDimmed ? 0.35 : 1)
        .scaleEffect(isSelected ? 1.3 : 1)
        .animation(.snappy, value: isSelected)
    }
}
