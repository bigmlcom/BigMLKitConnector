//
//  BMLConnector.swift
//  BigMLKitConnector
//
//  Created by sergio on 28/04/15.
//  Copyright (c) 2015 BigML Inc. All rights reserved.
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
    
    convenience init(code: Int, message: String) {
        self.init(domain: "BigMLKitConnector", code: code, userInfo: ["message" : message])
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

@objc public enum BMLMode : Int {

    case Development
    case Production
}

@objc public enum BMLResourceType : Int, StringLiteralConvertible {
    
    case File
    case Source
    case Dataset
    case Model
    case Cluster
    case Anomaly
    case Ensemble
    case Prediction
    case Project
    case NotAResource
    
    static let all = [File, Source, Dataset, Model, Cluster, Anomaly, Prediction, Project]

    public init(stringLiteral value: String) {
        switch (value) {
        case "file":
            self = File
        case "source":
            self = Source
        case "dataset":
            self = Dataset
        case "model":
            self = Model
        case "cluster":
            self = Cluster
        case "Prediction":
            self = Prediction
        case "anomaly":
            self = Anomaly
        case "ensemble":
            self = Ensemble
        case "project":
            self = Project
        default:
            self = NotAResource
        }
    }
    
    public init(_ value: String) {
        self.init(stringLiteral: value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self = BMLResourceType(value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        self = BMLResourceType(value)
    }

    public func stringValue() -> String {
        switch (self) {
        case File:
            return "file"
        case Source:
            return "source"
        case Dataset:
            return "dataset"
        case Model:
            return "model"
        case Cluster:
            return "cluster"
        case Prediction:
            return "prediction"
        case Anomaly:
            return "anomaly"
        case Ensemble:
            return "anomaly"
        case Project:
            return "project"
        default:
            return "invalid"
        }
    }
}

@objc public class BMLResourceTypeIdentifier : NSObject, NSCopying, StringLiteralConvertible, Printable {

    public var type : BMLResourceType
    
    public override var description: String {
        return self.stringValue()
    }

    public required init(rawType value: BMLResourceType) {
        self.type = value
        super.init()
    }
    
    public required init(stringLiteral value: String) {
        self.type = BMLResourceType(stringLiteral: value)
        super.init()
    }
    
    public convenience init(_ value: String) {
        self.init(stringLiteral: value)
    }
    
    public required init(extendedGraphemeClusterLiteral value: String) {
        self.type = BMLResourceType(value)
        super.init()
    }
    
    public required init(unicodeScalarLiteral value: String) {
        self.type = BMLResourceType(value)
        super.init()
    }
    
    public func stringValue() -> String {
        return self.type.stringValue()
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return BMLResourceTypeIdentifier(rawType: self.type)
    }
}

public func == (left : BMLResourceTypeIdentifier, right : BMLResourceType) -> Bool {
    return left.type == right
}

public func != (left : BMLResourceTypeIdentifier, right : BMLResourceType) -> Bool {
    return left.type != right
}

public typealias BMLResourceUuid = String
public typealias BMLResourceFullUuid = String

/**
The following values must match those at https://bigml.com/developers/status_codes
Not all values are necessarily to be represented.
**/
@objc public enum BMLResourceStatus : Int, IntegerLiteralConvertible {
    
    case Undefined = 1000
    case Waiting = 0
    case Queued = 1
    case Started = 2
    case InProgress = 3
    case Summarized = 4
    case Ended = 5
    case Failed = -1
    case Unknown = -2
    case Runnable = -3
    
    public init(integerLiteral value: IntegerLiteralType) {
        switch(value) {
        case 1000:
            self = .Undefined
        case 0:
            self = .Waiting
        case 1:
            self = .Queued
        case 2:
            self = .Started
        case 3:
            self = .InProgress
        case 4:
            self = .Summarized
        case 5:
            self = .Ended
        case -1:
            self = .Failed
        case -2:
            self = .Unknown
        case -3:
            self = .Runnable
        default:
            self = .Undefined
        }
    }
}

func < (left : BMLResourceStatus, right : BMLResourceStatus) -> Bool {
    return left.rawValue < right.rawValue
}
func != (left : BMLResourceStatus, right : BMLResourceStatus) -> Bool {
    return left.rawValue != right.rawValue
}

@objc public protocol BMLResource {
    
    var name : String  { get }
    var type : BMLResourceType  { get }
    var uuid : BMLResourceUuid { get }
    var fullUuid : BMLResourceFullUuid { get }
    
    var jsonDefinition : [String : AnyObject] { get set }
    
    var status : BMLResourceStatus { get set }
    var progress : Float { get set }
    
    init(name: String, type: BMLResourceType, uuid: String)
}

public class BMLMinimalResource : NSObject, BMLResource {
    
    public var name : String
    public var type : BMLResourceType
    
    public var jsonDefinition : [String : AnyObject]

    public dynamic var status : BMLResourceStatus
    public dynamic var progress : Float
    
    public var uuid : BMLResourceUuid
    public var fullUuid : BMLResourceFullUuid {
        get {
            return "\(type.stringValue())/\(uuid)"
        }
    }
    
    public required init(name: String, type: BMLResourceType, uuid: String) {
        
        self.name = name
        self.type = type
        self.uuid = uuid
        self.status = BMLResourceStatus.Undefined
        self.progress = 0.0
        self.jsonDefinition = [:];
    }
    
   
    public required init(name: String, rawType: BMLResourceType, uuid: String) {
        
        self.name = name
        self.type = rawType
        self.uuid = uuid
        self.status = BMLResourceStatus.Undefined
        self.progress = 0.0
        self.jsonDefinition = [:];
    }
    
    public required init(name : String, fullUuid : String, definition : [String : AnyObject]) {
        
        let components = split(fullUuid) {$0 == "/"}
        self.name = name
        self.type = BMLResourceType(stringLiteral: components[0])
        self.uuid = components[1]
        self.status = BMLResourceStatus.Undefined
        self.progress = 0.0
        self.jsonDefinition = definition;
    }
}

public class BMLConnector : NSObject {
    
    let username : String
    let apiKey : String
    let mode : BMLMode
    let authToken : String
    
    lazy var session: NSURLSession = self.initializeSession()
    
    public init(username: String, apiKey: String, mode:BMLMode) {
        
        self.username = username
        self.apiKey = apiKey
        self.mode = mode
        self.authToken = "username=\(username);api_key=\(apiKey);"
        
        super.init()
    }
    
    func initializeSession() -> NSURLSession {
        
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        configuration.HTTPAdditionalHeaders = [ "Content-Type": "application/json" ];

        return NSURLSession(configuration : configuration)
    }
    
    func optionsToString(options : [String : String]) {
        
        var result = ""
        for (key, value) in options {
            if (count(value) > 0) {
                let trimmedOption = value.substringWithRange(Range<String.Index>(start: advance(value.startIndex, 1), end: advance(value.endIndex, -1)))
                result = "\(result), \(trimmedOption)"
            }
        }
    }
    
    func dataWithRequest(request : NSURLRequest, completion:(data : NSData!, error : NSError!) -> Void) {
        
        let task = self.session.dataTaskWithRequest(request) { (data : NSData!, response : NSURLResponse!, error : NSError!) in
            var localError : NSError? = error;
            if (error == nil) {
                if let response = response as? NSHTTPURLResponse {
                } else {
                    localError = NSError(code:-10001, message:"Bad response format")
                }
            }
            var result = []
            completion(data: data, error: localError)
        }
        task.resume()
    }
    
    func delete(url : NSURL, completion:(error : NSError?) -> Void) {
        
        let request = NSMutableURLRequest(URL:url)
        request.HTTPMethod = "DELETE";
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        self.dataWithRequest(request) { (data, error) in
            
            var localError : NSError? = error;
            if (localError == nil) {
                let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments, error:nil)
                if let jsonDict = jsonObject as? [String : AnyObject],
                    status = jsonDict["status"] as? [String : AnyObject],
                    code = status["code"] as? Int {
                        if (code != 204) {
                            localError = NSError(code: code, message: status.description)
                        }
                }
            }
            completion(error: localError)
        }
    }
    
    func put(url : NSURL, body : [String : AnyObject], completion:(error : NSError?) -> Void) {
        
        var localError : NSError? = nil
        if let bodyData = NSJSONSerialization.dataWithJSONObject(body, options: nil, error:&localError) {
            let request = NSMutableURLRequest(URL:url)
            request.HTTPBody = bodyData
            request.HTTPMethod = "PUT";
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            self.dataWithRequest(request) { (data, error) in
                
                var localError : NSError? = error;
                if (error == nil) {
                    let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments, error:nil)
                    if let jsonDict = jsonObject as? [String : AnyObject],
                        status = jsonDict["status"] as? [String : AnyObject],
                        code = jsonDict["code"] as? Int {
                            if (code != 202) {
                                localError = NSError(code: code, message: status.description)
                            }
                    }
                }
                completion(error: localError)
            }
        } else {
            completion(error: localError)
        }
    }
    
    func get(url : NSURL, completion:(jsonObject : AnyObject?, error : NSError?) -> Void) {
        
        self.dataWithRequest(NSMutableURLRequest(URL:url)) { (data, error) in
            
            var localError : NSError? = error;
            var jsonObject : AnyObject?
            if (error == nil) {
                jsonObject = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments, error:&localError)
            }
            completion(jsonObject: jsonObject, error: localError)
        }
    }
    
    func post(url : NSURL, body: [String : AnyObject], completion:(result : [String : AnyObject], error : NSError?) -> Void) {
        
        var localError : NSError? = nil
        if let bodyData = NSJSONSerialization.dataWithJSONObject(body, options: nil, error:&localError) {
            let request = NSMutableURLRequest(URL:url)
            request.HTTPBody = bodyData
            request.HTTPMethod = "POST";
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            
            self.dataWithRequest(request) { (data, error) in
                
                var localError : NSError? = error;
                var result = ["" : "" as AnyObject]
                if (error == nil) {
                    
                    let jsonObject : AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments, error:&localError)
                    if let jsonDict = jsonObject as? [String : AnyObject], code = jsonDict["code"] as? Int {
                        result = jsonDict
                        if (code != 201) {
                            localError = NSError(code: code, message: jsonDict["status"]!.description)
                        }
                    } else {
                        localError = NSError(code:-10001, message:"Bad response format")
                    }
                }
                completion(result: result, error: localError)
            }
        } else {
            completion(result: [:], error: localError)
        }
    }
    
    func upload(url : NSURL, filename: String, filePath: String, body: [String : AnyObject], completion:(result : [String : AnyObject], error : NSError?) -> Void) {
        
        let request = NSMutableURLRequest(URL:url)
        let boundary = "---------------------------14737809831466499882746641449"

        var error : NSError? = nil
        let bodyData : NSMutableData = NSMutableData()
        for (name, value) in body {
            if let fieldData = NSJSONSerialization.dataWithJSONObject(value, options: nil, error:&error) {
                if let value = NSString(data: fieldData, encoding:NSUTF8StringEncoding) {
                    bodyData.appendString("\r\n--\(boundary)\r\n")
                    bodyData.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n")
                    bodyData.appendString("\r\n\(value)")
                }
            }
        }
        bodyData.appendString("\r\n--\(boundary)\r\n")
        bodyData.appendString("Content-Disposition: form-data; name=\"userfile\"; filename=\"\(filename)\"\r\n")
        bodyData.appendString("Content-Type: application/octet-stream\r\n\r\n")
        bodyData.appendData(NSData(contentsOfFile:filePath)!)
        bodyData.appendString("\r\n--\(boundary)--\r\n")
        
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField:"Content-Type")
        request.HTTPBody = bodyData
        request.HTTPMethod = "POST";

        self.dataWithRequest(request) { (data, error) in
            
            var localError : NSError? = error;
            var result = ["" : "" as AnyObject]
            if (error == nil) {
                
                let jsonObject : AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments, error:&localError)
                if let jsonDict = jsonObject as? [String : AnyObject], code = jsonDict["code"] as? Int {
                    result = jsonDict
                    if (code != 201) {
                        localError = NSError(code: code, message: jsonDict["status"]!.description)
                    }
                } else {
                    localError = NSError(code:-10001, message:"Bad response format")
                }
            }
            completion(result: result, error: localError)
        }
    }
    
    func authenticatedUrl(uri : String, arguments : [String : AnyObject]) -> NSURL? {
        
        var args = ""
        for (key, value) in arguments {
            args = "\(key)=\(value);\(args)"
        }
        let modeSelector = self.mode == BMLMode.Development ? "dev/" : ""
        return NSURL(string:"https://bigml.io/\(modeSelector)andromeda/\(uri)?\(args)\(self.authToken)")
    }
    
    public func createResource(
        type: BMLResourceType,
        name: String,
        options: [String : AnyObject],
        from: BMLResource,
        completion:(resource : BMLResource?, error : NSError?) -> Void) {

            if let url = self.authenticatedUrl(type.stringValue(), arguments:[:]) {
                
                let completionBlock : (result : [String : AnyObject], error : NSError?) -> Void = { (result, error) in
                    
                    var resource : BMLResource?
                    var localError = error
                    if (localError == nil) {
                        if let fullUuid = result["resource"] as? String {
                            resource = BMLMinimalResource(name: name, fullUuid: fullUuid, definition: [:])
                            self.trackResourceStatus(resource!, completion: completion)
                        } else {
                            localError = NSError(code: -10001, message: "Bad response format")
                        }
                    }
                    if (localError != nil) {
                        completion(resource : nil, error : localError)
                    }
                }
                
                if (from.type == BMLResourceType.File) {
                    
                    self.upload(url, filename:name, filePath:from.uuid, body: options, completion: completionBlock)
                    
                } else {

                    var body = options
                    body.updateValue(name, forKey: "name")
                    if (from.type != BMLResourceType.Project) {
                        body.updateValue(from.fullUuid, forKey: from.type.stringValue())
                    }

                    self.post(url, body: body, completion: completionBlock)
                }
            }
    }

    public func listResources(
        type: BMLResourceType,
        filters: [String : AnyObject],
        completion:(resources : [BMLResource], error : NSError?) -> Void) {
            
            if let url = self.authenticatedUrl(type.stringValue(), arguments: filters) {
                self.get(url) { (jsonObject, error) in
                    
                    var localError = error;
                    var resources : [BMLResource] = []
                    if let jsonDict = jsonObject as? [String : AnyObject],
                        jsonResources = jsonDict["objects"] as? [AnyObject] {

                        resources = jsonResources.map {
                            
                            if let type = $0["resource"] as? String,
                                resourceDict = $0 as? [String : AnyObject] {
                                
                                return BMLMinimalResource(name: $0["name"] as! String,
                                    fullUuid:$0["resource"] as! String,
                                    definition:resourceDict)
                            } else {
                                localError = NSError(code:-10001, message:"Bad response format")
                                return BMLMinimalResource(name: "Wrong Resource",
                                    fullUuid: "Wrong/Resource",
                                    definition: [:])
                            }
                        }
                    } else {
                        localError = NSError(code:-10001, message:"Bad response format")
//                        println("RESPONSE: \(jsonObject)")
                    }
                    completion(resources: resources, error: localError)
                }
            }
    }
    
    public func deleteResource(
        type: BMLResourceType,
        uuid: String,
        completion:(error : NSError?) -> Void) {
            
            if let url = self.authenticatedUrl("\(type.stringValue())/\(uuid)", arguments: [:]) {
                self.delete(url) { (error) in
                    completion(error: error)
                }
            }
    }
    
    public func updateResource(
        type: BMLResourceType,
        uuid: String,
        values: [String : AnyObject],
        completion:(error : NSError?) -> Void) {
            
            if let url = self.authenticatedUrl("\(type.stringValue())/\(uuid)", arguments: [:]) {
                
                self.put(url, body: values) { (error) in
                    completion(error: error)
                }
            }
    }
    
    func getIntermediateResource(
        type: BMLResourceType,
        uuid: String,
        completion:(resourceDict : [String : AnyObject], error : NSError?) -> Void) {
            
            if let url = self.authenticatedUrl("\(type.stringValue())/\(uuid)", arguments:[:]) {
                self.get(url) { (jsonObject, error) in
                    
                    var localError = error;
                    var resourceDict = ["" : "" as AnyObject]
                    if let jsonDict = jsonObject as? [String : AnyObject],
                        code = jsonDict["code"] as? Int {
                        resourceDict = jsonDict
                    } else {
                        localError = NSError(code:-10001, message:"Bad response format")
                    }
                    completion(resourceDict : resourceDict, error : localError)
                }
            }
    }
    
    public func getResource(
        type: BMLResourceType,
        uuid: String,
        completion:(resource : BMLResource?, error : NSError?) -> Void) {
            
            self.getIntermediateResource(type, uuid: uuid) { (resourceDict, error) -> Void in

                var localError = error;
                var resource : BMLResource? = nil
                if let code = resourceDict["code"] as? Int {
                    
                    if (code == 200) {
                        if let type = resourceDict["resource"] as? String {
                            resource = BMLMinimalResource(name: resourceDict["name"] as! String,
                                fullUuid: resourceDict["resource"] as! String,
                                definition: resourceDict)
                        }
                    } else {
                        if let message = resourceDict["status"]?["message"] as? String {
                            localError = NSError(code:code, message:message)
                        }
                    }
                }
                if (resource == nil && localError == nil) {
                    localError = NSError(code:-10001, message:"Bad response format")
//                    println("RESPONSE: \(resourceDict)")
                }
                completion(resource : resource, error : localError)
            }
    }
    
    func trackResourceStatus(resource : BMLResource,
        completion:(resource : BMLResource?, error : NSError?) -> Void) {
    
        if (resource.type == BMLResourceType.Project) {
            completion(resource: resource, error: nil)
        }
        self.getIntermediateResource(resource.type, uuid: resource.uuid) { (resourceDict, error) -> Void in
            
            var localError = error
            if (localError == nil) {
                if let statusDict = resourceDict["status"] as? [String : AnyObject], statusCodeInt = statusDict["code"] as? Int {
                    let statusCode = BMLResourceStatus(integerLiteral: statusCodeInt)
                    println("Monitoring status \(statusCode.rawValue)")
                    if (statusCode < BMLResourceStatus.Waiting) {
                        if let code = statusDict["error"] as? Int, message = statusDict["message"] as? String {
                            localError = NSError(code: code, message: message)
                        }
                        resource.status = BMLResourceStatus.Failed
                    } else if (statusCode < BMLResourceStatus.Ended) {
                        delay(1.0) {
                            self.trackResourceStatus(resource, completion: completion)
                        }
                        if (resource.status != statusCode) {
                            resource.status = statusCode
                            if let progress = statusDict["progress"] as? Float {
                                resource.progress = progress
                            }
                        }
                    } else if (statusCode == BMLResourceStatus.Ended) {
                        resource.status = statusCode
                        resource.jsonDefinition = resourceDict
                        completion(resource: resource, error: error)
                    }
                } else {
                    localError = NSError(code: -10001, message: "Bad response format: no status found")
                }
            }
            if (localError != nil) {
                println("Tracking error \(localError)")
                resource.status = BMLResourceStatus.Failed
                completion(resource: nil, error: localError)
            }
        }
    }

}

