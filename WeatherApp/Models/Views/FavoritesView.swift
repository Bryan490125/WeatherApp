import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteLocation.sortOrder) private var favorites: [FavoriteLocation]
    @State private var showingSearch = false

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "No Saved Locations",
                        systemImage: "star.slash",
                        description: Text("Add a city to see it here.")
                    )
                } else {
                    List {
                        ForEach(favorites) { location in
                            Button {
                                setActive(location)
                            } label: {
                                HStack {
                                    Image(systemName: location.cachedConditionSFSymbol ?? "cloud.sun.fill")
                                        .font(.title2)
                                        .frame(width: 36)
                                    VStack(alignment: .leading) {
                                        HStack(spacing: 6) {
                                            Text(location.name).font(.headline)
                                            if location.isLastViewed {
                                                Image(systemName: "star.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.yellow)
                                            }
                                        }
                                        Text(location.country)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let temp = location.cachedTemp {
                                        Text("\(Int(temp.rounded()))°")
                                            .font(.title3.bold())
                                    }
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                        .onDelete(perform: deleteFavorites)
                        .onMove(perform: moveFavorites)
                    }
                }
            }
            .navigationTitle("My Locations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSearch = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingSearch) { SearchView() }
        }
    }

    private func setActive(_ location: FavoriteLocation) {
        for favorite in favorites {
            favorite.isLastViewed = (favorite.id == location.id)
        }
        try? modelContext.save()
    }

    private func deleteFavorites(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(favorites[index])
        }
        try? modelContext.save()
    }

    private func moveFavorites(from source: IndexSet, to destination: Int) {
        var reordered = favorites
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, location) in reordered.enumerated() {
            location.sortOrder = index
        }
        try? modelContext.save()
    }
}
