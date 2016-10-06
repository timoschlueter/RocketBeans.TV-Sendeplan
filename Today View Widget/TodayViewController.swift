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
    
    @IBOutlet var programPlanNextScheduleItemTitle: NSTextField!
    @IBOutlet var programPlanNextScheduleItemSubtitle: NSTextField!
    @IBOutlet var programPlanNextScheduleItemDate: NSTextField!
    @IBOutlet var programPlanNextScheduleItemType: NSTextField!
    
    var programPlanSchedule = Dictionary<String,AnyObject>()
    var programPlanNextSchedule = Dictionary<String,AnyObject>()
    
    let programPlan = ProgramPlan()

    override var nibName: String? {
        return "TodayViewController"
    }

    var lastCompletionHandler: ((NCUpdateResult) -> Void)!
    
    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        
        self.lastCompletionHandler = completionHandler;
        
        /* Empty text do indicate a running refresh */
        programPlanScheduleItemTitle?.stringValue = "Aktualisieren..."
        programPlanScheduleItemType?.stringValue = ""
        programPlanScheduleItemSubtitle?.stringValue = ""
        programPlanScheduleItemDate?.stringValue = ""
        
        programPlanNextScheduleItemTitle?.stringValue = ""
        programPlanNextScheduleItemSubtitle?.stringValue = ""
        programPlanNextScheduleItemType?.stringValue = ""
        programPlanNextScheduleItemDate?.stringValue = ""
        
        programPlan.delegate = self
        programPlan.refresh();
    }
    
    func didFinishRefresh(_ data: [Dictionary<String,AnyObject>]) {
        
        self.programPlanSchedule = data[0]
        self.programPlanNextSchedule = data[1]
        
        /* Item titles */
        let scheduleItemTitle = "\((programPlanSchedule["title"] as! String))"
        let nextScheduleItemTitle = "\((programPlanNextSchedule["title"] as! String))"
        
        /*  Item topics */
        var scheduleItemTopic: String
        var nextScheduleItemTopic: String
        
        /* Current */
        if (programPlanSchedule["topic"] as! String == "") {
            scheduleItemTopic = ""
        } else {
            scheduleItemTopic = "\((programPlanSchedule["topic"] as! String))"
        }
        /* Next */
        if (programPlanNextSchedule["topic"] as! String == "") {
            nextScheduleItemTopic = ""
        } else {
            nextScheduleItemTopic = "\((programPlanNextSchedule["topic"] as! String))"
        }
        
        /* Item types */
        var scheduleItemType: String
        var nextScheduleItemType: String
        
        /* Current */
        if (programPlanSchedule["type"] as! String == "") {
            scheduleItemType = "WDH"
        } else {
            scheduleItemType = "\((programPlanSchedule["type"] as! String).uppercased())"
        }
        
        /* Next */
        if (programPlanNextSchedule["type"] as! String == "") {
            nextScheduleItemType = "WDH"
        } else {
            nextScheduleItemType = "\((programPlanNextSchedule["type"] as! String).uppercased())"
        }
        
        /* Item type colors */
        var scheduleItemTypeColor: NSColor
        var nextScheduleItemTypeColor: NSColor
        
        /* Current */
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
        
        /* Next */
        switch ((programPlanNextSchedule["type"] as! String).uppercased()) {
        case "LIVE":
            nextScheduleItemTypeColor = NSColor(red:1.00, green:0.13, blue:0.49, alpha:1.0)
            break
        case "PREMIERE":
            nextScheduleItemTypeColor = NSColor(red:0.09, green:0.58, blue:0.70, alpha:1.0)
            break
        default:
            nextScheduleItemTypeColor = NSColor.black
            break
        }
        
        /* Item start and end dates */
        let scheduleTimeStart: String = programPlanSchedule["timeStart"] as! String
        let scheduleTimeEnd: String = programPlanSchedule["timeEnd"] as! String
        let nextScheduleTimeStart: String = programPlanNextSchedule["timeStart"] as! String
        let nextScheduleTimeEnd: String = programPlanNextSchedule["timeEnd"] as! String
        
        let timeStartParsed: Date = programPlan.convertDate(date: scheduleTimeStart)
        let timeEndParsed: Date = programPlan.convertDate(date: scheduleTimeEnd)
        let nextTimeStartParsed: Date = programPlan.convertDate(date: nextScheduleTimeStart)
        let nextTimeEndParsed: Date = programPlan.convertDate(date: nextScheduleTimeEnd)
        
        /* Current */
        programPlanScheduleItemTitle?.stringValue = scheduleItemTitle
        programPlanScheduleItemType?.stringValue = scheduleItemType
        programPlanScheduleItemType?.textColor = scheduleItemTypeColor
        programPlanScheduleItemSubtitle?.stringValue = scheduleItemTopic
        programPlanScheduleItemDate?.stringValue = "\(programPlan.convertDoHumanDate(date: timeStartParsed)) Uhr - \(programPlan.convertDoHumanDate(date: timeEndParsed)) Uhr"
        
        /* Next */
        programPlanNextScheduleItemTitle?.stringValue = nextScheduleItemTitle
        programPlanNextScheduleItemType?.stringValue = nextScheduleItemType
        programPlanNextScheduleItemType?.textColor = nextScheduleItemTypeColor
        programPlanNextScheduleItemSubtitle?.stringValue = nextScheduleItemTopic
        programPlanNextScheduleItemDate?.stringValue = "\(programPlan.convertDoHumanDate(date: nextTimeStartParsed)) Uhr - \(programPlan.convertDoHumanDate(date: nextTimeEndParsed)) Uhr"
        
        self.lastCompletionHandler(.newData)
    }

}