func plural(string : String, multiplicity : Int) -> String {
    
    if (multiplicity == 1) {
        return string
    }
    return "\(string)s"
}

class Predicate {
    
    static let TM_TOKENS = "tokens_only"
    static let TM_FULL_TERMS = "full_terms_only"
    static let TM_ALL = "all"
    static let FULL_TERM_PATTERN = "^.+\\b.+$"
    
    var op : String
    var field : String
    var value : AnyObject
    var term : String?
    var missing : Bool
    
    init (op : String, field : String, value : AnyObject, term : String? = .None) {
        
        self.op = op
        self.field = field
        self.value = value
        self.term = term
        self.missing = false
        if self.op =~ "\\*$" {
            self.missing = true
            self.op = self.op.substringToIndex(advance(self.op.startIndex, count(self.op)-1))
        }
    }
    
    func isFullTerm(fields : [String : AnyObject]) -> Bool {
        
        if let term = self.term,
            fieldDict = fields[self.field] as? [String : AnyObject],
            options = fieldDict["term_analysis"] as? [String : AnyObject] {

                if let tokenMode = options["token_mode"] as? String {
                    if tokenMode == Predicate.TM_FULL_TERMS {
                        return true
                    }
                    if tokenMode == Predicate.TM_ALL {
                        return term =~ Predicate.FULL_TERM_PATTERN
                    }
                }
        }
        return false
    }
    
