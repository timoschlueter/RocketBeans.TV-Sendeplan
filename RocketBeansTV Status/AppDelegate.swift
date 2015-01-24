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
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSXMLParserDelegate {

    @IBOutlet weak var mainMenu: NSMenu!
    @IBOutlet weak var programViewCell: NSMenuItem!
    @IBOutlet weak var supportViewCell: NSMenuItem!
    @IBOutlet weak var programView: NSView!
    @IBOutlet weak var programTableView: NSTableView!
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
    
    /* Element Start */
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: NSDictionary!)
    {
        currentElementName = elementName
        
        if (elementName == "entry") {
            programTitle = ""
            programSummary = ""
        }
    }
    
    /* Element processed */
    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        
        let data = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if (!data.isEmpty) {
            
            if (currentElementName == "title") {
                programTitle += data
            } else if (currentElementName == "summary") {
                programSummary += data
            }
            
        }
    }
    
    /* Element end */
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!)
    {
        
        if (elementName == "entry") {
            
            /* HTML Character decode */
            programTitle = programTitle.stringByReplacingOccurrencesOfString("&amp;", withString: "&", options: nil, range: nil)
            
        
            if let range = programTitle.rangeOfString("[L] ") {
                programState = "live"
                programTitle.removeRange(range)
            } else if let range = programTitle.rangeOfString("[L]") {
                programState = "live"
                programTitle.removeRange(range)
            } else if let range = programTitle.rangeOfString("[N] ") {
                programState = "new"
                programTitle.removeRange(range)
            } else if let range = programTitle.rangeOfString("[N]") {
                programState = "new"
                programTitle.removeRange(range)
            } else {
                programState = "rerun"
            }
            
            programSummary = programSummary.componentsSeparatedByString("&nbsp;")[0]

            var pattern = "Wann: (.*)"
            var error: NSError? = nil
            var regex = NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions.DotMatchesLineSeparators, error: &error)
            
            var result = regex?.stringByReplacingMatchesInString(programSummary, options: nil, range: NSRange(location:0, length:countElements(programSummary)), withTemplate: "$1")
            
            if (result != nil) {
                programDate = result!
            }
            
            let program: ProgramPlan = ProgramPlan()
            program.programTitle = programTitle
            program.programDate = programDate
            program.programState = programState
            
            var dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "ee'.' dd'.' MMM'.' yyyy kk:mm"
            dateFormatter.locale = NSLocale(localeIdentifier: "de_DE")
            var date = dateFormatter.dateFromString(programDate.componentsSeparatedByString(" bis")[0])
            
            if (date != nil) {
                var timeinterval = date?.timeIntervalSince1970
                program.programEpochDate = timeinterval!
            }
            
            /* Check if program is in the future (or two hours ago) */
            let currentDate = NSDate()
            let currentEpochDate = currentDate.timeIntervalSince1970
            
            if ((currentEpochDate - 7200) < program.programEpochDate) {
                programPlan.append(program)
            }
            
            /* Sort the programs */
            programPlan.sort({$0.programEpochDate < $1.programEpochDate})
            
        }
        
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
            let program: ProgramPlan = ProgramPlan()
            program.programTitle = "Keine Verbindung zum Internet!"
            program.programDate = "Programm kann nicht geladen werden."
            program.programState = ""
            programPlan.append(program)
        } else {
            parser = NSXMLParser(contentsOfURL: (NSURL(string: "https://www.google.com/calendar/feeds/h6tfehdpu3jrbcrn9sdju9ohj8%40group.calendar.google.com/public/basic?hl=de")))!
            parser.delegate = self
            parser.parse()
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
        
        // Insert code here to initialize your application
        self.statusItem.toolTip = "Tooltip"
        self.statusItem.image = NSImage(named: "StatusIcon")
        self.statusItem.image?.setTemplate(true)
        self.statusItem.highlightMode = true
        self.statusItem.menu = mainMenu
        
        self.programViewCell.view = programView
        self.supportViewCell.view = supportView
        self.programTableView.setDataSource(self)
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("beginParsing"), userInfo: nil, repeats: true)
        
        self.beginParsing()
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView!) -> Int
    {
        return self.programPlan.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn: NSTableColumn, row: Int) -> NSView
    {
        
        let programPlan: ProgramPlan = self.programPlan[row]
        var cell = tableView.makeViewWithIdentifier("programCell", owner: self) as CustomTableView
        tableView.backgroundColor = NSColor.clearColor()
        
        cell.titleTextfield?.stringValue = "\(programPlan.programTitle)"
        cell.startTimeTextfield?.stringValue = "\(programPlan.programDate)"
        
        switch (programPlan.programState) {
            case "live":
                cell.logoImageView.image = NSImage(named: "live.png")
            case "new":
                cell.logoImageView.image = NSImage(named: "new.png")
            case "rerun":
                cell.logoImageView.image = NSImage(named: "rerun.png")
            default:
                cell.logoImageView.image = NSImage(named: "transparent.png")
        }
                
        return cell;
    }


    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

