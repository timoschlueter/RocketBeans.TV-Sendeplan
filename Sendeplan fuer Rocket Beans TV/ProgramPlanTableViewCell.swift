//
//  ProgramPlanTableViewCell.swift
//  Sendeplan fuer Rocket Beans TV
//
//  Created by Timo Schlüter on 03.05.16.
//  Copyright © 2016 Timo Schlüter. All rights reserved.
//

import Foundation
import AppKit

class ProgramPlanTableViewCell: NSTableCellView {
    
    var currentItem: Dictionary<String,AnyObject> = [:]
    var enabledNotifications: [Dictionary<String,AnyObject>] = []
    
    @IBOutlet weak var programPlanScheduleItemTitle: NSTextField!
    @IBOutlet weak var programPlanScheduleItemSubtitle: NSTextField!
    @IBOutlet weak var programPlanScheduleItemType: NSTextField!
    @IBOutlet weak var programPlanScheduleItemDate: NSTextField!
    @IBOutlet weak var programPlanScheduleItemProgress: NSProgressIndicator!
    @IBOutlet weak var programPlanScheduleItemNotificationToggle: NSButton!
    
    @IBAction func toggleNotification(_ sender: AnyObject) {
        enabledNotifications = UserDefaults.standard.value(forKey: "enabledNotifications") as! [Dictionary<String, AnyObject>]
        
        if (programPlanScheduleItemNotificationToggle.state == 0) {
            enabledNotifications = enabledNotifications.filter(){$0["id"] as! Int != currentItem["id"] as! Int}
            UserDefaults.standard.setValue(enabledNotifications, forKey: "enabledNotifications")
        } else {
            if enabledNotifications.contains(where: {$0["id"] as! Int == currentItem["id"] as! Int}) {
                /* Do nothing */
            } else {
                enabledNotifications.append(currentItem)
            }
            UserDefaults.standard.setValue(enabledNotifications, forKey: "enabledNotifications")
        }
    }
}