    func rule(fields : [String : AnyObject], label : String = "name") -> String {
        
        if let fieldDict = fields[self.field] as? [String : AnyObject],
            name = fieldDict[label] as? String {

                let fullTerm = self.isFullTerm(fields)
                let relationMissing = self.missing ? " or missing " : ""
                if let term = self.term, value = self.value as? Int {
                    var relationSuffix = ""
                    let relationLiteral : String
                    if ((self.op == "<" && value <= 1) || (self.op == "<=" && value == 0)) {
                        relationLiteral = fullTerm ? " is not equal to " : " does not contain "
                    } else {
                        relationLiteral = fullTerm ? " is equal to " : " contains "
                        if !fullTerm {
                            if self.op != ">" || value != 0 {
                                let times = plural("time", value)
                                if self.op == ">=" {
                                    relationSuffix = "\(value) \(times) at most"
                                } else if self.op == "<=" {
                                    relationSuffix = "no more than \(value) \(times)"
                                } else if self.op == ">" {
                                    relationSuffix = "more than \(value) \(times)"
                                } else if self.op == "<" {
                                    relationSuffix = "less than \(value) \(times)"
                                }
                            }
                        }
                    }
                    return "\(name) \(relationLiteral) \(term) \(relationSuffix)\(relationMissing)"
                }
                if let value = self.value as? NSNull {
                    let v = (self.op == "=") ? " is None " : " is not None "
                    return "\(name) \(self.op) \(self.value) \(relationMissing)"
                } else {
                    return "\(name) \(self.op) \(self.value) \(relationMissing)"
                }
        } else {
            return self.op
        }
    }
    
