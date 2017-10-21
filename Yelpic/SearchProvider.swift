//
//  SearchProvider.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/21/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import Foundation

enum NetworkError: Error {
    case NoClientID
    case TransmissionError(Error)
    case NoDataReturned
    case JSONParseError
}

enum NetworkResult<T> {
    case Success(T)
    case Error(NetworkError)
}

class YelpSearchProvider: NetworkInjection {

    let searchTerm: String
    var session: URLSession?
    var amountFetched = 0

    init(searchTerm: String) {
        self.searchTerm = searchTerm
    }

    func performSearch(withResults resultsCallback: @escaping (NetworkResult<[String]>) -> ()) {
        let request = createRequest(searchTerm: searchTerm, withOffset: amountFetched)
        
        if let session = self.session {
            performRequest(request: request, withSession: session, andResults: resultsCallback)
        } else {
            initSession() { result in
                switch result {
                case .Success(let session):
                    self.session = session
                    self.performRequest(request: request, withSession: session, andResults: resultsCallback)
                    
                case .Error(let error):
                    resultsCallback(.Error(error))
                }
            }
        }
    }

    private func createRequest(searchTerm: String, withOffset offset: Int) -> URLRequest {
        var urlComponents = URLComponents(string: "https://api.yelp.com/v3/businesses/search")!
        let searchTermParam = URLQueryItem(name: "term", value: searchTerm)
        let latParam = URLQueryItem(name: "latitude", value: "37.786882")
        let longParam = URLQueryItem(name: "longitude", value: "-122.399972")
        let offsetParam = URLQueryItem(name: "offset", value: "\(offset)")
        urlComponents.queryItems = [searchTermParam, latParam, longParam, offsetParam]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        return request
    }
    
    private func performRequest(request: URLRequest, withSession session: URLSession, andResults resultsCallback: @escaping (NetworkResult<[String]>) -> () ) {
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!)
                resultsCallback(.Error(.TransmissionError(error!)))
                return
            }
            
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                resultsCallback(.Error(.NoDataReturned))
                return
            }
            
            do {
                guard let responseJSON = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String : AnyObject] else {
                    print("Error: Unable to decode JSON")
                    resultsCallback(.Error(.JSONParseError))
                    return
                }
                
                if let businesses = responseJSON["businesses"] as? [[String: AnyObject]] {
                    let urls = businesses.flatMap({ dict in
                        if let url = dict["image_url"] as? String, !url.isEmpty {
                            return url
                        }
                        return nil
                    })
                    self.amountFetched += urls.count
                    DispatchQueue.main.async {
                        resultsCallback(.Success(urls))
                    }
                }
                
            } catch {
                print("Error trying to convert data to JSON")
            }
        }
        task.resume()
    }
    
    private func initSession( callback: @escaping (NetworkResult<URLSession>) -> ()) {
        guard let apiKeys = keyProvider.provideKeys() else {
            callback(.Error(.NoClientID))
            return
        }
        
        fetchYelpToken(apiKeys) { (result) in
            switch result {
            case .Success(let bearerToken):
                let sessionConfig = URLSessionConfiguration.default
                sessionConfig.httpAdditionalHeaders = ["Authorization": "Bearer \(bearerToken)"]
                callback(.Success(URLSession(configuration: sessionConfig)))
                
            case .Error(let error):
                callback(.Error(error))
            }
        }
    }
    
    private func fetchYelpToken(_ apiKeys: [String : String], result: @escaping (NetworkResult<String>) -> ()) {
        // Check if we already have an access token
        // According to Yelp, they won't expire until 2038
        if let token = UserDefaults.standard.string(forKey: "YELP_TOKEN") {
            print("Token exists")
            result(.Success(token))
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
