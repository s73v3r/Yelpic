//
//  SearchProvider.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/21/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import Foundation

class YelpSearchProvider {

    let searchTerm: String
    let session: URLSession
    var amountFetched = 0

    init(searchTerm: String, bearerToken: String) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = ["Authorization": "Bearer \(bearerToken)"]
        session = URLSession(configuration: sessionConfig)
        self.searchTerm = searchTerm
    }

    func performSearch(withResults resultsCallback: @escaping ([String]) -> ()) {
        let request = createRequest(searchTerm: searchTerm, withOffset: amountFetched)

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
                    self.amountFetched += urls.count
                    DispatchQueue.main.async {
                        resultsCallback(urls)
                    }
                }

            } catch {
                print("Error trying to convert data to JSON")
            }
        }
        task.resume()
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
}
