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
    @IBOutlet var progremPlanScheduleItemProgress: NSProgressIndicator!
    
    @IBOutlet var programPlanNextScheduleItemTitle: NSTextField!
    @IBOutlet var programPlanNextScheduleItemSubtitle: NSTextField!
    @IBOutlet var programPlanNextScheduleItemDate: NSTextField!
    @IBOutlet var programPlanNextScheduleItemType: NSTextField!
    
    var programPlanSchedule: Program!
    var programPlanNextSchedule: Program!
    
    let programPlan = ProgramPlan()
    
    override var nibName: NSNib.Name? {
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
        progremPlanScheduleItemProgress?.isHidden = true
        
        programPlanNextScheduleItemTitle?.stringValue = ""
        programPlanNextScheduleItemSubtitle?.stringValue = ""
        programPlanNextScheduleItemType?.stringValue = ""
        programPlanNextScheduleItemDate?.stringValue = ""
        
        programPlan.delegate = self
        programPlan.refresh();
    }
    
    func didFinishRefresh(_ data: [Program]) {
        
        self.programPlanSchedule = data[0]
        self.programPlanNextSchedule = data[1]
        
        /* Item titles */
        let scheduleItemTitle = programPlanSchedule.title
        let nextScheduleItemTitle = programPlanNextSchedule.title
        
        /*  Item topics */
        var scheduleItemTopic: String
        var nextScheduleItemTopic: String
        
        /* Current */
        if (programPlanSchedule.topic == "") {
            scheduleItemTopic = ""
        } else {
            scheduleItemTopic = programPlanSchedule.topic
        }
        /* Next */
        if (programPlanNextSchedule.topic == "") {
            nextScheduleItemTopic = ""
        } else {
            nextScheduleItemTopic = programPlanNextSchedule.topic
        }
        
        /* Item types */
        var scheduleItemType: String
        var nextScheduleItemType: String
        
        /* Current */
        if (programPlanSchedule.type == "") {
            scheduleItemType = "WDH"
        } else {
            scheduleItemType = programPlanSchedule.type.uppercased()
        }
        
        /* Next */
        if (programPlanNextSchedule.type == "") {
            nextScheduleItemType = "WDH"
        } else {
            nextScheduleItemType = programPlanNextSchedule.type.uppercased()
        }
        
        /* Item type colors */
        var scheduleItemTypeColor: NSColor
        var nextScheduleItemTypeColor: NSColor
        
        /* Current */
        switch (programPlanSchedule.type.uppercased()) {
        case "LIVE":
            scheduleItemTypeColor = NSColor(red:0.99, green:0.08, blue:0.13, alpha:1.0)
            break
        case "PREMIERE":
            scheduleItemTypeColor = NSColor(red:0.15, green:0.44, blue:0.61, alpha:1.0)
            break
        default:
            scheduleItemTypeColor = NSColor.labelColor
            break
        }
        
        /* Next */
        switch (programPlanNextSchedule.type.uppercased()) {
        case "LIVE":
            nextScheduleItemTypeColor = NSColor(red:0.99, green:0.08, blue:0.13, alpha:1.0)
            break
        case "PREMIERE":
            nextScheduleItemTypeColor = NSColor(red:0.15, green:0.44, blue:0.61, alpha:1.0)
            break
        default:
            nextScheduleItemTypeColor = NSColor.labelColor
            break
        }
        
        /* Current */
        programPlanScheduleItemTitle?.stringValue = scheduleItemTitle
        programPlanScheduleItemType?.stringValue = scheduleItemType
        programPlanScheduleItemType?.textColor = scheduleItemTypeColor
        programPlanScheduleItemSubtitle?.stringValue = scheduleItemTopic
        programPlanScheduleItemDate?.stringValue = "\(programPlan.convertDoHumanDate(date: programPlanSchedule.timeStart)) Uhr - \(programPlan.convertDoHumanDate(date: programPlanSchedule.timeEnd)) Uhr"
        
        /* Progress indicator */
        progremPlanScheduleItemProgress?.doubleValue = programPlan.calculateProgress(startDate: programPlanSchedule.timeStart, endDate: programPlanSchedule.timeEnd)
        progremPlanScheduleItemProgress?.isHidden = false
        
        /* Next */
        programPlanNextScheduleItemTitle?.stringValue = nextScheduleItemTitle
        programPlanNextScheduleItemType?.stringValue = nextScheduleItemType
        programPlanNextScheduleItemType?.textColor = nextScheduleItemTypeColor
        programPlanNextScheduleItemSubtitle?.stringValue = nextScheduleItemTopic
        programPlanNextScheduleItemDate?.stringValue = "\(programPlan.convertDoHumanDate(date: programPlanNextSchedule.timeStart)) Uhr - \(programPlan.convertDoHumanDate(date: programPlanNextSchedule.timeEnd)) Uhr"
        
        self.lastCompletionHandler(.newData)
    }

}
