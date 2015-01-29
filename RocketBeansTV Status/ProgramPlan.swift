//
//  ProgramPlan.swift
//  RocketBeansTV Status
//
//  Created by Timo Schlüter on 23.01.15.
//  Copyright (c) 2015 Timo Schlüter. All rights reserved.
//

import Foundation

class ProgramPlan {
    var programTitle: String = ""
    var programDate: String = ""
    var programEpochDate: Double = 0.0
    var programState: String = ""
    var programCurrent: Bool = false
    
    /* New variables for ics parsing */
    var programStartDate: String = ""
    var programStartDateFormattable: NSDate = NSDate()
    var programStartDateEpoch: Double = 0.0
    var programEndDate: String = ""
    var programEndDateFormattable: NSDate = NSDate()
    var programEndDateEpoch: Double = 0.0
    var programCreatedDate: String = ""
    var programLastModifiedDate: String = ""

    func humanReadableStartDate() -> String
    {
        return self.convertDateToHumanReadable(self.programStartDateFormattable)
    }
    
    func humanReadableEndDate() -> String
    {
        return self.convertDateToHumanReadable(self.programEndDateFormattable)
    }
    
    /* Formatting the date end setting timezone to local timezone */
    private func convertDateToHumanReadable(date: NSDate) -> String
    {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter.stringFromDate(date)
    }
}
