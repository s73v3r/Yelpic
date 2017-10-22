//
//  ViewController.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/14/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate {
    @IBOutlet weak var pictureCollection: UICollectionView!
    @IBOutlet weak var searchText: UITextField!
    
    var dataSource : ImageCellDataSource!
    
    var amountFetched = 0
    var session: URLSession?
    var searchProvider: YelpSearchProvider?
    var waiting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]

        dataSource = ImageCellDataSource(collectionView: pictureCollection, withReuseIdentifier: "ImageCell")
        pictureCollection.dataSource = dataSource
        pictureCollection.delegate = self
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
            self.dataSource?.clearURLs()
            self.waiting = false
            searchProvider = YelpSearchProvider(searchTerm: searchTerm)
            searchProvider?.performSearch(withResults: { (result) in
                switch result {
                case .Success(let urls):
                    self.dataSource?.addURLs(urls: urls)
                    
                case .Error(let error):
                    print("ERROR: \(error)")
                }
            })
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let dataSource = self.dataSource,
           (indexPath.row > dataSource.collectionView(collectionView, numberOfItemsInSection: 0) - 4),
           !self.waiting {
            print("Fetching more items")
            self.waiting = true
            self.searchProvider?.performSearch { result in
                self.waiting = false
                switch result {
                case .Success(let urls):
                    self.dataSource?.addURLs(urls: urls)

                case .Error(let error):
                    switch error {
                    case .NoMoreResults:
                        self.waiting = true
                        
                    default:
                        print("Error fetching more items")
                    }
                }
            }
        }
    }
}
