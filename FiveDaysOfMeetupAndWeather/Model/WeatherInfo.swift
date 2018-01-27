//
//  WeatherInfo.swift
//  FiveDaysOfMeetupAndWeather
//
//  Created by Bruce Cichowlas on 1/10/18.
//  Copyright © 2018 Real Keys Music. All rights reserved.
//

import UIKit
import SwiftyJSON

class WeatherInfo: NSObject {
    static let mKey = "*** put your Dark Sky key here +++"
    
    public var mWeatherDescription : String?
    public var mMinTemperature : Double?
    public var mMaxTemperature : Double?
    
    // similar to code in other clasees for now, but eventually will vary
    public enum ErrorCode {
        case none
        case uncategorizedProblem
    }

    
    class func interpretResponse(_ s: String, dateIndex: Int) -> WeatherInfo? {
        let data = s.data(using: .utf8)
        do {
            let json = try JSON(data: data!)
            let summary = json["daily"]["data"][dateIndex]["summary"]
            let temperatureMin = json["daily"]["data"][dateIndex]["temperatureMin"]
            let temperatureMax = json["daily"]["data"][dateIndex]["temperatureMax"]

            let weatherInfo = WeatherInfo()
            weatherInfo.mWeatherDescription = summary.stringValue
            weatherInfo.mMinTemperature = temperatureMin.doubleValue
            weatherInfo.mMaxTemperature = temperatureMax.doubleValue
            return weatherInfo
        } catch {
            return nil
        }
    }
    
    
    // TODO: needs to be updated for latitude and longitude and this is currently not for weather
    
    class func makeInfoURL(latitude: Double, longitude: Double) -> String {
        return "https://api.darksky.net/forecast/\(mKey)/\(latitude),\(longitude)"
    }
    
    class func onlineRetrieval(latitude:Double, longitude:Double,  onResult: @escaping (_ error: ErrorCode, _ response: String?) -> Void) {
        Util.commGet(makeInfoURL(latitude: latitude, longitude: longitude)) {
            (result:String?) in
            if let result = result {
                onResult(.none, result)
            } else {
                // some kind of error occurred, perhaps timeout
                onResult(.uncategorizedProblem, nil)
            }
        }
        
    }


}
