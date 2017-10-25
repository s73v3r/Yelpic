//
//  ViewController.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/14/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UICollectionViewDelegate {
    @IBOutlet weak var pictureCollection: UICollectionView!
    @IBOutlet weak var searchText: UITextField!
    
    var dataSource : ImageCellDataSource!
    
    var amountFetched = 0
    var session: URLSession?
    var searchProvider: YelpSearchProvider?
    var waiting = false
    var location: CLLocation?
    
    let locationProvider = LocationProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]

        dataSource = ImageCellDataSource(collectionView: pictureCollection, withReuseIdentifier: "ImageCell")
        pictureCollection.dataSource = dataSource
        pictureCollection.delegate = self
        
        locationProvider.getLocationUpdate { (result) in
            switch result {
            case .Success(let location):
                self.location = location
                
            case .Error( _):
                let alert = UIAlertController(title: "Location Error",
                                              message: "Problem acquiring location. For demo purposes, location will default to Apple's HQ",
                                              preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                
            case .NoAuthorization:
                let alert = UIAlertController(title: "Location Permission Needed",
                                              message: "Please enable location so we can show you businesses near you\n For demo purposes, location will default to Apple's HQ",
                                              preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
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
        self.searchText.resignFirstResponder()
        if let searchTerm = searchText.text, !searchTerm.isEmpty {
            self.dataSource?.clearURLs()
            self.waiting = false
            if let location = self.location {
                searchProvider = YelpSearchProvider(searchTerm: searchTerm, withLatitude: location.coordinate.latitude, andWithLongitude: location.coordinate.longitude)
            } else {
                searchProvider = YelpSearchProvider(searchTerm: searchTerm)
            }
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
