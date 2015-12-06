// Copyright 2015-2016 BigML
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License. You may obtain
// a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

import Foundation

func delay(delay:Double, closure:()->()) {
    
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

struct AnyKey: Hashable, Comparable {
    
    let underlying: Any
    private let hashValueFunc: () -> Int
    private let equalityFunc: (Any) -> Bool
    private let compareFunc: (Any) -> Bool
    
    init<T where T:Hashable, T:Comparable>(_ key: T) {
        underlying = key
        //-- Capture the key's hashability and equatability using closures.
        //-- The Key shares the hash of the underlying value.
        hashValueFunc = { key.hashValue }
        
        //-- The Key is equal to a Key of the same underlying type,
        //-- whose underlying value is "==" to ours.
        equalityFunc = {
            if let other = $0 as? T {
                return key == other
            }
            return false
        }
        
        compareFunc = {
            if let other = $0 as? T {
                return key < other
            }
            return false
        }
    }
    
    var hashValue: Int { return hashValueFunc() }
}

func ==(lhs: AnyKey, rhs: AnyKey) -> Bool {
    return lhs.equalityFunc(rhs.underlying)
}

func < (lhs: AnyKey, rhs: AnyKey) -> Bool {
    return lhs.compareFunc(rhs.underlying)
}

/**
* We convert the Array to a dictionary for ease of manipulation
*
* @param distribution current distribution as an array
* @return the distribution as a dictionary
*/
//func distributionDictionary(distributionArray : [(value : AnyObject, dist : Int)])
//    -> [AnyObject : Int] {
//        
//        var dict : NSDictionary = NSMutableDictionary()
//        for distValue in distributionArray {
//            dict.updateValue(distValue.dist, forKey:distValue.value)
//        }
//        return dict
//}

/**
* Convert a dictionary to an array. Dual of dictionaryFromDistributionArray:
*
* @param distribution current distribution as an NSDictionary
* @return the distribution as an NSArray
*/
//func distributionArray(distributionDictionary : [AnyObject : Int])
//    -> [(value : AnyObject, dist : Int)] {
//        
//        let a = distributionDictionary.sort({ $0.0 < $1.0 })
//        return a.map {
//            ($0.0, $0.1)
//        }
//}

/**
* Adds up a new distribution structure to a map formatted distribution
*
* @param dist1
* @param dist2
* @return
*/
func mergeDistributions(distribution1 : [(value : Double, dist : Int)],
    distribution : [(value : Double, dist : Int)])
    -> [(value : Double, dist : Int)] {
        
        var d1 = distribution1.sort({ $0.0 < $1.0 })
        let d2 = distribution.sort({ $0.0 < $1.0 })
        
        for var i = 0, j = 0; i < d1.count && j < d2.count; ++i {
            while (d1[i].0 > d2[j].0) {
                ++j
            }
            if (d1[i].0 == d2[j].0) {
                d1[i].1 += d2[j].1
            }
        }
        return d1
}

/**
* Adds up a new distribution structure to an array formatted distribution
*
* @param dist1
* @param dist2
* @return
*/
func mergeDistributions(distribution1 : [(value : AnyObject, dist : Int)],
    distribution : [(value : AnyObject, dist : Int)])
    -> [(value : AnyObject, dist : Int)] {
        
        if let _ = distribution1.first?.0 as? Double,
            _ = distribution.first?.0 as? Double {
                
                return mergeDistributions(distribution1.map { ($0.0 as? Double ?? Double.NaN, $0.1) },
                    distribution: distribution.map { ($0.0 as? Double ?? Double.NaN, $0.1) })
        }
        return mergeDistributions(distribution1.map { ($0.0 as? String ?? "", $0.1) },
            distribution: distribution.map { ($0.0 as? String ?? "", $0.1) })
}

/**
* Merges the bins of a regression distribution to the given limit number.
* Two methods are provided: a generic one which is only required for compilation,
* and a Double-tailored version. The generic version simply asserts.
*/
func mergeBins(distribution : [(value : AnyObject, dist : Int)], limit : Int)
    -> [(value : AnyObject, dist : Int)] {
    
    let length = distribution.count
    if (limit < 1 || length <= limit || length < 2) {
        return distribution
    }
    var indexToMerge = 2
    var shortest = DBL_MAX
    for var i = 1; i < length; ++i {
        let distance = (distribution[i].0 as? Double ?? Double.NaN) -
            (distribution[i-1].0 as? Double ?? Double.NaN)
        if distance < shortest {
            shortest = distance
            indexToMerge = i
        }
    }
    var newDistribution = Array<(value : AnyObject, dist : Int)>(distribution[0...indexToMerge-1])
    let left = distribution[indexToMerge - 1]
    let right = distribution[indexToMerge]
    let f1 = (left.0 as? Double ?? Double.NaN) * (Double(left.1) ?? Double.NaN) +
        (right.0 as? Double ?? Double.NaN) * (Double(right.1) ?? Double.NaN)
    let f2 = left.1 * right.1
    newDistribution.append((f1 / (Double(f2) ?? Double.NaN), f2))
    if (indexToMerge < length - 1) {
        newDistribution += distribution[indexToMerge + 1 ... distribution.count - 1]
    }
    return mergeBins(newDistribution, limit: limit)
}

/**
* Computes the mean of a distribution
*
* @param distribution
* @return
*/
func meanOfDistribution(distribution : [(value: Double, dist: Int)]) -> Double {
    
    let (acc, count) = distribution.reduce((0.0, 0)) {
        ($1.0 * (Double($1.1) ?? Double.NaN), $0.1 + $1.1)
    }
    return acc / (Double(count) ?? Double.NaN)
}

func meanOfDistribution(distribution : [(value: AnyObject, dist: Int)]) -> Double {
    
    return meanOfDistribution(
        distribution.map { ($0.0 as? Double ?? Double.NaN, $0.1) })
}

func regressionError(variance : Double, instances : Int, rz : Double) -> Double {

    assert(false, "Not implemented Yet (Missing strategy MissingStrategyProportional not supported)")
    return Double.NaN
}

func varianceOfDistribution(distribution : [(value: Double, dist: Int)], mean : Double)
    -> Double {
    
    let (acc, count) = distribution.reduce((0.0, 0)) {
        (($1.0 - mean) * ($1.0 - mean) * (Double($1.1) ?? Double.NaN), $0.1 + $1.1)
    }
    return acc / (Double(count) ?? Double.NaN)
}

func varianceOfDistribution(distribution : [(value: AnyObject, dist: Int)], mean : Double)
    -> Double {
    
        return varianceOfDistribution(
            distribution.map { ($0.0 as? Double ?? Double.NaN, $0.1) },
            mean: mean)
}

func medianOfDistribution(distribution : [(value: Double, dist: Int)], instances : Int) -> Double {
 
    var count = 0
    var previousPoint = Double.NaN
    for bin in distribution {
        let point = bin.0
        count += bin.1
        if count > instances / 2 {
            if (instances % 2 != 0) && (count-1 == instances/2) && previousPoint != Double.NaN {
                return (point + previousPoint) / 2
            }
            return point
        }
        previousPoint = point
    }
    return Double.NaN
}

func medianOfDistribution(distribution : [(value: AnyObject, dist: Int)], instances : Int) -> Double {

    return medianOfDistribution(
        distribution.map { ($0.0 as? Double ?? Double.NaN, $0.1) },
        instances: instances)
}

func strippedValue(value : String, field : [String : AnyObject]) -> String {
    
    var newValue = value
    if let prefix = field["prefix"] as? String {
        if (newValue.hasPrefix(prefix)) {
            newValue.removeRange(newValue.startIndex ..<
                newValue.startIndex.advancedBy(prefix.characters.count))
        }
    }
    if let suffix = field["suffix"] as? String {
        if (newValue.hasSuffix(suffix)) {
            newValue.removeRange(newValue.endIndex.advancedBy(-suffix.characters.count) ..<
                newValue.endIndex)
        }
    }
    return newValue
}

func castArguments(arguments : [String : AnyObject], fields : [String : AnyObject])
    -> [String : AnyObject] {

        return arguments.map { (key, value) in
            let field = fields[key] as? [String : AnyObject] ?? [:]
            if let opType = field["optype"] as? String {
                if opType == "numeric" && value is String {
                    return (key, strippedValue(value as! String, field: field))
                }
            }
            return (key, value)
        }
}

func findInDistribution(distribution : [(value : AnyObject, dist : Int)],
    element : AnyObject) -> (value : AnyObject, dist : Int)? {
        
        for distElement in distribution {
            if distElement.0 as? String == element as? String {
                return distElement
            }
        }
        return nil
}

func wsConfidence(prediction : AnyObject,
    distribution : [(value : AnyObject, dist : Int)],
    n : Int,
    z : Double = 1.96) -> Double {
        
        var p = Double.NaN
        if let v = findInDistribution(distribution, element: prediction) {
            p = Double(v.dist) ?? Double.NaN
        }
        assert (!p.isNaN && p > 0)
        
        let norm = Double(distribution.reduce(0) { $0 + $1.dist }) ?? Double.NaN
        if norm != 1.0 {
            p /= norm
        }
        let n = Double(n) ?? Double.NaN
        let z2 = z * z
        let wsFactor = z2 / n
        let wsSqrt = sqrt((p * (1 - p) + wsFactor / 4) / n)
        return (p + wsFactor / 2 - z * wsSqrt) / (1 + wsFactor)
}

func wsConfidence(prediction : AnyObject,
    distribution : [(value : AnyObject, dist : Int)]) -> Double {
        
        return wsConfidence(prediction, distribution: distribution,
            n: distribution.reduce(0) { $0 + $1.dist })
}

func compareDoubles(d1 : Double, d2 : Double, eps : Double = 0.01) -> Bool {
    return ((d1 - eps) < d2) && ((d1 + eps) > d2)
}

extension String {
    
    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
        let to16 = from16.advancedBy(nsRange.length, limit: utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
                return from ..< to
        }
        return nil
    }

    func NSRangeFromRange(range : Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.startIndex, within: utf16view)
        let to = String.UTF16View.Index(range.endIndex, within: utf16view)
        return NSMakeRange(utf16view.startIndex.distanceTo(from), from.distanceTo(to))
    }
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
        return Dictionary<Key, U>(self.map({ (key, value) in (key, transform(value)) }))
    }
    
    func map<T : Hashable, U>(transform: (Key, Value) -> (T, U)) -> [T : U] {
        return Dictionary<T, U>(self.map(transform))
    }
    
    func filter(includeElement: Element -> Bool) -> [Key : Value] {
        return Dictionary(self.filter(includeElement))
    }
    
    func reduce<U>(initial: U, @noescape combine: (U, Element) -> U) -> U {
        return self.reduce(initial, combine: combine)
    }
}

