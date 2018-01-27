//
//  MainViewController.swift
//  FiveDaysOfMeetupAndWeather
//
//  Created by Bruce Cichowlas on 1/3/18.
//  Copyright © 2018 Real Keys Music. All rights reserved.
//

// TODO:
//    Discard data when location changes significantly.


import UIKit
import CoreLocation
import SafariServices
import WebKit

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var tblMeetups: UITableView!
    @IBOutlet weak var lblWaitingForAuthorization: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblTemperatureLine: UILabel!
    @IBOutlet weak var lblWeatherDescription: UILabel!
    @IBOutlet var swipeGestureLeft: UISwipeGestureRecognizer!
    @IBOutlet var swipeGestureRight: UISwipeGestureRecognizer!
    
    var locManager = CLLocationManager()
    var currentLocation: CLLocation!
    let authCheckDelay = 3.0 // would normally only happen when running the first time

    var mContentHeight : [CGFloat] = []
    
    let useRecursive = true // things seem to result in messy update if we don't use "once and for all" approach in calculating all the heights before we begin to display.  (Set this to false to see what happens. Maybe we will understand why later and can simplify, but maybe it is an unavoidable interaction between how tableview reuses cells and how wkwebview works.)  Since we have only one test wkWebView to test the layout for the height and it operates asynchronously, we have no choice but to use it serially and take a recursive approach.
    
    var meetups:[MeetupInfo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        locManager.requestWhenInUseAuthorization()
        Model.instance.setupDays()
        if checkForAuth(){
            lblWaitingForAuthorization.isHidden = true
            
        } else {
            lblWaitingForAuthorization.isHidden = false
            perform(#selector(checkForAuth), with: nil, afterDelay: authCheckDelay)
            
        }
        updateView()
        
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            if let currentLocation = locManager.location {
                print(currentLocation.coordinate.latitude)
                print(currentLocation.coordinate.longitude)
            } else {
                print("? 48 location not available")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func checkForAuth()->Bool {
        let authorized = CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways
        if authorized {
            DispatchQueue.main.async {
                self.updateView()
                self.lblWaitingForAuthorization.isHidden = true
            }
        } else {
            perform(#selector(checkForAuth), with: nil, afterDelay: authCheckDelay)
        }
        return authorized
    }
    
    func updateView(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none
        lblDate.text = dateFormatter.string(from: Model.instance.mDays[Model.instance.mCurrentDayIndex])
        
        // get data for this date, using cached data if available
        guard let location = locManager.location else { return } // we'll just not attempt to update if we don't have a reasonable location
        updateWeather(location: location)
        updateMeetup(location: location)
    }
    
    func updateWeather(location: CLLocation){
        let dateIndex = Model.instance.mCurrentDayIndex
        DataManager.retrieveWeatherInfo(dateIndex: dateIndex, latitude:location.coordinate.latitude,
                                        longitude: location.coordinate.longitude) { (errorCode:DataManager.ErrorCode, weatherInfo: WeatherInfo?) in
                                            DispatchQueue.main.async {
                                                if let weatherInfo = weatherInfo {
                                                    self.lblWeatherDescription.text = weatherInfo.mWeatherDescription
                                                    self.lblTemperatureLine.text = "\(Int(weatherInfo.mMaxTemperature!))\u{00B0} / \(Int(weatherInfo.mMinTemperature!))\u{00B0}"
                                                }
                                            }
        }
    }
    
    func updateMeetup(location: CLLocation){
        let day = Model.instance.mDays[Model.instance.mCurrentDayIndex]
        DataManager.retrieveMeetupInfo(date: day,
                                       latitude:location.coordinate.latitude,
                                       longitude: location.coordinate.longitude) { (errorCode:DataManager.ErrorCode, meetupInfo: [MeetupInfo]?) in
                                        if let meetupInfo = meetupInfo {
                                            let n = meetupInfo.count
                                            self.mContentHeight = []
                                            for _ in 0 ..< n {
                                                self.mContentHeight.append(0)
                                            }
                                            self.meetups = meetupInfo

                                            }
                                        DispatchQueue.main.async {
                                            self.tblMeetups.reloadData()
                                        }
        }
    }
    
    @IBAction func swipeLeft(_ sender: Any) {
        Model.instance.dayForward()
        updateView()
    }
    
    @IBAction func swipeRight(_ sender: Any) {
        Model.instance.dayBackward()
        updateView()
    }
    
    // (meetup) table view delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return meetups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCellMeetup", for: indexPath) as! TableViewCellMeetup
        let row = indexPath.row
        cell.mTable = tableView
        cell.tag = row
        // this is the only place where the asynchronous loadHTMLString sequence gets kicked off, but don't play with the height if we remember it from the same string before.
        let string = meetups[row].mDescription
        let foundHeight = WebKitHeightCache.lookupHeight(string: string)
        
        if let foundHeight = foundHeight {
            cell.mHeight = foundHeight
            mContentHeight[row] = foundHeight
            cell.mUsingFoundHeightValue = true
        } else {
            cell.mHeight = 0
            
            mContentHeight[row] = 0 // I see that in a way I am replacing cell.mHeight with this local array, just to avoid the TableView call that is failing.  But that's alright under the circumstances, I think.
            cell.mUsingFoundHeightValue = false
            cell.mDescription = string
        }
        cell.lblName.text = meetups[row].mName
        cell.webView.loadHTMLString(string, baseURL: nil)
        cell.btnLink.addTarget(self, action: #selector(moreLink), for: .touchUpInside)
        cell.btnLink.tag = row
        return cell
    }
    
    @objc func moreLink(_ sender:UIButton){
        let tag = sender.tag
        let url = meetups[tag].mEventUrl
        if url != "" {
            let svc = SFSafariViewController(url: URL(string:url)!)
            present(svc, animated: true, completion: nil)
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var ret:CGFloat = 0
        
        ret = mContentHeight[indexPath.row]
        return ret
    }
    
    
    
}

