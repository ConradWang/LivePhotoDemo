//
//  ViewController.swift
//  LivePhotoDemo
//
//  Created by Cong Wang on 2018/7/4.
//  Copyright © 2018年 Cong Wang. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices
import SnapKit

class ViewController: UIViewController {

    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    
    var imageURL: URL? {
        didSet {
            if let imgURL = imageURL {
                photoTitleLabel.alpha = 1
                photoImageView.alpha = 1
                
                selectButton.isHidden = true
                uploadButton.isHidden = false
                
                do {
                    let imgData = try Data(contentsOf: imgURL)
                    photoImageView.image = UIImage(data: imgData)
                } catch {
                    print(error.localizedDescription)
                }
                
            } else {
                selectButton.isHidden = false
                uploadButton.isHidden = true
                
                photoTitleLabel.alpha = 0
                photoImageView.alpha = 0
                photoImageView.image = nil
            }
        }
    }
    
    var movURL: URL? {
        didSet {
            if let imgURL = movURL {
                movTitleLabel.alpha = 1
                movPlayerBGView.alpha = 1
                
                selectButton.isHidden = true
                uploadButton.isHidden = false
                
                avPlayer?.pause()
                avPlayerLayer?.removeFromSuperlayer()
                
                avPlayer = AVPlayer(url: imgURL)
                avPlayerLayer = AVPlayerLayer(player: self.avPlayer)
                avPlayerLayer?.frame = movPlayerBGView.bounds
                if let playerLayer = avPlayerLayer {
                    movPlayerBGView.layer.addSublayer(playerLayer)
                }
                avPlayer?.play()
                
            } else {
                movTitleLabel.alpha = 0
                movPlayerBGView.alpha = 0
                
                selectButton.isHidden = false
                uploadButton.isHidden = true
                
                avPlayer?.pause()
                avPlayerLayer?.removeFromSuperlayer()
            }
        }
    }
    
    var avPlayer: AVPlayer?
    var avPlayerLayer: AVPlayerLayer?
    
    
    lazy var photoTitleLabel: UILabel = {
        let photoTitleLabel = UILabel(frame: CGRect.zero)
        photoTitleLabel.text = "图片内容："
        return photoTitleLabel
    }()
    
    lazy var photoImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    

    lazy var movTitleLabel: UILabel = {
        let movTitleLabel = UILabel(frame: CGRect.zero)
        movTitleLabel.text = "视频内容："
        return movTitleLabel
    }()
    
    lazy var movPlayerBGView: UIView = {
        let bgView = UIView(frame: CGRect.zero)
        return bgView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        layoutUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(movDidPlayEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func layoutUI() {

        self.view.addSubview(photoTitleLabel)
        photoTitleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(100)
            make.left.equalToSuperview().offset(15)
        }
        
        self.view.addSubview(photoImageView)
        photoImageView.snp.makeConstraints { (make) in
            make.top.equalTo(photoTitleLabel.snp.bottom).offset(5)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(200)
        }
        
        self.view.addSubview(movTitleLabel)
        movTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(photoImageView.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(15)
        }
        
        self.view.addSubview(movPlayerBGView)
        movPlayerBGView.snp.makeConstraints { (make) in
            make.top.equalTo(movTitleLabel.snp.bottom).offset(5)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(200)
        }
        
        selectButton.isHidden = false
        uploadButton.isHidden = true
        
        imageURL = nil
        movURL = nil
    }

    @objc func movDidPlayEnd() {
        avPlayer?.seek(to: CMTimeMake(0, 1))
        avPlayer?.play()
    }
    
    @IBAction func clickedSelectedButton(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeLivePhoto as String]
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    @IBAction func clickedUploadButton(_ sender: UIButton) {
        if let imageURL = imageURL, let movURL = movURL {
            PHLivePhoto.request(withResourceFileURLs: [movURL, imageURL], placeholderImage: nil, targetSize: CGSize.zero, contentMode: .default) { (livePhoto, info) in
                if (info[PHLivePhotoInfoCancelledKey] as? NSNumber) == NSNumber(value: false) {
                    let displayVC = DisplayLivePhotoVC()
                    displayVC.livePhoto = livePhoto
                    
                    let backItem = UIBarButtonItem()
                    backItem.title = "返回"
                    self.navigationItem.backBarButtonItem = backItem
                    self.navigationController?.pushViewController(displayVC, animated: true)
                }
            }
        }
        
        
//        PHAssetCreationRequest
    }
}

extension ViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let livePhoto = info[UIImagePickerControllerLivePhoto] as? PHLivePhoto {
            
            getImageAndMov(for: livePhoto) { (imagePath, movPath, error) in
                //
                print(imagePath ?? "")
                print(movPath ?? "")
                print(error?.localizedDescription ?? "")
                if let imagePath = imagePath, let movPath = movPath {
                    self.imageURL = URL(fileURLWithPath: imagePath)
                    self.movURL = URL(fileURLWithPath: movPath)
                }
            }
            
        } else {
            print("it is'nt a LivePhoto")
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}

func getImageAndMov(for livePhoto: PHLivePhoto, resultBlock: @escaping (_ imagePath: String?, _ movPath: String?, _ error: Error?) -> Void) {
    let assetResources = PHAssetResource.assetResources(for: livePhoto)
    
    var imagePathString: String?
    var movPathString: String?
    
    var hasError = false
    
    for assetRes in assetResources {
        let path = NSTemporaryDirectory() + assetRes.originalFilename
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
        
        PHAssetResourceManager.default().writeData(for: assetRes, toFile: url, options: nil) { (error) in
            if hasError { return }
            
            if error != nil {
                resultBlock(nil, nil, error)
                hasError = true
            } else {
                if assetRes.type == .photo {
                    imagePathString = path
                } else if assetRes.type == .pairedVideo {
                    movPathString = path
                }
                if (imagePathString != nil) && (movPathString != nil) {
                    resultBlock(imagePathString, movPathString, nil)
                }
            }
        }
    }
}

