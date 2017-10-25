//
//  LocationProvider.swift
//  Yelpic
//
//  Created by Steve Malsam on 10/24/17.
//  Copyright © 2017 Steve Malsam. All rights reserved.
//

import CoreLocation

enum LocationResult {
    case Success(CLLocation)
    case Error(Error)
    case NoAuthorization()
}

typealias LocationCallback = (LocationResult) -> ()

class LocationProvider: NSObject, CLLocationManagerDelegate {
    let locationManager : CLLocationManager
    var locationCallback: LocationCallback?
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 500
    }
    
    func getLocationUpdate(callback: @escaping LocationCallback) {
        self.locationCallback = callback

        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if case .denied = status,
            let callback = self.locationCallback {
            callback(.NoAuthorization())
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let callback = self.locationCallback,
            let location = locations.first {
            callback(.Success(location))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        if let callback = self.locationCallback {
            callback(.Error(error))
        }
    }
}