    func termCount(text : String, forms : [String], options : [String : AnyObject]?) -> Int {
        assert(false, "TBD")
        return 0
    }
    
    func apply(input : [String : AnyObject], fields : [String : AnyObject]) -> Bool {
        
        if (self.op == "TRUE") {
            return true
        }
//        println("APPLYING: \(input) to field \(self.field)")
        if input[self.field] == nil {
            return self.missing || (self.op == "=" && self.value as! NSObject == NSNull())
        } else if self.op == "!=" && self.value as! NSObject == NSNull() {
            return true
        }
        
//        if input[self.field] == nil {
//            if  !self.missing {
//                if let value = self.value as? NSNull {
//                    return self.op == "="
//                }
//            } else {
//                return true
//            }
//        } else {
//            if let value = self.value as? NSNull {
//                return self.op == "!="
//            }
//        }

//        println("INPUT: \(input[self.field]!) -- FIELD: \(self.field) -- VALUE: \(self.value)")
        if self.op == "in" {
            let predicate = NSPredicate(format:"ls \(self.op) rs")
//            println("PREDICATE \(predicate)")
            return predicate.evaluateWithObject([
                "ls" : input[self.field]!,
                "rs" : self.value])
        }
        if let term = self.term,
            text = input[self.field] as? String,
            field = fields[self.field] as? [String : AnyObject],
            summary = fields["summary"] as? [String : AnyObject],
            allForms = summary["term_forms"] as? [String : AnyObject],
            termForms = allForms[term] as? [String] {

                let terms = [term] + termForms
                let options = field["term_analysis"] as? [String : AnyObject]
                let predicate = NSPredicate(format:"ls \(self.op) rs")
//                println("PREDICATE \(predicate)")
                return predicate.evaluateWithObject([
                    "ls" : self.termCount(text, forms: terms, options: options),
                    "rs" : self.value])
        }
        let predicate = NSPredicate(format:"ls \(self.op) rs")
        println("PREDICATE \(predicate)")
        if let inputValue : AnyObject = input[self.field] {
            return predicate.evaluateWithObject([
                "ls" : input[self.field]!,
                "rs" : self.value])
        }
        assert(false, "Should not be here: no input value provided!")
        return false
    }
}

