import WidgetKit
import SwiftUI
import BikeKit

/// Picks the layout for whichever Lock Screen size the user placed.
struct DockWidgetView: View {
    let entry: DockEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            RectangularView(entry: entry).containerBackground(.clear, for: .widget)
        case .accessoryCircular:
            CircularView(entry: entry).containerBackground(for: .widget) { AccessoryWidgetBackground() }
        default:
            InlineView(entry: entry).containerBackground(.clear, for: .widget)
        }
    }
}

@main
struct DockWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "DockWidget", intent: DockConfig.self, provider: Provider()) {
            DockWidgetView(entry: $0)
        }
        .configurationDisplayName("Citi Bike Docks")
        .description("Open docks at nearby, favorite, or destination stations.")
        // Lock Screen only — the official Citi Bike app covers the home screen.
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

#Preview(as: .accessoryRectangular) { DockWidget() } timeline: {
    DockEntry.sample
    DockEntry(date: .now, stations: [], state: .noFavorites)
}
#Preview(as: .accessoryCircular) { DockWidget() } timeline: { DockEntry.sample }
#Preview(as: .accessoryInline) { DockWidget() } timeline: { DockEntry.sample }
