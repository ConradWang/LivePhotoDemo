//
//  DisplayLivePhotoVC.swift
//  LivePhotoDemo
//
//  Created by Cong Wang on 2018/7/6.
//  Copyright © 2018年 Cong Wang. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class DisplayLivePhotoVC: UIViewController {
    
    open var livePhoto: PHLivePhoto? {
        didSet {
            livePhotoView?.livePhoto = livePhoto
            livePhotoView?.startPlayback(with: .full)
        }
    }
    
    private var livePhotoView: PHLivePhotoView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = "LivePhoto显示"
        
        livePhotoView = PHLivePhotoView(frame: view.bounds)
        livePhotoView.livePhoto = livePhoto
        view.addSubview(livePhotoView)
        
        let gesture = livePhotoView.playbackGestureRecognizer
        gesture.addTarget(self, action: #selector(playbackGestureResponse(gesture:)))
        
    }
    
    
    
    @objc func playbackGestureResponse(gesture: UIGestureRecognizer) {
        print(gesture.state)
    }

}
