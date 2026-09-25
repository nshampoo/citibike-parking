import SwiftUI
import MapKit
import BikeKit

/// Full-screen map with a draggable station sheet floating over it, Apple Maps style.
struct HomeView: View {
    @Environment(LocationModel.self) private var location
    @Environment(FavoritesStore.self) private var favorites
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("onlyWithRoom") private var onlyWithRoom = false

    @State private var model = HomeModel()

    /// SwiftUI maps slow down with thousands of annotations, so draw at most this many.
    private static let maxPins = 150

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
            .task { await model.load(near: location.location) }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await model.load(near: location.location) } }
            }
    }

    private var map: some View {
        Map(position: $model.camera) {
            UserAnnotation()
            if let destination = model.destination {
                Marker(destination.name, systemImage: "mappin", coordinate: destination.coordinate)
                    .tint(.purple)
            }
            ForEach(pins) { s in
                Annotation(s.name, coordinate: s.coordinate) {
                    StationPin(docks: s.docks, isFavorite: favorites.contains(s.id),
                               isSelected: s.id == model.selectedID, isDimmed: onlyWithRoom && !s.hasRoom)
                        .onTapGesture { model.select(s, moveMap: false) }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { model.visibleRegion = $0.region }
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
    /// iOS 26 gives partial-height sheets Liquid Glass on its own; earlier versions get a material.
    @ViewBuilder func translucentSheetBackground() -> some View {
        if #available(iOS 26, *) {
            self
        } else {
            presentationBackground(.regularMaterial)
        }
    }
}
