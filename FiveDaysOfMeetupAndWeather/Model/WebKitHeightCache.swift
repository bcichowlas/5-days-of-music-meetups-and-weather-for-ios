//
//  WebKitHeightCache.swift
//
//  Created by Bruce Cichowlas on 1/21/18.
//  Copyright © 2018 Real Keys Music. All rights reserved.
//

import UIKit
import CoreData

class WebKitHeightCache: NSObject {
    
    static let mDbTableName = "DbWebKitHeight"
    
    class func lookupHeight(string:String!) -> CGFloat? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // check for cache record with this date
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: mDbTableName)
        
        do {
            request.predicate = NSPredicate(format: "string = %@", string as CVarArg)
            request.returnsObjectsAsFaults = false
            let result = try context.fetch(request) as! [DbWebKitHeight]
            if result.count == 0 {
                return nil
            } else {
                return CGFloat(result[0].height)
            }
        } catch {
            return nil
        }
    }
    
    class func rememberHeight(string: String, height: CGFloat){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let entity =
            NSEntityDescription.entity(forEntityName: mDbTableName,
                                       in: context)!
        // check for cache record with this date
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: mDbTableName)
        
        do {
            request.predicate = NSPredicate(format: "string = %@", string as CVarArg)
            request.returnsObjectsAsFaults = false
            let result = try context.fetch(request) as! [DbWebKitHeight]
            if result.count == 0 {
                let newObj = NSManagedObject(entity: entity,
                                             insertInto: context)
                // set values
                newObj.setValue(string, forKeyPath: "string")
                newObj.setValue(height, forKeyPath: "height")
            } else {
                result[0].height = Double(height)
            }
            // save it in database
            try context.save()
        } catch {
            print("WebKitHeightCache.rememberHeight failed for \(string) \(height)")
        }
        
    }
    
    class func forgetAll(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: mDbTableName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        
        do {
            
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("WebKitHeightCache.forgetAll failed")
        }
    }
    
}
