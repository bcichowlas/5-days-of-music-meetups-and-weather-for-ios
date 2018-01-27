//
//  Model.swift
//  EqualitySkinCapture
//
//  Created by Bruce Cichowlas on 10/28/17.
//  Copyright © 2017 Gyroscope. All rights reserved.
//

import UIKit

private let _ModelInstance = Model()


class Model: NSObject {
    
    class var instance: Model {
        return _ModelInstance
    }
    
    var mCurrentDayIndex = 0
    let mDayCount = 5
    var mDays : [Date] = []

    func setupDays(){
        let today = Calendar.current.startOfDay(for: Date())
        mDays = [today]
        // add four more days
        for i in 1 ..< mDayCount {
            mDays.append(today.addingTimeInterval(Double(i*24*60*60)))
        }
        mCurrentDayIndex = 0
    }
    
    func dayForward(){
        if mCurrentDayIndex < mDayCount - 1 {
            mCurrentDayIndex += 1
        }
    }
    
    func dayBackward(){
        if mCurrentDayIndex > 0 {
            mCurrentDayIndex -= 1
        }
    }
    
}