class Predicates {
    
    let predicates : [Predicate]
    
    init(predicates : [AnyObject]) {
        self.predicates = predicates.map() {

//            println("PREDICATE: \($0)")
            if let p = $0 as? String {
                return Predicate(op: "TRUE", field: "", value: 1, term: "")
            }
            if let p = $0 as? [String : AnyObject] {
                if let op = p["op"] as? String, field = p["field"] as? String, value : AnyObject = p["value"] {
                    if let term = p["term"] as? String {
                        return Predicate(op: op, field: field, value: value, term: term)
                    } else {
                        return Predicate(op: op, field: field, value: value, term: "")
                    }
                }
            }
            assert(false, "COULD NOT CREATE PREDICATE")
        }
    }
    
    func rule(fields : [String : AnyObject], label : String = "name") -> String {

        let strings = self.predicates.map() {
            return $0.rule(fields, label: label)
        }
        return " and ".join(strings)
    }

    func apply(input : [String : AnyObject], fields : [String : AnyObject]) -> Bool {

        return predicates.reduce(true) {
            let rule = $1.rule(fields)
            let result = $1.apply(input, fields: fields)
//            println("Applying predicate: \(result)")
            return $0 && result
        }
    }
}

class AnomalyTree {
    
    internal let fields : [String : AnyObject]
    var predicates : Predicates
    var id : AnyObject?
    var children : [AnomalyTree] = []

