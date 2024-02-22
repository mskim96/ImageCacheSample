/*
 Abstract:
 The class for caching images using a local files approach.
 */

import UIKit
import UniformTypeIdentifiers

class LocalCache {
    
    var fileManager: FileManager
    var imageFormat: UTType
    var directoryURL: URL
    
    init(directoryURL: URL,
         imageFormat: UTType,
         fileManager: FileManager
    ) {
        self.directoryURL = directoryURL
        self.imageFormat = imageFormat
        self.fileManager = fileManager
    }
    
    // MARK: - Default behaviors
    
    /// FileManager에 Directory가 없으면 새로 생성하고, 있다면 아무 동작하지 않는다.
    func createDirectoryIfNeeded() throws {
        try fileManager.createDirectory(at: self.directoryURL,
                                        withIntermediateDirectories: true)
    }
    
    // Movie asset의 ID 에 해당하는 MovieAsset을 가져온다.
    ///
    /// - Parameters:
    ///     - id: the id of `MovieAsset`
    func fetch(with id: MovieAsset.ID) -> MovieAsset? {
        guard let image = UIImage(contentsOfFile: fileURL(for: id).path) else {
            return nil
        }
        return MovieAsset(id: id, isPlaceholder: false, backdropImage: image)
    }
    
    /// Image를 downsampling한 후, 지정 된 경로에 downsampling 된 image를 저장한다.
    ///
    /// - Parameters:
    ///     - sourceURL: Image source의 URL
    ///     - id: 파일 경로 찾기에 사용 할 `MovieAsset`의 ID
    func save(_ sourceURL: URL, for id: MovieAsset.ID) {
        self.downsample(from: sourceURL, to: self.fileURL(for: id))
    }
    
    /// Cache를 전부 clear하고, Directory를 새로 생성한다.
    func clear() throws {
        try fileManager.removeItem(at: self.directoryURL)
        try createDirectoryIfNeeded()
    }
    
    /// 새로운 Directory의 URL을 받는다.
    ///
    /// - Parameters:
    ///     - id: `MovieAsset`의 ID
    /// - Returns: MovieAsset의 ID로 생성한 Local file의 URL
    func fileURL(for id: MovieAsset.ID) -> URL {
        // e.g)   Cache        /DFASD-VZXC-2134                 .jpeg
        return directoryURL.appendingPathComponent(id).appendingPathExtension(for: imageFormat)
    }
    
    // MARK: - Releated Downsampling
    
    /// Image를 downsampling한 후, 지정 된 경로에 image 결과를 추가한다.
    ///
    /// - Parameters:
    ///     - sourceURL: URL of image source
    ///     - destinationURL: 결과를 저장할 경로의 URL
    func downsample(from sourceURL: URL, to destinationURL: URL) {
        let readOptions: [CFString: Any] = [
            // 새 이미지를 저장할 때 추가 메모리를 유지하지 않기 위해 false 설정
            // Image downsampling 작업을 수행할 때 추가적인 메모리 사용을 최소화
            // 하기 위해서 해상도를 줄이는데, 이미지를 캐시한다면 이미지를 메모리에 보관
            // 하기때문에 추가메모리를 사용한다. 이는 성능에 영향을 줄 수 있다.
            kCGImageSourceShouldCache: false
        ]
        
        // 원본 Image source URL을 Read option과 함께 CFImageSource 생성한다.
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, readOptions as CFDictionary)
        else {
            return
        }
        
        let imageSize = sizeFromImageSource(source)
        
        let writeOptions = [
            // Image를 읽을때, 필요한 만큼의 데이터만 읽는다.
            // subsampleFactor 은 2,4,8 등의 값을 받으며, 작성한 subsampleFactor은 5등의 값을 반환할 수도 있다.
            // (이 때 2, 4, 8등에 가까운 값으로 반올림 된다고 추정한다.)
            kCGImageSourceSubsampleFactor: subsampleFactor(maxPixelSize: 800, imageSize: imageSize),
            // Data를 write할 때, 가장 긴 dimension 설정.
            kCGImageDestinationImageMaxPixelSize: 800,
            // 이미지를 가능한 한 줄인다.
            kCGImageDestinationLossyCompressionQuality: 0.0
        ].merging(readOptions, uniquingKeysWith: { aSide, bSide in aSide })
        
        // DestinationURL과 Write option을 사용하여 새로운 ImageDestination 생성한다.
        guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL,
                                                                imageFormat.identifier as CFString,
                                                                1,
                                                                writeOptions as CFDictionary)
        else {
            return
        }
        
        // Image source의 image를 image destination에 추가한다.
        CGImageDestinationAddImageFromSource(destination, source, 0, writeOptions as CFDictionary)
        // Image destination과 연결된 URL에 Image data를 write한다.
        CGImageDestinationFinalize(destination)
    }
    
    /// Image의 축소율을 결정한다.
    ///
    /// - Returns: 축소 비율
    func subsampleFactor(maxPixelSize: Int, imageSize: CGSize) -> Int {
        // 이미지의 가로와 세로 중 더 큰값을 선택하고, maxPixelSize로 나눈다.
        // 이 결과는 이미지의 larger Dimension이 maxPixcelSize보다 클 때 이미지를 축소해야 하는 정도를 나타낸다.
        let largerDimensionMultiple = max(imageSize.width, imageSize.height) / CGFloat(maxPixelSize)
        // 로그를 사용하여 위 값을 계산한다.
        let subsampleFactor = floor(log2(largerDimensionMultiple))
        return Int(subsampleFactor.rounded(.towardZero))
    }
    
    /// Image source로부터 Size를 추출한다.
    ///
    /// - Parameters:
    ///     - source: image 의 source
    /// - Returns: Image source의 CGSize
    func sizeFromImageSource(_ source: CGImageSource) -> CGSize {
        let options: [CFString: Any] = [
            // memory에서 읽기전에 이미지 사이즈를 가져온다.
            kCGImageSourceShouldCache: false
        ]
        
        // Imagesource의 이미지 속성을 반환한다.
        let properties = CGImageSourceCopyPropertiesAtIndex(
            source, 0, options as NSDictionary
        ) as? [String: CFNumber]
        
        // width와 height를 추출하고, 없다면 1을 반환
        let width = properties?[kCGImagePropertyPixelWidth as String] ?? 1 as CFNumber
        let height = properties?[kCGImagePropertyPixelHeight as String] ?? 1 as CFNumber
        
        return CGSize(width: Int(truncating: width), height: Int(truncating: height))
    }
}
