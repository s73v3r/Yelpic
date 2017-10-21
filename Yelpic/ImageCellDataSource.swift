//
//  ImageCellDataSource.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/19/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import UIKit

class ImageCellDataSource :NSObject, UICollectionViewDataSource {
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! ImageCell
        cell.image.backgroundColor = UIColor.green
        
        let url:URL! = URL(string: urls[indexPath.row])
        if let cacheImage = cache.object(forKey: urls[indexPath.row] as AnyObject) as? UIImage {
            cell.image.image = cacheImage
        } else {
            URLSession.shared.downloadTask(with: url) { (location, response, error) in
                if let imgData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        if let imgCell:ImageCell = collectionView.cellForItem(at: indexPath) as? ImageCell {
                            let image = UIImage(data: imgData)
                            imgCell.image.image = image;
                            self.cache.setObject(image!, forKey:url.absoluteString as AnyObject)
                        }
                    }
                }
            }.resume()
        }
        
        return cell
    }
}
