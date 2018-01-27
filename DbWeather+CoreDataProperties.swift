//
//  DbWeather+CoreDataProperties.swift
//  FiveDaysOfMeetupAndWeather
//
//  Created by Bruce Cichowlas on 1/22/18.
//  Copyright © 2018 Real Keys Music. All rights reserved.
//
//

import Foundation
import CoreData


extension DbWeather {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DbWeather> {
        return NSFetchRequest<DbWeather>(entityName: "DbWeather")
    }

    @NSManaged public var acquired: NSDate?
    @NSManaged public var dateOfInterest: NSDate?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var response: String?

}
