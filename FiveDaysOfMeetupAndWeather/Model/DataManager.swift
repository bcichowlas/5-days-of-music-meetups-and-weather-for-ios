//
//  DataManager.swift
//  FiveDaysOfMeetupAndWeather
//
//  Created by Bruce Cichowlas on 1/10/18.
//  Copyright © 2018 Real Keys Music. All rights reserved.
//

import UIKit
import CoreData

class DataManager: NSObject {
    
    static let mDistanceThreshold = 1000.0 // meters
    static let mRecentThreshhold:Double = 60 * 60 * 3 // 3 hours
    
    public enum ErrorCode {
        case none
        case uncategorizedProblem
        case onlineRetrievalProblem
        case databaseSaveProblem
    }
    
    // these use the cache if available.  TODO: Perhaps the cache should go stale after a certain period, like perhaps an hour.
    
    // Note: the response contains data for all five days, so the caller will need to know which of the days it is interested in.
    
    fileprivate static func obtainWeatherDataOnline(_ latitude: Double, _ longitude: Double, _ context: NSManagedObjectContext, _ onResult: @escaping (DataManager.ErrorCode, WeatherInfo?) -> Void, _ dateIndex: Int) {
        WeatherInfo.onlineRetrieval(latitude: latitude, longitude: longitude, onResult: { (errorCode: WeatherInfo.ErrorCode, response: String?) in
            if errorCode == .none {
                do {
                    // need to put it in the database.  In the case of weather, we can clear out all old values.
                    let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "DbWeather")
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
                    
                    try context.execute(deleteRequest)
                    try context.save()
                    
                    let entity =
                        NSEntityDescription.entity(forEntityName: "DbWeather",
                                                   in: context)!
                    
                    let newObj = NSManagedObject(entity: entity,
                                                 insertInto: context)
                    // set values
                    newObj.setValue(Date().startOfDay, forKeyPath: "dateOfInterest")
                    newObj.setValue(latitude, forKeyPath: "latitude")
                    newObj.setValue(longitude, forKeyPath: "longitude")
                    newObj.setValue(Date(), forKeyPath: "acquired")
                    newObj.setValue(response!, forKeyPath: "response")
                    // save it in database
                    try context.save()
                    
                    onResult(.none, WeatherInfo.interpretResponse(response!, dateIndex: dateIndex))
                } catch {
                    onResult(.databaseSaveProblem, nil)
                }
            } else {
                onResult(.uncategorizedProblem, nil)
            }
        })
    }
    
    fileprivate static func obtainMeetupDataOnline(_ date: Date, _ latitude: Double, _ longitude: Double, _ context: NSManagedObjectContext, _ onResult: @escaping (DataManager.ErrorCode, [MeetupInfo]?) -> Void) {
        MeetupInfo.onlineRetrieval(date: date, latitude: latitude, longitude: longitude, radius: mDistanceThreshold, onResult: { (errorCode: MeetupInfo.ErrorCode, response: String?) in
            if errorCode == .none {
                do {
                    // need to put it in the database.
                    
                    // erase any old record for this date
                    let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "DbMeetup")
                    deleteFetch.predicate = NSPredicate(format: "dateOfInterest = %@", date as CVarArg)
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
                    try context.execute(deleteRequest)
                    try context.save()
                    
                    let entity =
                        NSEntityDescription.entity(forEntityName: "DbMeetup",
                                                   in: context)!
                    
                    let newObj = NSManagedObject(entity: entity,
                                                 insertInto: context)
                    // set values
                    newObj.setValue(date, forKeyPath: "dateOfInterest")
                    newObj.setValue(latitude, forKeyPath: "latitude")
                    newObj.setValue(longitude, forKeyPath: "longitude")
                    newObj.setValue(Date(), forKeyPath: "acquired")
                    newObj.setValue(response!, forKeyPath: "response")
                    // we don't currently store radius because it is constant for this app
                    
                    // save it in database
                    try context.save()
                    
                    onResult(.none, MeetupInfo.interpretResponse(response!))
                } catch {
                    onResult(.databaseSaveProblem, nil)
                }
            } else {
                onResult(.uncategorizedProblem, nil)
            }
        })
    }
    

    
    class func retrieveWeatherInfo(dateIndex: Int, latitude:Double, longitude:Double,  onResult: @escaping (_ error: ErrorCode, _ info: WeatherInfo?) -> Void) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // check for cache record with this date
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DbWeather")
        
        do {
            request.predicate = NSPredicate(format: "dateOfInterest = %@", Date().startOfDay as CVarArg)
            request.returnsObjectsAsFaults = false
            let result = try context.fetch(request) as! [DbWeather]
            if result.count == 0 {
                obtainWeatherDataOnline(latitude, longitude, context, onResult, dateIndex)
            } else {
                for data in result { // there should only be at most one of these at a time
                    let dLatitude = data.value(forKey: "latitude") as! Double
                    let dLongitude = data.value(forKey: "longitude") as! Double
                    let dAcquired = data.value(forKey: "acquired") as! Date
                    let isNearby = Util.isLocationSimilar(dist: mDistanceThreshold, lat1: latitude, long1: longitude, lat2: dLatitude, long2: dLongitude)
                    let isRecent = Date().timeIntervalSince(dAcquired) <= mRecentThreshhold
                    
                    // was this nearby and recent?
                    if isNearby && isRecent{
                        // use the cache value
                        let result = data.value(forKey: "response") as! String
                        onResult(.none, WeatherInfo.interpretResponse(result, dateIndex: dateIndex))
                    } else {
                        // in the case of the weather data, we will be getting data for all five days at once.  So we don't need to search by date.
                        // delete the cache value and try to get another.
                        context.delete(data)
                        try context.save()
                        obtainWeatherDataOnline(latitude, longitude, context, onResult, dateIndex)
                    }
                }
            }
        } catch {
            onResult(.uncategorizedProblem, nil)
        }
        
    }
    
    // similar to above.  I considered refactoring to put some or all as extensions of a common class, but not sure that the criteria will remain so symmetric.  Could be done later, especially if there are more than two sources of data.
    
    class func retrieveMeetupInfo(date: Date, latitude:Double, longitude:Double,  onResult: @escaping (_ error: ErrorCode, _ info: [MeetupInfo]?) -> Void) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // check for cache record with this date
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DbMeetup")
        
        do {
            request.predicate = NSPredicate(format: "dateOfInterest = %@", date as CVarArg)
            request.returnsObjectsAsFaults = false
            let result = try context.fetch(request) as! [DbMeetup]
            if result.count == 0 {
                obtainMeetupDataOnline(date, latitude, longitude, context, onResult)
            } else {

            for data in result { // there should only be at most one of these at a time
                let dLatitude = data.value(forKey: "latitude") as! Double
                let dLongitude = data.value(forKey: "longitude") as! Double
                let dAcquired = data.value(forKey: "acquired") as! Date
                let isNearby = Util.isLocationSimilar(dist: mDistanceThreshold, lat1: latitude, long1: longitude, lat2: dLatitude, long2: dLongitude)
                let isRecent = Date().timeIntervalSince(dAcquired) <= mRecentThreshhold
                
                // was this nearby and recent?
                if isNearby && isRecent{
                    // use the cache value
                    let result = data.value(forKey: "response") as! String
                    onResult(.none, MeetupInfo.interpretResponse(result))
                    
                } else {
                    // delete the cache value and try to get another.
                    context.delete(data)
                    try context.save()
                    obtainMeetupDataOnline(date, latitude, longitude, context, onResult)
                }
            }
            }
        } catch {
            onResult(.uncategorizedProblem, nil)
        }
        
    }
}

