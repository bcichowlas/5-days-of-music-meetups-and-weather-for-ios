//
//  TableViewCellMeetup.swift
//  FiveDaysOfMeetupAndWeather
//
//  Created by Bruce Cichowlas on 1/11/18.
//  Copyright © 2018 Real Keys Music. All rights reserved.
//

import UIKit
import WebKit

class TableViewCellMeetup: UITableViewCell,WKNavigationDelegate,WKUIDelegate {
    
    // Important note: I discovered that when WebKit called the 'didFinish' delegate, the WKWebView scroll content size is not yet set.  It gets set approximately 2 - 8 milliseconds later in the cases that I tried.  Rather than waste response time with inserting delays, it is possible to detect the content size value being set through KVO.  Unfortunately, the first initial value set through KVO is not usable, so I wait until the second setting.  All of this makes this somewhat dependent on the implementation of WKWebView, but the alternative seemed to be inserting artificial delays for values determined empirically and that would also be implementation-dependent.  Perhaps Apple will someday change 'didFinish" to not be called until the webView interpretation has set the content scroll values.
    
    let headerSize : CGFloat = 25
    let trailerSize : CGFloat = 25
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var btnLink: UIButton!
    @IBOutlet weak var webView: WKWebView!
    var mTable : UITableView?
    var mHeight: CGFloat = 0
    var lastValue : CGFloat = -1
    var mUsingFoundHeightValue = false // rather than having WebKit recalculate heights for contents asynchronously, try to reuse results when available
    var ignoringTheFirst: Bool = true // see above
    var mDescription : String? // remember the content for which our length was calculated
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        addObserver(self, forKeyPath: "webView.scrollView.contentSize", options: .new, context: nil)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.flexibleHeight]
        webView.scrollView.bounces = false
        webView.scrollView.scrollsToTop = true
        
    }
    
    deinit{
        removeObserver(self, forKeyPath: "webView.scrollView.contentSize", context: nil)
    }
    
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        ignoringTheFirst = true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let cell = object as! TableViewCellMeetup! else {return}
        let webView = cell.webView!
        mHeight = webView.scrollView.contentSize.height + headerSize + trailerSize
        
        if !mUsingFoundHeightValue {
            if let mTable = mTable {
                if self.ignoringTheFirst {
                    self.ignoringTheFirst = false
                } else {
                    if mHeight != lastValue {
                        // remember this calculation
                        if mDescription != nil {
                            WebKitHeightCache.rememberHeight(string: mDescription!, height: mHeight)
                        }
                        DispatchQueue.main.async {
                            mTable.reloadData()
                        }
                    }
                }
            }
            
        }
    }
    
    
    
}
