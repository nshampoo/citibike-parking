import SwiftUI
import CoreLocation
import BikeKit

/// The sheet shown when you tap a pin or a list row: live counts plus a favorite button.
struct StationDetailView: View {
    let station: NearbyStation
    let here: CLLocation?
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        let starred = favorites.contains(station.id)
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(station.name).font(.title3.bold())
                if let here {
                    Text(Measurement(value: station.distance(from: here), unit: UnitLength.meters),
                         format: .measurement(width: .abbreviated, usage: .road))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }

            HStack {
                stat(station.docks, "docks", color: dockColor(station.docks))
                stat(station.classic, "bikes")
                stat(station.ebikes, "e-bikes")
            }

            if !station.renting {
                Label("Not renting bikes right now", systemImage: "exclamationmark.triangle")
                    .font(.footnote).foregroundStyle(.orange)
            }

            Button { favorites.toggle(station.id) } label: {
                Label(starred ? "Remove from Favorites" : "Add to Favorites",
                      systemImage: starred ? "star.slash" : "star.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(starred ? .gray : .yellow)
            .controlSize(.large)
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func stat(_ value: Int, _ label: String, color: Color = .primary) -> some View {
        VStack {
            Text("\(value)").font(.title.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
