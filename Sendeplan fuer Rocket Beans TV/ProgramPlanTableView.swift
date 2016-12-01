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
    var enabledNotifications: [Dictionary<String,AnyObject>] = []
    
    let programPlan = ProgramPlan()
    
    func didFinishRefresh(_ data: [Dictionary<String,AnyObject>]) {
        
        self.programPlanScheduleItems = data.count
        self.programPlanSchedule = data
        
        let appDelegate:AppDelegate = NSApplication.shared().delegate as! AppDelegate
        let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        enabledNotifications = UserDefaults.standard.value(forKey: "enabledNotifications") as! [Dictionary<String, AnyObject>]
        
        /* Go through all saved notifications */
        for (index, enabledNotification) in enabledNotifications.enumerated() {
            let foundElementIndex = self.programPlanSchedule.index(where: {$0["id"] as! Int == enabledNotification["id"] as! Int})
            /* Clean up notifications that are no longer possible to trigger */
            if (foundElementIndex == nil) {
                enabledNotifications.remove(at: index)
            } else {
                let scheduleTimeStart: String = enabledNotification["timeStart"] as! String
                let timeStartParsed: Date = programPlan.convertDate(date: scheduleTimeStart)
                
                /* Check if a notification is due */
                if programPlan.notificationIsDue(startDate: timeStartParsed) {
                    
                    /* Send notification */
                    let notification = NSUserNotification()
                    
                    if (enabledNotification["topic"] as! String == "") {
                        notification.title = enabledNotification["title"] as? String
                    } else {
                        notification.title = "\(enabledNotification["title"] as! String) - \(enabledNotification["topic"] as! String)"
                    }
                    
                    notification.informativeText = "Beginnt \(programPlan.convertDoHumanDate(date: timeStartParsed)) Uhr"
                    
                    if (UserDefaults.standard.string(forKey: "notificationSound") == nil) {
                        notification.soundName = NSUserNotificationDefaultSoundName
                    } else {
                        notification.soundName = nil
                        
                        switch UserDefaults.standard.integer(forKey: "notificationSound") {
                        case 0:
                            notification.soundName = NSUserNotificationDefaultSoundName
                        case 1:
                            let notificationSound = NSSound(named: "NotificationNicenstein")
                            notificationSound?.play()
                        case 2:
                            let notificationSound = NSSound(named: "NotificationMaximaleRealitaet")
                            notificationSound?.play()
                        case 3:
                            let notificationSound = NSSound(named: "NotificationKappa")
                            notificationSound?.play()
                        default:
                            notification.soundName = NSUserNotificationDefaultSoundName
                        }
                    }
                    
                    NSUserNotificationCenter.default.deliver(notification)
                    
                    /* Since we did send the notification, we can remove it from the saved ones */
                    enabledNotifications.remove(at: index)
                }
            }
        }
        
        UserDefaults.standard.setValue(enabledNotifications, forKey: "enabledNotifications")
        
        if (UserDefaults.standard.value(forKey: "coloredIcon") == nil) {
            appDelegate.statusItem.image = NSImage(named: "StatusIcon")
        } else {
            if UserDefaults.standard.value(forKey: "coloredIcon") as! Int == 0 {
                appDelegate.statusItem.image = NSImage(named: "StatusIcon")
            } else {
                switch ((self.programPlanSchedule[0]["type"] as! String).uppercased()) {
                case "LIVE":
                    /* Set special Live-Icon for Dark Mode */
                    if (appearance == "Dark") {
                        appDelegate.statusItem.image = NSImage(named: "StatusItemLIVE-Dark")
                    } else {
                        appDelegate.statusItem.image = NSImage(named: "StatusItemLIVE-Light")
                    }
                    break
                case "PREMIERE":
                    /* Set special Premiere-Icon for Dark Mode */
                    if (appearance == "Dark") {
                        appDelegate.statusItem.image = NSImage(named: "StatusItemNEU-Dark")
                    } else {
                        appDelegate.statusItem.image = NSImage(named: "StatusItemNEU-Light")
                    }
                    break
                default:
                    appDelegate.statusItem.image = NSImage(named: "StatusIcon")
                    break
                }
            }
        }
        
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
                scheduleItemTypeColor = NSColor.labelColor
                break
            }
            
            /* Item start and end dates */
            let scheduleTimeStart: String = self.programPlanSchedule[row]["timeStart"] as! String
            let scheduleTimeEnd: String = self.programPlanSchedule[row]["timeEnd"] as! String
            
            let timeStartParsed: Date = programPlan.convertDate(date: scheduleTimeStart)
            let timeEndParsed: Date = programPlan.convertDate(date: scheduleTimeEnd)
            
            
            if ((self.programPlanSchedule[row]["topic"] as! String) == "") {
                let cell: ProgramPlanTableViewCellSimple = tableView.make(withIdentifier: "ProgramPlanTableViewCellSimple", owner: self) as! ProgramPlanTableViewCellSimple
                
                /* Pass the item id to the row in order to manage notifications */
                cell.currentItem = self.programPlanSchedule[row]
                
                cell.programPlanScheduleItemTitle?.stringValue = scheduleItemTitle
                cell.programPlanScheduleItemType?.stringValue = scheduleItemType
                cell.programPlanScheduleItemType?.textColor = scheduleItemTypeColor
                cell.programPlanScheduleItemDate?.stringValue = "\(programPlan.convertDoHumanDate(date: timeStartParsed)) Uhr - \(programPlan.convertDoHumanDate(date: timeEndParsed)) Uhr"

                
                /* Show progress indicator for currently running show */
                if (row == 0) {
                    cell.programPlanScheduleItemProgress?.doubleValue = programPlan.calculateProgress(startDate: timeStartParsed, endDate: timeEndParsed)
                    cell.programPlanScheduleItemProgress?.isHidden = false
                    cell.programPlanScheduleItemNotificationToggle?.isHidden = true
                } else {
                    cell.programPlanScheduleItemProgress?.isHidden = true
                    cell.programPlanScheduleItemNotificationToggle?.isHidden = false
                }
                
                /* Set the notification toggle to active if notifications are enabled */
                if enabledNotifications.contains(where: {$0["id"] as! Int == self.programPlanSchedule[row]["id"] as! Int}) {
                    cell.programPlanScheduleItemNotificationToggle.state = 1
                } else {
                    cell.programPlanScheduleItemNotificationToggle.state = 0
                }
                
                return cell
                
            } else {
                let cell: ProgramPlanTableViewCell = tableView.make(withIdentifier: "ProgramPlanTableViewCell", owner: self) as! ProgramPlanTableViewCell
                
                /* Pass the item id to the row in order to manage notifications */
                cell.currentItem = self.programPlanSchedule[row]
                
                cell.programPlanScheduleItemTitle?.stringValue = scheduleItemTitle
                cell.programPlanScheduleItemType?.stringValue = scheduleItemType
                cell.programPlanScheduleItemType?.textColor = scheduleItemTypeColor
                cell.programPlanScheduleItemType?.backgroundColor = NSColor.clear
                cell.programPlanScheduleItemSubtitle?.stringValue = "\((self.programPlanSchedule[row]["topic"] as! String))"
                cell.programPlanScheduleItemDate?.stringValue = "\(programPlan.convertDoHumanDate(date: timeStartParsed)) Uhr - \(programPlan.convertDoHumanDate(date: timeEndParsed)) Uhr"
                
                
                /* Show progress indicator for currently running show */
                if (row == 0) {
                    cell.programPlanScheduleItemProgress?.doubleValue = programPlan.calculateProgress(startDate: timeStartParsed, endDate: timeEndParsed)
                    cell.programPlanScheduleItemProgress?.isHidden = false
                    cell.programPlanScheduleItemNotificationToggle?.isHidden = true
                } else {
                    cell.programPlanScheduleItemProgress?.isHidden = true
                    cell.programPlanScheduleItemNotificationToggle?.isHidden = false
                }
                
                /* Set the notification toggle to active if notifications are enabled */
                if enabledNotifications.contains(where: {$0["id"] as! Int == self.programPlanSchedule[row]["id"] as! Int}) {
                    cell.programPlanScheduleItemNotificationToggle.state = 1
                } else {
                    cell.programPlanScheduleItemNotificationToggle.state = 0
                }
                
                return cell
            }
        }
        
        return nil
    }
}
