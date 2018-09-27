//
//  ProgramPlanMenu.swift
//  Sendeplan fuer Rocket Beans TV
//
//  Created by Timo Schlüter on 29.04.16.
//  Copyright © 2018 Timo Schlüter. All rights reserved.
//

import Foundation
import AppKit

class ProgramPlanMenu: NSMenu {
    
    @IBOutlet weak var informationWindow: InformationWindow!

    @IBOutlet weak var settingsWindow: SettingsWindow!
    
    @IBAction func itemQuit(_ sender: AnyObject) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func itemOpenStream(_ sender: AnyObject) {
        NSWorkspace.shared.open(NSURL(string: "https://www.rocketbeans.tv")! as URL)
    }
    @IBAction func itemOpenSettings(_ sender: AnyObject) {
        NSApp.activate(ignoringOtherApps: true)
        self.settingsWindow.center()
        self.settingsWindow.makeKeyAndOrderFront(self)
    }
    
    @IBAction func itemOpenInfo(_ sender: AnyObject) {
        NSApp.activate(ignoringOtherApps: true)
        self.informationWindow.center()
        self.informationWindow.makeKeyAndOrderFront(self)
    }
}
