import SwiftUI
import CoreLocation
import MapKit
import BikeKit

/// The sheet shown when you tap a pin or a list row: live counts, favorite, and directions.
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

            HStack {
                Button { favorites.toggle(station.id) } label: {
                    Label(starred ? "Unfavorite" : "Favorite", systemImage: starred ? "star.slash" : "star.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(starred ? .gray : .yellow)

                Button(action: openDirections) {
                    Label("Directions", systemImage: "bicycle")
                        .frame(maxWidth: .infinity)
                }
                .tint(.blue)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
    }

    /// Hands off to Apple Maps with cycling directions to the station.
    private func openDirections() {
        let item: MKMapItem
        if #available(iOS 26, *) {
            item = MKMapItem(location: CLLocation(latitude: station.latitude, longitude: station.longitude), address: nil)
        } else {
            item = MKMapItem(placemark: MKPlacemark(coordinate: station.coordinate))
        }
        item.name = station.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeCycling])
    }

    private func stat(_ value: Int, _ label: String, color: Color = .primary) -> some View {
        VStack {
            Text("\(value)").font(.title.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
