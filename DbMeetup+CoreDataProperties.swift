//
//  DbMeetup+CoreDataProperties.swift
//  FiveDaysOfMeetupAndWeather
//
//  Created by Bruce Cichowlas on 1/22/18.
//  Copyright © 2018 Real Keys Music. All rights reserved.
//
//

import Foundation
import CoreData


extension DbMeetup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DbMeetup> {
        return NSFetchRequest<DbMeetup>(entityName: "DbMeetup")
    }

    @NSManaged public var acquired: NSDate?
    @NSManaged public var dateOfInterest: NSDate?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var response: String?

}
