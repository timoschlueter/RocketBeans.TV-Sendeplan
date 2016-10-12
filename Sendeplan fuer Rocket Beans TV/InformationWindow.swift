//
//  InformationWindow.swift
//  Sendeplan fuer Rocket Beans TV
//
//  Created by Timo Schlüter on 29.09.16.
//  Copyright © 2016 Timo Schlüter. All rights reserved.
//

import Foundation
import AppKit

class InformationWindow: NSWindow {
    
    @IBOutlet weak var versionLabel: NSTextField!
    
    @IBAction func buttonTwitter(_ sender: AnyObject) {
        NSWorkspace.shared().open(NSURL(string: "https://twitter.com/tmuuh")! as URL)
    }
    
    @IBAction func buttonFacebook(_ sender: AnyObject) {
        NSWorkspace.shared().open(NSURL(string: "https://www.facebook.com/timo.schlueter")! as URL)
    }
    
    @IBAction func buttonGitHub(_ sender: AnyObject) {
        NSWorkspace.shared().open(NSURL(string: "https://github.com/timoschlueter/RocketBeans.TV-Sendeplan")! as URL)
        
    }
    
    override func awakeFromNib() {
        /* Set the version label */
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "0"
        versionLabel.stringValue = "Version \(version) (\(build))"
    }
}
