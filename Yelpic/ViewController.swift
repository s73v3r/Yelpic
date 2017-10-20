//
//  ViewController.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/14/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var pictureCollection: UICollectionView!
    @IBOutlet weak var searchText: UITextField!
    
    var dataSource : ImageCellDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        
        guard let apiKeys = readFile("Config") else { return }
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
        if let searchTerm = searchText.text, !searchTerm.isEmpty {
            getPicturesOfFood(searchTerm: searchTerm)
        }
    }
    
    func readFile(_ fileName: String) -> [String: AnyObject]? {
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "plist") else {
            print("Error: Unable to find File")
            return nil
        }
        
        guard let data = try? Data(contentsOf: fileURL) else {
            print("Error: Unable to Read file")
            return nil
        }
        
        guard let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : AnyObject] else {
            print("Error: File wrong")
            return nil
        }
        
        return result
    }
    
    fileprivate func fetchYelpToken(_ apiKeys: [String : AnyObject]) {
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

    func getPicturesOfFood(searchTerm: String) {
        guard let token = UserDefaults.standard.string(forKey: "YELP_TOKEN") else {
            print("Error: Cannot search without token")
            return
        }
        
        let bearer = "Bearer \(token)"
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = ["Authorization": bearer]
        
        var urlComponents = URLComponents(string: "https://api.yelp.com/v3/businesses/search")!
        let searchTerm = URLQueryItem(name: "term", value: searchTerm)
        let lat = URLQueryItem(name: "latitude", value: "37.786882")
        let long = URLQueryItem(name: "longitude", value: "-122.399972")
        urlComponents.queryItems = [searchTerm, lat, long]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        
        let session = URLSession(configuration: sessionConfig)
        let task = session.dataTask(with: request) { (data, response, error) in
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
                
                if let businesses = responseJSON["businesses"] as? [[String: AnyObject]] {
                    let urls = businesses.flatMap({ dict in
                        if let url = dict["image_url"] as? String, !url.isEmpty {
                            return url
                        }
                        return nil
                    })
                    DispatchQueue.main.async { [unowned self] in
                        self.dataSource?.addURLs(urls: urls)
                    }
                }
                
            } catch {
                print("Error trying to convert data to JSON")
            }
        }
        task.resume()
    }
}

