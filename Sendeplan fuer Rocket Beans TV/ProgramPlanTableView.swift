//
//  ProgramPlanTableView.swift
//  Sendeplan für Rocket Beans TV
//
//  Created by Timo Schlüter on 02.10.16.
//  Copyright © 2018 Timo Schlüter. All rights reserved.
//

import Foundation
import AppKit

class ProgramPlanTableView: NSTableView, ProgramPlanDelegate, NSTableViewDataSource, NSTableViewDelegate {
    
    var programPlanScheduleItems: Int = 0
    var programPlanSchedule: [Program]!
    var enabledNotifications =  [Program]()
    
    let programPlan = ProgramPlan()
    
    func didFinishRefresh(_ data: [Program]) {
        
        self.programPlanScheduleItems = data.count
        self.programPlanSchedule = data
        
        let appDelegate:AppDelegate = NSApplication.shared.delegate as! AppDelegate
        let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
                
        if let data = UserDefaults.standard.value(forKey:"enabledNotifications") as? Data {
            enabledNotifications = try! PropertyListDecoder().decode([Program].self, from: data)
        }
        
        /* Go through all saved notifications */
        for (index, enabledNotification) in enabledNotifications.enumerated() {
            let foundElementIndex = self.programPlanSchedule.firstIndex(where: {$0.id == enabledNotification.id})
            /* Clean up notifications that are no longer possible to trigger */
            if (foundElementIndex == nil) {
                enabledNotifications.remove(at: index)
            } else {
                /* Check if a notification is due */
                if programPlan.notificationIsDue(startDate: enabledNotification.timeStart) {
                    
                    /* Send notification */
                    let notification = NSUserNotification()
                    
                    if (enabledNotification.topic == "") {
                        notification.title = enabledNotification.title
                    } else {
                        notification.title = "\(enabledNotification.title) - \(enabledNotification.topic)"
                    }
                    
                    notification.informativeText = "Beginnt \(programPlan.convertDoHumanDate(date: enabledNotification.timeStart)) Uhr"
                    
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
        
        UserDefaults.standard.set(try? PropertyListEncoder().encode(enabledNotifications), forKey:"enabledNotifications")
        
        if (UserDefaults.standard.value(forKey: "coloredIcon") == nil) {
            appDelegate.statusItem.image = NSImage(named: "StatusIcon")
        } else {
            if UserDefaults.standard.value(forKey: "coloredIcon") as! Int == 0 {
                appDelegate.statusItem.image = NSImage(named: "StatusIcon")
            } else {
                switch (self.programPlanSchedule[0].type.uppercased()) {
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
        if (self.programPlanSchedule[row].topic == "") {
            return 55.0
        } else {
            return 75.0
        }
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        /* Nothing for now */
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier: String = (tableColumn?.identifier)!.rawValue
        
        if (identifier == "ProgramPlanTableViewColumn") {
            
            /* Item title */
            let scheduleItemTitle = self.programPlanSchedule[row].title
            
            /* Item type */
            var scheduleItemType: String
            if (self.programPlanSchedule[row].type == "") {
                scheduleItemType = "WDH"
            } else {
                scheduleItemType = self.programPlanSchedule[row].type.uppercased()
            }
            
            /* Item type colors */
            var scheduleItemTypeColor: NSColor
            
            switch (self.programPlanSchedule[row].type.uppercased()) {
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
            
            if (self.programPlanSchedule[row].topic == "") {
                let cell: ProgramPlanTableViewCellSimple = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ProgramPlanTableViewCellSimple"), owner: self) as! ProgramPlanTableViewCellSimple
                
                /* Pass the item id to the row in order to manage notifications */
                cell.currentItem = self.programPlanSchedule[row] as Program
                
                cell.programPlanScheduleItemTitle?.stringValue = scheduleItemTitle
                cell.programPlanScheduleItemType?.stringValue = scheduleItemType
                cell.programPlanScheduleItemType?.textColor = scheduleItemTypeColor
                cell.programPlanScheduleItemDate?.stringValue = "\(programPlan.convertDoHumanDate(date: self.programPlanSchedule[row].timeStart)) Uhr - \(programPlan.convertDoHumanDate(date: self.programPlanSchedule[row].timeEnd)) Uhr"

                
                /* Show progress indicator for currently running show */
                if (row == 0) {
                    cell.programPlanScheduleItemProgress?.doubleValue = programPlan.calculateProgress(startDate: self.programPlanSchedule[row].timeStart, endDate: self.programPlanSchedule[row].timeEnd)
                    cell.programPlanScheduleItemProgress?.isHidden = false
                    cell.programPlanScheduleItemNotificationToggle?.isHidden = true
                } else {
                    cell.programPlanScheduleItemProgress?.isHidden = true
                    cell.programPlanScheduleItemNotificationToggle?.isHidden = false
                }
                
                /* Set the notification toggle to active if notifications are enabled */
                if enabledNotifications.contains(where: {$0.id == self.programPlanSchedule[row].id}) {
                    cell.programPlanScheduleItemNotificationToggle.state = NSControl.StateValue(rawValue: 1)
                } else {
                    cell.programPlanScheduleItemNotificationToggle.state = NSControl.StateValue(rawValue: 0)
                }

                
                return cell
                
            } else {
                let cell: ProgramPlanTableViewCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ProgramPlanTableViewCell"), owner: self) as! ProgramPlanTableViewCell
                
                /* Pass the item id to the row in order to manage notifications */
                cell.currentItem = self.programPlanSchedule[row] as Program
                
                cell.programPlanScheduleItemTitle?.stringValue = scheduleItemTitle
                cell.programPlanScheduleItemType?.stringValue = scheduleItemType
                cell.programPlanScheduleItemType?.textColor = scheduleItemTypeColor
                cell.programPlanScheduleItemType?.backgroundColor = NSColor.clear
                cell.programPlanScheduleItemSubtitle?.stringValue = self.programPlanSchedule[row].topic
                cell.programPlanScheduleItemDate?.stringValue = "\(programPlan.convertDoHumanDate(date: self.programPlanSchedule[row].timeStart)) Uhr - \(programPlan.convertDoHumanDate(date: self.programPlanSchedule[row].timeEnd)) Uhr"
                
                
                /* Show progress indicator for currently running show */
                if (row == 0) {
                    cell.programPlanScheduleItemProgress?.doubleValue = programPlan.calculateProgress(startDate: self.programPlanSchedule[row].timeStart, endDate: self.programPlanSchedule[row].timeEnd)
                    cell.programPlanScheduleItemProgress?.isHidden = false
                    cell.programPlanScheduleItemNotificationToggle?.isHidden = true
                } else {
                    cell.programPlanScheduleItemProgress?.isHidden = true
                    cell.programPlanScheduleItemNotificationToggle?.isHidden = false
                }
                
                /* Set the notification toggle to active if notifications are enabled */
                if enabledNotifications.contains(where: {$0.id == self.programPlanSchedule[row].id}) {
                    cell.programPlanScheduleItemNotificationToggle.state = NSControl.StateValue(rawValue: 1)
                } else {
                    cell.programPlanScheduleItemNotificationToggle.state = NSControl.StateValue(rawValue: 0)
                }
                
                return cell
            }
        }
        
        return nil
    }
}
