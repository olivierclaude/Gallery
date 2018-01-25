import UIKit
import AVFoundation

@objc(Config)
public class Config : NSObject {

  @available(*, deprecated, message: "Use tabsToShow instead.")
  @objc public static var showsVideoTab: Bool {
    // Maintains backwards-compatibility.
    get {
      return tabsToShow.index(of: .videoTab) != nil
    }
    set(newValue) {
      if !newValue {
        tabsToShow = tabsToShow.filter({$0 != .videoTab})
      } else {
        if tabsToShow.index(of: .videoTab) == nil {
          tabsToShow.append(.videoTab)
        }
      }
    }
  }
  public static var tabsToShow: [GalleryTab] = [.imageTab, .cameraTab, .videoTab]
  // Defaults to cameraTab if present, or whatever tab is first if cameraTab isn't present.
  public static var initialTab: GalleryTab?
  
  @objc public enum GalleryTab : Int, RawRepresentable {
    case imageTab
    case cameraTab
    case videoTab
        
    public typealias RawValue = String
        
    public var rawValue: RawValue {
      switch self {
        case .imageTab:
          return "IMAGE"
        case .cameraTab:
          return "CAMERA"
        case .videoTab:
          return "VIDEO"
      }
    }
        
    public init?(rawValue: RawValue) {
      switch rawValue {
        case "IMAGE":
          self = .imageTab
        case "CAMERA":
          self = .cameraTab
        case "VIDEO":
          self = .videoTab
        default:
          self = .cameraTab
        }
    }
  }

  @objc(ConfigPageIndicator)
  public class PageIndicator : NSObject {
    @objc public static var backgroundColor: UIColor = UIColor(red: 0, green: 3/255, blue: 10/255, alpha: 1)
    @objc public static var textColor: UIColor = UIColor.white
  }

  @objc(ConfigCamera)
  public class Camera : NSObject {

    @objc public static var recordLocation: Bool = false
    
    @objc public static var allowVolumeButtonsToTakePicture: Bool = true


    @objc(ConfigShutterButton)
    public class ShutterButton : NSObject {
      @objc public static var numberColor: UIColor = UIColor(red: 54/255, green: 56/255, blue: 62/255, alpha: 1)
    }

    @objc(ConfigBottomContainer)
    public class BottomContainer : NSObject {
      @objc public static var backgroundColor: UIColor = UIColor(red: 23/255, green: 25/255, blue: 28/255, alpha: 1)
    }
    
    @objc(ConfigFilterGallery)
    public class FilterGallery : NSObject {
      @objc public static var backgroundColor = UIColor(red: 0.15, green: 0.19, blue: 0.24, alpha: 1)
      @objc public static var gallerySeparatorColor = UIColor.black.withAlphaComponent(0.6)
      @objc public static var mainColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1)
      @objc public static var indicatorWidth: CGFloat = 41
      @objc public static var indicatorHeight: CGFloat = 8
    }

    @objc(ConfigStackView)
    public class StackView : NSObject {
      @objc public static let imageCount: Int = 4
    }
    
    @objc public static var imageLimit: Int = 0
    
  }

  @objc(ConfigGrid)
  public class Grid : NSObject {

    @objc(ConfigCloseButton)
    public class CloseButton : NSObject {
      @objc public static var tintColor: UIColor = UIColor(red: 109/255, green: 107/255, blue: 132/255, alpha: 1)
    }

    @objc(ConfigArrowButton)
    public class ArrowButton : NSObject {
      @objc public static var tintColor: UIColor = UIColor(red: 110/255, green: 117/255, blue: 131/255, alpha: 1)
    }

    @objc(ConfigFrameView)
    public class FrameView : NSObject {
      @objc public static var fillColor: UIColor = UIColor(red: 50/255, green: 51/255, blue: 59/255, alpha: 1)
      @objc public static var borderColor: UIColor = UIColor(red: 253/255, green: 83/255, blue: 91/255, alpha: 1)
    }

    @objc(ConfigDimension)
    class Dimension : NSObject {
      static let columnCount: CGFloat = 4
      static let cellSpacing: CGFloat = 2
    }
  }

  @objc(ConfigEmptyView)
  public class EmptyView : NSObject {
    @objc public static var image: UIImage? = GalleryBundle.image("gallery_empty_view_image")
    @objc public static var textColor: UIColor = UIColor(red: 102/255, green: 118/255, blue: 138/255, alpha: 1)
  }

  @objc(ConfigPermission)
  public class Permission : NSObject {
    @objc public static var image: UIImage? = GalleryBundle.image("gallery_permission_view_camera")
    @objc public static var textColor: UIColor = UIColor(red: 102/255, green: 118/255, blue: 138/255, alpha: 1)

    @objc(ConfigButton)
    public class Button : NSObject {
      @objc public static var textColor: UIColor = UIColor.white
      @objc public static var highlightedTextColor: UIColor = UIColor.lightGray
      @objc public static var backgroundColor = UIColor(red: 40/255, green: 170/255, blue: 236/255, alpha: 1)
    }
  }

  @objc(ConfigFont)
  public class Font : NSObject {

    @objc(ConfigMain)
    public class Main : NSObject {
      @objc public static var light: UIFont = UIFont.systemFont(ofSize: 1)
      @objc public static var regular: UIFont = UIFont.systemFont(ofSize: 1)
      @objc public static var bold: UIFont = UIFont.boldSystemFont(ofSize: 1)
      @objc public static var medium: UIFont = UIFont.boldSystemFont(ofSize: 1)
    }

    @objc(ConfigText)
    public class Text : NSObject {
      @objc public static var regular: UIFont = UIFont.systemFont(ofSize: 1)
      @objc public static var bold: UIFont = UIFont.boldSystemFont(ofSize: 1)
      @objc public static var semibold: UIFont = UIFont.boldSystemFont(ofSize: 1)
    }
  }

  @objc(ConfigVideoEditor)
  public class VideoEditor : NSObject {

    @objc public static var quality: String = AVAssetExportPresetHighestQuality
    @objc public static var savesEditedVideoToLibrary: Bool = false
    @objc public static var maximumDuration: TimeInterval = 15
    @objc public static var portraitSize: CGSize = CGSize(width: 360, height: 640)
    @objc public static var landscapeSize: CGSize = CGSize(width: 640, height: 360)
  }
}
