import WidgetKit
import SwiftUI
import BikeKit

// Lock Screen widgets render in a single tint, so color can't carry meaning —
// the dock count itself is the headline. They show just the closest station.

/// Short text for error/empty states, shared by all accessory sizes.
private func statusText(_ entry: DockEntry) -> String? {
    switch entry.state {
    case .failed: "Couldn't load"
    case .noFavorites: "Star stations in the app"
    case .loaded: entry.stations.isEmpty ? "No stations" : nil
    }
}

/// Station name, docks, and bikes — about three lines of space.
struct RectangularView: View {
    let entry: DockEntry

    var body: some View {
        if let s = entry.stations.first {
            VStack(alignment: .leading, spacing: 0) {
                Text(s.name).font(.headline).lineLimit(1).widgetAccentable()
                Text("\(s.docks) docks").font(.body.bold())
                Text("\(s.classic) bikes · \(s.ebikes) e-bikes").font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Label(statusText(entry) ?? "", systemImage: "bicycle")
                .font(.caption)
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
                    Text("docks").font(.caption2)
                }
            }
        } else {
            Image(systemName: entry.state == .failed ? "exclamationmark.triangle" : "bicycle")
        }
    }
}

/// One line above the clock. Inline widgets only render a single Text/Label.
struct InlineView: View {
    let entry: DockEntry

    var body: some View {
        if let s = entry.stations.first {
            Label("\(s.docks) docks · \(s.name)", systemImage: "bicycle")
        } else {
            Label(statusText(entry) ?? "", systemImage: "bicycle")
        }
    }
}
