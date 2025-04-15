// Updated enum to include new visibility levels
enum LocationVisibilityLevel: String, CaseIterable {
    case everyone = "Everyone"
    case friendsOnly = "Friends Only"
    case selectiveFriends = "Only These Friends"
    case allExcept = "All Friends Except"
    case nobody = "Nobody"
}
