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

@objc public enum BMLMode : Int {

    case BMLDevelopmentMode
    case BMLProductionMode
}

@objc public enum BMLResourceType : Int, StringLiteralConvertible {
    
    case File
    case Source
    case Dataset
    case Model
    case Cluster
    case Anomaly
    case Prediction
    case Project
    case InvalidType
    
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
        case "project":
            self = Project
        default:
            self = InvalidType
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
        case Project:
            return "project"
        default:
            return "invalid"
        }
    }
}

public typealias BMLResourceUuid = String
public typealias BMLResourceFullUuid = String

@objc public enum BMLResourceStatus : Int {
    
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
    var status : BMLResourceStatus { get set }
    
    init(name: String, type: BMLResourceType, uuid: String)
}

public class BMLMinimalResource : NSObject, BMLResource {
    
    public var name : String
    public var type : BMLResourceType
    public var status : BMLResourceStatus
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
    }
    
    public required init(name: String, fullUuid: String) {
        
        let components = split(fullUuid) {$0 == "/"}
        self.name = name
        self.type = BMLResourceType(stringLiteral: components[0])
        self.uuid = components[1]
        self.status = BMLResourceStatus.Undefined
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
        self.authToken = "?username=\(username);api_key=\(apiKey);"
        
        super.init()
    }
    
    func initializeSession() -> NSURLSession {
        
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        configuration.HTTPAdditionalHeaders = [ "Content-Type": "application/json" ];

        return NSURLSession(configuration : configuration)
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
    
    func post(url : NSURL, body: [String : String], completion:(result : [String : AnyObject], error : NSError?) -> Void) {
        
        var error : NSError? = nil
        if let bodyData = NSJSONSerialization.dataWithJSONObject(body, options: nil, error:&error) {
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
//                        println("RESPONSE: \(jsonObject)")
                        if (code != 201) {
                            localError = NSError(code: code, message: jsonDict["status"]!.description)
                        }
                    } else {
                        localError = NSError(code:-10001, message:"Bad response format")
//                        println("RESPONSE: \(jsonObject)")
                    }
                }
                completion(result: result, error: localError)
            }
        }
    }
    
    func upload(url : NSURL, filename: String, filePath: String, body: [String : String], completion:(result : [String : AnyObject], error : NSError?) -> Void) {
        
        let request = NSMutableURLRequest(URL:url)
        let boundary = "---------------------------14737809831466499882746641449"

        let bodyData : NSMutableData = NSMutableData()
        for (name, value) in body {
            if (count(value) > 0) {
                bodyData.appendString("\r\n--\(boundary)\r\n")
                bodyData.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n")
                bodyData.appendString("\r\n\(value)")
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
//                    println("RESPONSE: \(jsonObject)")
                    if (code != 201) {
                        localError = NSError(code: code, message: jsonDict["status"]!.description)
                    }
                } else {
                    localError = NSError(code:-10001, message:"Bad response format")
//                    println("RESPONSE: \(jsonObject)")
                }
            }
            completion(result: result, error: error)
        }
    }
    
    func authenticatedUrl(uri : String) -> NSURL? {
        
        return NSURL(string:"https://bigml.io/dev/andromeda/\(uri)\(self.authToken)")
    }
    
    public func createResource(
        type: BMLResourceType,
        name: String,
        options: [String : String],
        from: BMLResource,
        completion:(resource : BMLResource?, error : NSError?) -> Void) {

            if let url = self.authenticatedUrl(type.stringValue()) {
                
                let completionBlock : (result : [String : AnyObject], error : NSError?) -> Void = { (result, error) in
                    
                    var resource : BMLResource?
                    var localError = error
                    if (localError == nil) {
                        if let fullUuid = result["resource"] as? String {
                            resource = BMLMinimalResource(name: name, fullUuid: fullUuid)
                            self.trackResourceStatus(resource!, completion: completion)
                        } else {
                            localError = NSError(code: -10001, message: "Bad response format")
                        }
                    }
                    if (localError != nil) {
                        completion(resource : nil, error : localError)
                    }
                }
                
                if (from.type == "file") {
//                if (from.type == BMLResourceType.File) {
                    
//                    assert(type == BMLResourceType.Source, "Attempting to create a \(type.stringValue()) from a CSV File.")
                    self.upload(url, filename:name, filePath:from.uuid, body: [String : String](), completion: completionBlock)
                    
                } else {

                    let body : [String : String] = [
                        from.type.stringValue() : from.fullUuid,
                        "name" : name,
                    ]
                    self.post(url, body: body, completion: completionBlock)
                }
            }
    }

    public func listResources(
        type: BMLResourceType,
        completion:(resources : [BMLResource], error : NSError?) -> Void) {
            
            if let url = self.authenticatedUrl(type.stringValue()) {
                self.get(url) { (jsonObject, error) in
                    
                    var localError = error;
                    var resources : [BMLResource] = []
                    if let jsonDict = jsonObject as? [String : AnyObject], jsonResources = jsonDict["objects"] as? [AnyObject] {

                        resources = map(jsonResources) {
                            if let type = $0["resource"] as? String {
                                return BMLMinimalResource(name: $0["name"] as! String, fullUuid:$0["resource"] as! String)
                            } else {
                                localError = NSError(code:-10001, message:"Bad response format")
                                return BMLMinimalResource(name: "Wrong Resource", fullUuid:"Wrong/Resource")
                            }
                        }
                    } else {
                        localError = NSError(code:-10001, message:"Bad response format")
                        println("RESPONSE: \(jsonObject)")
                    }
                    completion(resources: resources, error : nil)
                }
            }
    }
    
    func getIntermediateResource(
        type: BMLResourceType,
        uuid: String,
        completion:(resourceDict : [String : AnyObject], error : NSError?) -> Void) {
            
            if let url = self.authenticatedUrl("\(type.stringValue())/\(uuid)") {
                self.get(url) { (jsonObject, error) in
                    
                    var localError = error;
                    var resourceDict = ["" : "" as AnyObject]
                    if let jsonDict = jsonObject as? [String : AnyObject]/*, code = jsonDict["code"] as? Int*/ {
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
                            resource = BMLMinimalResource(name: resourceDict["name"] as! String, fullUuid:resourceDict["resource"] as! String)
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
    
        self.getIntermediateResource(resource.type, uuid: resource.uuid) { (resourceDict, error) -> Void in
            if (error != nil) {
                resource.status = BMLResourceStatus.Failed
                completion(resource: resource, error: error)
            } else {
                if let statusDict = resourceDict["status"] as? NSDictionary, statusCode = statusDict["code"] as? BMLResourceStatus {
                    println("Monitoring status \(statusCode)")
                    if (statusCode < BMLResourceStatus.Waiting) {
                        resource.status = BMLResourceStatus.Failed
                    } else if (statusCode < BMLResourceStatus.Ended) {
                        delay(1.0) {
                            self.trackResourceStatus(resource, completion: completion)
                        }
                        if (resource.status != statusCode) {
                            resource.status = statusCode
    //                        resource.progress = (resourceDict["status"] as! NSDictionary)["progress"] as Float
                        }
                    } else if (statusCode == BMLResourceStatus.Ended) {
                        resource.status = statusCode
                        completion(resource: resource, error: error)
                    }
                }
            }
        }
    }

}