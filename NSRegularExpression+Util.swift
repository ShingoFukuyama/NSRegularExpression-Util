//
//  NSRegularExpression+Util.swift
//
//  Created by FukuyamaShingo on 3/3/16.
//  Copyright © 2016 Shingo Fukuyama. All rights reserved.
//
//  Almost importing from - bendytree/Objective-C-RegEx-Categories
//  https://github.com/bendytree/Objective-C-RegEx-Categories
//

import UIKit


struct RxMatch {
    var original:String = ""
    var value:String? = nil
    var range:NSRange? = nil
    var groups = [RxMatchGroup]()
}

struct RxMatchGroup {
    var value:String? = nil
    var range:NSRange? = nil
}


func rx(pattern: String) -> NSRegularExpression {
    return rx(pattern, caseSensitive: false)
}

func rx(pattern: String, caseSensitive: Bool) -> NSRegularExpression {
    return rx(pattern, options: caseSensitive ? NSRegularExpressionOptions(rawValue: 0) : .CaseInsensitive)
}

func rx(pattern: String, options: NSRegularExpressionOptions) -> NSRegularExpression {
    do {
        return try NSRegularExpression.init(pattern: pattern, options: options)
    }
    catch {
        assert(false, "\(__FUNCTION__)::error:\(error)")
    }
}

extension NSRegularExpression {
    
    class func rx(pattern: String) -> NSRegularExpression {
        return rx(pattern)
    }
    
    class func rx(pattern: String, caseSensitive: Bool) -> NSRegularExpression {
        return rx(pattern, caseSensitive: caseSensitive)
    }
    
    class func rx(pattern: String, options: NSRegularExpressionOptions) -> NSRegularExpression {
        return rx(pattern, options: options)
    }
    
    func rx_isMatch(text: String) -> Bool {
        return self.numberOfMatchesInString(text, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, text.characters.count)) > 0
    }
    
    func rx_indexOf(text: String) -> Int {
        let range = self.rangeOfFirstMatchInString(text, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, text.characters.count))
        return (range.location == NSNotFound) ? -1 : range.location
    }
    
    func rx_split(text: String) -> [String] {
        let range = NSMakeRange(0, text.characters.count)
        
        var matchingRanges = [NSValue]()
        let matches = self.matchesInString(text, options: NSMatchingOptions(rawValue: 0), range: range)
        for match in matches {
            matchingRanges.append(NSValue.init(range: match.range))
        }
        print("matcheeeeeees: \(matches)")
        
        var pieceRanges = [NSValue]()
        let firstRange = NSMakeRange(0, matchingRanges.count == 0 ? text.characters.count : matchingRanges.first!.rangeValue.location)
        pieceRanges.append(NSValue.init(range: firstRange))
        for i in 0..<matchingRanges.count {
            let isLast = (i + 1 == matchingRanges.count)
            let rangeValue = matchingRanges[i].rangeValue
            let startLocation = rangeValue.location + rangeValue.length
            let endLocation = isLast ? text.characters.count : matchingRanges[i + 1].rangeValue.location
            pieceRanges.append(NSValue.init(range: NSMakeRange(startLocation, endLocation - startLocation)))
        }
        
        var pieces = [String]()
        for value in pieceRanges {
            let piece = text.rx_substringWithNSRange(value.rangeValue)
            pieces.append(String( piece ) )
        }
        
        return pieces
    }
    
    func rx_replace(text: String, with replacement: String) -> String {
        return self.stringByReplacingMatchesInString(text, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, text.characters.count), withTemplate: replacement)
    }
    
    func rx_replace(text: String, withBlock handler: (String -> String?)) -> String {
        var replaced = text
        let matches = self.matchesInString(text, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, text.characters.count))
        if matches.count > 0 {
            for match in matches.reverse() {
                let matchedString = text.rx_substringWithNSRange(match.range)
                let replacement = handler(matchedString)
                if let rep = replacement {
                    replaced.rx_replaceNSRange(match.range, with: rep)
                }
            }
        }
        return replaced
    }
    
    func rx_replace(text: String, withDetailsBlock handler: (RxMatch -> String?)) -> String {
        var replaced = text
        let matches = self.matchesInString(text, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, text.characters.count))
        if matches.count > 0 {
            for result in matches.reverse() {
                let match = self.rx_resultToMatch(result, original: text)
                let replacement = handler(match)
                if let rep = replacement {
                    replaced.rx_replaceNSRange(result.range, with: rep)
                }
            }
        }
        return replaced
    }
    
    func rx_resultToMatch(result: NSTextCheckingResult, original: String) -> RxMatch {
        var match = RxMatch()
        match.original = original
        match.range = result.range
        if result.range.length > 0 {
            match.value = original.rx_substringWithNSRange(result.range)
        }
        
        var groups = [RxMatchGroup]()
        for i in 0..<result.numberOfRanges {
            var group = RxMatchGroup()
            group.range = result.rangeAtIndex(i)
            if let range = group.range {
                if range.length > 0 {
                    group.value = original.rx_substringWithNSRange(range)
                }
            }
            groups.append(group)
        }
        match.groups = groups
        return match
    }
    
    func rx_matches(text: String) -> [String] {
        var matches = [String]()
        let results = self.matchesInString(text, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, text.characters.count))
        for result in results {
            let match = text.rx_substringWithNSRange(result.range)
            matches.append(match)
        }
        return matches
    }
    
    func rx_firstMatch(text: String) -> String? {
        let match = self.firstMatchInString(text, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, text.characters.count))
        guard let result = match else {
            return nil
        }
        return text.rx_substringWithNSRange(result.range)
    }
    
    func rx_matchesWithDetails(text: String) -> [RxMatch] {
        var matches = [RxMatch]()
        let results = self.matchesInString(text, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, text.characters.count))
        for result in results {
            matches.append(self.rx_resultToMatch(result, original: text))
        }
        return matches
    }
    
    func rx_firstMatchWithDetails(text: String) -> RxMatch? {
        let results = self.matchesInString(text, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, text.characters.count))
        if let result = results.first {
            return self.rx_resultToMatch(result, original: text)
        }
        return nil
    }
    
}



