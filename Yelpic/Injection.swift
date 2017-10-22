//
//  Injection.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/19/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import Foundation

enum NetworkError: Error {
    case NoClientID
    case TransmissionError(Error)
    case NoDataReturned
    case JSONParseError
    case CorruptedImage
}

enum NetworkResult<T> {
    case Success(T)
    case Error(NetworkError)
}

protocol KeyProviderInjection{}

struct KeyProviderInjector: KeyProviderInjection {
    static var keyProvider = YelpKeyProvider()
}

extension KeyProviderInjection {
    var keyProvider:KeyProvider { get { return KeyProviderInjector.keyProvider } }
}

protocol BearerTokenInjection{}

struct BearerTokenInjector: BearerTokenInjection {
    static var bearerTokenProvider = YelpBearerTokenProvider()
}

extension BearerTokenInjection {
    var bearerTokenProvider: BearerTokenProvider { get { return BearerTokenInjector.bearerTokenProvider } }
}

protocol ImageProviderInjection {}

struct ImageProviderInjector {
    static var imageProvider = YelpImageProvider()
}

extension ImageProviderInjection {
    var imageProvider: ImageProvider { get { return ImageProviderInjector.imageProvider } }
}
