//
//  TodayViewController.swift
//  RocketbeansTV
//
//  Created by Mario Schreiner on 31/01/15.
//  Copyright (c) 2015 Timo Schlüter. All rights reserved.
//

import Cocoa
import NotificationCenter
import SystemConfiguration

class TodayViewController: NSViewController, NCWidgetProviding, ProgramPlanDelegate {
    
    @IBOutlet weak var nowTextField: NSTextField!
    @IBOutlet weak var nextTextField: NSTextField!
    
    let refreshInterval: NSTimeInterval = 60
    var programPlan: ProgramPlan
    
    override init() {
        self.programPlan = ProgramPlan()
        
        super.init()
        
        self.programPlan.delegate = self
    }
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.programPlan = ProgramPlan()
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.programPlan.delegate = self
    }

    required init?(coder: NSCoder) {
        self.programPlan = ProgramPlan()
        
        super.init(coder: coder)
        
        self.programPlan.delegate = self
    }
    
    override var nibName: String? {
        return "TodayViewController"
    }
    
    var lastCompletionHandler: ((NCUpdateResult) -> Void)!
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        //Let the user know we are updating...
        dispatch_async(dispatch_get_main_queue(), {
            self.nowTextField.stringValue = "Updating...";
            self.nextTextField.stringValue = "";
            completionHandler(.NewData)
        });

        self.lastCompletionHandler = completionHandler;
        self.programPlan.beginRefresh()
    }
    
    func programPlanDidRefresh(programPlan: ProgramPlan) {
        self.nowTextField.stringValue = "";
        
        var programs = self.programPlan.currentAndFuturePrograms()
        for (var i=0; i<programs.count; i++) {
            var program = programs[i];
            
            if (program.current || program.state() == .Error) {
                self.nowTextField.stringValue = "Jetzt - "+(program.title());
            }
            
            if (program.future) {
                self.nextTextField.stringValue = "Um \(program.shortHumanReadableStartDate()) - \(program.title())";
                break;
            }
        }
        
        self.lastCompletionHandler(.NewData)
    }
    
    @IBAction func widgetClicked(sender: NSButton) {
        let twitchUrl: NSURL = NSURL(string: "http://www.twitch.tv/rocketbeanstv")!
        NSWorkspace.sharedWorkspace().openURL(twitchUrl)
    }
}
