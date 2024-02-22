/*
 Abstract:
 A structure for representing Movie response.
 */

import Foundation

struct MovieResponse {
    let totalPage: Int
    let currentPage: Int
    let movies: [Movie]
}

// MARK: - Decodable

extension MovieResponse: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case totalPage = "total_pages"
        case currentPage = "page"
        case movies = "results"
    }
}
