import WidgetKit
import SwiftUI
import BikeKit

struct DockWidgetView: View {
    let entry: DockEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Citi Bike").font(.caption.bold())
                Spacer()
                Text(entry.date, style: .time).font(.caption2).foregroundStyle(.secondary)
                Button(intent: RefreshIntent()) {
                    Image(systemName: "arrow.clockwise").font(.caption)
                }
                .buttonStyle(.plain)
            }

            switch entry.state {
            case .failed:
                message("Couldn't load")
            case .noFavorites:
                message("Star stations in the app")
            case .loaded where entry.stations.isEmpty:
                message("No stations found")
            case .loaded:
                ForEach(entry.stations) { row($0) }
            }

            Spacer(minLength: 0)   // top-align rows in the large size
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func row(_ s: NearbyStation) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(s.name).font(.caption.weight(.semibold)).lineLimit(1)
                Text("\(s.classic) bikes · \(s.ebikes) e-bikes").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(s.docks)").font(.title3.bold()).foregroundStyle(color(for: s.docks))
            Text("docks").font(.caption2)
        }
    }

    private func message(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(.secondary)
    }

    private func color(for docks: Int) -> Color { docks == 0 ? .red : docks <= 3 ? .orange : .green }
}

@main
struct DockWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "DockWidget", intent: DockConfig.self, provider: Provider()) {
            DockWidgetView(entry: $0)
        }
        .configurationDisplayName("Citi Bike Docks")
        .description("Open docks and bikes at nearby or favorite stations.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    DockWidget()
} timeline: {
    DockEntry.sample
    DockEntry(date: .now, stations: [], state: .noFavorites)
}
