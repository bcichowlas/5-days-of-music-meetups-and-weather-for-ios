//
//  DbWebKitHeight+CoreDataProperties.swift
//  FiveDaysOfMeetupAndWeather
//
//  Created by Bruce Cichowlas on 1/22/18.
//  Copyright © 2018 Real Keys Music. All rights reserved.
//
//

import Foundation
import CoreData


extension DbWebKitHeight {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DbWebKitHeight> {
        return NSFetchRequest<DbWebKitHeight>(entityName: "DbWebKitHeight")
    }

    @NSManaged public var height: Double
    @NSManaged public var string: String?
    @NSManaged public var whenCreated: NSDate?

}