extension String {
    
    func rx_toRx() -> NSRegularExpression {
        return rx(self)
    }
    
    func rx_toRx(caseSensitive: Bool) -> NSRegularExpression {
        return rx(self, caseSensitive: caseSensitive)
    }
    
    func rx_toRx(options: NSRegularExpressionOptions) -> NSRegularExpression {
        return rx(self, options: options)
    }
    
    func rx_isMatch(regex: String) -> Bool {
        return rx(regex).rx_isMatch(self)
    }
    
    func rx_indexOf(regex: String) -> Int {
        return rx(regex).rx_indexOf(self)
    }
    
    func rx_split(regex: String) -> [String] {
        return rx(regex).rx_split(self)
    }
    
    func rx_replace(regex: String, with replacement: String) -> String {
        return rx(regex).rx_replace(self, with: replacement)
    }
    
    func rx_replace(regex: String, withBlock handler: (String -> String?)) -> String {
        return rx(regex).rx_replace(self, withBlock: handler)
    }
    
    func rx_replace(regex: String, withDetailsBlock handler: (RxMatch -> String?)) -> String {
        return rx(regex).rx_replace(self, withDetailsBlock: handler)
    }
    
    func rx_matches(regex: String) -> [String] {
        return rx(regex).rx_matches(self)
    }
    
    func rx_firstMatch(regex: String) -> String? {
        return rx(regex).rx_firstMatch(self)
    }
    
    func rx_matchesWithDetails(regex: String) -> [RxMatch] {
        return rx(regex).rx_matchesWithDetails(self)
    }
    
    func rx_firstMatchWithDetails(regex: String) -> RxMatch? {
        return rx(regex).rx_firstMatchWithDetails(self)
    }
    
    /**
     *  NSRange to Range<String.Index> - stack overflow
     *  http://stackoverflow.com/questions/25138339/nsrange-to-rangestring-index
     */
    func rx_rangeFromNSRange(range: NSRange) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advancedBy(range.location, limit: utf16.endIndex)
        let to16 = from16.advancedBy(range.length, limit: utf16.endIndex)
        if let from = String.Index(from16, within: self),
                let to = String.Index(to16, within: self) {
            return from ..< to
        }
        return nil
    }
    
    func rx_NSRangeFromRange(range: Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.startIndex, within: utf16view)
        let to = String.UTF16View.Index(range.endIndex, within: utf16view)
        return NSMakeRange(utf16view.startIndex.distanceTo(from), from.distanceTo(to))
    }
    
    func rx_substringWithNSRange(range: NSRange) -> String {
        return self.substringWithRange(self.rx_rangeFromNSRange(range)!)
    }
    
    mutating func rx_replaceNSRange(range: NSRange, with: String) {
        var text = self
        text.replaceRange(self.rx_rangeFromNSRange(range)!, with: with)
        self = text
    }
    
}



