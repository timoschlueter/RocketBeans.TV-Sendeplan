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
    var posts = NSMutableArray()
    var elements = NSMutableDictionary()
    var currentElementName = NSString()
    
    var programTitle: String = ""
    var programSummary: String = ""
    var programState: String = ""
    var programDate: String = ""
    
    var programPlan: [ProgramPlan] = []
    
    /* 
    
    ICS Parsing
    
    The main data handling happens here now. This function gets the program from ICS.
    All the logic that chooses which program is visible and which is not should be applied here.
    Formatting such as human readable dates and program title gimmicks should be applied when tableview is drawn
    
    */
    
    let icsUrl: String = "https://www.google.com/calendar/ical/h6tfehdpu3jrbcrn9sdju9ohj8%40group.calendar.google.com/public/basic.ics"
    
    func parseICS() {
        
        var session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithURL(NSURL(string: icsUrl)!) {(data, response, error) in
            
            if (error == nil) {
                
                var dataContent: NSString = NSString(data: data, encoding: NSUTF8StringEncoding)!
                dataContent = dataContent.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                
                let dataLines: NSArray = dataContent.componentsSeparatedByString("\n")
                
                var programList:[ProgramPlan] = []
                
                for var i = 0; i < dataLines.count; i++ {
                    
                    if dataLines[i].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "BEGIN:VEVENT" {
                        var program: ProgramPlan = ProgramPlan()
                        i++
                        var event: [String] = []
                        
                        while (dataLines[i].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "END:VEVENT") {
                            
                            var currentLine = dataLines[i].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                            
                            let splittedLine = currentLine.componentsSeparatedByString(":")
                            
                            var value = ""
                            var attribute = ""
                            
                            if splittedLine.count > 1 {
                                attribute = splittedLine[0]
                                value = splittedLine[1]
                            }
                            
                            switch (attribute) {
                            case "DTSTART":
                                program.programStartDate = value
                            case "DTEND":
                                program.programEndDate = value
                            case "CREATED":
                                program.programCreatedDate = value
                            case "LAST-MODIFIED":
                                program.programLastModifiedDate = value
                            case "SUMMARY":
                                program.programTitle = value
                            default:
                                break
                            }
                            
                            i++
                        }
                        
                        /* Date parsing */
                        var dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
                        var startDate = dateFormatter.dateFromString(program.programStartDate)
                        var endDate = dateFormatter.dateFromString(program.programEndDate)
                        
                        /* Convert ICS date to UTC */
                        startDate = startDate?.dateByAddingTimeInterval(1 * 60 * 60)
                        endDate = endDate?.dateByAddingTimeInterval(1 * 60 * 60)
                        
                        /* Get current date in UTC */
                        let currentDate = NSDate()
                        
                        /* Date related functions */
                        /* From now on, we are comparing only in UTC. Setting local timezone will be done at the last step */
                        /* Check if program is in the future or now */
                        
                        if ((startDate?.compare(currentDate) == NSComparisonResult.OrderedDescending)
                            || (startDate?.compare(currentDate) == NSComparisonResult.OrderedSame))
                            || ((currentDate.compare(startDate!) == NSComparisonResult.OrderedDescending)
                            && (currentDate.compare(endDate!) == NSComparisonResult.OrderedAscending))
                        {
                            /* Check if program is currently running */
                            if (currentDate.compare(startDate!) == NSComparisonResult.OrderedDescending) && (currentDate.compare(endDate!) == NSComparisonResult.OrderedAscending) {
                                program.programCurrent = true
                            } else {
                                program.programCurrent = false
                            }
                            
                            //println(program.programTitle + " - Start: \(startDate!) / Ende: \(endDate!)")
                            
                            program.programStartDateFormattable = startDate!
                            var startEpochDate = startDate?.timeIntervalSince1970
                            program.programStartDateEpoch = startEpochDate!
                            
                            program.programEndDateFormattable = endDate!
                            var endEpochDate = endDate?.timeIntervalSince1970
                            program.programEndDateEpoch = endEpochDate!
                            
                            /* Append program to list */
                            programList.append(program)
                        }
                    }
                }
                
                programList.sort({$0.programStartDateEpoch < $1.programStartDateEpoch})
                
                /* Since NSURLSession is asynchrounous, we have to dispach the data back to the main thread of the app */
                dispatch_async(dispatch_get_main_queue(), {
                    /* Set global programPlan to the just generated programList */
                    self.programPlan = programList
                    /* Sort by date before entering main thread */
                    self.programPlan.sort({$0.programStartDateEpoch < $1.programStartDateEpoch})
                    self.programTableView.reloadData()
                })
                
            } else {
                /* An error occured */
            }
        }
        
        task.resume()
    }
    
    @IBAction func informationButtonPressed(sender: AnyObject) {
        self.informationWindow.makeKeyAndOrderFront(self)
        self.informationWindow.makeMainWindow()
        var application: AnyObject! = NSApp
        application.activateIgnoringOtherApps(true)

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
    
    var statusItem: NSStatusItem
    let statusItemLength: CGFloat = 25.0
    
    override init() {
        let statusBar = NSStatusBar.systemStatusBar()
        self.statusItem = statusBar.statusItemWithLength(-1)
    }
    
    func beginParsing()
    {
        self.programPlan = []
        
        if (!self.isConnectedToNetwork()) {
            /* No connection to the internet */
            let program: ProgramPlan = ProgramPlan()
            program.programTitle = "Keine Verbindung zum Internet!"
            program.programDate = "Sendeplan kann nicht geladen werden."
            program.programState = ""
            programPlan.append(program)
        } else {
            /* We have a signal! Lets go! */
            self.parseICS()
        }

        programTableView.reloadData()
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
        
        self.statusItem.toolTip = "RocketBeans.TV Sendeplan"
        self.statusItem.image = NSImage(named: "StatusIcon")
        self.statusItem.image?.setTemplate(true)
        self.statusItem.highlightMode = true
        self.statusItem.menu = mainMenu
        
        self.programViewCell.view = programView
        self.supportViewCell.view = supportView
        self.programTableView.setDataSource(self)
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("beginParsing"), userInfo: nil, repeats: true)
        
        self.beginParsing()
        
        let bundle:NSBundle = NSBundle.mainBundle()
        let appVersion: String = bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as String
        
        self.appVersionLabel.stringValue = "Version \(appVersion)"
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView!) -> Int
    {
        return self.programPlan.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn: NSTableColumn, row: Int) -> NSView
    {
        
        let programRow: ProgramPlan = self.programPlan[row]
        
        var cell = tableView.makeViewWithIdentifier("programCell", owner: self) as CustomTableView
        
        tableView.backgroundColor = NSColor.clearColor()
        
        /*
        
        if (programRow.programCurrent) {
            var rowView = tableView.rowViewAtRow(row, makeIfNecessary: true) as NSTableRowView
            /* TODO: strange things happening when background color is changed */
            rowView.backgroundColor = NSColor.lightGrayColor()
        }
    
        */
        
        /* Determine the state of the program and set the icon */
        if let range = programRow.programTitle.rangeOfString("[L] ") {
            cell.logoImageView.image = NSImage(named: "LiveIcon")
            programRow.programTitle.removeRange(range)
        } else if let range = programRow.programTitle.rangeOfString("[L]") {
            cell.logoImageView.image = NSImage(named: "LiveIcon")
            programRow.programTitle.removeRange(range)
        } else if let range = programRow.programTitle.rangeOfString("[N] ") {
            cell.logoImageView.image = NSImage(named: "NewIcon")
            programRow.programTitle.removeRange(range)
        } else if let range = programRow.programTitle.rangeOfString("[N]") {
            cell.logoImageView.image = NSImage(named: "NewIcon")
            programRow.programTitle.removeRange(range)
        } else {
            cell.logoImageView.image = NSImage(named: "RerunIcon")
        }
        
        /* Append special state, if the program is currently running */
        if (programRow.programCurrent) {
            var rowView = tableView.rowViewAtRow(row, makeIfNecessary: true) as NSTableRowView
            programRow.programTitle = "(JETZT!) \(programRow.programTitle)"
        }
        
        /* Set the program final title */
        cell.titleTextfield?.stringValue = "\(programRow.programTitle)"
        
        /* Formatting the date end setting timezone to local timezone */
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.doesRelativeDateFormatting = true
        let humanReadableStartDate = dateFormatter.stringFromDate(programRow.programStartDateFormattable)
        let humanReadableEndDate = dateFormatter.stringFromDate(programRow.programEndDateFormattable)
        
        /* Set the date label */
        cell.startTimeTextfield?.stringValue = "\(humanReadableStartDate) - \(humanReadableEndDate)"
        
        return cell;
    }


    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

