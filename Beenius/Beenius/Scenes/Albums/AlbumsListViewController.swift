//
//  AlbumsListViewController.swift
//  Beenius
//
//  Created by Marcel Salej on 10/10/2019.
//  Copyright © 2019 Marcel Salej. All rights reserved.
//

import UIKit

protocol AlbumsListDisplayLogic: AnyObject {
  func displayAlbumsListSuccess(viewModels: [AlbumsListViewController.ViewModel])
  func displayAlbumsListFailure(error: NetworkError)
}

class AlbumsListViewController: UIViewController {
  var interactor: AlbumsListBusinessLogic?
  var router: AlbumsListRoutingLogic?
  private lazy var contentView = AlbumsListContentView.setupAutoLayout()
  private let user: User
  private let dataSource = AlbumsDataSource()
  private var viewModels = [ViewModel]()
  
  init(delegate: AlbumsListRouterDelegate?, user: User) {
    self.user = user
    super.init(nibName: nil, bundle: nil)
    let interactor = AlbumsListInteractor()
    let presenter = AlbumsListPresenter()
    let router = AlbumsListRouter()
    interactor.presenter = presenter
    presenter.viewController = self
    router.viewController = self
    router.delegate = delegate
    self.interactor = interactor
    self.router = router
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    fetchUserAlbums(userId: user.id)
  }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    contentView.tableView.deselectSelectedRow()
  }
}

// MARK: - Load data
extension AlbumsListViewController {
  func fetchUserAlbums(userId: Int) {
    contentView.toggleLoading(true)
    interactor?.fetchAlbumList(for: userId)
  }
}

// MARK: - Display Logic
extension AlbumsListViewController: AlbumsListDisplayLogic {
  func displayAlbumsListSuccess(viewModels: [AlbumsListViewController.ViewModel]) {
    self.viewModels = viewModels
    dataSource.setData(viewModels: viewModels)
    contentView.tableView.reloadData()
    contentView.toggleLoading(false)
    contentView.refreshControl.endRefreshing()
  }
  
  func displayAlbumsListFailure(error: NetworkError) {
    dataSource.setData(viewModels: [])
    contentView.toggleLoading(false)
    contentView.setupNoDataView()
    contentView.tableView.reloadData()
    contentView.refreshControl.endRefreshing()
  }
}

// MARK: - UI setup
private extension AlbumsListViewController {
  func setupViews() {
    setupNavigationHeader()
    setupContentView()
  }
  
  func setupContentView() {
    view.addSubview(contentView)
    contentView.backgroundColor = .white
    contentView.tableView.dataSource = dataSource
    contentView.tableView.delegate = self
    contentView.refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
    contentView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }
  
  func setupNavigationHeader() {
    navigationItem.title = "Albums"
  }
}

private extension AlbumsListViewController {
  @objc func didPullToRefresh() {
    interactor?.fetchAlbumList(for: user.id)
  }
}

// MARK: - UITableViewDelegate
extension AlbumsListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    viewModels[safe: indexPath.row].map {
      router?.navigateToPhotos(user: user, selectedAlbum: $0)
      return
    }
    contentView.tableView.deselectSelectedRow()
  }
}

extension AlbumsListViewController {
  struct ViewModel {
    let album: Album
    let photos: [Photo]
  }
}
