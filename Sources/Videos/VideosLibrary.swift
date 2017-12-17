import UIKit
import Photos

@objc(VideosLibrary)
class VideosLibrary : NSObject {

  @objc open var items: [Video] = []
  @objc open var fetchResults: PHFetchResult<PHAsset>?

  // MARK: - Initialization

  override init() {

  }

  // MARK: - Logic

  func reload(_ completion: @escaping () -> Void) {
    DispatchQueue.global().async {
      self.reloadSync()
      DispatchQueue.main.async {
        completion()
      }
    }
  }

  fileprivate func reloadSync() {
    fetchResults = PHAsset.fetchAssets(with: .video, options: Utils.fetchOptions())

    items = []
    fetchResults?.enumerateObjects({ (asset, _, _) in
      self.items.append(Video(asset: asset))
    })
  }
}

