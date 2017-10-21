//
//  ViewController.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/14/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import UIKit

enum AuthenticationError : Error {
    case TokenNotFound
}

class ViewController: UIViewController, NetworkInjection {
    @IBOutlet weak var pictureCollection: UICollectionView!
    @IBOutlet weak var searchText: UITextField!
    
    var dataSource : ImageCellDataSource!
    
    var amountFetched = 0
    var session: URLSession?
    var searchProvider: YelpSearchProvider?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]

        dataSource = ImageCellDataSource(collectionView: pictureCollection, withReuseIdentifier: "ImageCell")
        pictureCollection.dataSource = dataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    @IBAction func onSearchClicked(_ sender: Any) {
        if let searchTerm = searchText.text, !searchTerm.isEmpty {
            searchProvider = YelpSearchProvider(searchTerm: searchTerm)
            searchProvider?.performSearch(withResults: { (result) in
                switch result {
                case .Success(let urls):
                    self.dataSource?.addURLs(urls: urls)
                    
                default:
                    print("ERROR")
                }
            })
        }
    }
}
