/*
 Abstract:
 A class to provide movies and related methods.
 */

import Foundation

class MovieProvider {
    
    private let client: MovieClient = MovieClient()
    // Dictionary for movie model.
    var movies = [Movie]()
    
    /// Movie를 Network client로부터 fetch하고 provider의
    /// Array에 초기화 한다.
    ///
    /// - Parameters:
    ///     - page: network에 요청할 movie data의 page
    func fetchMovies(with page: Int = 1) async throws {
        let movies = try await client.fetchMovies(with: page)
        self.movies = movies
    }
    
    /// Movie의 ID에 맞는 Movie object를 가져온다.
    ///
    /// - Parameters:
    ///     - id: id of the movie.
    func getMovie(with id: Movie.ID) -> Movie {
        guard let movie = movies.first(where: { $0.id == id }) else {
            fatalError("The movie doen't exist")
        }
        return movie
    }
}
