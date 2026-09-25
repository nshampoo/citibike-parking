import SwiftUI

/// Green plenty, orange few, red none.
func dockColor(_ docks: Int) -> Color { docks == 0 ? .red : docks <= 3 ? .orange : .green }

/// A map pin: a dot showing the open-dock count, with a star badge for favorites.
struct StationPin: View {
    let docks: Int
    let isFavorite: Bool
    let isSelected: Bool
    var isDimmed = false

    var body: some View {
        Text("\(docks)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(dockColor(docks), in: .circle)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .overlay(alignment: .topTrailing) {
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                        .shadow(radius: 1)
                        .offset(x: 5, y: -5)
                }
            }
            .opacity(isDimmed ? 0.35 : 1)
            .scaleEffect(isSelected ? 1.35 : 1)
            .animation(.snappy, value: isSelected)
            .shadow(radius: 2)
    }
}
