//
//  ImageCell.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/17/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import UIKit

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var image: UIImageView!
    
    override func prepareForReuse() {
        image.image = nil
    }
}
