//
//  MeetupInfo.swift
//  FiveDaysOfMeetupAndWeather
//
//  Created by Bruce Cichowlas on 1/10/18.
//  Copyright © 2018 Real Keys Music. All rights reserved.
//

import UIKit
import SwiftyJSON


class MeetupInfo: NSObject {
    
    static let mMeetupKey = "***put your Meetup key here***"
    
    static let mTopic = "music" // this would make a useful variable
    
    
    // similar to code in other clasees for now, but eventually will vary
    public enum ErrorCode {
        case none
        case uncategorizedProblem
    }
    
    // Guarantee these are non-nil even if they are blank
    public var mName : String = ""
    public var mGroupName : String = ""
    public var mDescription : String = ""
    public var mEventUrl : String = ""
    
    
    class func interpretResponse(_ s: String) -> [MeetupInfo]? {
        let data = s.data(using: .utf8)
        do {
            var infos:[MeetupInfo] = []
            
            let json = try JSON(data: data!)
            let n = json["results"].count
            for i in 0..<n {
                let meetupInfo = MeetupInfo()
                let results = json["results"][i]
                meetupInfo.mName = results["name"].stringValue
                meetupInfo.mDescription = results["description"].stringValue
                meetupInfo.mEventUrl = results["event_url"].stringValue
                meetupInfo.mGroupName = results["group"]["name"].stringValue
                infos.append(meetupInfo)
            }
            return infos
        } catch {
            print("! 45 problem - returning nil")
            return nil
        }
    }
    
    
    // TODO: needs to be updated for latitude and longitude
    
    class func makeInfoURL(date: Date, latitude: Double, longitude: Double, radius: Double) -> String {
        let starting = Int64(date.startOfDay.timeIntervalSince1970) * 1000
        let ending = starting + 1000 * 60 * 60 * 24 - 1
        let dateString = "\(starting),\(ending)"
        return "https://api.meetup.com/2/open_events?&sign=true&photo-host=public&topic=\(mTopic)&lon=\(longitude)&lat=\(latitude)&time=\(dateString)&radius=\(radius)&page=20&key=\(mMeetupKey)"
    }
    
    class func onlineRetrieval(date: Date, latitude:Double, longitude:Double, radius:Double,  onResult: @escaping (_ error: ErrorCode, _ response: String?) -> Void) {
        Util.commGet(makeInfoURL(date: date, latitude: latitude, longitude: longitude, radius: radius)) {
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
