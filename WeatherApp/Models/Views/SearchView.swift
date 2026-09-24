import SwiftUI
import SwiftData

struct SearchView: View {
    var onDone: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var favorites: [FavoriteLocation]

    @State private var query = ""
    @State private var results: [GeoResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                }

                ForEach(results) { result in
                    Button {
                        addFavorite(result)
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)

                            VStack(alignment: .leading) {
                                Text(result.displayName)
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            if isAlreadySaved(result) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "plus.circle")
                            }
                        }
                    }
                    .disabled(isAlreadySaved(result))
                }
            }
            .overlay {
                if isSearching {
                    ProgressView()
                }
            }
            .navigationTitle("Search Cities")
            .searchable(
                text: $query,
                prompt: "Search for a city"
            )
            .onChange(of: query) { _, newValue in
                searchTask?.cancel()

                searchTask = Task {
                    await search(newValue)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        query = ""

                        if let onDone {
                            onDone()
                        } else {
                            dismiss()
                        }
                    }
                }
            }
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    private func isAlreadySaved(_ result: GeoResult) -> Bool {
        favorites.contains {
            $0.id == "\(result.name)-\(result.lat)-\(result.lon)"
        }
    }

    private func search(_ text: String) async {
        let trimmedText = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard trimmedText.count >= 2 else {
            results = []
            errorMessage = nil
            return
        }

        do {
            try await Task.sleep(
                for: .milliseconds(300)
            )
        } catch {
            return
        }

        guard !Task.isCancelled else {
            return
        }

        isSearching = true
        errorMessage = nil

        defer {
            isSearching = false
        }

        do {
            results = try await WeatherService.shared.searchCity(
                named: trimmedText
            )
        } catch {
            guard !Task.isCancelled else {
                return
            }

            results = []
            errorMessage = error.localizedDescription
        }
    }

    private func addFavorite(_ result: GeoResult) {
        guard !isAlreadySaved(result) else {
            return
        }

        // Make the newly added location active on the Home screen.
        for favorite in favorites {
            favorite.isLastViewed = false
        }

        let newLocation = FavoriteLocation(
            name: result.name,
            country: result.country,
            latitude: result.lat,
            longitude: result.lon,
            sortOrder: favorites.count,
            isLastViewed: true
        )

        modelContext.insert(newLocation)

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Couldn't save this location."
        }
    }
}
