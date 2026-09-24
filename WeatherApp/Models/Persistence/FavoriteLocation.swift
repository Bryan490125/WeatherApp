import Foundation
import SwiftData

/// A user-saved location, persisted locally with SwiftData.
/// This is what satisfies the "data persistence" requirement:
/// favorites survive relaunches without hitting the network again.
@Model
final class FavoriteLocation {
    @Attribute(.unique) var id: String
    var name: String
    var country: String
    var latitude: Double
    var longitude: Double
    var sortOrder: Int
    var isLastViewed: Bool

    // Simple cache so Home/Favorites can show something instantly
    // before the network refresh completes.
    var cachedTemp: Double?
    var cachedConditionSFSymbol: String?
    var cachedConditionText: String?
    var cachedAt: Date?

    init(name: String, country: String, latitude: Double, longitude: Double, sortOrder: Int = 0, isLastViewed: Bool = false) {
        self.id = "\(name)-\(latitude)-\(longitude)"
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.sortOrder = sortOrder
        self.isLastViewed = isLastViewed
    }
}
