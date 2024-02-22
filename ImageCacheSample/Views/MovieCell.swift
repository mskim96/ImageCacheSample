/*
 Abstract:
 UICollectionViewCell for representing movie data in UICollectionView.
 */

import UIKit

class MovieCell: UICollectionViewCell {
    
    // 각각의 Cell에서 사용하는 MovieAsset을 추적하기 위한 Task.
    // prepareForReuse 또는 deinit 단계에서 해당 token은 전부 파기된다.
    // 중복 된 요청을 막기 위함
    var movieAssetToken: Task<MovieAsset, Error>?
    
    private let backdropImageView = UIImageView()
    private let titleLabel = UILabel()
    private let overviewLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        movieAssetToken?.cancel()
        movieAssetToken = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        movieAssetToken?.cancel()
        movieAssetToken = nil
    }
    
    func configureHierarchy() {
        // backdrop image 관련 설정
        backdropImageView.contentMode = .scaleAspectFill
        
        // title label 관련 설정
        titleLabel.textColor = .white
        titleLabel.font = .preferredFont(forTextStyle: .title3)
        titleLabel.numberOfLines = 2
        
        // overview label 관련 설정
        overviewLabel.textColor = .systemGray2
        overviewLabel.font = .preferredFont(forTextStyle: .callout)
        overviewLabel.numberOfLines = 3
        
        backdropImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        overviewLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(backdropImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(overviewLabel)
        
        NSLayoutConstraint.activate([
            // Backdrop image 의 가로:세로 비율을 2:1 로 조정.
            backdropImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backdropImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.0),
            backdropImageView.heightAnchor.constraint(equalTo: backdropImageView.widthAnchor, multiplier: 0.5),
            
            // Constraints of titleLabel.
            titleLabel.leadingAnchor.constraint(equalTo: backdropImageView.leadingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: backdropImageView.bottomAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: backdropImageView.trailingAnchor, constant: -8),
            
            // Constraints of overviewLabel.
            overviewLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            overviewLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            overviewLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            overviewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    /// Cell의 데이터를 구성.
    ///
    /// - Parameters:
    ///     - movie: `Movie` 데이터
    ///     - image: `Movie` 의 image
    public func configure(for movie: Movie, using asset: MovieAsset) {
        if movieAssetToken != nil {
            // Token이 존재한다면, 해당 task의 작업이 완료될 때 까지 기다려서
            //backdrop image 의 이미지를 변경한다.
            Task {
                let assetFromToken = try await movieAssetToken!.value
                backdropImageView.image = assetFromToken.backdropImage
            }
        } else {
            // Token 이 존재하지 않는다면, parameter로 받은 이미지로 초기화한다.
            backdropImageView.image = asset.backdropImage
        }
        titleLabel.text = movie.title
        overviewLabel.text = movie.overview
    }
}
