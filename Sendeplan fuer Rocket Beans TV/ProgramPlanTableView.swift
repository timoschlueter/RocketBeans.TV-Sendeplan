//
//  ProgramPlanTableView.swift
//  Sendeplan für Rocket Beans TV
//
//  Created by Timo Schlüter on 02.10.16.
//  Copyright © 2016 Timo Schlüter. All rights reserved.
//

import Foundation
import AppKit

class ProgramPlanTableView: NSTableView, ProgramPlanDelegate, NSTableViewDataSource, NSTableViewDelegate {
    
    var programPlanScheduleItems: Int = 0
    var programPlanSchedule = [Dictionary<String,AnyObject>]()
    
    let programPlan = ProgramPlan()
        
    func didFinishRefresh(_ data: [Dictionary<String,AnyObject>]) {
        self.programPlanScheduleItems = data.count
        self.programPlanSchedule = data
        
        self.reloadData()
    }
        
    func numberOfRows(in tableView: NSTableView) -> Int {
        return programPlanScheduleItems
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if ((self.programPlanSchedule[row]["topic"] as! String) == "") {
            return 55.0
        } else {
            return 75.0
        }
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        /* Nothing for now */
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier: String = (tableColumn?.identifier)!
        
        if (identifier == "ProgramPlanTableViewColumn") {
            
            /* Item title */
            let scheduleItemTitle = "\((self.programPlanSchedule[row]["title"] as! String))"
            
            /* Item type */
            var scheduleItemType: String
            if (self.programPlanSchedule[row]["type"] as! String == "") {
                scheduleItemType = "WDH"
            } else {
                scheduleItemType = "\((self.programPlanSchedule[row]["type"] as! String).uppercased())"
            }
            
            /* Item type colors */
            var scheduleItemTypeColor: NSColor
            
            switch ((self.programPlanSchedule[row]["type"] as! String).uppercased()) {
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
            let scheduleTimeStart: String = self.programPlanSchedule[row]["timeStart"] as! String
            let scheduleTimeEnd: String = self.programPlanSchedule[row]["timeEnd"] as! String
            
            let timeStartParsed: Date = programPlan.convertDate(date: scheduleTimeStart)
            let timeEndParsed: Date = programPlan.convertDate(date: scheduleTimeEnd)
            
            
            if ((self.programPlanSchedule[row]["topic"] as! String) == "") {
                
                let cell: ProgramPlanTableViewCellSimple = tableView.make(withIdentifier: "ProgramPlanTableViewCellSimple", owner: self) as! ProgramPlanTableViewCellSimple
                
                cell.programPlanScheduleItemTitle?.stringValue = scheduleItemTitle
                cell.programPlanScheduleItemType?.stringValue = scheduleItemType
                cell.programPlanScheduleItemType?.textColor = scheduleItemTypeColor
                cell.programPlanScheduleItemDate?.stringValue = "\(programPlan.convertDoHumanDate(date: timeStartParsed)) Uhr - \(programPlan.convertDoHumanDate(date: timeEndParsed)) Uhr"
                
                return cell
                
            } else {
                let cell: ProgramPlanTableViewCell = tableView.make(withIdentifier: "ProgramPlanTableViewCell", owner: self) as! ProgramPlanTableViewCell
                
                cell.programPlanScheduleItemTitle?.stringValue = scheduleItemTitle
                cell.programPlanScheduleItemType?.stringValue = scheduleItemType
                cell.programPlanScheduleItemType?.textColor = scheduleItemTypeColor
                cell.programPlanScheduleItemType?.backgroundColor = NSColor.clear
                cell.programPlanScheduleItemSubtitle?.stringValue = "\((self.programPlanSchedule[row]["topic"] as! String))"
                cell.programPlanScheduleItemDate?.stringValue = "\(programPlan.convertDoHumanDate(date: timeStartParsed)) Uhr - \(programPlan.convertDoHumanDate(date: timeEndParsed)) Uhr"
                return cell
            }
        }
        
        return nil
    }
}
