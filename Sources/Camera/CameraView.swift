import UIKit
import AVFoundation
import PhotoEditorSDK
import GLKit


protocol CameraViewDelegate: class {
  func cameraView(_ cameraView: CameraView, didTouch point: CGPoint)
}

@objc(CameraView)
class CameraView: UIView, UIGestureRecognizerDelegate {

  struct GestureConstants {
    static let maximumHeight: CGFloat = 125
    static let minimumHeight: CGFloat = 125
    static let velocity: CGFloat = 100
  }

  lazy var closeButton: UIButton = self.makeCloseButton()
  lazy var flashButton: TripleButton = self.makeFlashButton()
  lazy var rotateButton: UIButton = self.makeRotateButton()
  fileprivate lazy var bottomContainer: UIView = self.makeBottomContainer()
  lazy var bottomView: UIView = self.makeBottomView()
  lazy var stackView: StackView = self.makeStackView()
  lazy var shutterButton: ShutterButton = self.makeShutterButton()
  lazy var doneButton: UIButton = self.makeDoneButton()
  lazy var focusImageView: UIImageView = self.makeFocusImageView()
  lazy var tapGR: UITapGestureRecognizer = self.makeTapGR()
  lazy var rotateOverlayView: UIView = self.makeRotateOverlayView()
  lazy var shutterOverlayView: UIView = self.makeShutterOverlayView()
  lazy var blurView: UIVisualEffectView = self.makeBlurView()

  open lazy var galleryView: FilterGalleryView = { [unowned self] in
    let galleryView = FilterGalleryView()
    galleryView.delegate = self
        
    galleryView.filterSelection.collectionView.layer.anchorPoint = CGPoint(x: 0, y: 0)
        
    return galleryView
  }()
    
  lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
    let gesture = UIPanGestureRecognizer()
    gesture.addTarget(self, action: #selector(panGestureRecognizerHandler(_:)))
        
    return gesture
  }()

  var timer: Timer?
  //var previewLayer: AVCaptureVideoPreviewLayer?
  weak var camera: CameraController?;
  weak var previewLayer: GLKView?
  
  weak var delegate: CameraViewDelegate?
  var totalSize: CGSize { return UIScreen.main.bounds.size }
  var initialFrame: CGRect?
  var initialContentOffset: CGPoint?
  var numberOfCells: Int?

  // MARK: - Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = UIColor.black
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
    
  // MARK: - Setup

  func setup() {
    //addGestureRecognizer(tapGR)

    [closeButton, flashButton, rotateButton, galleryView, bottomContainer].forEach {
      addSubview($0)
    }

    [bottomView, shutterButton].forEach {
      bottomContainer.addSubview($0)
    }

    [stackView, doneButton].forEach {
      bottomView.addSubview($0 as! UIView)
    }

    [closeButton, flashButton, rotateButton].forEach {
      $0.g_addShadow()
    }

    rotateOverlayView.addSubview(blurView)
    insertSubview(rotateOverlayView, belowSubview: rotateButton)
    insertSubview(focusImageView, belowSubview: bottomContainer)
    insertSubview(shutterOverlayView, belowSubview: bottomContainer)

    closeButton.g_pin(on: .left)
    closeButton.g_pin(size: CGSize(width: 44, height: 44))

    flashButton.g_pin(on: .centerY, view: closeButton)
    flashButton.g_pin(on: .centerX)
    flashButton.g_pin(size: CGSize(width: 60, height: 44))

    rotateButton.g_pin(on: .right)
    rotateButton.g_pin(size: CGSize(width: 44, height: 44))

    if #available(iOS 11, *) {
      Constraint.on(
        closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
        rotateButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
      )
    } else {
      Constraint.on(
        closeButton.topAnchor.constraint(equalTo: topAnchor),
        rotateButton.topAnchor.constraint(equalTo: topAnchor)
      )
    }

    bottomContainer.g_pinDownward()
    bottomContainer.g_pin(height: 80)
    bottomView.g_pinEdges()

    stackView.g_pin(on: .centerY, constant: -4)
    stackView.g_pin(on: .left, constant: 38)
    stackView.g_pin(size: CGSize(width: 56, height: 56))

    shutterButton.g_pinCenter()
    shutterButton.g_pin(size: CGSize(width: 60, height: 60))
    
    doneButton.g_pin(on: .centerY)
    doneButton.g_pin(on: .right, constant: -38)

    rotateOverlayView.g_pinEdges()
    blurView.g_pinEdges()
    shutterOverlayView.g_pinEdges()
    
    let galleryHeight: CGFloat = UIScreen.main.nativeBounds.height == 960
        ? FilterGalleryView.Dimensions.filterBarHeight : GestureConstants.minimumHeight
    
    let bottomContainerHeight: CGFloat = 120
    
