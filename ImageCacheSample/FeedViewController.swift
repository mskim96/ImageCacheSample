/*
 Abstract:
 A viewController for representing the list of movie data.
 */

import UIKit

class FeedViewController: UIViewController {
    
    private enum Section {
        case main
    }
    
    private let movieProvider = MovieProvider()
    private let assetProvider = MovieAssetProvider()
    
    private var collectionView: UICollectionView! = nil
    private var dataSource: UICollectionViewDiffableDataSource<Section, Movie.ID>! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationItem()
        configureHierarchy()
        configureDataSource()
        
        Task {
            try await movieProvider.fetchMovies()
            setInitialData()
        }
    }
}

// MARK: - Layout Creation and Hiearachy configuration

extension FeedViewController {
    /// Collection view 구성
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // Navigationbar 구성
    private func configureNavigationItem() {
        navigationItem.title = "Feed"
        
        let buttonImage = UIImage(systemName: "folder.badge.minus")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: buttonImage,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(clearCacheDirectory))
    }
    
    // Card 형식 그리드 레이아웃 구성
    private func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int,
                                 layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            // ItemSize는 가로전체 영역에, 세로 추정치 350.
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(350))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // GroupSize는 가로전체 영역에, 세로 추정치 350
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(350))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            // 섹션의 내부 아이템 즉 group간의 spacing 조정.
            section.interGroupSpacing = 40
            // Section 자체의 inset 설정. collectionView와 섹션간의 간격이 됨.
            section.contentInsets = NSDirectionalEdgeInsets(top: 32, leading: 0, bottom: 16, trailing: 0)
            return section
        }
        let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
        return layout
    }
    
    func showCacheClearAlert() {
        let title = "알림"
        let message = "Local cache를 삭제하였습니다. 확인하려면 앱을 재 시동 해주세요."
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        present(alertController, animated: true)
    }
}

extension FeedViewController {
    func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration { [weak self]
            (cell: MovieCell, indexPath: IndexPath, movieID: Movie.ID) in
            guard let self = self else { return }
            
            // movie data 를 받아온다.
            let movie = self.movieProvider.getMovie(with: movieID)
            // movie data의 imageURL이 /로 시작하기 때문에 앞글자를 삭제하여 movieAssetID 을 정의한다.
            let movieAssetId = String(movie.backdropImageURL.absoluteString.dropFirst())
            
            // 이 부분을 사용하지 않으면, MovieAsset의 이미지 파일을 다 불러올때까지 cell에 movie의 정보조차 표시되지
            // 않으므로 기본 아무것도 존재하지 않는 이미지를 사용해 Movie data를 한번 초기화 시킨다.
            let placeholderAsset = MovieAsset(id: "", isPlaceholder: true, backdropImage: UIImage())
            cell.configure(for: movie, using: placeholderAsset)
            
            Task {
                let movieAsset = await self.assetProvider.fetchImage(with: movieAssetId)
                // 기존 movieAssetToken을 가져온다.
                var assetToken = cell.movieAssetToken
                
                // asset이 placeholder이거나, token이 존재하지 않을 경우 asset provider에서 asset을 가져오는
                // task를 가져온다.
                if movieAsset.isPlaceholder && assetToken == nil {
                    let task = try await self.assetProvider.prepareAssetIfNeeded(with: movieAssetId)
                    assetToken = task
                    await self.assetProvider.clearRequestCache(with: movieAssetId)
                    self.setFeedNeedsUpdate(movieID)
                }
                // cell 에 token을 할당한다. nil 또는, task
                cell.movieAssetToken = assetToken
                cell.configure(for: movie, using: movieAsset)
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            (collectionView, indexPath, identifier) in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration,
                                                                for: indexPath,
                                                                item: identifier)
        }
    }
    
    private func setFeedNeedsUpdate(_ id: Movie.ID) {
        var snapshot = self.dataSource.snapshot()
        snapshot.reconfigureItems([id])
        self.dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    
    private func setInitialData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Movie.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(movieProvider.movies.map { $0.id })
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    /// Cache Directory 를 초기화한다.
    @objc
    private func clearCacheDirectory() {
        Task {
            do {
                try await self.assetProvider.clear()
                showCacheClearAlert()
            } catch {
                debugPrint("Cache clearing failed.")
            }
        }
    }
}
