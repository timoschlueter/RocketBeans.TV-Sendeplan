//
//  SettingsWindow.swift
//  Sendeplan für Rocket Beans TV
//
//  Created by Timo Schlüter on 12.10.16.
//  Copyright © 2016 Timo Schlüter. All rights reserved.
//

import Foundation
import AppKit

class SettingsWindow: NSWindow {
    @IBOutlet weak var checkboxColoredIcon: NSButton!
    
    @IBAction func buttonSave(_ sender: AnyObject) {
        UserDefaults.standard.setValue(checkboxColoredIcon.state, forKey: "coloredIcon")
    }
    
    override func awakeFromNib() {
        
        if (UserDefaults.standard.value(forKey: "coloredIcon") == nil) {
            checkboxColoredIcon.state = 1
        } else {
            checkboxColoredIcon.state = UserDefaults.standard.value(forKey: "coloredIcon") as! Int
        }
    }
}
