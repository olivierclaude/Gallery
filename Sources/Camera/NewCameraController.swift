import UIKit
import AVFoundation
import PhotoEditorSDK
import PhotosUI
import Photos

@objc(NewCameraController)
class NewCameraController: UIViewController {
    
    var locationManager: LocationManager?
    lazy var cameraMan: CameraController = self.makeCameraMan()
    lazy var cameraView: CameraView = self.makeCameraView()
    let once = Once()
    let cart: Cart
    let savingQueue = DispatchQueue(label: "no.hyper.Gallery.Camera.SavingQueue", qos: .background)
    
    
    // MARK: - Init
    
    public required init(cart: Cart) {
        self.cart = cart
        super.init(nibName: nil, bundle: nil)
        cart.delegates.add(self)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        setupLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        locationManager?.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        locationManager?.stop()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        //    coordinator.animate(alongsideTransition: { _ in
        //      if let connection = self.cameraView.previewLayer?.connection,
        //        connection.isVideoOrientationSupported {
        //        connection.videoOrientation = Utils.videoOrientation()
        //      }
        //    }, completion: nil)
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // MARK: - Setup
    
    func setup() {
        view.addSubview(cameraView)
        cameraView.g_pinEdges()
        
        cameraView.closeButton.addTarget(self, action: #selector(closeButtonTouched(_:)), for: .touchUpInside)
        cameraView.flashButton.addTarget(self, action: #selector(flashButtonTouched(_:)), for: .touchUpInside)
        cameraView.rotateButton.addTarget(self, action: #selector(rotateButtonTouched(_:)), for: .touchUpInside)
        cameraView.stackView.addTarget(self, action: #selector(stackViewTouched(_:)), for: .touchUpInside)
        cameraView.shutterButton.addTarget(self, action: #selector(shutterButtonTouched(_:)), for: .touchUpInside)
        cameraView.doneButton.addTarget(self, action: #selector(doneButtonTouched(_:)), for: .touchUpInside)
    }
    
    func setupLocation() {
        if Config.Camera.recordLocation {
            locationManager = LocationManager()
        }
    }
    
    // MARK: - Action
    
    @objc func closeButtonTouched(_ button: UIButton) {
        EventHub.shared.close?()
    }
    
    @objc func flashButtonTouched(_ button: UIButton) {
        cameraView.flashButton.toggle()
        
        if let flashMode = AVCaptureDevice.FlashMode(rawValue: cameraView.flashButton.selectedIndex) {
            cameraMan.flashModes = [flashMode]
            cameraMan.selectNextLightMode()
        }
    }
    
    @objc func rotateButtonTouched(_ button: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            self.cameraView.rotateOverlayView.alpha = 1
        }, completion: { _ in
            self.cameraMan.toggleCameraPosition()
            UIView.animate(withDuration: 0.7, animations: {
                self.cameraView.rotateOverlayView.alpha = 0
            })
        })
    }
    
    @objc func stackViewTouched(_ stackView: StackView) {
        EventHub.shared.stackViewTouched?()
    }
    
    @objc func shutterButtonTouched(_ button: ShutterButton) {
        guard isBelowImageLimit() else { return }
        //guard let previewLayer = cameraView.previewLayer else { return }
        
        button.isEnabled = false
        UIView.animate(withDuration: 0.1, animations: {
            self.cameraView.shutterOverlayView.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.cameraView.shutterOverlayView.alpha = 0
            })
        })
        
        if cart.imagesLimit == 1
        {
            cameraMan.takePhoto() { [weak self] (image, error) in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.savePhoto(image, location: strongSelf.locationManager?.latestLocation) { [weak self] asset in
                    guard self != nil else {
                        return
                    }
                    if let asset = asset {
                        strongSelf.cart.add(Image(asset: asset), newlyTaken: true)
                    }
                    
                    EventHub.shared.doneWithImages?()
                }
            }
        }
        else
        {
            self.cameraView.stackView.startLoading()
            cameraMan.takePhoto() { [weak self] (image, error) in
                guard let strongSelf = self else {
                    return
                }
                
                button.isEnabled = true
                
                strongSelf.savePhoto(image, location: strongSelf.locationManager?.latestLocation) { [weak self] asset in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    if let asset = asset {
                        strongSelf.cart.add(Image(asset: asset), newlyTaken: true)
                    }
                }
                
                strongSelf.cameraView.stackView.stopLoading()
            }
        }
    }
    
    func savePhoto(_ image: UIImage?, location: CLLocation?, completion: @escaping ((PHAsset?) -> Void)) {
        var localIdentifier: String?
        
        savingQueue.async {
            do {
                try PHPhotoLibrary.shared().performChangesAndWait {
                    let request = PHAssetChangeRequest.creationRequestForAsset(from: image!)
                    localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
                    
                    request.creationDate = Date()
                    request.location = location
                }
                
                DispatchQueue.main.async {
                    if let localIdentifier = localIdentifier {
                        completion(Fetcher.fetchAsset(localIdentifier))
                    } else {
                        completion(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    @objc func doneButtonTouched(_ button: UIButton) {
        EventHub.shared.doneWithImages?()
    }
    
    fileprivate func isBelowImageLimit() -> Bool {
        return (cart.imagesLimit == 0 || cart.imagesLimit > cart.images.count)
    }
    
    // MARK: - View
    
    func refreshView() {
        let hasImages = !cart.images.isEmpty
        cameraView.bottomView.g_fade(visible: hasImages)
        cameraView.doneButton.isHidden = false
    }
    
    // MARK: - Controls
    
    func makeCameraMan() -> CameraController {
        let man = CameraController()
        man.tapToFocusEnabled = true
        return man
    }
    
    
    func makeCameraView() -> CameraView {
        let view = CameraView()
        view.delegate = self
        
        return view
    }
}

extension NewCameraController: CartDelegate {
    
    func cart(_ cart: Cart, didAdd image: Image, newlyTaken: Bool) {
        cameraView.stackView.reload(cart.images, added: true)
        refreshView()
    }
    
    func cart(_ cart: Cart, didRemove image: Image) {
        cameraView.stackView.reload(cart.images)
        refreshView()
    }
    
    func cartDidReload(_ cart: Cart) {
        cameraView.stackView.reload(cart.images)
        refreshView()
    }
}

extension NewCameraController: PageAware {
    
    func pageDidShow() {
        once.run {
            do {
                self.cameraView.setupPreviewLayer(self.cameraMan)
                
                try cameraMan.setup(with: .photo, completion: {
                    self.cameraMan.startCamera()
                })
            }
            catch{
                
            }
        }
    }
}


extension NewCameraController: CameraViewDelegate {
    
    func cameraView(_ cameraView: CameraView, didTouch point: CGPoint) {
        //cameraMan.focus(point)
    }
}


//extension NewCameraController: CameraManDelegate {
//
//  func cameraManDidStart(_ cameraMan: CameraMan) {
//    cameraView.setupPreviewLayer(cameraMan.session)
//  }
//
//  func cameraManNotAvailable(_ cameraMan: CameraMan) {
//    cameraView.focusImageView.isHidden = true
//  }
//
//  func cameraMan(_ cameraMan: CameraMan, didChangeInput input: AVCaptureDeviceInput) {
//    cameraView.flashButton.isHidden = !input.device.hasFlash
//  }
//
//}