    init(tree : [String : AnyObject], fields : [String : AnyObject]) {
        
        self.fields = fields
        self.predicates = Predicates(predicates: ["True"])
        if let predicates = tree["predicates"] as? [[String : AnyObject]] {
            self.predicates = Predicates(predicates: predicates)
            self.id = .None
        }
        if let children = tree["children"] as? [[String : AnyObject]] {
            self.children = children.map {
                AnomalyTree(tree: $0, fields: self.fields)
            }
        }
    }
    
    func depth(input : [String : AnyObject], path : [String] = [], depth : Int = 0) -> (Int, [String]) {
        
        var depth = depth
        if depth == 0 {
            if !self.predicates.apply(input, fields: self.fields) {
                return (depth, path)
            }
            depth += 1
        }
        var path = path
        for child in self.children {
            if child.predicates.apply(input, fields: self.fields) {
                path.append(child.predicates.rule(self.fields))
                return child.depth(input, path: path, depth: depth+1)
            }
        }
        return (depth, path)
    }
}

let DEPTH_FACTOR : Double = 0.5772156649

public class FieldedResource : NSObject {
 
    internal let fields : [String : AnyObject]
    internal let objectiveId : String?
    internal let locale : String?
    internal let missingTokens : [String]?
    internal var inverseFieldMap : [String : String]
    
