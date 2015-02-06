//
//  AppDelegate.swift
//  RocketBeansTV Status
//
//  Created by Timo Schlüter on 19.01.15.
//  Copyright (c) 2015 Timo Schlüter. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, ProgramPlanDelegate, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var mainMenu: NSMenu!
    @IBOutlet weak var programViewCell: NSMenuItem!
    @IBOutlet weak var supportViewCell: NSMenuItem!
    @IBOutlet weak var programView: NSView!
    @IBOutlet weak var programTableView: NSTableView!
    @IBOutlet weak var appVersionLabel: NSTextField!
    @IBOutlet weak var supportView: NSView!
    
    @IBOutlet weak var informationWindow: NSWindow!
    
    var refreshInterval: NSTimeInterval = 60
    var refreshTimer: NSTimer?
    
    var programPlan: ProgramPlan // all events from the google calendar
    var tableViewPrograms: [Program] = [] // program for the table view
    
    var settingsWC: SettingsWindowController?
    
<<<<<<< HEAD
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
=======
    func beginParsing()
    {
        self.tableViewPrograms = []
        self.programPlan.beginRefresh()
    }
    
    /* Callback from ProgramPlan */
    func programPlanDidRefresh(programPlan: ProgramPlan) {
        /* Set global programPlan to the just generated programList */
        self.tableViewPrograms = programPlan.currentAndFuturePrograms()
        self.programTableView.reloadData()
>>>>>>> origin/pr/24
        
        self.checkForNewProgramPlan(self.tableViewPrograms)
        self.checkForNextBroadcastNotification(self.tableViewPrograms)
    }
    
    /* check if we have a user notification for the next broadcast */
    func checkForNextBroadcastNotification(newPlan: [Program])
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
                        
                        if program.uid == notification.identifier {
                            found = true
                            break
                        }
                    }
                    
                    if !found {
                        /* get human readable date */
                        let humanReadableStartDate = program.humanReadableStartDate()
                        let humanReadableEndDate = program.humanReadableEndDate()
                        
                        /* calculate delivery date */
                        var deliveryDate = program.startDateFormattable
                        let aheadInterval = NSUserDefaults.standardUserDefaults().doubleForKey("BroadcastAheadInterval")
                        deliveryDate = deliveryDate.dateByAddingTimeInterval(-1 * 60 * aheadInterval)
                        
                        /* send the notification */
                        self.sendLocalNotification(program.title(), text: "\(humanReadableStartDate) - \(humanReadableEndDate)", deliveryDate: deliveryDate, identifier: program.uid)
                    }
                }
            }
        }
    }
    
    /* check for updated program plan and send user notification */
    var lastCount = 0;
    func checkForNewProgramPlan(newPlan: [Program])
    {
        // if the number of entries is different - we have a changed program plan
        // if we have only a single entry and its an error, something went wrong - no notification
        if lastCount != newPlan.count && lastCount != 0 && newPlan.count > 0 {
            if newPlan.count > 1 || newPlan[0].state() != .Error {
                if NSUserDefaults.standardUserDefaults().boolForKey("NotificationOnChanges") {
                    self.sendLocalNotification("Aktualisierung", text: "Der Sendeplan wurde aktualisiert.")
                }
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
<<<<<<< HEAD
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
=======
        self.programPlan = ProgramPlan()
>>>>>>> origin/pr/24
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
        
        self.programPlan.delegate = self;
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
    
    func numberOfRowsInTableView(aTableView: NSTableView!) -> Int
    {
        return self.tableViewPrograms.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn: NSTableColumn, row: Int) -> NSView
    {
        
        let programRow: Program = self.tableViewPrograms[row]
        
        var cell = tableView.makeViewWithIdentifier("programCell", owner: self) as CustomTableView
//        cell.layer?.rasterizationScale = 1.0
//        cell.layer?.backgroundColor = NSColor.clearColor().CGColor
        
//        tableView.backgroundColor = NSColor.clearColor()
        
        /*
        
        if (programRow.current) {
            var rowView = tableView.rowViewAtRow(row, makeIfNecessary: true) as NSTableRowView
            //TODO: strange things happening when background color is changed
            rowView.backgroundColor = NSColor.lightGrayColor()
        }

        */


        
        /* get title without type tag and get icon name */
        if let iconName = programRow.iconName() {
            cell.logoImageView.image = NSImage(named: iconName)
        }
        
        /* Append special state, if the program is currently running */
        var title = programRow.title()
        if (programRow.current) {
            title = "(JETZT) \(title)"
        }
        
        /* Set the final program title */
        cell.titleTextfield?.stringValue = "\(title)"
        
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

