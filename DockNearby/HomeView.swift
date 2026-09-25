import SwiftUI
import MapKit
import BikeKit

/// Full-screen map with a draggable station sheet floating over it, Apple Maps style.
struct HomeView: View {
    @Environment(LocationModel.self) private var location
    @Environment(FavoritesStore.self) private var favorites
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("onlyWithRoom") private var onlyWithRoom = false

    @State private var model = HomeModel()
    #if DEBUG
    @Environment(DestinationsStore.self) private var destinations
    #endif

    /// SwiftUI maps slow down with thousands of annotations, so draw at most this many.
    private static let maxPins = 150
    /// Covers the whole Citi Bike area with room to spare, so the wash has no visible edge.
    private static let washArea = [
        CLLocationCoordinate2D(latitude: 38, longitude: -77), CLLocationCoordinate2D(latitude: 38, longitude: -71),
        CLLocationCoordinate2D(latitude: 43, longitude: -71), CLLocationCoordinate2D(latitude: 43, longitude: -77),
    ]

    private var mapWash: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.12, blue: 0.14).opacity(0.55)
            : Color.white.opacity(0.2)
    }

    /// Zoomed out past ~3 km of latitude, pins drop their numbers and become dots.
    private static let numbersBelowSpan = 0.03

    var body: some View {
        map
            // Always on screen; drag it between peek, half, and full height.
            .sheet(isPresented: .constant(true)) {
                StationsSheet(model: model)
                    .presentationDetents([HomeModel.peek, HomeModel.half, .large], selection: $model.detent)
                    // Keep the map usable below full height, so you can pan and tap pins.
                    .presentationBackgroundInteraction(.enabled(upThrough: HomeModel.half))
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled()
                    .translucentSheetBackground()
            }
            .task {
                await model.load(near: location.location)
                model.keepCameraInServiceArea(user: location.location)
                #if DEBUG
                applyScreenshotArguments()
                #endif
            }
            .onChange(of: location.location) { _, user in model.keepCameraInServiceArea(user: user) }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await model.load(near: location.location) } }
            }
    }

    private var map: some View {
        Map(position: $model.camera) {
            // A translucent graphite wash over the tiles (under labels and pins) pulls the
            // map's navy/teal/purple toward neutral grey so it matches the app's palette.
            MapPolygon(coordinates: Self.washArea)
                .foregroundStyle(mapWash)
                .mapOverlayLevel(level: .aboveRoads)
            UserAnnotation()
            if let destination = model.destination {
                Marker(destination.name, systemImage: "mappin", coordinate: destination.coordinate)
                    .tint(.purple)
            }
            let compact = (model.visibleRegion?.span.latitudeDelta ?? 0) > Self.numbersBelowSpan
            ForEach(pins) { s in
                Annotation(s.name, coordinate: s.coordinate) {
                    // A real Button (not onTapGesture) so VoiceOver can read and activate pins.
                    Button { model.select(s, moveMap: false) } label: {
                        StationPin(docks: s.docks, isFavorite: favorites.contains(s.id),
                                   isSelected: s.id == model.selectedID, isDimmed: onlyWithRoom && !s.hasRoom,
                                   isCompact: compact && s.id != model.selectedID)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(pinLabel(s))
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { model.visibleRegion = $0.region }
        // Top padding lines it up with the system location button on the right.
        .overlay(alignment: .topLeading) { aboutButton.padding(.leading).padding(.top, 16) }
    }

    /// Opens the About popup. The sheet presents it, since the map's view controller
    /// is already busy presenting the sheet.
    private var aboutButton: some View {
        Button { model.showingAbout = true } label: {
            Image(systemName: "info")
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 32)
        }
        .glassCircle()
        .accessibilityLabel("About Park It")
    }

    private func pinLabel(_ s: NearbyStation) -> String {
        let docks = s.docks == 1 ? "1 open dock" : "\(s.docks) open docks"
        return [s.name, docks, favorites.contains(s.id) ? "favorite" : nil].compactMap { $0 }.joined(separator: ", ")
    }

    /// Stations inside the visible region; if there are too many, the ones nearest its center.
    private var pins: [NearbyStation] {
        guard let r = model.visibleRegion else { return [] }
        let inView = model.stations.filter {
            abs($0.latitude - r.center.latitude) <= r.span.latitudeDelta / 2
                && abs($0.longitude - r.center.longitude) <= r.span.longitudeDelta / 2
        }
        guard inView.count > Self.maxPins else { return inView }
        let center = CLLocation(latitude: r.center.latitude, longitude: r.center.longitude)
        return Array(inView.sorted { $0.distance(from: center) < $1.distance(from: center) }.prefix(Self.maxPins))
    }
}

private extension View {
    /// A floating round button: Liquid Glass on iOS 26, a material before.
    /// (Use the glass button style, not .glassEffect(.interactive()) on a plain button —
    /// that glass swallows the tap and the action never runs.)
    @ViewBuilder func glassCircle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glass).buttonBorderShape(.circle)
        } else {
            buttonStyle(.plain).padding(6).background(.regularMaterial, in: .circle).shadow(radius: 2)
        }
    }

    /// iOS 26 gives partial-height sheets Liquid Glass on its own; earlier versions get a material.
    @ViewBuilder func translucentSheetBackground() -> some View {
        if #available(iOS 26, *) {
            self
        } else {
            presentationBackground(.regularMaterial)
        }
    }
}

#if DEBUG
extension HomeView {
    /// Debug-only launch arguments that stage App Store screenshots without tapping:
    ///   -screenshotCard    open the first favorite's (or nearest roomy station's) card
    ///   -screenshotPlaces  save demo Home/Work if missing and show docks near Work
    private func applyScreenshotArguments() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-screenshotCard"),
           let s = model.stations.first(where: { favorites.contains($0.id) })
               ?? model.stations.first(where: { $0.docks > 5 }) {
            model.select(s, moveMap: true)
        }
        if args.contains("-screenshotPlaces") {
            if destinations.home == nil {
                destinations.add(name: "Home", kind: .home, at: .init(latitude: 40.7781, longitude: -73.9820))
            }
            if destinations.work == nil {
                destinations.add(name: "Work", kind: .work, at: .init(latitude: 40.7527, longitude: -73.9772))
            }
            if let work = destinations.work { model.show(work) }
        }
    }
}
#endif
