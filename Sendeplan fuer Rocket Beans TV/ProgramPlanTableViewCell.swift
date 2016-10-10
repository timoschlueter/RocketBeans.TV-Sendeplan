//
//  ProgramPlanTableViewCell.swift
//  Sendeplan fuer Rocket Beans TV
//
//  Created by Timo Schlüter on 03.05.16.
//  Copyright © 2016 Timo Schlüter. All rights reserved.
//

import Foundation
import AppKit

class ProgramPlanTableViewCell: NSTableCellView {
    
    @IBOutlet weak var programPlanScheduleItemTitle: NSTextField!
    @IBOutlet weak var programPlanScheduleItemSubtitle: NSTextField!
    @IBOutlet weak var programPlanScheduleItemType: NSTextField!
    @IBOutlet weak var programPlanScheduleItemDate: NSTextField!
    @IBOutlet weak var programPlanScheduleItemProgress: NSProgressIndicator!
    
}
