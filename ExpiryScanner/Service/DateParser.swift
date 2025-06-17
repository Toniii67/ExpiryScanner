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
        
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            for match in matches {
                if let date = match.date {
                    print("DEBUG: NSDataDetector found date: \(date)")
                    allFoundDates.append(date)
                }
            }
        }
        
        let patterns = [
            // DD MM YYYY
            "\\b(\\d{1,2})\\s+(\\d{1,2})\\s+(\\d{4})\\b",
            "\\b(\\d{1,2})\\s+(\\d{1,2})\\s+(\\d{2})\\b",
            
            // untuk "12 27"
            "\\b(\\d{1,2})\\s+(\\d{2})\\b",
            
            // DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
            "\\b(\\d{1,2})[\\/\\-\\.](\\d{1,2})[\\/\\-\\.](\\d{2,4})\\b",
            
            // DD MMM YYYY
            "\\b(\\d{1,2})\\s*(JAN|FEB|MAR|APR|MEI|MAY|JUN|JUL|AGU|AUG|SEP|OKT|OCT|NOV|DES|DEC|JANUARI|FEBRUARI|MARET|APRIL|JUNI|JULI|AGUSTUS|SEPTEMBER|OKTOBER|NOVEMBER|DESEMBER|JANUARY|FEBRUARY|MARCH|JUNE|JULY|AUGUST|OCTOBER|DECEMBER)\\s*(\\d{2,4})\\b",
            
            // YYYY-MM-DD
            "\\b(\\d{4})[\\/\\-\\.](\\d{1,2})[\\/\\-\\.](\\d{1,2})\\b",
            
            // MM/YYYY, MM-YYYY, MM.YYYY
            "\\b(\\d{1,2})[\\/\\-\\.](\\d{4})\\b",
            
            // MM/YY, MM-YY, MM.YY
            "\\b(\\d{1,2})[\\/\\-\\.](\\d{2})\\b",
            
            // MMM YYYY (nama bulan saja dengan tahun)
            "\\b(JAN|FEB|MAR|APR|MEI|MAY|JUN|JUL|AGU|AUG|SEP|OKT|OCT|NOV|DES|DEC|JANUARI|FEBRUARI|MARET|APRIL|JUNI|JULI|AGUSTUS|SEPTEMBER|OKTOBER|NOVEMBER|DESEMBER|JANUARY|FEBRUARY|MARCH|JUNE|JULY|AUGUST|OCTOBER|DECEMBER)\\s+(\\d{4})\\b",
            
            // MMM YY (nama bulan dengan tahun 2 digit)
            "\\b(JAN|FEB|MAR|APR|MEI|MAY|JUN|JUL|AGU|AUG|SEP|OKT|OCT|NOV|DES|DEC|JANUARI|FEBRUARI|MARET|APRIL|JUNI|JULI|AGUSTUS|SEPTEMBER|OKTOBER|NOVEMBER|DESEMBER|JANUARY|FEBRUARY|MARCH|JUNE|JULY|AUGUST|OCTOBER|DECEMBER)\\s+(\\d{2})\\b",
            
            // YYYY/MM, YYYY-MM, YYYY.MM
            "\\b(\\d{4})[\\/\\-\\.](\\d{1,2})\\b",
            
            // YYYY
            "\\b(\\d{4})\\b",
            
            // DDMMYYYY
            "\\b(\\d{2})(\\d{2})(\\d{4})\\b",
            
            // DDMMYY
            "\\b(\\d{2})(\\d{2})(\\d{2})\\b",
            
            // YYYYMMDD
            "\\b(\\d{4})(\\d{2})(\\d{2})\\b",
            
            // MMYYYY
            "\\b(\\d{2})(\\d{4})\\b",
            
            // MMYY
            "\\b(\\d{2})(\\d{2})\\b",
            
            // EXP format dengan berbagai variasi
            "EXP[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "EXP[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "EXP[:\\s]*(\\d{2,4})",
            "EXPIRE[SD]?[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "EXPIRE[SD]?[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            
            // BEST BEFORE
            "BEST\\s*BEFORE[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "BEST\\s*BEFORE[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "BEST\\s*BY[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "BEST\\s*BY[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            
            // USE BY
            "USE\\s*BY[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "USE\\s*BY[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "USE\\s*BEFORE[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "USE\\s*BEFORE[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            
            // BBE format
            "BBE[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "BBE[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            
            // ED format
            "ED[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "ED[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            
            // Tanggal dalam format Indonesia
            "TGL[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "TANGGAL[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "KADALUARSA[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "KADALUARSA[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            
            // Format dengan kata keterangan
            "VALID\\s*UNTIL[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "VALID\\s*UNTIL[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "VALID\\s*THRU[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            "VALID\\s*THRU[:\\s]*(\\d{1,2}[\\/\\-\\.\\s]\\d{2,4})",
            
            // Format dengan angka Romawi untuk bulan
            "\\b(\\d{1,2})[\\/\\-\\.\\s](I|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII)[\\/\\-\\.\\s](\\d{2,4})\\b",
            
            // Format dengan ordinal numbers
            "\\b(\\d{1,2})(ST|ND|RD|TH)\\s+(JAN|FEB|MAR|APR|MEI|MAY|JUN|JUL|AGU|AUG|SEP|OKT|OCT|NOV|DEC)\\s+(\\d{2,4})\\b",
            
            // YYDDD
            "\\b(\\d{2})(\\d{3})\\b",
            
            // Format dengan week number
            "\\b(\\d{4})W(\\d{1,2})\\b",
            "WEEK\\s*(\\d{1,2})\\s*(\\d{4})",
            
            // Format dengan quarter
            "Q(\\d)\\s*(\\d{4})",
            "(\\d{4})Q(\\d)",
            
            // Format dengan slash berbeda
            "\\b(\\d{1,2})\\\\(\\d{1,2})\\\\(\\d{2,4})\\b",
            
            // Format dengan titik dua
            "\\b(\\d{1,2}):(\\d{1,2}):(\\d{2,4})\\b",
            
            // Format dengan spasi lebih banyak
            "\\b(\\d{1,2})\\s{2,}(\\d{1,2})\\s{2,}(\\d{2,4})\\b"
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
        // Filter yang lebih longgar, tidak terlalu ketat pada tahun
        let validFutureDates = allFoundDates.filter { date in
            let year = Calendar.current.component(.year, from: date)
            let isFuture = date > today
            let isReasonableYear = year >= 2025 && year <= 2050
            print("DEBUG: Checking date \(date) - Future: \(isFuture), Year: \(year), Valid: \(isReasonableYear)")
            return isFuture && isReasonableYear
        }
        
        if validFutureDates.isEmpty {
            print("DEBUG: No valid future dates found")
            // Coba dengan filter yang lebih longgar
            let fallbackDates = allFoundDates.filter { date in
                date > today
            }
            if !fallbackDates.isEmpty {
                let selectedDate = fallbackDates.min() // Ambil yang terdekat
                print("DEBUG: Using fallback date: \(String(describing: selectedDate))")
                return selectedDate
            }
            return nil
        }
        
        let sortedDates = validFutureDates.sorted()
        let selectedDate = sortedDates.first
        
        print("DEBUG: All valid future dates: \(validFutureDates)")
        print("DEBUG: Selected earliest future date: \(String(describing: selectedDate))")
        return selectedDate
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
            
        case 2: // MM YY
            let parts = cleanString.components(separatedBy: " ").filter { !$0.isEmpty }
            guard parts.count == 2,
                  let month = Int(parts[0]),
                  let year = Int(parts[1]),
                  month >= 1 && month <= 12 else {
                print("DEBUG: Failed to parse MM YY format: \(cleanString)")
                return nil
            }
            
            components.month = month
            components.year = year + 2000
            components.day = 1 // Set to first day of the month
            
        case 3: // DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY (index berubah karena ada pattern baru)
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
            
        case 4: // DD MMM YYYY (index berubah)
            return parseNamedMonthDate(cleanString)
            
        case 5: // YYYY-MM-DD (index berubah)
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
            
        case 6: // MM/YYYY (index berubah)
            let separators = CharacterSet(charactersIn: "/-.")
            let parts = cleanString.components(separatedBy: separators).filter { !$0.isEmpty }
            guard parts.count == 2,
                  let month = Int(parts[0]),
                  let year = Int(parts[1]),
                  month >= 1 && month <= 12 else {
                print("DEBUG: Failed to parse MM/YYYY format: \(cleanString)")
                return nil
            }
            
            components.month = month
            components.year = year
            components.day = 1 // Set to first day of the month
            
        case 7: // MM/YY (index berubah)
            let separators = CharacterSet(charactersIn: "/-.")
            let parts = cleanString.components(separatedBy: separators).filter { !$0.isEmpty }
            guard parts.count == 2,
                  let month = Int(parts[0]),
                  let year = Int(parts[1]),
                  month >= 1 && month <= 12 else {
                print("DEBUG: Failed to parse MM/YY format: \(cleanString)")
                return nil
            }
            
            components.month = month
            components.year = year + 2000
            components.day = 1 // Set to first day of the month
            
        case 8: // MMM YYYY (index berubah)
            return parseNamedMonthDate(cleanString)
            
        case 9: // MMM YY (index berubah)
            return parseNamedMonthDate(cleanString)
            
        case 10: // YYYY/MM (index berubah)
            let separators = CharacterSet(charactersIn: "/-.")
            let parts = cleanString.components(separatedBy: separators).filter { !$0.isEmpty }
            guard parts.count == 2,
                  let year = Int(parts[0]),
                  let month = Int(parts[1]),
                  month >= 1 && month <= 12 else {
                print("DEBUG: Failed to parse YYYY/MM format: \(cleanString)")
                return nil
            }
            
            components.year = year
            components.month = month
            components.day = 1
            
        case 11:
            guard let year = Int(cleanString),
                  year >= 2024 && year <= 2050 else {
                print("DEBUG: Invalid year for YYYY format: \(cleanString)")
                return nil
            }
            components.year = year
            components.month = 1
            components.day = 1
            
        default:
            let extractedDate = extractDateFromLabeledString(cleanString)
            return extractedDate
        }
        
        guard let day = components.day, day >= 1 && day <= 31,
              let month = components.month, month >= 1 && month <= 12,
              let year = components.year, year >= 2024 else {
            print("DEBUG: Invalid date components - day: \(components.day), month: \(components.month), year: \(components.year)")
            return nil
        }
        
        return calendar.date(from: components)
    }
    
    private static func parseNamedMonthDate(_ dateString: String) -> Date? {
        print("DEBUG: Parsing named month date: '\(dateString)'")
        
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            let matches = detector.matches(in: dateString, options: [], range: NSRange(location: 0, length: dateString.utf16.count))
            if let firstMatch = matches.first, let date = firstMatch.date {
                print("DEBUG: NSDataDetector parsed: \(date)")
                return date
            }
        }
        
        let monthMappingIndonesia = [
            "JANUARI": 1, "FEBRUARI": 2, "MARET": 3, "APRIL": 4, "MEI": 5, "JUNI": 6,
            "JULI": 7, "AGUSTUS": 8, "SEPTEMBER": 9, "OKTOBER": 10, "NOVEMBER": 11, "DESEMBER": 12,
            "JAN": 1, "FEB": 2, "MAR": 3, "APR": 4, "MAY": 5, "JUN": 6, "JUL": 7,
            "AGU": 8, "SEP": 9, "OKT": 10, "NOV": 11, "DES": 12, "AUG": 8, "OCT": 10, "DEC": 12
        ]
        
        let parts = dateString.uppercased().components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { !$0.isEmpty }
        print("DEBUG: Split parts: \(parts)")
        
        var month: Int?
        var year: Int?
        var day: Int?
        
        // Find month name
        for part in parts {
            if let foundMonth = monthMappingIndonesia[part] {
                month = foundMonth
                print("DEBUG: Found month: \(part) = \(foundMonth)")
                break
            }
        }
        
        let numbers = parts.compactMap { Int($0) }.filter { $0 > 0 }
        print("DEBUG: Found numbers: \(numbers)")
        
        for number in numbers {
            if number >= 24 && number <= 99 {
                year = number + 2000
                print("DEBUG: Found 2-digit year: \(number) -> \(year!)")
            } else if number >= 2024 && number <= 2050 {
                year = number
                print("DEBUG: Found 4-digit year: \(year!)")
            } else if number >= 1 && number <= 31 && day == nil {
                day = number
                print("DEBUG: Found day: \(day!)")
            }
        }
        
        guard let foundMonth = month else {
            print("DEBUG: No month found")
            return nil
        }
        
        var components = DateComponents()
        components.month = foundMonth
        
        if let foundYear = year {
            components.year = foundYear
        } else {
            let currentMonth = Calendar.current.component(.month, from: Date())
            let currentYear = Calendar.current.component(.year, from: Date())
            components.year = foundMonth < currentMonth ? currentYear + 1 : currentYear
            print("DEBUG: Using inferred year: \(components.year!)")
        }
        
        if let foundDay = day {
            components.day = foundDay
        } else {
            components.day = 1 // Set to first day of the month
            print("DEBUG: Using first day of month: \(components.day!)")
        }
        
        let result = Calendar.current.date(from: components)
        print("DEBUG: Final parsed date: \(String(describing: result))")
        return result
    }
    
    private static func extractDateFromLabeledString(_ labeledString: String) -> Date? {
        print("DEBUG: Extracting date from labeled string: '\(labeledString)'")
        
        let mmYYPattern = "\\b(\\d{1,2})\\s+(\\d{2})\\b"
        if let regex = try? NSRegularExpression(pattern: mmYYPattern, options: []),
           let match = regex.firstMatch(in: labeledString, options: [], range: NSRange(location: 0, length: labeledString.utf16.count)) {
            
            let fullMatch = (labeledString as NSString).substring(with: match.range)
            let parts = fullMatch.components(separatedBy: " ").filter { !$0.isEmpty }
            
            if parts.count == 2,
               let month = Int(parts[0]),
               let year = Int(parts[1]),
               month >= 1 && month <= 12 {
                
                print("DEBUG: Found MM YY pattern: \(month)/20\(year)")
                
                var components = DateComponents()
                components.month = month
                components.year = year + 2000
                components.day = 1 // Set to first day of the month
                
                return Calendar.current.date(from: components)
            }
        }
        
        let mmYYYYPattern = "\\b(\\d{1,2})\\s+(\\d{4})\\b"
        if let regex = try? NSRegularExpression(pattern: mmYYYYPattern, options: []),
           let match = regex.firstMatch(in: labeledString, options: [], range: NSRange(location: 0, length: labeledString.utf16.count)) {
            
            let fullMatch = (labeledString as NSString).substring(with: match.range)
            let parts = fullMatch.components(separatedBy: " ").filter { !$0.isEmpty }
            
            if parts.count == 2,
               let month = Int(parts[0]),
               let year = Int(parts[1]),
               month >= 1 && month <= 12 {
                
                print("DEBUG: Found MM YYYY pattern: \(month)/\(year)")
                
                var components = DateComponents()
                components.month = month
                components.year = year
                components.day = 1 // Set to first day of the month
                
                return Calendar.current.date(from: components)
            }
        }
        
        let numberPattern = "\\d{1,2}[\\/\\-\\.\\s]\\d{1,2}[\\/\\-\\.\\s]\\d{2,4}|\\d{1,2}[\\/\\-\\.\\s]\\d{2,4}"
        
        guard let regex = try? NSRegularExpression(pattern: numberPattern, options: []),
              let match = regex.firstMatch(in: labeledString, options: [], range: NSRange(location: 0, length: labeledString.utf16.count)) else {
            return nil
        }
        
        let dateString = (labeledString as NSString).substring(with: match.range)
        print("DEBUG: Extracted date string: '\(dateString)'")
        
        if dateString.contains("/") || dateString.contains("-") || dateString.contains(".") {
            return parseMatchedString(dateString, patternIndex: 3)
        }
        
        return nil
    }
}
