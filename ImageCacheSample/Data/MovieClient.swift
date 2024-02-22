/*
 Abstract:
 A class to fetch and cache movie data from remove network.
 */

import Foundation

/// Network error state를 나타낸다.
enum NetworkError: Error {
    case invalidResponse
    case invalidURL
}

private let validStatus = 200...299
private let headers = [
    "accept": "application/json",
    "Authorization": Bundle.main.authToken
]

class MovieClient {
    
    private lazy var decoder: JSONDecoder = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let aDecoder = JSONDecoder()
        aDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        return aDecoder
    }()
    
    func fetchMovies(with page: Int = 1) async throws -> [Movie] {
        // Page query를 위한 URLComponents 정의
        let urlComponents = makeMovieURLComponents(with: page)
        
        // API가 요구하는 Header과 함께, URL request 정의
        guard let url = urlComponents.url else { throw NetworkError.invalidURL }
        let request = makeMovieRequests(with: url)
        
        // URLSession을 이용하여, data를 받아오고 해당 response가 http 통신 성공 범위에 있는지 확인
        guard let (data, response) = try await URLSession.shared.data(for: request) as? (Data, HTTPURLResponse),
              validStatus.contains(response.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        // movieRespons 를 decoding하고 movie array 반환
        let movieResponse = try decoder.decode(MovieResponse.self, from: data)
        return movieResponse.movies
    }
    
    func makeMovieRequests(with url: URL) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        return request
    }
    
    func makeMovieURLComponents(with page: Int = 1) -> URLComponents {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.themoviedb.org"
        urlComponents.path = "/3/movie/upcoming"
        urlComponents.queryItems = [URLQueryItem(name: "page", value: String(page))]
        return urlComponents
    }
}
