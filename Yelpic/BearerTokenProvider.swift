//
//  BearerTokenProvider.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/21/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import Foundation

typealias BearerTokenResult = NetworkResult<String>
typealias BearerTokenResultCallback = (BearerTokenResult) -> ()

protocol BearerTokenProvider {
    func loadBearerToken(result: @escaping BearerTokenResultCallback)
}

class YelpBearerTokenProvider: BearerTokenProvider, KeyProviderInjection {
    func loadBearerToken(result: @escaping (BearerTokenResult) -> ()) {
        // Check if we already have an access token
        // According to Yelp, they won't expire until 2038
        if let token = UserDefaults.standard.string(forKey: "YELP_TOKEN") {
            print("Token exists")
            result(.Success(token))
            return
        }
        
        guard let apiKeys = keyProvider.provideKeys() else {
            result(.Error(.NoClientID))
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
                result(.Error(.TransmissionError(error!)))
                return
            }
            
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                result(.Error(.NoDataReturned))
                return
            }
            
            do {
                guard let responseJSON = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String : AnyObject] else {
                    print("Error: Unable to decode JSON")
                    result(.Error(.JSONParseError))
                    return
                }
                
                if let token = responseJSON["access_token"] as? String {
                    print("Saving token")
                    UserDefaults.standard.set(token, forKey: "YELP_TOKEN")
                    result(.Success(token))
                }
            } catch {
                print("Error trying to convert data to JSON")
            }
            return
        }
        task.resume()
    }
    
    
}
