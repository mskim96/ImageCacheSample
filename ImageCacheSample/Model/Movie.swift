/*
 Abstract:
 A structure for representing movie data.
 */

import Foundation

struct Movie: Identifiable {
    let id: Int
    let title: String
    let overview: String
    let releaseDate: Date
    let backdropImageURL: URL
}

// MARK: - Decodable

extension Movie: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case releaseDate = "release_date"
        case backdropImageURL = "backdrop_path"
    }
}
