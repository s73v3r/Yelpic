//
//  KeyProvider.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/19/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import Foundation

enum AuthenticationError : Error {
    case TokenNotFound
}

protocol KeyProvider {
    func provideKeys() -> [String: String]?
}

protocol PlistKeyProvider : KeyProvider {
    var fileName: String {get}
}

class YelpKeyProvider: PlistKeyProvider {
    var fileName = "Config"

    func provideKeys() -> [String : String]? {
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "plist") else {
            print("Error: Unable to find File")
            return nil
        }
        
        guard let data = try? Data(contentsOf: fileURL) else {
            print("Error: Unable to Read file")
            return nil
        }
        
        guard let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : String] else {
            print("Error: File wrong")
            return nil
        }
        
        return result
    }
}
