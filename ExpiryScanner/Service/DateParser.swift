//
//  DateParser.swift
//  ExpiryScanner
//
//  Created by Franco Antonio Pranata on 11/06/25.

import Foundation

struct DateParser {
    static func findDate(in text: String) -> Date? {
        print("DEBUG: Searching for date in text: '\(text)'")
        
        var allFoundDates: [Date] = []
        
        // Coba dengan NSDataDetector untuk mengumpulkan semua tanggal
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            for match in matches {
                if let date = match.date {
                    print("DEBUG: NSDataDetector found date: \(date)")
                    allFoundDates.append(date)
                }
            }
        }
        
        // Pattern regex yang lebih lengkap
        let patterns = [
            // DD MM YYYY dengan spasi
            "\\b(\\d{1,2})\\s+(\\d{1,2})\\s+(\\d{4})\\b",
            "\\b(\\d{1,2})\\s+(\\d{1,2})\\s+(\\d{2})\\b",
            
            // DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
            "\\b(\\d{1,2})[\\/\\-\\.](\\d{1,2})[\\/\\-\\.](\\d{2,4})\\b",
            
            // DD MMM YYYY
            "\\b(\\d{1,2})\\s*(JAN|FEB|MAR|APR|MEI|MAY|JUN|JUL|AGU|AUG|SEP|OKT|OCT|NOV|DES|DEC)\\s*(\\d{2,4})\\b",
            
            // YYYY-MM-DD
            "\\b(\\d{4})[\\/\\-\\.](\\d{1,2})[\\/\\-\\.](\\d{1,2})\\b",
            
            // EXP format
            "EXP[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "BEST\\s*BEFORE[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})"
        ]
        
        for (index, pattern) in patterns.enumerated() {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                print("DEBUG: Failed to create regex for pattern \(index)")
                continue
            }
            
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches {
                let matchedString = (text as NSString).substring(with: match.range)
                print("DEBUG: Pattern \(index) matched: '\(matchedString)'")
                
                // Parse berdasarkan pattern
                if let date = parseMatchedString(matchedString, patternIndex: index) {
                    print("DEBUG: Successfully parsed date from regex: \(date)")
                    allFoundDates.append(date)
                }
            }
        }
        
        let today = Date()
        let validFutureDates = allFoundDates.filter { date in
            let year = Calendar.current.component(.year, from: date)
            return date > today && year >= 2025
        }
        
        if validFutureDates.isEmpty {
            print("DEBUG: No valid future dates found")
            return nil
        }
        
        let latestDate = validFutureDates.max()
        print("DEBUG: Selected latest date as expired date: \(String(describing: latestDate))")
        return latestDate
    }
    
    private static func parseMatchedString(_ matchedString: String, patternIndex: Int) -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        let cleanString = matchedString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch patternIndex {
        case 0, 1: // DD MM YYYY atau DD MM YY dengan spasi
            let parts = cleanString.components(separatedBy: " ").filter { !$0.isEmpty }
            guard parts.count == 3,
                  let day = Int(parts[0]),
                  let month = Int(parts[1]),
                  let year = Int(parts[2]) else {
                print("DEBUG: Failed to parse DD MM YYYY format: \(cleanString)")
                return nil
            }
            
            components.day = day
            components.month = month
            components.year = year < 100 ? year + 2000 : year
            
        case 2: // DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
            let separators = CharacterSet(charactersIn: "/-.")
            let parts = cleanString.components(separatedBy: separators).filter { !$0.isEmpty }
            guard parts.count == 3,
                  let day = Int(parts[0]),
                  let month = Int(parts[1]),
                  let year = Int(parts[2]) else {
                print("DEBUG: Failed to parse DD/MM/YYYY format: \(cleanString)")
                return nil
            }
            
            components.day = day
            components.month = month
            components.year = year < 100 ? year + 2000 : year
            
        case 3: // DD MMM YYYY
            if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
                let matches = detector.matches(in: cleanString, options: [], range: NSRange(location: 0, length: cleanString.utf16.count))
                if let firstMatch = matches.first, let date = firstMatch.date {
                    return date
                }
            }
            return nil
            
        case 4: // YYYY-MM-DD
            let separators = CharacterSet(charactersIn: "/-.")
            let parts = cleanString.components(separatedBy: separators).filter { !$0.isEmpty }
            guard parts.count == 3,
                  let year = Int(parts[0]),
                  let month = Int(parts[1]),
                  let day = Int(parts[2]) else {
                print("DEBUG: Failed to parse YYYY-MM-DD format: \(cleanString)")
                return nil
            }
            
            components.year = year
            components.month = month
            components.day = day
            
        default:
            // Untuk EXP dan BEST BEFORE, extract tanggal dari string
            let numberPattern = "\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4}"
            guard let regex = try? NSRegularExpression(pattern: numberPattern, options: []),
                  let match = regex.firstMatch(in: cleanString, options: [], range: NSRange(location: 0, length: cleanString.utf16.count)) else {
                return nil
            }
            
            let dateString = (cleanString as NSString).substring(with: match.range)
            return parseMatchedString(dateString, patternIndex: 0)
        }
        
        guard let day = components.day, day >= 1 && day <= 31,
              let month = components.month, month >= 1 && month <= 12,
              let year = components.year, year >= 2024 else {
            print("DEBUG: Invalid date components - day: \(components.day), month: \(components.month), year: \(components.year)")
            return nil
        }
        
        return calendar.date(from: components)
    }
}
