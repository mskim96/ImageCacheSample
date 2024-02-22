/*
 Abstract:
 The movie asset provider.
 */

import UIKit
import UniformTypeIdentifiers

actor MovieAssetProvider {
    
    private enum MovieAssetError: Error {
        case invalidImage
        case preparingImageFailed
    }
    
    private let fileManager: FileManager = .default
    private let localCache: LocalCache
    // Memory cache for movie asset.
    var movieAssets = NSCache<NSString, MovieAssetObject>()
    
    init() {
        // Caches directory의 하위에 movie-assets directory 생성.
        let cacheDirectory = try! fileManager.url(for: .cachesDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
            .appendingPathComponent("movie-assets", isDirectory: true)
        self.localCache = LocalCache(directoryURL: cacheDirectory,
                                     imageFormat: .jpeg,
                                     fileManager: fileManager)
        try! localCache.createDirectoryIfNeeded()
    }
    
    /// MovieAsset의 ID에 맞는 MovieAsset을 가져온다.
    func fetchImage(with id: MovieAsset.ID) -> MovieAsset {
        // Memory cache에 asset이 존재한다면 반환한다
        if let asset = movieAssets[id] {
            return asset
        }
        // localCache에서 asset을 가져오고 만약 없다면, 빈 이미지를 반환한다.
        return localCache.fetch(with: id) ?? MovieAsset(id: id, isPlaceholder: true, backdropImage: UIImage())
    }
    
    /// LocalCache의 데이터를 전부 삭제한다.
    func clear() throws {
        try localCache.clear()
    }
    
    /// 해당 MovieAsset에 대한 task를 관리하는 cache.
    private var requestsCache: [MovieAsset.ID: Task<MovieAsset, Error>] = [:]
    /// 동일한 요청을 여러번 하지 않기 위해서 조건에 따라 Task를 반환한다.
    func prepareAssetIfNeeded(with id: MovieAsset.ID) async throws -> Task<MovieAsset, Error> {
        // 이미 Request를 보내서, cache에 존재한다면 존재하는 task를 반환한다.
        if let request = requestsCache[id] {
            return request
        }
        // 없다면 MovieAsset을 반환하는 Task를 생성한다.
        let task = Task<MovieAsset, Error> {
            let preparedAsset = try await prepareMovieAsset(with: id)
            return preparedAsset
        }
        
        requestsCache[id] = task
        return task
    }
    
    // Request작업이 끝난 후 해당 Dictionary에서 작업을 삭제한다.
    func clearRequestCache(with id: MovieAsset.ID) {
        requestsCache.removeValue(forKey: id)
    }
    
    /// LocalCache 또는 Network에서 MovieAsset을 가져온다.
    private func prepareMovieAsset(with id: MovieAsset.ID) async throws -> MovieAsset {
        // LocalCache에 Asset이 있다면 MemoryCache에 해당 Asset을 저장하고 MovieAsset 반환
        if let localMovieAsset = localCache.fetch(with: id) {
            self.movieAssets[id] = localMovieAsset
            return localMovieAsset
        }
        // 없다면, Network에서 MovieAsset을 가져온다.
        let movieAsset = try await makeMovieAssetRequest(with: id)
        // decode작업이 메모리를 많이 소비하므로 main thread가 아닌 background thread로 decode작업을 보낸다.
        guard let preparedImage = movieAsset.backdropImage.preparingForDisplay() else {
            throw MovieAssetError.preparingImageFailed
        }
        let backdropImage = movieAsset.setBackdropImage(preparedImage)
        self.movieAssets[id] = backdropImage
        return backdropImage
    }
    
    /// Movie Asset을 다운로드하고, 해당 Download 한 Asset을 받아온다.
    private func makeMovieAssetRequest(with id: MovieAsset.ID) async throws -> MovieAsset {
        try await makeMovieAssetDownload(for: id)
        guard let movieAsset = self.localCache.fetch(with: id) else {
            throw CocoaError.error(.fileNoSuchFile)
        }
        return movieAsset
    }
    
    /// Movie Asset을 다운로드하고 지정 된 목적지 URL에 저장한다.
    ///
    /// - Parameters:
    ///     - id: Movie Asset의 ID
    ///     - destinationURL: data를 저장할 목적지 URL
    private func makeMovieAssetDownload(for id: MovieAsset.ID) async throws {
        let url = try imageURL(id)
        // * Network 지연 테스트용 *
        try await Task.sleep(for: .seconds(UInt8.random(in: 0...4)))
        let (data, _) = try await URLSession.shared.data(from: url)
        // Data가 유효한지 UIImage에 넣어서 확인.
        guard let _ = UIImage(data: data) else { throw MovieAssetError.invalidImage }
        localCache.save(url, for: id)
    }
    
    /// Movie Asset의 ID가 이미지를 불러오는 Full URL의 일부이므로,
    /// 해당 ID로 전체 이미지를 불러오는 URL로 변경한다.
    ///
    /// - Parameters:
    ///     - id: Movie Asset의 ID
    /// - Returns: Image를 불러올 수 있는 전체 URL
    private func imageURL(_ id: MovieAsset.ID) throws -> URL {
        let fullURL = URL(string: "https://image.tmdb.org/t/p/original/\(id)")
        guard let fullURL = fullURL else { throw NetworkError.invalidURL }
        return fullURL
    }
}