    galleryView.frame = CGRect(x: 0,
                               y: totalSize.height - bottomContainerHeight - galleryHeight,
                               width: totalSize.width,
                               height: galleryHeight)
    
    galleryView.filterSelection.collectionView.transform = CGAffineTransform.identity
    galleryView.filterSelection.collectionView.contentInset = UIEdgeInsets.zero
    
    galleryView.updateFrames()
    
    galleryView.filterSelection.selectedBlock = { [unowned self] photoEffect in
        self.camera?.photoEffect = photoEffect
    }
    
    initialFrame = galleryView.frame
    initialContentOffset = galleryView.filterSelection.collectionView.contentOffset
  }

  func setupPreviewLayer(_ session: CameraController) {
    guard previewLayer == nil else { return }
        
    camera = session
    previewLayer = session.videoPreviewView
        
    let layer = previewLayer?.layer
    layer?.autoreverses = true
    layer?.frame = self.layer.bounds
        
    self.layer.insertSublayer(layer!, at: 0)
  }


  override func layoutSubviews() {
    super.layoutSubviews()

    previewLayer?.frame = self.layer.bounds
  }

  // MARK: - Action

  @objc func viewTapped(_ gr: UITapGestureRecognizer) {
    let point = gr.location(in: self)

    focusImageView.transform = CGAffineTransform.identity
    timer?.invalidate()
    delegate?.cameraView(self, didTouch: point)

    focusImageView.center = point

    UIView.animate(withDuration: 0.5, animations: {
      self.focusImageView.alpha = 1
      self.focusImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
    }, completion: { _ in
      self.timer = Timer.scheduledTimer(timeInterval: 1, target: self,
        selector: #selector(CameraView.timerFired(_:)), userInfo: nil, repeats: false)
    })
  }

  // MARK: - Timer

  @objc func timerFired(_ timer: Timer) {
    UIView.animate(withDuration: 0.3, animations: {
      self.focusImageView.alpha = 0
    }, completion: { _ in
      self.focusImageView.transform = CGAffineTransform.identity
    })
  }

  // MARK: - UIGestureRecognizerDelegate
  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    let point = gestureRecognizer.location(in: self)

    return point.y > closeButton.frame.maxY
      && point.y < bottomContainer.frame.origin.y
  }

  // MARK: - Controls

  func makeCloseButton() -> UIButton {
    let button = UIButton(type: .custom)
    button.setImage(GalleryBundle.image("gallery_close"), for: UIControlState())

    return button
  }

  func makeFlashButton() -> TripleButton {
    let states: [TripleButton.State] = [
      TripleButton.State(title: "Gallery.Camera.Flash.Off".g_localize(fallback: "OFF"), image: GalleryBundle.image("gallery_camera_flash_off")!),
      TripleButton.State(title: "Gallery.Camera.Flash.On".g_localize(fallback: "ON"), image: GalleryBundle.image("gallery_camera_flash_on")!),
      TripleButton.State(title: "Gallery.Camera.Flash.Auto".g_localize(fallback: "AUTO"), image: GalleryBundle.image("gallery_camera_flash_auto")!)
    ]

    let button = TripleButton(states: states)

    return button
  }

  func makeRotateButton() -> UIButton {
    let button = UIButton(type: .custom)
    button.setImage(GalleryBundle.image("gallery_camera_rotate"), for: UIControlState())

    return button
  }

  func makeBottomContainer() -> UIView {
    let view = UIView()

    return view
  }

  func makeBottomView() -> UIView {
    let view = UIView()
    view.backgroundColor = Config.Camera.BottomContainer.backgroundColor
    view.alpha = 1

    return view
  }

  func makeStackView() -> StackView {
    let view = StackView()

    return view
  }

  func makeShutterButton() -> ShutterButton {
    let button = ShutterButton()
    button.g_addShadow()

    return button
  }

  func makeDoneButton() -> UIButton {
    let button = UIButton(type: .system)
    button.setTitleColor(UIColor.white, for: UIControlState())
    button.setTitleColor(UIColor.lightGray, for: .disabled)
    button.titleLabel?.font = Config.Font.Text.regular.withSize(16)
    button.setTitle("Gallery.Done".g_localize(fallback: "Done"), for: UIControlState())

    button.isHidden = false

    return button
  }

  func makeFocusImageView() -> UIImageView {
    let view = UIImageView()
    view.frame.size = CGSize(width: 110, height: 110)
    view.image = GalleryBundle.image("gallery_camera_focus")
    view.backgroundColor = .clear
    view.alpha = 0

    return view
  }

  func makeTapGR() -> UITapGestureRecognizer {
    let gr = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
    gr.delegate = self

    return gr
  }

  func makeRotateOverlayView() -> UIView {
    let view = UIView()
    view.alpha = 0

    return view
  }

  func makeShutterOverlayView() -> UIView {
    let view = UIView()
    view.alpha = 0
    view.backgroundColor = UIColor.black

    return view
  }

  func makeBlurView() -> UIVisualEffectView {
    let effect = UIBlurEffect(style: .dark)
    let blurView = UIVisualEffectView(effect: effect)

    return blurView
  }

    // MARK: - Helpers
    
    open func collapseGalleryView(_ completion: (() -> Void)?) {
        galleryView.filterSelection.collectionView.collectionViewLayout.invalidateLayout()
        UIView.animate(withDuration: 0.3, animations: {
            self.updateGalleryViewFrames(self.galleryView.topSeparator.frame.height)
            self.galleryView.filterSelection.collectionView.transform = CGAffineTransform.identity
            self.galleryView.filterSelection.collectionView.contentInset = UIEdgeInsets.zero
        }, completion: { _ in
            completion?()
        })
    }
    
    open func showGalleryView() {
        galleryView.filterSelection.collectionView.collectionViewLayout.invalidateLayout()
        UIView.animate(withDuration: 0.3, animations: {
            self.updateGalleryViewFrames(GestureConstants.minimumHeight)
            self.galleryView.filterSelection.collectionView.transform = CGAffineTransform.identity
            self.galleryView.filterSelection.collectionView.contentInset = UIEdgeInsets.zero
        })
    }
    
    open func expandGalleryView() {
        galleryView.filterSelection.collectionView.collectionViewLayout.invalidateLayout()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.updateGalleryViewFrames(GestureConstants.minimumHeight)
            
            let scale = (GestureConstants.maximumHeight - FilterGalleryView.Dimensions.filterBarHeight) / (GestureConstants.minimumHeight - FilterGalleryView.Dimensions.filterBarHeight)
            self.galleryView.filterSelection.collectionView.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            let value = self.frame.width * (scale - 1) / scale
            self.galleryView.filterSelection.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right:  value)
        })
    }
    
    func updateGalleryViewFrames(_ constant: CGFloat) {
        let bottomContainerHeight: CGFloat = 120
        
        galleryView.frame.origin.y = totalSize.height - bottomContainerHeight - constant
        galleryView.frame.size.height = constant
    }
}

