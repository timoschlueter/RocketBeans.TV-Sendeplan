//
//  TodayViewController.swift
//  Today View Widget
//
//  Created by Timo Schlüter on 01.10.16.
//  Copyright © 2016 Timo Schlüter. All rights reserved.
//

import Cocoa
import NotificationCenter

class TodayViewController: NSViewController, NCWidgetProviding, ProgramPlanDelegate {
    
    @IBOutlet var programPlanScheduleItemTitle: NSTextField!
    @IBOutlet var programPlanScheduleItemSubtitle: NSTextField!
    @IBOutlet var programPlanScheduleItemType: NSTextField!
    @IBOutlet var programPlanScheduleItemDate: NSTextField!
    
    var programPlanScheduleItems: Int = 0
    var programPlanSchedule = Dictionary<String,AnyObject>()

    override var nibName: String? {
        return "TodayViewController"
    }
    
    func convertDoHumanDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter.string(from: date)
    }
    
    func convertDate(date: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ" /* ISO 8601 */
        let parsedDate: Date = dateFormatter.date(from: date)!
        return parsedDate
    }

    var lastCompletionHandler: ((NCUpdateResult) -> Void)!
    
    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        
        self.lastCompletionHandler = completionHandler;
        
        /* Empty text do indicate a running refresh */
        programPlanScheduleItemTitle?.stringValue = "Aktualisieren..."
        programPlanScheduleItemType?.stringValue = ""
        programPlanScheduleItemSubtitle?.stringValue = ""
        programPlanScheduleItemDate?.stringValue = ""
        
        let programPlan = ProgramPlan()
        programPlan.delegate = self
        programPlan.refresh();
    }
    
    func didFinishRefresh(_ data: [Dictionary<String,AnyObject>]) {
        self.programPlanScheduleItems = data.count
        self.programPlanSchedule = data[0]
        
        /* Item title */
        let scheduleItemTitle = "\((programPlanSchedule["title"] as! String))"
        
        /*  Item topic */
        var scheduleItemTopic: String
        if (programPlanSchedule["topic"] as! String == "") {
            scheduleItemTopic = ""
        } else {
            scheduleItemTopic = "\((programPlanSchedule["topic"] as! String))"
        }
        
        /* Item type */
        var scheduleItemType: String
        if (programPlanSchedule["type"] as! String == "") {
            scheduleItemType = "WDH"
        } else {
            scheduleItemType = "\((programPlanSchedule["type"] as! String).uppercased())"
        }
        
        /* Item type colors */
        var scheduleItemTypeColor: NSColor
        
        switch ((programPlanSchedule["type"] as! String).uppercased()) {
        case "LIVE":
            scheduleItemTypeColor = NSColor(red:1.00, green:0.13, blue:0.49, alpha:1.0)
            break
        case "PREMIERE":
            scheduleItemTypeColor = NSColor(red:0.09, green:0.58, blue:0.70, alpha:1.0)
            break
        default:
            scheduleItemTypeColor = NSColor.black
            break
        }
        
        /* Item start and end dates */
        let scheduleTimeStart: String = programPlanSchedule["timeStart"] as! String
        let scheduleTimeEnd: String = programPlanSchedule["timeEnd"] as! String
        
        let timeStartParsed: Date = convertDate(date: scheduleTimeStart)
        let timeEndParsed: Date = convertDate(date: scheduleTimeEnd)
        
        programPlanScheduleItemTitle?.stringValue = scheduleItemTitle
        programPlanScheduleItemType?.stringValue = scheduleItemType
        
        programPlanScheduleItemSubtitle?.stringValue = scheduleItemTopic
        
        programPlanScheduleItemType?.textColor = scheduleItemTypeColor
        programPlanScheduleItemDate?.stringValue = "\(convertDoHumanDate(date: timeStartParsed)) Uhr - \(convertDoHumanDate(date: timeEndParsed)) Uhr"
        
        self.lastCompletionHandler(.newData)
    }

}
