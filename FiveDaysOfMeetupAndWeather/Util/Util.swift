//
//  Util.swift
//  EqualitySkinCapture
//
//  Created by Bruce Cichowlas on 11/9/17.
//  Copyright © 2017 Gyroscope. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON

class Util: NSObject {
    
    class func isLocationSimilar(dist:Double, lat1:Double, long1:Double, lat2:Double, long2:Double) -> Bool {
        let loc1 = CLLocation(latitude: lat1, longitude: long1)
        let loc2 = CLLocation(latitude: lat2, longitude: long2)
        return loc1.distance(from: loc2) <= dist
    }
    
    class func commPost(_ url_to_request:String,_ body: String, onComplete: @escaping (String?) -> Void) {
        
        
        let url:NSURL = NSURL(string: url_to_request)!
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        
        
        let data = body.data(using: String.Encoding.utf8)
        
        
        let task = session.uploadTask(with: request as URLRequest, from: data, completionHandler:
        {(data,response,error) in
            
            guard let data = data, let _:URLResponse = response, error == nil else {
                print("! 31 error")
                return
            }
            
            let dataString = String(data: data, encoding: String.Encoding.utf8)
            DispatchQueue.main.async {
                onComplete(dataString)
            }
        }
        );
        
        task.resume()
    }
    
    class func commGet(_ url_to_request:String, onComplete: @escaping (String?) -> Void) {
        
        
        let url:NSURL = NSURL(string: url_to_request)!
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        
        
        let task = session.dataTask(with: request as URLRequest, completionHandler:
        {(data,response,error) in
            
            guard let data = data, let _:URLResponse = response, error == nil else {
                print("! 61 error")
                return
            }
            
            let dataString = String(data: data, encoding: String.Encoding.utf8)
            DispatchQueue.main.async {
                onComplete(dataString)
            }
        }
        );
        
        task.resume()
    }
    
    class func delay(bySeconds seconds: Double, dispatchLevel: DispatchLevel = .main, closure: @escaping () -> Void) {
        let dispatchTime = DispatchTime.now() + seconds
        dispatchLevel.dispatchQueue.asyncAfter(deadline: dispatchTime, execute: closure)
    }
    
    public enum DispatchLevel {
        case main, userInteractive, userInitiated, utility, background
        var dispatchQueue: DispatchQueue {
            switch self {
            case .main:                 return DispatchQueue.main
            case .userInteractive:      return DispatchQueue.global(qos: .userInteractive)
            case .userInitiated:        return DispatchQueue.global(qos: .userInitiated)
            case .utility:              return DispatchQueue.global(qos: .utility)
            case .background:           return DispatchQueue.global(qos: .background)
            }
        }
    }
    
}

// Extensions

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType:  NSAttributedString.DocumentType.html], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }}
