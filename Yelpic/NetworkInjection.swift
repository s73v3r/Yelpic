//
//  Injection.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/19/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import Foundation

protocol NetworkInjection{}

struct NetworkInjector: NetworkInjection {
    static var keyProvider = YelpKeyProvider()
}

extension NetworkInjection {
    var keyProvider:KeyProvider { get { return NetworkInjector.keyProvider } }
}
