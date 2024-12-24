//
//  extensionNotificationName.swift
//  RTCnew
//
//  Created by Stefano on 28/04/24.
//

import Foundation
import CoreLocation

extension Notification.Name {
    static var genericMessage: Notification.Name {
        return .init(rawValue: "genericMessage.message")
    }
    static var dataChannelReadyState: Notification.Name {
        return .init(rawValue: "dataChannelReadyState.message")
    }
    static var dataChannelConnectionState: Notification.Name {
        return .init(rawValue: "dataChannelConnectionState.message")
    }
    static var delay: Notification.Name {
        return .init(rawValue: "delay.message")
    }
    
}

extension CLAuthorizationStatus {
    func toString() -> String {
        switch self.rawValue {
        case 0: return "notDetermined"
        // This application is not authorized to use location services.  Due
        // to active restrictions on location services, the user cannot change
        // this status, and may not have personally denied authorization
        case 1: return "restricted"
        // User has explicitly denied authorization for this application, or
        // location services are disabled in Settings.
        case 2: return "denied"
        // User has granted authorization to use their location at any
        // time.  Your app may be launched into the background by
        // monitoring APIs such as visit monitoring, region monitoring,
        // and significant location change monitoring.
        //
        // This value should be used on iOS, tvOS and watchOS.  It is available on
        // MacOS, but kCLAuthorizationStatusAuthorized is synonymous and preferred.
        case 3: return "authorizedAlways"
        // User has granted authorization to use their location only while
        // they are using your app.  Note: You can reflect the user's
        // continued engagement with your app using
        // -allowsBackgroundLocationUpdates.
        //
        // This value is not available on MacOS.  It should be used on iOS, tvOS and
        // watchOS.
        case 4: return "authorizedWhenInUse"
        default: return "NotKnown"
        }
    }
}
