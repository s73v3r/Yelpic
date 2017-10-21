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
        
        guard let apiKeys = keyProvider.provideKeys() else { return }
        fetchYelpToken(apiKeys)
        
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
        if let searchTerm = searchText.text, !searchTerm.isEmpty,
            let bearerToken = try? loadBearerToken() {
            searchProvider = YelpSearchProvider(searchTerm: searchTerm, bearerToken: bearerToken)
            searchProvider?.performSearch(withResults: { (urls) in
                self.dataSource?.addURLs(urls: urls)
            })
        }
    }
    
    private func fetchYelpToken(_ apiKeys: [String : String]) {
        // Check if we already have an access token
        // According to Yelp, they won't expire until 2038
        if let key = UserDefaults.standard.string(forKey: "YELP_TOKEN") {
            print("Key exists: \(key)")
            return
        }
        
        let url = URL(string: "https://api.yelp.com/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content_Type")
        
        let body = (apiKeys.map({ (key, value) -> String in
            return "\(key)=\(value)"
        }) as Array).joined(separator: "&")
        request.httpBody = body.data(using: String.Encoding.utf8)
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { (data, resposne, error) in
            guard error == nil else {
                print("Error: Unable to retrieve token")
                print(error!)
                return
            }
            
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            
            do {
                guard let responseJSON = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String : AnyObject] else {
                    print("Error: Unable to decode JSON")
                    return
                }
                
                if let token = responseJSON["access_token"] as? String {
                    print("Saving token")
                    UserDefaults.standard.set(token, forKey: "YELP_TOKEN")
                }
                
            } catch {
                print("Error trying to convert data to JSON")
            }
            return
        }
        task.resume()
    }

    func loadBearerToken() throws -> String {
        guard let token = UserDefaults.standard.string(forKey: "YELP_TOKEN") else {
            print("Error: Cannot search without token")
            throw AuthenticationError.TokenNotFound
        }

        return token
    }
}
