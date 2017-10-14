//
//  ViewController.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/14/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var pictureCollection: UICollectionView!
    
    fileprivate func fetchYelpToken(_ apiKeys: [String : AnyObject]) {
        let headers = ["grant_type", "client_id", "client_secret"]
        
        let url = URL(string: "https://api.yelp.com/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content_Type")
        
        
        let body = (apiKeys.map({ (key, value) -> String in
            return "\(key)=\(value)"
        }) as Array).joined(separator: "&")
        request.httpBody = body.data(using: String.Encoding.utf8)
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
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
                
                print(responseJSON["access_token"] as! String)
            } catch {
                print("Error trying to convert data to JSON")
            }
            return
        }
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        guard let apiKeys = readFile("Config") else { return }
        fetchYelpToken(apiKeys)
    }
    
    func readFile(_ fileName: String) -> [String: AnyObject]? {
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "plist") else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        guard let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : AnyObject] else {
            return nil
        }
        
        return result
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

