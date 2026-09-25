import WidgetKit
import SwiftUI
import BikeKit

// Home screen widgets can use color, so counts wear the same green/amber/red as the app.

/// Small: header, then three stations as "72nd ······ 7".
/// Medium / large: header with age, then rows with the name, a detail line, and a big count.
struct HomeScreenView: View {
    let entry: DockEntry
    @Environment(\.widgetFamily) private var family

    private var isSmall: Bool { family == .systemSmall }

    var body: some View {
        VStack(alignment: .leading, spacing: isSmall ? 5 : 7) {
            header
            if let status = statusText(entry) {
                Spacer(minLength: 0)
                Text(status).font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(entry.stations) { stationRow($0) }
            }
            Spacer(minLength: 0)   // top-align rows
        }
        .containerBackground(.background, for: .widget)
    }

    /// "PARKING" over "Nearby" on the left; refresh (with the age, when there's room) on the right.
    private var header: some View {
        HStack(alignment: .top, spacing: 4) {
            VStack(alignment: .leading, spacing: 0) {
                Text(countLabel(for: entry.need))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(entry.title)
                    .font(.caption.bold())
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Button(intent: RefreshIntent()) {
                HStack(spacing: 3) {
                    if !isSmall {
                        DataAge(date: entry.date).multilineTextAlignment(.trailing)
                    }
                    Image(systemName: "arrow.clockwise")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder private func stationRow(_ s: NearbyStation) -> some View {
        if isSmall { smallRow(s) } else { row(s) }
    }

    private func smallRow(_ s: NearbyStation) -> some View {
        let n = s.count(of: entry.need)
        return HStack {
            Text(s.shortName).font(.subheadline.weight(.semibold)).lineLimit(1)
            Spacer(minLength: 4)
            Text("\(n)").font(.headline).monospacedDigit().foregroundStyle(availabilityColor(n))
        }
    }

    private func row(_ s: NearbyStation) -> some View {
        let n = s.count(of: entry.need)
        return HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
                Text(s.name).font(.caption.weight(.semibold)).lineLimit(1)
                Text(detail(s)).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            Text("\(n)")
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(availabilityColor(n))
            Text(entry.need.noun(for: n)).font(.caption2).foregroundStyle(.secondary)
        }
    }

    /// Distance plus whatever the big number isn't: bikes when counting parking, docks when counting bikes.
    private func detail(_ s: NearbyStation) -> String {
        let distance = Measurement(value: s.meters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
        let other = entry.need == .dock
            ? "\(s.classic) classic · \(s.ebikes) e-bikes"
            : "\(s.docks) \(Need.dock.noun(for: s.docks)) open"
        return "\(distance) · \(other)"
    }
}
