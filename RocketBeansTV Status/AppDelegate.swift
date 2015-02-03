//
//  AppDelegate.swift
//  RocketBeansTV Status
//
//  Created by Timo Schlüter on 19.01.15.
//  Copyright (c) 2015 Timo Schlüter. All rights reserved.
//

import Cocoa
import SystemConfiguration

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var mainMenu: NSMenu!
    @IBOutlet weak var programViewCell: NSMenuItem!
    @IBOutlet weak var supportViewCell: NSMenuItem!
    @IBOutlet weak var programView: NSView!
    @IBOutlet weak var programTableView: NSTableView!
    @IBOutlet weak var appVersionLabel: NSTextField!
    @IBOutlet weak var supportView: NSView!
    
    @IBOutlet weak var informationWindow: NSWindow!
    
    var parser = NSXMLParser()
    var refreshInterval: NSTimeInterval = 60
    var refreshTimer: NSTimer?
    var posts = NSMutableArray()
    var elements = NSMutableDictionary()
    var currentElementName = NSString()
    
    var programTitle: String = ""
    var programSummary: String = ""
    var programState: String = ""
    var programDate: String = ""
    
    var programPlan: [ProgramPlan] = [] // all events from the google calendar
    var tableViewProgramPlan: [ProgramPlan] = [] // program for the table view
    
    var settingsWC: SettingsWindowController?
    
    /*
    
    Google Calender API Key.
    Go to your Google Developer Console (https://console.developers.google.com/project) and create a new Project with an iOS Specific API key.
    Set the Bundle Identifier to "in.timo.ios.RocketBeans-TV-Sendeplan" and insert the generated API key below.
    
    */
    
    var googleApiKey = ""
    
    
    /*
    
    Google Calendar Parsing
    
    The main data handling happens here now. This function gets the program from Google Calendar API
    All the logic that chooses which program is visible and which is not should be applied here.
    Formatting such as human readable dates and program title gimmicks should be applied when tableview is drawn
    
    */
    
    func parseGoogleCalendar() {
        
        /* Determine date for calendar request */
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        var now = NSDate()
        var timeMin = dateFormatter.stringFromDate(now)
        
        var timeMinEncoded = timeMin.stringByReplacingOccurrencesOfString("+", withString: "%2B")
        
        /* Put together the request url */
        var url: NSURL = NSURL(string: "https://www.googleapis.com/calendar/v3/calendars/h6tfehdpu3jrbcrn9sdju9ohj8%40group.calendar.google.com/events?orderBy=startTime&singleEvents=true&key=\(self.googleApiKey)&maxResults=20&timeMin=\(timeMinEncoded)")!
        
        var sessionConfig:NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.HTTPAdditionalHeaders = ["X-Ios-Bundle-Identifier": "in.timo.ios.RocketBeans-TV-Sendeplan"]
        
        let session = NSURLSession(configuration: sessionConfig)
        
        let task : NSURLSessionDataTask = session.dataTaskWithURL(url) {(data, response, error) in
            let jsonData: NSData = data
            var error: NSError?
            
            let programData: AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonData, options: nil, error: &error)
            
            var dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssXXX" /* Example: 2015-01-18T00:00:00+01:00 */
            
            var programList:[ProgramPlan] = []
            var tableViewProgramPlan:[ProgramPlan] = []
            
            if let programCalendar = programData as? NSDictionary {

                if let programItems = programCalendar["items"] as? NSArray {
                    
                    for singleProgramItem in programItems {
                        
                        var program: ProgramPlan = ProgramPlan()
                        
                        if let singleProgramItemAttributes = singleProgramItem as? NSDictionary {
                            
                            if let startDateObject = singleProgramItemAttributes["start"] as? NSDictionary {
                                var startDateString = startDateObject["dateTime"] as String
                                var startDate = dateFormatter.dateFromString(startDateString)!
                                program.programStartDateFormattable = startDate
                                var startEpochDate = startDate.timeIntervalSince1970
                                program.programStartDateEpoch = startEpochDate
                                
                            }
                            
                            if let endDateObject = singleProgramItemAttributes["end"] as? NSDictionary {
                                var endDateString = endDateObject["dateTime"] as String
                                var endDate = dateFormatter.dateFromString(endDateString)
                                program.programEndDateFormattable = endDate!
                                var endEpochDate = endDate?.timeIntervalSince1970
                                program.programEndDateEpoch = endEpochDate!
                            }
                            
                            program.programTitle = singleProgramItemAttributes["summary"] as String
                            program.programUid = singleProgramItemAttributes["iCalUID"] as String
                            
                            programList.append(program)
                            
                            /* Get current date in UTC */
                            var currentDate = NSDate()
                            
                            var comparingStartDate = program.programStartDateFormattable
                            var comparingEndDate = program.programEndDateFormattable
                            
                            /* Check if program is in the future or now */
                            if ((comparingStartDate.compare(currentDate) == NSComparisonResult.OrderedDescending)
                                || (comparingStartDate.compare(currentDate) == NSComparisonResult.OrderedSame))
                                || ((currentDate.compare(comparingStartDate) == NSComparisonResult.OrderedDescending)
                                    && (currentDate.compare(comparingEndDate) == NSComparisonResult.OrderedAscending))
                            {
                                /* Check if program is currently running */
                                if (currentDate.compare(comparingStartDate) == NSComparisonResult.OrderedDescending)
                                    && (currentDate.compare(comparingEndDate) == NSComparisonResult.OrderedAscending)
                                {
                                    program.programCurrent = true
                                } else {
                                    program.programCurrent = false
                                }
                                
                                /* Append program to list for the table view */
                                tableViewProgramPlan.append(program)
                            }
                            
                            programList.sort({$0.programStartDateEpoch < $1.programStartDateEpoch})
                            tableViewProgramPlan.sort({$0.programStartDateEpoch < $1.programStartDateEpoch})
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                /* Set global programPlan to the just generated programList */
                                self.tableViewProgramPlan = tableViewProgramPlan
                                self.programTableView.reloadData()
                            })
                            
                            /* checks if program plan has changed */
                            self.checkForNewProgramPlan(programList)
                            
                            /* checks if we need to add a user notification for upcoming broadcast */
                            self.checkForNextBroadcastNotification(tableViewProgramPlan)
                        }
                    }
                }
            }
            
        };
        
        task.resume()
    }
    
    /* check if we have a user notification for the next broadcast */
    func checkForNextBroadcastNotification(newPlan: [ProgramPlan])
    {
        /* only if notifications for broadcasts are enabled */
        if NSUserDefaults.standardUserDefaults().boolForKey("NotificationOnAir") {
            
            /* check first two entries */
            for i in 0...1 {
                if newPlan.count > i {
                    
                    let program = newPlan[i]
                    var found = false
                    
                    /* check if there is already a notification in progress */
                    for n in NSUserNotificationCenter.defaultUserNotificationCenter().scheduledNotifications {
                        
                        let notification = n as NSUserNotification
                        
                        if program.programUid == notification.identifier {
                            found = true
                            break
                        }
                    }
                    
                    if !found {
                        /* get human readable date */
                        let humanReadableStartDate = program.humanReadableStartDate()
                        let humanReadableEndDate = program.humanReadableEndDate()
                        
                        let title = self.iconNameFromTitle(program.programTitle)
                        
                        /* calculate delivery date */
                        var deliveryDate = program.programStartDateFormattable
                        let aheadInterval = NSUserDefaults.standardUserDefaults().doubleForKey("BroadcastAheadInterval")
                        deliveryDate = deliveryDate.dateByAddingTimeInterval(-1 * 60 * aheadInterval)
                        
                        /* send the notification */
                        self.sendLocalNotification(title.stripedTitle, text: "\(title.stripedTitle): \(humanReadableStartDate) - \(humanReadableEndDate)", deliveryDate: deliveryDate, identifier: program.programUid)
                    }
                }
            }
        }
    }
    
    /* check for updated program plan and send user notification */
    func checkForNewProgramPlan(newPlan: [ProgramPlan])
    {
        // if the number of entries is different - we have a changed program plan
        if self.programPlan.count != newPlan.count && self.programPlan.count != 0 {
            self.programPlan = newPlan
            if NSUserDefaults.standardUserDefaults().boolForKey("NotificationOnChanges") {
                self.sendLocalNotification("Aktualisierung", text: "Der Sendeplan wurde aktualisiert.")
            }
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func informationButtonPressed(sender: AnyObject) {
        self.informationWindow.makeKeyAndOrderFront(self)
        self.informationWindow.makeMainWindow()
        var application: AnyObject! = NSApp
        application.activateIgnoringOtherApps(true)

    }
    
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        if self.settingsWC == nil {
            self.settingsWC = SettingsWindowController(windowNibName: "SettingsWindowController")
        }
        
        self.settingsWC?.showWindow(self)
        self.settingsWC?.window?.makeKeyAndOrderFront(self)
        self.settingsWC?.window?.makeMainWindow()
    }
    
    /* START Social Media Buttons */
    @IBAction func twitterButtonPressed(sender: AnyObject) {
        let twitterUrl: NSURL = NSURL(string: "http://www.twitter.com/tmuuh")!
        NSWorkspace.sharedWorkspace().openURL(twitterUrl)
    }
    
    @IBAction func redditButtonPressed(sender: AnyObject) {
        let redditUrl: NSURL = NSURL(string: "http://www.reddit.com/user/t-muh/")!
        NSWorkspace.sharedWorkspace().openURL(redditUrl)
    }
    
    @IBAction func facebookButtonPressed(sender: AnyObject) {
        let facebookUrl: NSURL = NSURL(string: "https://www.facebook.com/timo.schlueter")!
        NSWorkspace.sharedWorkspace().openURL(facebookUrl)
    }
    
    @IBAction func wordpressButtonPressed(sender: AnyObject) {
        let wordpressUrl: NSURL = NSURL(string: "http://www.timo.in")!
        NSWorkspace.sharedWorkspace().openURL(wordpressUrl)
    }
    
    @IBAction func githubButtonPressed(sender: AnyObject) {
        let githubUrl: NSURL = NSURL(string: "https://github.com/timoschlueter")!
        NSWorkspace.sharedWorkspace().openURL(githubUrl)
    }
    
    /* END Social Media Buttons */
    
    @IBAction func startStreamButtonClicked(sender: AnyObject) {
        let twitchUrl: NSURL = NSURL(string: "http://www.twitch.tv/rocketbeanstv")!
        NSWorkspace.sharedWorkspace().openURL(twitchUrl)
    }
    
    @IBAction func openGoogleCalendarButtonClicked(sender: AnyObject) {
        let gcalUrl: NSURL = NSURL(string: "https://www.google.com/calendar/embed?src=h6tfehdpu3jrbcrn9sdju9ohj8%40group.calendar.google.com")!
        NSWorkspace.sharedWorkspace().openURL(gcalUrl)
    }
    
    @IBAction func closeButtonClicked(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    @IBAction func amazonButtonClicked(sender: AnyObject) {
        let amazonUrl: NSURL = NSURL(string: "http://www.amazon.de/?_encoding=UTF8&camp=1638&creative=19454&linkCode=ur2&site-redirect=de&tag=rocketbeansde-21&linkId=TS4VQU7BZNNUKCKO")!
        NSWorkspace.sharedWorkspace().openURL(amazonUrl)
    }

    @IBAction func rbShopButtonClicked(sender: AnyObject) {
        let rbShopUrl: NSURL = NSURL(string: "http://rocketbeans-shop.de")!
        NSWorkspace.sharedWorkspace().openURL(rbShopUrl)
    }
    
    @IBAction func g2aButtonClicked(sender: AnyObject) {
        let g2aShopUrl: NSURL = NSURL(string: "https://www.g2a.com/r/rocket-beans")!
        NSWorkspace.sharedWorkspace().openURL(g2aShopUrl)
    }
    
    // MARK: -
    
    var statusItem: NSStatusItem
    let statusItemLength: CGFloat = 25.0
    
    override init() {
        let statusBar = NSStatusBar.systemStatusBar()
        self.statusItem = statusBar.statusItemWithLength(-1)
    }
    
    func beginParsing()
    {
        self.tableViewProgramPlan = []
        
        if (!self.isConnectedToNetwork()) {
            /* No connection to the internet */
            let program: ProgramPlan = ProgramPlan()
            program.programTitle = "Keine Verbindung zum Internet!"
            program.programDate = "Sendeplan kann nicht geladen werden."
            program.programState = ""
            self.tableViewProgramPlan.append(program)
        } else {
            /* We have a signal! Lets go! */
            self.parseGoogleCalendar()
        }

        programTableView.reloadData()
    }
    
    /* sends a local notification for given title and text */
    func sendLocalNotification(title: String, text: String)
    {
        let deliveryDate = NSDate(timeIntervalSinceNow: 2) // 2 seconds delay
        self.sendLocalNotification(title, text: text, deliveryDate: deliveryDate, identifier: nil)
    }

    /* sends a local notification for given title and text - at the delivery date */
    func sendLocalNotification(title: String, text: String, deliveryDate: NSDate, identifier: String?)
    {
        let notificationCenter = NSUserNotificationCenter.defaultUserNotificationCenter()
        let notification = NSUserNotification()
        notification.title = title
        if identifier != nil { notification.identifier = identifier! }
        notification.informativeText = text
        notification.deliveryDate = deliveryDate
        notificationCenter.scheduleNotification(notification)
    }
    
    func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
        }
        
        var flags: SCNetworkReachabilityFlags = 0
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
            return false
        }
        
        let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        
        return (isReachable && !needsConnection) ? true : false
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        /* register delivered default settings */
        NSUserDefaults.standardUserDefaults().registerDefaults([
            "NotificationOnChanges" : true,   // enable notifications for changes on air dates
            "NotificationOnAir" : true,       // enable notifications for starting broadcasts
            "UpdateInterval" : 1,             // update every minute
            "BroadcastAheadInterval" : 10     // notification 10 minutes before broadcast
            ])
        
        /* get updates for user defaults */
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updateValuesFromUserDefaults"), name: NSUserDefaultsDidChangeNotification, object: nil)
        
        self.statusItem.toolTip = "RocketBeans.TV Sendeplan"
        self.statusItem.image = NSImage(named: "StatusIcon")
        self.statusItem.image?.setTemplate(true)
        self.statusItem.highlightMode = true
        self.statusItem.menu = mainMenu
        
        self.programViewCell.view = programView
        self.supportViewCell.view = supportView
        self.programTableView.setDataSource(self)
        
        self.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(self.refreshInterval, target: self, selector: Selector("beginParsing"), userInfo: nil, repeats: true)
        
        self.beginParsing()
        
        let bundle:NSBundle = NSBundle.mainBundle()
        let appVersion: String = bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as String
        
        self.appVersionLabel.stringValue = "Version \(appVersion)"
    }
    
    func updateValuesFromUserDefaults()
    {
        /* stop previous timer */
        self.refreshTimer?.invalidate()
        /* update user settings */
        self.refreshInterval = NSUserDefaults.standardUserDefaults().doubleForKey("UpdateInterval") * 60 // and convert minutes to seconds
        /* restart timer */
        self.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(self.refreshInterval, target: self, selector: Selector("beginParsing"), userInfo: nil, repeats: true)
    }
    
    /* seperates title to iconname and title without type tag in front of it */
    func iconNameFromTitle(title: String) -> (stripedTitle: String, iconName: String)
    {
        var stripedTitle = title
        var iconName: String
        
        if let range = title.rangeOfString("[L] ") {
            iconName = "LiveIcon"
            stripedTitle.removeRange(range)
        } else if let range = title.rangeOfString("[L]") {
            iconName = "LiveIcon"
            stripedTitle.removeRange(range)
        } else if let range = title.rangeOfString("[N] ") {
            iconName = "NewIcon"
            stripedTitle.removeRange(range)
        } else if let range = title.rangeOfString("[N]") {
            iconName = "NewIcon"
            stripedTitle.removeRange(range)
        } else {
            iconName = "RerunIcon"
        }
        
        return (stripedTitle, iconName)
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView!) -> Int
    {
        return self.tableViewProgramPlan.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn: NSTableColumn, row: Int) -> NSView
    {
        
        let programRow: ProgramPlan = self.tableViewProgramPlan[row]
        
        var cell = tableView.makeViewWithIdentifier("programCell", owner: self) as CustomTableView
        
        tableView.backgroundColor = NSColor.clearColor()
        
        /*
        
        if (programRow.programCurrent) {
            var rowView = tableView.rowViewAtRow(row, makeIfNecessary: true) as NSTableRowView
            /* TODO: strange things happening when background color is changed */
            rowView.backgroundColor = NSColor.lightGrayColor()
        }
    
        */
        
        /* get title without type tag and get icon name */
        let titleInfo = self.iconNameFromTitle(programRow.programTitle)
        programRow.programTitle = titleInfo.stripedTitle
        cell.logoImageView.image = NSImage(named: titleInfo.iconName)
        
        /* Append special state, if the program is currently running */
        if (programRow.programCurrent) {
            var rowView = tableView.rowViewAtRow(row, makeIfNecessary: true) as NSTableRowView
            programRow.programTitle = "(JETZT!) \(programRow.programTitle)"
        }
        
        /* Set the final program title */
        cell.titleTextfield?.stringValue = "\(programRow.programTitle)"
        
        /* get human readable date */
        let humanReadableStartDate = programRow.humanReadableStartDate()
        let humanReadableEndDate = programRow.humanReadableEndDate()
        
        /* Set the date label */
        cell.startTimeTextfield?.stringValue = "\(humanReadableStartDate) - \(humanReadableEndDate)"
        
        return cell;
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}

