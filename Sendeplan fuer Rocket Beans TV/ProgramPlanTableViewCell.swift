//
//  ProgramPlanTableViewCell.swift
//  Sendeplan fuer Rocket Beans TV
//
//  Created by Timo Schlüter on 03.05.16.
//  Copyright © 2018 Timo Schlüter. All rights reserved.
//

import Foundation
import AppKit

class ProgramPlanTableViewCell: NSTableCellView {
    
    var currentItem: Program!
    var enabledNotifications = [Program]()
    
    @IBOutlet weak var programPlanScheduleItemTitle: NSTextField!
    @IBOutlet weak var programPlanScheduleItemSubtitle: NSTextField!
    @IBOutlet weak var programPlanScheduleItemType: NSTextField!
    @IBOutlet weak var programPlanScheduleItemDate: NSTextField!
    @IBOutlet weak var programPlanScheduleItemProgress: NSProgressIndicator!
    @IBOutlet weak var programPlanScheduleItemNotificationToggle: NSButton!
    
    @IBAction func toggleNotification(_ sender: AnyObject) {
        if let data = UserDefaults.standard.value(forKey:"enabledNotifications") as? Data {
            enabledNotifications = try! PropertyListDecoder().decode([Program].self, from: data)
        }
        
        if (programPlanScheduleItemNotificationToggle.state.rawValue == 0) {
            enabledNotifications = enabledNotifications.filter(){$0.id != currentItem.id}
            UserDefaults.standard.set(try? PropertyListEncoder().encode(enabledNotifications), forKey:"enabledNotifications")
        } else {
            enabledNotifications.append(currentItem)
            if enabledNotifications.contains(where: {$0.id == currentItem.id}) {
                /* Do nothing */
            } else {
                enabledNotifications.append(currentItem)
            }
            UserDefaults.standard.set(try? PropertyListEncoder().encode(enabledNotifications), forKey:"enabledNotifications")
        }
    }
}
