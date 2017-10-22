//
//  ImageCellDataSource.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/19/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import UIKit

class ImageCellDataSource :NSObject, UICollectionViewDataSource, ImageProviderInjection {
    var urls = [String]()
    let collectionView : UICollectionView
    let cellReuseIdentifier: String
    let cache: NSCache<AnyObject, AnyObject>

    init(collectionView: UICollectionView, withReuseIdentifier reuseID: String) {
        self.collectionView = collectionView
        self.cellReuseIdentifier = reuseID
        self.cache = NSCache<AnyObject, AnyObject>()
        self.cache.countLimit = 100
    }

    func addURLs(urls: [String]) {
        self.urls.append(contentsOf: urls)
        self.collectionView.reloadData()
    }

    func clearURLs() {
        self.urls.removeAll()
        self.collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! ImageCell
        
        let url:URL! = URL(string: urls[indexPath.row])
        imageProvider.retrieveImageAtURL(url: url) { result in
            switch result {
            case .Success(let image):
                cell.image.image = image

            case .Downloaded:
                self.collectionView.reloadItems(at: [indexPath])

            default:
                    print("Error retrieving image for \(indexPath)")
            }
        }

        return cell
    }
}
