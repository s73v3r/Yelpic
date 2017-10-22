//
//  ImageProvider.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/21/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import UIKit

typealias ImageResultCallback = (ImageResult) -> ()

enum ImageResult {
    case Success(UIImage)
    case Downloaded
    case Error(NetworkError)
}

protocol ImageProvider {
    func retrieveImageAtURL(url: URL, resultCallback: @escaping ImageResultCallback)
}

class YelpImageProvider: ImageProvider {
    enum RequestState {
        case InProgress([ImageResultCallback])
        case Finished(UIImage)
    }

    var requestStatus = Dictionary<URL, RequestState>()

    func retrieveImageAtURL(url: URL, resultCallback: @escaping (ImageResult) -> ()) {
        if let state = requestStatus[url] {
            switch state {
                case .InProgress(var requesters):
                    print("\(url): Adding to list of requesters")
                    requesters.append(resultCallback)

                case .Finished(let image):
                    print("\(url): Using Image from Cache")
                    resultCallback(.Success(image))
            }
        } else {
            print("\(url): Fetching image from Web")
            requestStatus[url] = .InProgress([resultCallback])
            URLSession.shared.downloadTask(with: url) { (location, response, error) in
                if let imgData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        if let image = UIImage(data: imgData) {
                            if let requestStatus = self.requestStatus[url] {
                                if case .InProgress(let requests) = requestStatus {
                                    self.requestStatus[url] = .Finished(image)
                                    for request in requests {
                                        request(.Downloaded)
                                    }
                                }
                            }
                        } else {
                            if let requestStatus = self.requestStatus[url] {
                                if case .InProgress(let requests) = requestStatus {
                                    self.requestStatus.removeValue(forKey: url)
                                    for request in requests {
                                        request(.Error(.CorruptedImage))
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            }.resume()
        }
    }
}
