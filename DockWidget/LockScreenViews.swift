import WidgetKit
import SwiftUI
import BikeKit

// Lock Screen widgets render in a single tint, so color can't carry meaning —
// the dock count itself is the headline, labeled with a short street name ("72nd").

/// Short text for error/empty states, shared by all accessory sizes.
private func statusText(_ entry: DockEntry) -> String? {
    switch entry.state {
    case .failed: "Couldn't load"
    case .noFavorites: "Star stations in the app"
    case .noDestination: "Pick a destination"
    case .loaded: entry.stations.isEmpty ? "No stations" : nil
    }
}

/// Up to three dots side by side: open docks inside, short street name below.
struct RectangularView: View {
    let entry: DockEntry

    var body: some View {
        if entry.stations.isEmpty {
            Label(statusText(entry) ?? "", systemImage: "bicycle")
                .font(.caption)
        } else {
            HStack(spacing: 4) {
                ForEach(entry.stations) { s in
                    VStack(spacing: 2) {
                        Text("\(s.docks)")
                            .font(.title3.bold())
                            .minimumScaleFactor(0.6)
                            .frame(width: 36, height: 36)
                            .background { AccessoryWidgetBackground().clipShape(.circle) }
                            .widgetAccentable()
                        Text(s.shortName)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

/// Ring gauge of open docks vs. capacity; plain number if capacity is unknown.
struct CircularView: View {
    let entry: DockEntry

    var body: some View {
        if let s = entry.stations.first {
            if let capacity = s.capacity {
                Gauge(value: Double(min(s.docks, capacity)), in: 0...Double(capacity)) {
                    Image(systemName: "bicycle")
                } currentValueLabel: {
                    Text("\(s.docks)")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .widgetAccentable()
            } else {
                VStack(spacing: 0) {
                    Text("\(s.docks)").font(.title2.bold())
                    Text(s.shortName).font(.caption2).lineLimit(1).minimumScaleFactor(0.6)
                }
            }
        } else {
            Image(systemName: entry.state == .failed ? "exclamationmark.triangle" : "bicycle")
        }
    }
}

/// One line above the clock, e.g. "72nd 7 · 73rd 2". Inline widgets only render a single Text/Label.
struct InlineView: View {
    let entry: DockEntry

    var body: some View {
        if entry.stations.isEmpty {
            Label(statusText(entry) ?? "", systemImage: "bicycle")
        } else {
            Label(entry.stations.map { "\($0.shortName) \($0.docks)" }.joined(separator: " · "),
                  systemImage: "bicycle")
        }
    }
}