    init(fields : [String : AnyObject],
        objectiveId : String? = .None,
        locale : String? = .None,
        missingTokens : [String]? = .None) {
        
            self.fields = fields
            self.objectiveId = objectiveId
            self.locale = locale
            self.missingTokens = missingTokens
            self.inverseFieldMap = [:]
            
            super.init()
            self.inverseFieldMap = self.invertedFieldMap()
    }
    
    func normalizedValue(value : AnyObject) -> AnyObject? {
        
        if let value = value as? String, missingTokens = missingTokens {
            if contains(missingTokens, value) {
                return .None
            }
        }
        return value
    }
    
    func invertedFieldMap() -> [String : String] {
        
        var fieldMap : [String : String] = [:]
        for (key, value) in self.fields {
            if let name = value["name"] as? String {
                fieldMap[name] = key
            }
        }
        return fieldMap
    }
    
    func filterInputData(input : [String : AnyObject], byName : Bool = true) -> [String : AnyObject] {

        var output : [String : AnyObject] = [:]
        println("OBJID: \(self.objectiveId)")
        for (key, value) in input {
            if let value : AnyObject = self.normalizedValue(value) {
                if self.objectiveId == .None || key != self.objectiveId {
                    if let key = byName ? self.inverseFieldMap[key] : key {
                        output[key] = value
                    }
                }
            }
        }
        return output
    }
}

