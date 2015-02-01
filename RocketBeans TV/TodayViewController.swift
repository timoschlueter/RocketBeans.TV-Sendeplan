//
//  TodayViewController.swift
//  RocketbeansTV
//
//  Created by Mario Schreiner on 31/01/15.
//  Copyright (c) 2015 Timo Schlüter. All rights reserved.
//

import Cocoa
import NotificationCenter
import SystemConfiguration

class TodayViewController: NSViewController, NCWidgetProviding {
    
    @IBOutlet weak var nowTextField: NSTextField!
    @IBOutlet weak var nextTextField: NSTextField!
    
    let refreshInterval: NSTimeInterval = 60
    var programPlan: [ProgramPlan] = []
    
    override var nibName: String? {
        return "TodayViewController"
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        //Let the user know we are updating...
        dispatch_async(dispatch_get_main_queue(), {
            self.nowTextField.stringValue = "Updating...";
            self.nextTextField.stringValue = "";
        });
        
        self.programPlan = [];
        
        if (!self.isConnectedToNetwork()) {
            // No connection to the internet
            // Let the user know we can't fetch new data
            dispatch_async(dispatch_get_main_queue(), {
                self.nowTextField.stringValue = "Keine Internetverbindung";
                self.nextTextField.stringValue = "";
            });
            completionHandler(.NewData);
        } else {
            //Internet connection ready
            //Call the parser and hand it the completion handler. It will call the handler once its done.
            self.parseICS(completionHandler)
        }
    }
    
    func updateUI() {
        var didCurrent = false;
        for (var i=0; i<self.programPlan.count; i++) {
            var program = self.programPlan[i];
            
            if (program.programCurrent) {
                dispatch_sync(dispatch_get_main_queue(), {
                    self.nowTextField.stringValue = "    Jetzt: "+(program.programTitle);
                });
                didCurrent = true;
                continue;
            }
            
            if (didCurrent) {
                //Coming up next...
                dispatch_sync(dispatch_get_main_queue(), {
                    self.nextTextField.stringValue = "Danach: "+(program.programTitle);
                });
                break;
            }
        }
    }
    
    @IBAction func widgetClicked(sender: NSButton) {
        let twitchUrl: NSURL = NSURL(string: "http://www.twitch.tv/rocketbeanstv")!
        NSWorkspace.sharedWorkspace().openURL(twitchUrl)
    }
    
    let icsUrl: String = "https://www.google.com/calendar/ical/h6tfehdpu3jrbcrn9sdju9ohj8%40group.calendar.google.com/public/basic.ics"
    
    func parseICS(completionHandler: ((NCUpdateResult) -> Void)!) {
        
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
                            
                            /*
                            DEBUG: Print all programs with startdate and enddate
                            println(program.programTitle + " - Start: \(startDate!) / Ende: \(endDate!)")
                            */
                            
                            program.programStartDateFormattable = startDate!
                            var startEpochDate = startDate?.timeIntervalSince1970
                            program.programStartDateEpoch = startEpochDate!
                            
                            program.programEndDateFormattable = endDate!
                            var endEpochDate = endDate?.timeIntervalSince1970
                            program.programEndDateEpoch = endEpochDate!
                            
                            /* Append program to list */
                            programList.append(program)
                            
                            /* Check if program is starting in about 10 minutes - send notification if so */
                            if startDate != nil {
                                let diff = startDate!.timeIntervalSinceDate(currentDate)
                                if (diff > 600 - self.refreshInterval && diff <= 600) { // 600 = 10 minutes
                                    
                                    /* get human readable date */
                                    let humanReadableStartDate = program.humanReadableStartDate()
                                    let humanReadableEndDate = program.humanReadableEndDate()
                                    
                                    //                                    let title = self.iconNameFromTitle(program.programTitle)
                                    //                                    self.sendLocalNotification(title.stripedTitle, text: "\(title.stripedTitle): \(humanReadableStartDate) - \(humanReadableEndDate)")
                                }
                            }
                        }
                    }
                }
                
                /* Sort by date before entering main thread */
                programList.sort({$0.programStartDateEpoch < $1.programStartDateEpoch})
                
                //Set the data, update the UI and make sure our Widget is informed that new data arrived
                self.programPlan = programList
                self.updateUI();
                completionHandler(.NewData);
                
            } else {
                /* An error occured */
            }
        }
        
        task.resume()
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
}
