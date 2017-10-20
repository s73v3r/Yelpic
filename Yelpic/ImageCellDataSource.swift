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
    
    init(collectionView: UICollectionView, withReuseIdentifier reuseID: String) {
        self.collectionView = collectionView
        self.cellReuseIdentifier = reuseID
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
        URLSession.shared.downloadTask(with: url) { (location, response, error) in
            if let imgData = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    if let imgCell:ImageCell = collectionView.cellForItem(at: indexPath) as? ImageCell {
                        let image = UIImage(data: imgData)
                        imgCell.image.image = image;
                    }
                }
            }
        }.resume()
        
        return cell
    }
}
