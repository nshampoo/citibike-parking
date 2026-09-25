import AppIntents
import WidgetKit
import BikeKit

enum StationMode: String, AppEnum {
    case closest, favorites, destination, commute

    // Computed (not `static var x = ...`): Swift 6 rejects mutable globals.
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Stations" }
    static var caseDisplayRepresentations: [StationMode: DisplayRepresentation] {
        [.closest: "Closest to me", .favorites: "My favorites", .destination: "Near a destination",
         .commute: DisplayRepresentation(title: "Commute", subtitle: "Work until noon, then Home")]
    }
}

/// What the widget counts at each station — BikeKit's Need, as a widget setting.
enum CountKind: String, AppEnum {
    case docks, bikes, ebikes, classic

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Count" }
    static var caseDisplayRepresentations: [CountKind: DisplayRepresentation] {
        [.docks: "Open docks", .bikes: "Any bike", .ebikes: "E-bikes", .classic: "Classic bikes"]
    }

    var need: Need {
        switch self {
        case .docks: .dock
        case .bikes: .anyBike
        case .ebikes: .eBike
        case .classic: .classicBike
        }
    }
}

/// The per-widget setting shown under long-press > Edit Widget.
struct DockConfig: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Stations" }
    static var description: IntentDescription { "Choose which stations the widget shows." }

    @Parameter(title: "Show", default: .closest)
    var mode: StationMode

    @Parameter(title: "Destination")
    var destination: DestinationEntity?

    @Parameter(title: "Count", default: .docks)
    var counting: CountKind

    @Parameter(title: "Hide empty stations", default: false)
    var needsRoom: Bool

    // Only ask for a destination when that mode is picked.
    static var parameterSummary: some ParameterSummary {
        When(\DockConfig.$mode, .equalTo, StationMode.destination) {
            Summary {
                \.$mode
                \.$destination
                \.$counting
                \.$needsRoom
            }
        } otherwise: {
            Summary {
                \.$mode
                \.$counting
                \.$needsRoom
            }
        }
    }
}

/// The refresh button on the rectangular widget. perform() has nothing to do:
/// WidgetKit reloads the timeline after any Button(intent:) runs, which refetches.
struct RefreshIntent: AppIntent {
    static var title: LocalizedStringResource { "Refresh Citi Bike" }
    static var isDiscoverable: Bool { false }   // widget-only; hide from Shortcuts

    func perform() async throws -> some IntentResult { .result() }
}
