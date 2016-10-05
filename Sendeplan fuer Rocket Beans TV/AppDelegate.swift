//
//  AppDelegate.swift
//  Sendeplan fuer Rocket Beans TV
//
//  Created by Timo Schlüter on 29.04.16.
//  Copyright © 2016 Timo Schlüter. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var programPlanMenu: ProgramPlanMenu!
    @IBOutlet weak var programPlanMenuItem: NSMenuItem!
    @IBOutlet weak var programPlanTableView: ProgramPlanTableView!
    
    var statusItem: NSStatusItem = NSStatusItem()
    var programPlanScheduleItems: Int = 0
    var programPlanSchedule = [Dictionary<String,AnyObject>]()
    
    @IBOutlet weak var programPlanScrollView: NSScrollView!
    
    let programPlan = ProgramPlan()
    
    override init() {
        /* Nothing for now */
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let statusBar = NSStatusBar.system()
        self.statusItem = statusBar.statusItem(withLength: 25.0)
        self.statusItem.toolTip = "Sendeplan für Rocket Beans TV"
        self.statusItem.image = NSImage(named: "StatusIcon")
        self.statusItem.image?.isTemplate = true
        self.statusItem.highlightMode = true
        self.statusItem.menu = programPlanMenu
        
        programPlan.refresh()
        programPlan.startTimer(60.0)
        programPlan.delegate = programPlanTableView
        
        self.programPlanMenuItem.view = programPlanScrollView
        
        self.programPlanTableView.dataSource = programPlanTableView
        self.programPlanTableView.delegate = programPlanTableView
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}

