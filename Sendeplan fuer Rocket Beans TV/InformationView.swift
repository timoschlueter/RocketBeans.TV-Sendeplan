//
//  InformationView.swift
//  Sendeplan fuer Rocket Beans TV
//
//  Created by Timo Schlüter on 29.09.16.
//  Copyright © 2016 Timo Schlüter. All rights reserved.
//

import Foundation
import AppKit

class InformationView: NSView {
    
    @IBOutlet var versionLabel: NSTextField!
        
    @IBAction func buttonTwitter(_ sender: AnyObject) {
        NSWorkspace.shared().open(NSURL(string: "https://twitter.com/tmuuh")! as URL)
    }
    
    @IBAction func buttonFacebook(_ sender: AnyObject) {
        NSWorkspace.shared().open(NSURL(string: "https://www.facebook.com/timo.schlueter")! as URL)
    }
    
    @IBAction func buttonGitHub(_ sender: AnyObject) {
        NSWorkspace.shared().open(NSURL(string: "https://github.com/timoschlueter/RocketBeans.TV-Sendeplan")! as URL)
        
    }
}
