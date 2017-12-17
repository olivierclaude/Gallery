import UIKit
import Photos

@objc(Album)
class Album : NSObject {
    
  @objc open let collection: PHAssetCollection
  @objc open var items: [Image] = []


  // MARK: - Initialization

  init(collection: PHAssetCollection) {
    self.collection = collection
  }

  func reload() {
    items = []

    let itemsFetchResult = PHAsset.fetchAssets(in: collection, options: Utils.fetchOptions())
    itemsFetchResult.enumerateObjects({ (asset, count, stop) in
      if asset.mediaType == .image {
        self.items.append(Image(asset: asset))
      }
    })
  }
}
