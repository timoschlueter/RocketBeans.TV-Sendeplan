//
//  SettingsWindowController.swift
//  RocketBeans.TV Sendeplan
//
//  Created by Ralph-Gordon Paul on 31.01.15.
//  Copyright (c) 2015 Timo Schlüter. All rights reserved.
//

import Cocoa

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    
    @IBOutlet weak var notificationOnChangesButton: NSButton!
    @IBOutlet weak var notificationBeforeBroadcastButton: NSButton!
    @IBOutlet weak var updateIntervalTextField: NSTextField!
    @IBOutlet weak var broadcastNotificationAheadIntervalTextField: NSTextField!

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.delegate = self
    }
    
    func windowWillClose(notification: NSNotification!)
    {
        /* store input to NSUserDefaults */
        self.updateUserDefaultsFromViews()
        
        /* save user defaults on close */
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func windowDidBecomeKey(notification: NSNotification)
    {
        self.updateViewItems()
    }
    
    /* updates the views - textfields, buttons - with the data from NSUserDefaults */
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
        
        self.updateIntervalTextField.doubleValue = NSUserDefaults.standardUserDefaults().doubleForKey("UpdateInterval")
        self.broadcastNotificationAheadIntervalTextField.doubleValue = NSUserDefaults.standardUserDefaults().doubleForKey("BroadcastAheadInterval")
    }
    
    /* updates the NSUserDefaults with the data from the views */
    func updateUserDefaultsFromViews()
    {
        if self.notificationOnChangesButton.state == NSOnState {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "NotificationOnChanges")
        } else {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "NotificationOnChanges")
        }
        
        if self.notificationBeforeBroadcastButton.state == NSOnState {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "NotificationOnAir")
        } else {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "NotificationOnAir")
        }
        
        NSUserDefaults.standardUserDefaults().setDouble(self.updateIntervalTextField.doubleValue, forKey: "UpdateInterval")
        NSUserDefaults.standardUserDefaults().setDouble(self.broadcastNotificationAheadIntervalTextField.doubleValue, forKey: "BroadcastAheadInterval")
    }
    
    // MARK: - IBActions
    
    @IBAction func notificationOnChangesChanged(sender: AnyObject)
    {
        if self.notificationOnChangesButton.state == NSOnState {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "NotificationOnChanges")
        } else {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "NotificationOnChanges")
        }
    }
    
    @IBAction func notificationsForBroadcastsChanged(sender: AnyObject)
    {
        if self.notificationBeforeBroadcastButton.state == NSOnState {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "NotificationOnAir")
        } else {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "NotificationOnAir")
        }
    }
    
    @IBAction func updateIntervalChanged(sender: AnyObject)
    {
        NSUserDefaults.standardUserDefaults().setDouble(self.updateIntervalTextField.doubleValue, forKey: "UpdateInterval")
    }
    
    @IBAction func broadcastAheadTimeChanged(sender: AnyObject)
    {
        NSUserDefaults.standardUserDefaults().setDouble(self.broadcastNotificationAheadIntervalTextField.doubleValue, forKey: "BroadcastAheadInterval")
    }
}
