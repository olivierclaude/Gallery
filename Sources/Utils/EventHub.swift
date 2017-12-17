import Foundation

@objc(EventHub)
class EventHub : NSObject {

  typealias Action = () -> Void

  static let shared = EventHub()

  // MARK: Initialization

  override init() {}

  var close: Action?
  var doneWithImages: Action?
  var doneWithVideos: Action?
  var stackViewTouched: Action?
}
