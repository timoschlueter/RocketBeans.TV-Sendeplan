//
//  AppDelegate.swift
//  Sendeplan fuer Rocket Beans TV
//
//  Created by Timo Schlüter on 29.04.16.
//  Copyright © 2016 Timo Schlüter. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, ProgramPlanDelegate, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var programPlanMenu: ProgramPlanMenu!
    @IBOutlet weak var programPlanMenuItem: NSMenuItem!
    
    var statusItem: NSStatusItem = NSStatusItem()
    var programPlanScheduleItems: Int = 0
    var programPlanSchedule = [Dictionary<String,AnyObject>]()
    
    @IBOutlet weak var informationWindow: InformationWindow!
    
    @IBOutlet weak var programPlanScrollView: NSScrollView!    
    @IBOutlet weak var programPlanTableView: NSTableView!
    
    override init() {
        /* print("Launched") */
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let statusBar = NSStatusBar.system()
        self.statusItem = statusBar.statusItem(withLength: 25.0)
        self.statusItem.toolTip = "Sendeplan für Rocket Beans TV"
        self.statusItem.image = NSImage(named: "StatusIcon")
        self.statusItem.image?.isTemplate = true
        self.statusItem.highlightMode = true
        self.statusItem.menu = programPlanMenu
        
        let programPlan = ProgramPlan()
        programPlan.delegate = self
        programPlan.startTimer(60.0)
        programPlan.refresh();
        
        self.programPlanMenuItem.view = programPlanScrollView
        self.programPlanTableView.dataSource = self
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func didFinishRefresh(_ data: [Dictionary<String,AnyObject>]) {
        self.programPlanScheduleItems = data.count
        self.programPlanSchedule = data
        self.programPlanTableView.reloadData()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return programPlanScheduleItems
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if ((self.programPlanSchedule[row]["topic"] as! String) == "") {
            return 44.0
        } else {
            return 61.0
        }
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        /* Nothing for now */
    }
    
    func convertDate(date: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ" /* ISO 8601 */
        let parsedDate: Date = dateFormatter.date(from: date)!
        return parsedDate
    }
    
    func convertDoHumanDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter.string(from: date)
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
            
            let timeStartParsed: Date = convertDate(date: scheduleTimeStart)
            let timeEndParsed: Date = convertDate(date: scheduleTimeEnd)

            
            if ((self.programPlanSchedule[row]["topic"] as! String) == "") {
                
                let cell: ProgramPlanTableViewCellSimple = tableView.make(withIdentifier: "ProgramPlanTableViewCellSimple", owner: self) as! ProgramPlanTableViewCellSimple
                
                cell.programPlanScheduleItemTitle?.stringValue = scheduleItemTitle
                cell.programPlanScheduleItemType?.stringValue = scheduleItemType
                cell.programPlanScheduleItemType?.textColor = scheduleItemTypeColor
                cell.programPlanScheduleItemDate?.stringValue = "\(convertDoHumanDate(date: timeStartParsed)) Uhr - \(convertDoHumanDate(date: timeEndParsed)) Uhr"
                
                return cell
                
            } else {
                let cell: ProgramPlanTableViewCell = tableView.make(withIdentifier: "ProgramPlanTableViewCell", owner: self) as! ProgramPlanTableViewCell
                
                cell.programPlanScheduleItemTitle?.stringValue = scheduleItemTitle
                cell.programPlanScheduleItemType?.stringValue = scheduleItemType
                cell.programPlanScheduleItemType?.textColor = scheduleItemTypeColor
                cell.programPlanScheduleItemType?.backgroundColor = NSColor.clear
                cell.programPlanScheduleItemSubtitle?.stringValue = "\((self.programPlanSchedule[row]["topic"] as! String))"
                cell.programPlanScheduleItemDate?.stringValue = "\(convertDoHumanDate(date: timeStartParsed)) Uhr - \(convertDoHumanDate(date: timeEndParsed)) Uhr"
                return cell
            }
        }
        
        return nil
    }
    
}

