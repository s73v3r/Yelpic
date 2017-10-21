//
//  SearchProvider.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/21/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import Foundation

class YelpSearchProvider: BearerTokenInjection {

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
        bearerTokenProvider.loadBearerToken { (result) in
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
}
