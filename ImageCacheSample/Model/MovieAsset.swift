/*
 Abstract:
 A structure for image asset of movie.
 */

import UIKit

final class MovieAssetObject {
    var entry: MovieAsset
    init(entry: MovieAsset) {
        self.entry = entry
    }
}

/// Asset struct of movie data.
///
/// - Parameters:
///     - id: id of Asset
///     - isPlaceholder: image가 placeholder인지 나타내는 플래그
///     - backdropImage: 영화의 backdropImage
struct MovieAsset: Identifiable {
    var id: String
    var isPlaceholder: Bool
    var backdropImage: UIImage
    
    /// Backdrop Image를 설정한다.
    ///
    /// - Parameters:
    ///     - image: 설정할 image source
    /// - Returns: backdropImage가 설정된 `MovieAsset`
    func setBackdropImage(_ image: UIImage) -> MovieAsset {
        var this = self
        this.backdropImage = image
        return this
    }
}
