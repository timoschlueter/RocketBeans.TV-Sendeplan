//
//  File.swift
//  Sendeplan fuer Rocket Beans TV
//
//  Created by Timo Schlüter on 04.05.16.
//  Copyright © 2016 Timo Schlüter. All rights reserved.
//

import Foundation
import AppKit

class ProgramPlanTableViewCellSimple: NSTableCellView {
    
    @IBOutlet weak var programPlanScheduleItemTitle: NSTextField!
    @IBOutlet weak var programPlanScheduleItemType: NSTextField!
    @IBOutlet weak var programPlanScheduleItemDate: NSTextField!
    @IBOutlet weak internal var programPlanScheduleItemProgress: NSProgressIndicator!
    
}
