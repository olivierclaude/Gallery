import Foundation

@objc(Once)
class Once : NSObject {

  var already: Bool = false

  func run(_ block: () -> Void) {
    guard !already else { return }

    block()
    already = true
  }
}
