//
//  ProgramPlan.swift
//  RocketBeans.TV Sendeplan
//
//  Created by Mario Schreiner on 02/02/15.
//  Copyright (c) 2015 Timo Schlüter. All rights reserved.
//

import Foundation
import SystemConfiguration

<<<<<<< HEAD
class ProgramPlan {
    var programTitle: String = ""
    var programDate: String = ""
    var programEpochDate: Double = 0.0
    var programState: String = ""
    var programCurrent: Bool = false
    
    /* New variables for ics parsing */
    var programStartDate: String = ""
    var programStartDateFormattable: NSDate = NSDate()
    var programStartDateEpoch: Double = 0.0
    var programEndDate: String = ""
    var programEndDateFormattable: NSDate = NSDate()
    var programEndDateEpoch: Double = 0.0
    var programUid: String = ""
=======
>>>>>>> origin/pr/24

protocol ProgramPlanDelegate {
    func programPlanDidRefresh(programPlan: ProgramPlan);
}

class ProgramPlan {    
    var delegate: ProgramPlanDelegate?
    var programs: [Program] = []
    
    /*
    
    Google Calender API Key.
    Go to your Google Developer Console ( https://console.developers.google.com/project ) and create a new Project with an iOS Specific API key.
    Set the Bundle Identifier to "in.timo.ios.RocketBeans-TV-Sendeplan" and insert the generated API key below.
    
    */
    
    var googleApiKey = ""
    
    init() {
        
    }
    
    func currentAndFuturePrograms() -> [Program] {
        return self.programs.filter{(program) -> (Bool) in
            return program.current || program.future;
        }
    }
    
    func beginRefresh() {
        if (!self.isConnectedToNetwork()) {
            /* No connection to the internet */
            let program: Program = Program()
            program.rawTitle = "[E] Keine Verbindung zum Internet!" //[E] indicates an error
            program.date = "Sendeplan kann nicht geladen werden."
            
            self.delegate?.programPlanDidRefresh(self)
        } else {
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

                var programList:[Program] = []
                
                if let programCalendar = programData as? NSDictionary {
                    
                    if let programItems = programCalendar["items"] as? NSArray {
                        
                        for singleProgramItem in programItems {
                            var program: Program = Program()
                
                            if let singleProgramItemAttributes = singleProgramItem as? NSDictionary {
                                
                                if let startDateObject = singleProgramItemAttributes["start"] as? NSDictionary {
                                    var startDateString = startDateObject["dateTime"] as String
                                    var startDate = dateFormatter.dateFromString(startDateString)!
                                    program.startDateFormattable = startDate
                                    var startEpochDate = startDate.timeIntervalSince1970
                                    program.startDateEpoch = startEpochDate
                                    
                                }
                                
                                if let endDateObject = singleProgramItemAttributes["end"] as? NSDictionary {
                                    var endDateString = endDateObject["dateTime"] as String
                                    var endDate = dateFormatter.dateFromString(endDateString)
                                    program.endDateFormattable = endDate!
                                    var endEpochDate = endDate?.timeIntervalSince1970
                                    program.endDateEpoch = endEpochDate!
                                }
                                
                                program.rawTitle = singleProgramItemAttributes["summary"] as String
                                program.uid = singleProgramItemAttributes["iCalUID"] as String
                                
                                programList.append(program)
                                
                                /* Get current date in UTC */
                                var currentDate = NSDate()
                                
                                var comparingStartDate = program.startDateFormattable
                                var comparingEndDate = program.endDateFormattable
                                
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
                                        program.current = true
                                        program.future = false
                                    } else {
                                        program.current = false
                                        program.future = true
                                    }
                                }
                                
                                /* Sort by date before entering main thread */
                                programList.sort({$0.startDateEpoch < $1.startDateEpoch})
                                
                                self.programs = programList;
                                
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.delegate?.programPlanDidRefresh(self)
                                    return
                                })
                            }
                        }
                    }
                }
                
            };
            
            task.resume()
        }
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