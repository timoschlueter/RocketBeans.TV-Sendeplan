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
        
        /* Set statusbar icon if current show is live */
        if NSUserDefaults.standardUserDefaults().boolForKey("ColoredLiveStatusbarIcon") {
            if self.tableViewPrograms.first?.iconName() == "LiveIcon" {
                statusItem.image = NSImage(named: "StatusLiveIcon")
            }
            else {
                statusItem.image = NSImage(named: "StatusIcon")
            }
        }
        
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
                        
                        let notification = n as! NSUserNotification
                        
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
        NSApp.activateIgnoringOtherApps(true)
        self.informationWindow.center()
        self.informationWindow.makeKeyAndOrderFront(self)
        
    }
    
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        if self.settingsWC == nil {
            self.settingsWC = SettingsWindowController(windowNibName: "SettingsWindowController")
        }
        
        NSApp.activateIgnoringOtherApps(true);
        self.settingsWC?.window?.center()
        self.settingsWC?.showWindow(self)
        self.settingsWC?.window?.makeKeyAndOrderFront(self)
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
        self.programPlan = ProgramPlan()
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
            "ColoredLiveStatusbarIcon" : true,// enable colored statusbar icon for live shows
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
        let appVersion: String = bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        
        self.appVersionLabel.stringValue = "Version \(appVersion)"
        
        self.checkForAppUpdate(appVersion)
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
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int
    {
        return self.tableViewPrograms.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        
        let programRow: Program = self.tableViewPrograms[row]
        
        var cell = tableView.makeViewWithIdentifier("programCell", owner: self) as! CustomTableView
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
    
    func checkForAppUpdate(appVersion: String) {
        let url = NSURL(string: "http://api.rbtvosx.cvdev.de")
        let session = NSURLSession.sharedSession()
        let dataTask = session.dataTaskWithURL(url!, completionHandler: {(data, response, error) in
            
            if error != nil {
                // If there is an error in the web request, print it to the console
                println(error.localizedDescription)
            }
            
            var err: NSError?
            var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as! NSDictionary
            if err != nil {
                // If there is an error parsing JSON, print it to the console
                println("JSON Error \(err!.localizedDescription)")
            }
            
            let newVersion: String = String(stringInterpolationSegment: jsonResult["version"])
            let link: String = String(stringInterpolationSegment: jsonResult["link"])
            
            if appVersion != newVersion {
                println("Update verfügbar!")
                println("Das Update steht unter \(link) zur verfügung!")
                
                //funzt nicht - why?
                self.sendLocalNotification("Update verfügbar!", text: "Das Update steht unter \(link) zur verfügung!")
            }
            
        })
        
        dataTask.resume()
    }
}