public class Anomaly : FieldedResource {
    
    let sampleSize : Double?
    let inputFields : [String]?
    var meanDepth : Double?
    var expectedMeanDepth : Double? = .None
    var iforest : [AnomalyTree?]?
    
    public init(anomaly : BMLResource) {
    
        assert(anomaly.type == BMLResourceType.Anomaly, "Wrong resource passed in -- anomaly expected")
//        println("RESOURCE \(anomaly.jsonDefinition)")
        if let sampleSize = anomaly.jsonDefinition["sample_size"] as? Double,
            inputFields = anomaly.jsonDefinition["input_fields"] as? [String] {
                
            self.sampleSize = sampleSize
            self.inputFields = inputFields
                
        } else {
            
            self.sampleSize = .None
            self.inputFields = .None
        }
        if let model = anomaly.jsonDefinition["model"] as? [String : AnyObject],
            fields = model["fields"] as? [String : AnyObject] {
                
            if let topAnomalies = model["top_anomalies"] as? [AnyObject] {
                
                super.init(fields: fields)

                self.meanDepth = model["mean_depth"] as? Double
                if let status = anomaly.jsonDefinition["status"] as? [String : AnyObject],
                    intCode = status["code"] as? Int {
                    
                        let code = BMLResourceStatus(integerLiteral: intCode)
                        if (code == BMLResourceStatus.Ended) {
                            if let sampleSize = self.sampleSize, let meanDepth = self.meanDepth {
                                let defaultDepth = 2 * (DEPTH_FACTOR + log(sampleSize - 1) - ((sampleSize - 1) / sampleSize))
                                self.expectedMeanDepth = min(meanDepth, defaultDepth)
                            } else {
                                //-- HANDLE ERROR HERE: anomaly is not complete
                            }
                            if let iforest = model["trees"] as? [AnyObject] {
                                self.iforest = iforest.map {
                                    if let tree = $0 as? [String : AnyObject],
                                        root = tree["root"] as? [String : AnyObject] {
                                        return AnomalyTree(tree: root, fields: self.fields)
                                    } else {
                                        return .None
                                    }
                                }
                            }
                        } else {
                            //-- HANDLE ERROR HERE: anomaly is not complete
                        }
                }
            } else {
                self.meanDepth = 0
                super.init(fields: fields)
            }
        } else {
            self.meanDepth = 0
            super.init(fields: [:])
        }
    }
    
    public func score(input : [String : AnyObject], byName : Bool = true) -> Double {
        
        assert(self.iforest != nil, "Could not find forest info. The anomaly was possibly not completely created")
        if let iforest = self.iforest {
            let inputData = self.filterInputData(input, byName: byName)
            var depthSum = iforest.reduce(0) {
                if let tree = $1 {
//                    println("DEPTH: \(tree.depth(inputData))")
                    return $0 + tree.depth(inputData).0
                }
                assert(false, "Should not be here: non-tree found in forest!")
                return 0
            }
            let observedMeanDepth = Double(depthSum) / Double(iforest.count)
            return pow(2.0, -observedMeanDepth / self.expectedMeanDepth!)
        }
        return 0
    }
    
}