class BMLRegex {
    
    let internalExpression: NSRegularExpression
    let pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern
        do {
            self.internalExpression = try NSRegularExpression(pattern: pattern,
                options: .CaseInsensitive)
        } catch {
            self.internalExpression = try! NSRegularExpression(pattern: "^$",
                options: .CaseInsensitive)
        }
    }
    
    func matches(input: String) -> [NSTextCheckingResult] {
        return self.internalExpression.matchesInString(input,
            options: [],
            range:NSMakeRange(0, input.characters.count))
    }

    func test(input: String) -> Bool {
        return self.matches(input).count > 0
    }

    func matchCount(input: String) -> Int {
        return self.matches(input).count
    }
}

infix operator =~ { associativity left precedence 160 }
func =~ (input: String, pattern: String) -> [NSTextCheckingResult] {
    return BMLRegex(pattern).matches(input)
}

infix operator =~? { associativity left precedence 160 }
func =~? (input: String, pattern: String) -> Bool {
    return BMLRegex(pattern).test(input)
}

infix operator =~~ { associativity left precedence 160 }
func =~~ (input: String, pattern: String) -> Int {
    return BMLRegex(pattern).matchCount(input)
}

// MARK: some

infix operator %% { associativity left precedence 160 }
func %%<T: Equatable> (input: Array<T>, exp: (T) -> Bool) -> Bool {
    for t in input {
        if exp(t) {
            return true
        }
    }
    return false
}
