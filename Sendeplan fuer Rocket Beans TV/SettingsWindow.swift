//
//  SettingsWindow.swift
//  Sendeplan für Rocket Beans TV
//
//  Created by Timo Schlüter on 12.10.16.
//  Copyright © 2018 Timo Schlüter. All rights reserved.
//

import Foundation
import AppKit

class SettingsWindow: NSWindow, NSTextFieldDelegate {
    @IBOutlet weak var checkboxColoredIcon: NSButton!
    
    @IBOutlet var notificationTime: NSTextField!
        
    @IBOutlet var notificationSoundPicker: NSPopUpButton!
    
    @IBOutlet var saveButton: NSButton!
    
    @IBAction func buttonSave(_ sender: AnyObject) {
        UserDefaults.standard.setValue(checkboxColoredIcon.state, forKey: "coloredIcon")
        
        if Int(notificationTime.stringValue) != nil {
            UserDefaults.standard.setValue(Int(notificationTime.stringValue), forKey: "notificationTime")
        } else {
            UserDefaults.standard.setValue(Int(15), forKey: "notificationTime")
        }
        
        UserDefaults.standard.setValue(notificationSoundPicker.indexOfSelectedItem, forKey: "notificationSound")
    }
    
    override func awakeFromNib() {
        notificationTime.delegate = self
        
        notificationSoundPicker.removeAllItems()
        notificationSoundPicker.addItems(withTitles: ["Standard", "Nicenstein", "Maximale Realität", "Kappa"])
        
        if (UserDefaults.standard.value(forKey: "notificationSound") == nil) {
            notificationSoundPicker.selectItem(at: 0)
        } else {
            notificationSoundPicker.selectItem(at: UserDefaults.standard.integer(forKey: "notificationSound"))
        }
        
        if (UserDefaults.standard.value(forKey: "coloredIcon") == nil) {
            checkboxColoredIcon.state = NSControl.StateValue(rawValue: 1)
        } else {
            checkboxColoredIcon.state = NSControl.StateValue(rawValue: UserDefaults.standard.value(forKey: "coloredIcon") as! Int)
        }
        
        if (UserDefaults.standard.value(forKey: "notificationTime") == nil) {
            notificationTime.stringValue = "15"
        } else {
            notificationTime.stringValue = String(UserDefaults.standard.integer(forKey: "notificationTime"))
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        let textField: NSTextField = obj.object as! NSTextField
        let stringValue = textField.stringValue
        
        if Int(stringValue) != nil {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
            NSSound.beep()
        }
    }
}
