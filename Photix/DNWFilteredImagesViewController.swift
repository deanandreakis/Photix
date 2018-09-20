//
//  DNWFilteredImagesViewController.swift
//  Photix
//
//  Created by Dean Andreakis on 8/5/18.
//  Copyright © 2018 deanware. All rights reserved.
//

import UIKit
import AVFoundation

class DNWFilteredImagesViewController: UICollectionViewController {
    
    //var photos = Photo.allPhotos()
    var imageToSet:UIImage = UIImage(imageLiteralResourceName: "General")
    var thumbArray:[DNWFilteredImageModel] = []
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let patternImage = UIImage(named: "Pattern") {
            view.backgroundColor = UIColor(patternImage: patternImage)
        }
        collectionView?.backgroundColor = UIColor.clear
        collectionView?.contentInset = UIEdgeInsets(top: 23, left: 10, bottom: 10, right: 10)
        // Set the PinterestLayout delegate
        if let layout = collectionView?.collectionViewLayout as? PinterestLayout {
            layout.delegate = self
        }
        
        let rightBarButton = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.done, target: self, action: #selector(NextButtonPressed(_:)))
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
}

//MARK: - Button Press Actions
extension DNWFilteredImagesViewController {
    func NextButtonPressed(_ sender:UIBarButtonItem!) {
        //let storyboard = UIStoryboard(name: "MainStoryboard", bundle: nil)
        //let controller:DNWPictureViewController = storyboard.instantiateViewController(withIdentifier: "MyPicture") as! DNWPictureViewController
        //controller.imageToSet = self.imageToSet
        //self.navigationController?.pushViewController(controller, animated: true)
    }
}

//MARK: - UICollectionView Functions
extension DNWFilteredImagesViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1//photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AnnotatedPhotoCell", for: indexPath)
//        if let annotateCell = cell as? AnnotatedPhotoCell {
//            annotateCell.photo = photos[indexPath.item]
//        }
//        return cell
        return UICollectionViewCell(frame: .init(x: 1, y: 1, width: 1, height: 1))
    }
    
}

//MARK: - PINTEREST LAYOUT DELEGATE
extension DNWFilteredImagesViewController : PinterestLayoutDelegate {
    
    // 1. Returns the photo height
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath:IndexPath) -> CGFloat {
        return 1//photos[indexPath.item].image.size.height
    }
    
}

//MARK: - FilteringCompleteDelegate
extension DNWFilteredImagesViewController : FilteringCompleteDelegate {
    //array of DNWFilteredImageModel objects
    func filteringComplete(_ filteredImages:[Any]) {
        for item in filteredImages {
            thumbArray.append(item as! DNWFilteredImageModel)
        }
    }
}

