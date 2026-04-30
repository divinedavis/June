import Combine
import MapKit
import SwiftUI

/// Wraps MKLocalSearchCompleter with debouncing + region biasing so the home
/// sheet can show "places near me" suggestions as the user types.
@MainActor
final class SearchSuggestionsManager: NSObject, ObservableObject {
    @Published private(set) var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()
    private var debounceTask: Task<Void, Never>?

    var region: MKCoordinateRegion? {
        didSet {
            if let region { completer.region = region }
        }
    }

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    /// Call on every text-field change. Suggestions clear under 3 characters.
    func update(query: String) {
        debounceTask?.cancel()
        guard query.count >= 3 else {
            suggestions = []
            return
        }
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 180_000_000) // 180 ms debounce
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.completer.queryFragment = query
            }
        }
    }

    /// Convert a completion the user tapped into a concrete MKMapItem the rest
    /// of the app can render via PlaceDetailView.
    func resolve(_ completion: MKLocalSearchCompletion) async -> MKMapItem? {
        let request = MKLocalSearch.Request(completion: completion)
        if let region { request.region = region }
        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.first
        } catch {
            return nil
        }
    }
}

extension SearchSuggestionsManager: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            self.suggestions = results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.suggestions = []
        }
    }
}
