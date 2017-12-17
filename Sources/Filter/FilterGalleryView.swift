//
//  FilterGalleryView.swift
//  Gallery
//
//  Created by Olivier Claude on 11/09/17.
//  Copyright © 2017 Hyper Interaktiv AS. All rights reserved.
//

import UIKit
import Photos
import PhotoEditorSDK

protocol FilterGalleryPanGestureDelegate: class {
    
    func panGestureDidStart()
    func panGestureDidChange(_ translation: CGPoint)
    func panGestureDidEnd(_ translation: CGPoint, velocity: CGPoint)
}

open class FilterGalleryView: UIView {
    
    struct Dimensions {
        static let filterHeight: CGFloat = 160
        static let filterBarHeight: CGFloat = 24
    }
    
    lazy var filterSelection: FilterSelectionController = { [unowned self] in
        let view = FilterSelectionController(inputImage: GalleryBundle.image("filter"))
        
        view.collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.collectionView.backgroundColor = Config.Camera.FilterGallery.mainColor
        view.collectionView.showsHorizontalScrollIndicator = false
        
        return view
        }()
    
    
    lazy var topSeparator: UIView = { [unowned self] in
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addGestureRecognizer(self.panGestureRecognizer)
        view.backgroundColor = Config.Camera.FilterGallery.gallerySeparatorColor
        
        return view
        }()
    
    lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(handlePanGestureRecognizer(_:)))
        
        return gesture
        }()
    
    // MARK: Images
    lazy var indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    weak var delegate: FilterGalleryPanGestureDelegate?
    var collectionSize: CGSize?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        backgroundColor = Config.Camera.FilterGallery.mainColor
        
        addSubview(filterSelection.collectionView)
        addSubview(topSeparator)
        
        topSeparator.addSubview(indicatorView)
    }
    
    func updateFrames() {
        let totalWidth = UIScreen.main.bounds.width
        frame.size.width = totalWidth
        let collectionFrame = frame.height == Dimensions.filterBarHeight ? 100 + Dimensions.filterBarHeight : frame.height
        
        topSeparator.frame = CGRect(x: 0, y: 0, width: totalWidth, height: Dimensions.filterBarHeight)
        topSeparator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleWidth]
        indicatorView.frame = CGRect(x: (totalWidth - Config.Camera.FilterGallery.indicatorWidth) / 2, y: (topSeparator.frame.height - Config.Camera.FilterGallery.indicatorHeight) / 2, width: Config.Camera.FilterGallery.indicatorWidth, height: Config.Camera.FilterGallery.indicatorHeight)
        
        filterSelection.collectionView.frame = CGRect(x: 0, y: topSeparator.frame.height, width: totalWidth, height: collectionFrame - topSeparator.frame.height)
        collectionSize = CGSize(width: filterSelection.collectionView.frame.height, height: filterSelection.collectionView.frame.height)
        
        
        filterSelection.collectionView.reloadData()
    }
    
    // MARK: - Pan gesture recognizer
    
    @objc func handlePanGestureRecognizer(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        
        let translation = gesture.translation(in: superview)
        let velocity = gesture.velocity(in: superview)
        
        switch gesture.state {
        case .began:
            delegate?.panGestureDidStart()
        case .changed:
            delegate?.panGestureDidChange(translation)
        case .ended:
            delegate?.panGestureDidEnd(translation, velocity: velocity)
        default: break
        }
    }
}