// MARK: - Pan gesture handler

extension CameraView: FilterGalleryPanGestureDelegate {
    
    func panGestureDidStart() {
        guard let collectionSize = galleryView.collectionSize else { return }
        
        initialFrame = galleryView.frame
        initialContentOffset = galleryView.filterSelection.collectionView.contentOffset
        if let contentOffset = initialContentOffset { numberOfCells = Int(contentOffset.x / collectionSize.width) }
    }
    
    @objc func panGestureRecognizerHandler(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        
        if gesture.location(in: self).y > galleryView.frame.origin.y - 25 {
            gesture.state == .began ? panGestureDidStart() : panGestureDidChange(translation)
        }
        
        if gesture.state == .ended {
            panGestureDidEnd(translation, velocity: velocity)
        }
    }
    
    func panGestureDidChange(_ translation: CGPoint) {
        guard let initialFrame = initialFrame else { return }
        
        let galleryHeight = initialFrame.height - translation.y
        
        if galleryHeight >= GestureConstants.maximumHeight { return }
        
        if galleryHeight <= FilterGalleryView.Dimensions.filterBarHeight {
            updateGalleryViewFrames(FilterGalleryView.Dimensions.filterBarHeight)
        } else if galleryHeight >= GestureConstants.minimumHeight {
            let scale = (galleryHeight - FilterGalleryView.Dimensions.filterBarHeight) / (GestureConstants.minimumHeight - FilterGalleryView.Dimensions.filterBarHeight)
            galleryView.filterSelection.collectionView.transform = CGAffineTransform(scaleX: scale, y: scale)
            galleryView.frame.origin.y = initialFrame.origin.y + translation.y
            galleryView.frame.size.height = initialFrame.height - translation.y
            
            let value = frame.width * (scale - 1) / scale
            galleryView.filterSelection.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right:  value)
        } else {
            galleryView.frame.origin.y = initialFrame.origin.y + translation.y
            galleryView.frame.size.height = initialFrame.height - translation.y
        }
    }
    
    func panGestureDidEnd(_ translation: CGPoint, velocity: CGPoint) {
        guard let initialFrame = initialFrame else { return }
        let galleryHeight = initialFrame.height - translation.y
        if galleryView.frame.height < GestureConstants.minimumHeight && velocity.y < 0 {
            showGalleryView()
        } else if velocity.y < -GestureConstants.velocity {
            expandGalleryView()
        } else if velocity.y > GestureConstants.velocity || galleryHeight < GestureConstants.minimumHeight {
            collapseGalleryView(nil)
        }
    }
}
