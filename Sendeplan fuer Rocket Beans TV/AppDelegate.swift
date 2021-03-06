//
//  AppDelegate.swift
//  Sendeplan fuer Rocket Beans TV
//
//  Created by Timo Schlüter on 29.04.16.
//  Copyright © 2018 Timo Schlüter. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var programPlanMenu: ProgramPlanMenu!
    @IBOutlet weak var programPlanMenuItem: NSMenuItem!
    @IBOutlet weak var programPlanTableView: ProgramPlanTableView!
    
    public var statusItem: NSStatusItem = NSStatusItem()
    var programPlanScheduleItems: Int = 0
    var programPlanSchedule: [Program]!
    
    @IBOutlet weak var programPlanScrollView: NSScrollView!
    
    let programPlan = ProgramPlan()
    
    var enabledNotifications = [Program]()
    var currentEnabledNotifications = [Program]()
    
    override init() {
        /* Nothing for now */
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let buildString: String = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        let buildNumber: Int = Int(buildString) ?? 0
                
        /* If there are no settings yet, set the default value */
        if (UserDefaults.standard.value(forKey: "coloredIcon") == nil) {
            UserDefaults.standard.setValue(1, forKey: "coloredIcon")
        }
        
        if (UserDefaults.standard.value(forKey: "enabledNotifications") == nil) {
            UserDefaults.standard.set(try? PropertyListEncoder().encode(enabledNotifications), forKey:"enabledNotifications")
        } else {
            /* If there are user defaults, we have to check for the old type and remove initialize new ones */
            if (buildNumber < 17) {
                UserDefaults.standard.set(try? PropertyListEncoder().encode(enabledNotifications), forKey:"enabledNotifications")
            }
        }
        
        if (UserDefaults.standard.value(forKey: "notificationSound") == nil) {
            UserDefaults.standard.setValue(0, forKey: "notificationSound")
        }

        let statusBar = NSStatusBar.system
        self.statusItem = statusBar.statusItem(withLength: 25.0)
        self.statusItem.toolTip = "Sendeplan für Rocket Beans TV"
        self.statusItem.image = NSImage(named: "StatusIcon")
        /* self.statusItem.image?.isTemplate = true */
        self.statusItem.highlightMode = true
        self.statusItem.menu = programPlanMenu
                
        programPlan.refresh()
        programPlan.startTimer(60.0)
        programPlan.delegate = programPlanTableView
        
        self.programPlanMenuItem.view = programPlanScrollView
        
        self.programPlanTableView.dataSource = programPlanTableView
        self.programPlanTableView.delegate = programPlanTableView
                
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions" : true])
        
        if let data = UserDefaults.standard.value(forKey:"enabledNotifications") as? Data {
            currentEnabledNotifications = try! PropertyListDecoder().decode([Program].self, from: data)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}

