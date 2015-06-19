//
//  Utils.swift
//  BigMLX
//
//  Created by sergio on 19/06/15.
//  Copyright (c) 2015 sergio. All rights reserved.
//

import Foundation

func delay(delay:Double, closure:()->()) {
    
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

extension NSError {
    
    struct BMLExtendedError {
        static let DescriptionKey = "BMLExtendedErrorDescriptionKey"
    }
    
    convenience init(status : AnyObject?, code : Int) {
        
        var info = "Could not complete operation"
        var extraInfo : [String : AnyObject] = [:]
        if let statusDict = status as? [String : AnyObject] {
            if let message = statusDict["message"] as? String {
                info = message
            }
            if let extra = statusDict["extra"] as? [String : AnyObject] {
                extraInfo = extra
            }
        } else {
            info = "Bad response format"
        }
        self.init(info: info, code: code, message: extraInfo)
    }
    
    convenience init(info : String, code : Int) {
        self.init(info: info, code: code, message: [:])
    }
    
    convenience init(info : String, code : Int, message : [String : AnyObject]) {
        let userInfo = [
            NSLocalizedDescriptionKey : info,
            NSError.BMLExtendedError.DescriptionKey : message
            ] as [NSObject : AnyObject]
        self.init(domain: "com.bigml.bigmlkitconnector", code: code, userInfo: userInfo)
    }
    
}

extension NSMutableData {
    
    func appendString(string: String) {
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
            self.appendData(data)
        }
    }
}

extension Dictionary {
    init(_ elements: [Element]){
        self.init()
        for (k, v) in elements {
            self[k] = v
        }
    }
    
    func map<U>(transform: Value -> U) -> [Key : U] {
        return Dictionary<Key, U>(Swift.map(self, { (key, value) in (key, transform(value)) }))
    }
    
    func map<T : Hashable, U>(transform: (Key, Value) -> (T, U)) -> [T : U] {
        return Dictionary<T, U>(Swift.map(self, transform))
    }
    
    func filter(includeElement: Element -> Bool) -> [Key : Value] {
        return Dictionary(Swift.filter(self, includeElement))
    }
    
    func reduce<U>(initial: U, @noescape combine: (U, Element) -> U) -> U {
        return Swift.reduce(self, initial, combine)
    }
}

class BMLRegex {
    
    let internalExpression: NSRegularExpression?
    let pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern
        var error: NSError?
        self.internalExpression = NSRegularExpression(pattern: pattern, options: .CaseInsensitive, error: &error)
    }
    
    func test(input: String) -> Bool {
        let matches = self.internalExpression?.matchesInString(input, options: nil, range:NSMakeRange(0, count(input)))
        return matches?.count > 0
    }
}

infix operator =~ { associativity left precedence 160 }
func =~ (input: String, pattern: String) -> Bool {
    return BMLRegex(pattern).test(input)
}
