//
//  ProgramPlan.swift
//  Sendeplan fuer Rocket Beans TV
//
//  Created by Timo Schlüter on 29.04.16.
//  Copyright © 2018 Timo Schlüter. All rights reserved.
//

import Foundation

protocol ProgramPlanDelegate {
    func didFinishRefresh(_ data: [Program])
}

struct ProgramPlanSchedule: Codable {
    var schedule: [Program]
}

struct Program: Codable {
    let game: String
    let id: Int
    let length: Int
    let show: String
    let timeEnd: Date
    let timeStart: Date
    let title: String
    let topic: String
    let type: String
    let youtube: String
}



public class ProgramPlan {
    var apiScheduleEndpoint: String = "https://api.rocketbeans.tv/v1/schedule/legacy"
    var apiCurrentEndpoint: String = "https://api.rocketbeans.tv/v1/schedule/legacy/current"

    var apiCheckTimer: Timer!
    
    let requestSession = URLSession.shared
    
    var delegate: ProgramPlanDelegate?
    
    @objc func refresh() {
        
        var request = URLRequest(url: URL(string: apiScheduleEndpoint)!)

        request.httpMethod = "GET"
        
        let task : URLSessionDataTask = requestSession.dataTask(with: request, completionHandler: {(data, response, error) in
            if let HTTPResponse = response as? HTTPURLResponse {
                let statusCode = HTTPResponse.statusCode

                if statusCode == 200 {
                    do {
                        
                        guard let data = data else { return }
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "de_DE")
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .formatted(dateFormatter)
                        let programPlanSchedule = try decoder.decode(ProgramPlanSchedule.self, from: data)
                    
                        let currentDate = Date();
                        var activeProgramPlanSchedule:[Program] = programPlanSchedule.schedule.filter { $0.timeEnd > currentDate }
                        activeProgramPlanSchedule.sort { $0.timeStart < $1.timeStart }
                        
                        self.delegate?.didFinishRefresh(activeProgramPlanSchedule)
                    }
                    catch let error as NSError {
                        print("A JSON parsing error occurred, here are the details:\n \(error)")
                    }
                }
            }
        }) 
        task.resume()
    }
    
    func startTimer(_ interval: Double) {
        self.apiCheckTimer = Timer.scheduledTimer(timeInterval: interval,target: self,selector: #selector(ProgramPlan.refresh) ,userInfo: nil,repeats: true)
    }
    
    func stopTimer() {
        self.apiCheckTimer.invalidate()
    }
    
    func calculateProgress(startDate: Date, endDate: Date) -> Double {
        
        let currentDateEpoch: Double = Date().timeIntervalSince1970
        let startDateEpoch: Double = startDate.timeIntervalSince1970
        let endDateEpoch:Double = endDate.timeIntervalSince1970
        
        let totalSeconds: Double = endDateEpoch - startDateEpoch
        let elapsedSeconds: Double = currentDateEpoch - startDateEpoch
        
        let progressPercent: Double = round((elapsedSeconds/totalSeconds)*100)
        
        if (progressPercent >= 100.0) {
            return 99.0
        } else if (progressPercent < 0.0) {
            return 0.1
        } else {
            return progressPercent
        }
    }
    
    func notificationIsDue(startDate: Date) -> Bool {
        let currentDateEpoch: Double = Date().timeIntervalSince1970
        let startDateEpoch: Double = startDate.timeIntervalSince1970
        var notificationTime:Double = 0.0
        
        if (UserDefaults.standard.value(forKey: "notificationTime") == nil) {
            notificationTime = 15 * 60.0
        } else {
            notificationTime = Double(UserDefaults.standard.integer(forKey: "notificationTime")) * 60.0
        }
        
        /* Check if we have to trigger the notification */
        if ((startDateEpoch - currentDateEpoch) <= notificationTime) {
            return true
        } else {
            return false
        }
    }
    
    func convertDoHumanDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter.string(from: date)
    }
    
    func convertDate(date: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ" /* ISO 8601 */
        let parsedDate: Date = dateFormatter.date(from: date)!
        return parsedDate
    }
    
}

/* NSDate extension (http://stackoverflow.com/a/28016692/3118311) */
extension Foundation.Date {
    struct Date {
        static let formatterISO8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "Germany")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            
            return formatter
        }()
    }
    var formattedISO8601: String { return Date.formatterISO8601.string(from: self) }
}
