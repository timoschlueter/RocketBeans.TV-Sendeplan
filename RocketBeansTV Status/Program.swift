//
//  ProgramPlan.swift
//  RocketBeansTV Status
//
//  Created by Timo Schlüter on 23.01.15.
//  Copyright (c) 2015 Timo Schlüter. All rights reserved.
//

import Foundation


enum ProgramState {
    case Live
    case New
    case Rerun
    case Error
}

class Program {
    var rawTitle: String = ""
    var date: String = ""
    var epochDate: Double = 0.0
    var current: Bool = false
    var future: Bool = false
    
    /* New variables for ics parsing */
    var startDate: String = ""
    var startDateFormattable: NSDate = NSDate()
    var startDateEpoch: Double = 0.0
    var endDate: String = ""
    var endDateFormattable: NSDate = NSDate()
    var endDateEpoch: Double = 0.0
    var createdDate: String = ""
    var lastModifiedDate: String = ""
    var uid: String = ""
    
    func state() -> ProgramState {
        return self.parseRawTitle().state;
    }
    
    func title() -> String {
        return self.parseRawTitle().title;
    }

    func humanReadableStartDate() -> String
    {
        return self.convertDateToHumanReadable(self.startDateFormattable)
    }
    
    func humanReadableEndDate() -> String
    {
        return self.convertDateToHumanReadable(self.endDateFormattable)
    }
    
    func shortHumanReadableStartDate() -> String
    {
        return self.convertDateToShortHumanReadable(self.startDateFormattable)
    }
    
    func iconName() -> String? {
        switch (self.state()) {
        case .Live:  return "LiveIcon"
        case .New:   return "NewIcon"
        case .Rerun: return "RerunIcon"
        default:     return nil
        }
    }
    
    private func parseRawTitle() -> (title: String, state: ProgramState)
    {
        var stripedTitle = self.rawTitle
        var state = ProgramState.Rerun
        
        if let range = self.rawTitle.rangeOfString("[L] ") {
            state = .Live;
            stripedTitle.removeRange(range)
        } else if let range = self.rawTitle.rangeOfString("[L]") {
            state = .Live;
            stripedTitle.removeRange(range)
        } else if let range = self.rawTitle.rangeOfString("[N] ") {
            state = .New;
            stripedTitle.removeRange(range)
        } else if let range = self.rawTitle.rangeOfString("[N]") {
            state = .New;
            stripedTitle.removeRange(range)
        } else if let range = self.rawTitle.rangeOfString("[E] ") {
            state = .Error;
            stripedTitle.removeRange(range)
        } else if let range = self.rawTitle.rangeOfString("[E]") {
            state = .Error;
            stripedTitle.removeRange(range)
        } else {
            state = .Rerun;
        }
        
        return (stripedTitle, state)
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
    
    private func convertDateToShortHumanReadable(date: NSDate) -> String
    {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .NoStyle
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter.stringFromDate(date)
    }
}
