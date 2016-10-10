//
//  ProgramPlan.swift
//  Sendeplan fuer Rocket Beans TV
//
//  Created by Timo Schlüter on 29.04.16.
//  Copyright © 2016 Timo Schlüter. All rights reserved.
//

import Foundation
import CryptoSwift

protocol ProgramPlanDelegate {
    func didFinishRefresh(_ data: [Dictionary<String,AnyObject>])
}

public class ProgramPlan {
    
    var apiUsername: String = ""
    var apiPassword: String = ""
    var apiScheduleEndpoint: String = "https://api.rocketmgmt.de/schedule"
    var apiCurrentEndpoint: String = "https://api.rocketmgmt.de/schedule/current"

    var apiCheckTimer: Timer!
    
    let requestSession = URLSession.shared
    
    var delegate: ProgramPlanDelegate?
    
    @objc func refresh() {
        
        let date = Date().formattedISO8601
        let nonce = UUID().uuidString.sha1()
        let digest = (nonce + date + apiPassword).sha1()
        
        var request = URLRequest(url: URL(string: apiScheduleEndpoint)!)
        
        request.setValue("WSSE profile=\"UsernameToken\"", forHTTPHeaderField: "Authorization")
        request.setValue("UsernameToken Username=\"\(apiUsername)\", PasswordDigest=\"\(digest.toBase64())\", Nonce=\"\(nonce.toBase64())\", Created=\"\(date)\"", forHTTPHeaderField: "X-WSSE")
        request.httpMethod = "GET"
        
        let task : URLSessionDataTask = requestSession.dataTask(with: request, completionHandler: {(data, response, error) in
            if let HTTPResponse = response as? HTTPURLResponse {
                let statusCode = HTTPResponse.statusCode

                if statusCode == 200 {
                    do {
                        if let data = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? Dictionary<String, AnyObject> {
                            DispatchQueue.main.async {
                                
                                if let programPlanSchedule: [Dictionary<String,AnyObject>] = data["schedule"] as? [Dictionary<String,AnyObject>]  {
                                    self.delegate?.didFinishRefresh(programPlanSchedule)
                                }
                            }
                        }
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

/* String extension for encoding and decoding base64 (http://stackoverflow.com/a/35360697/3118311) */
extension String
{
    func fromBase64() -> String
    {
        let data = Data(base64Encoded: self, options: NSData.Base64DecodingOptions(rawValue: 0))
        return String(data: data!, encoding: String.Encoding.utf8)!
    }
    
    func toBase64() -> String
    {
        let data = self.data(using: String.Encoding.utf8)
        return data!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
}
