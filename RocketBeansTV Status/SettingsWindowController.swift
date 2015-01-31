//
//  SettingsWindowController.swift
//  RocketBeans.TV Sendeplan
//
//  Created by Ralph-Gordon Paul on 31.01.15.
//  Copyright (c) 2015 Timo Schlüter. All rights reserved.
//

import Cocoa

class SettingsWindowController: NSWindowController {
    
    
    @IBOutlet weak var notificationOnChangesButton: NSButton!
    @IBOutlet weak var notificationBeforeBroadcastButton: NSButton!
    @IBOutlet weak var updateIntervalTextField: NSTextField!
    @IBOutlet weak var broadcastNotificationAheadIntervalTextField: NSTextField!

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.updateViewItems()
    }
    
    func updateViewItems()
    {
        if NSUserDefaults.standardUserDefaults().boolForKey("NotificationOnChanges") {
            self.notificationOnChangesButton.state = NSOnState
        } else {
            self.notificationOnChangesButton.state = NSOffState
        }
        
        if NSUserDefaults.standardUserDefaults().boolForKey("NotificationOnAir") {
            self.notificationBeforeBroadcastButton.state = NSOnState
        } else {
            self.notificationBeforeBroadcastButton.state = NSOffState
        }
        
        self.updateIntervalTextField.integerValue = NSUserDefaults.standardUserDefaults().integerForKey("UpdateInterval")
        self.broadcastNotificationAheadIntervalTextField.integerValue = NSUserDefaults.standardUserDefaults().integerForKey("BroadcastAheadInterval")
    }
    
    // MARK: - IBActions
    
    @IBAction func notificationOnChangesChanged(sender: AnyObject)
    {
        if self.notificationOnChangesButton.state == NSOnState {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "NotificationOnChanges")
        } else {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "NotificationOnChanges")
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    @IBAction func notificationsForBroadcastsChanged(sender: AnyObject)
    {
        if self.notificationBeforeBroadcastButton.state == NSOnState {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "NotificationOnAir")
        } else {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "NotificationOnAir")
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    @IBAction func updateIntervalChanged(sender: AnyObject)
    {
        NSUserDefaults.standardUserDefaults().setInteger(self.updateIntervalTextField.integerValue, forKey: "UpdateInterval")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
