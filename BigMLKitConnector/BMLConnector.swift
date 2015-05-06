//
//  BMLConnector.swift
//  BigMLKitConnector
//
//  Created by sergio on 28/04/15.
//  Copyright (c) 2015 BigML Inc. All rights reserved.
//

import Foundation

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

@objc public protocol BMLResource {
    
    var name : String  { get }
    var type : BMLResourceType  { get }
    var uuid : String { get }
    var fullUuid : String { get }
    
    init(name: String, type: BMLResourceType, uuid: String)
}

public class BMLMinimalResource : NSObject, BMLResource {
    
    public var name : String
    public var type : BMLResourceType
    public var uuid : String
    public var fullUuid : String {
        get {
            return "\(type.stringValue())/\(uuid)"
        }
    }
    
    public required init(name: String, type: BMLResourceType, uuid: String) {
        
        self.name = name
        self.type = type
        self.uuid = uuid
    }
    
    public required init(name: String, fullUuid: String) {
        
        let components = split(fullUuid) {$0 == "/"}
        self.name = name
        self.type = BMLResourceType(components[0])
        self.uuid = components[1]
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
    
    func post(url : NSURL, body: [String : String], completion:(result : AnyObject?, error : NSError?) -> Void) {
        
        var error : NSError? = nil
        if let bodyData = NSJSONSerialization.dataWithJSONObject(body, options: nil, error:&error) {
            let request = NSMutableURLRequest(URL:url)
            request.HTTPBody = bodyData
            request.HTTPMethod = "POST";
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            
            self.dataWithRequest(request) { (data, error) in
                
                var localError : NSError? = error;
                if (error == nil) {
                    
                    let jsonObject : AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments, error:&localError)
                    if let jsonDict = jsonObject as? [String : AnyObject], code = jsonDict["code"] as? Int {
                        println("RESPONSE: \(jsonObject)")
                        if (code != 201) {
                            localError = NSError(code: code, message: jsonDict["status"]!.description)
                        }
                    } else {
                        localError = NSError(code:-10001, message:"Bad response format")
                        println("RESPONSE: \(jsonObject)")
                    }
                }
                let result = []
                completion(result: result, error: localError)
            }
        }
    }
    
    func upload(url : NSURL, filename: String, filePath: String, body: [String : String], completion:(result : AnyObject?, error : NSError?) -> Void) {
        
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

        self.dataWithRequest(request) { (result, error) in
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
                
                let completionBlock : (result : AnyObject?, error : NSError?) -> Void = { (result, error) in
                    
                    var resource : BMLResource?
                    if (error == nil) {
                        resource = BMLMinimalResource(name: name, type: type, uuid: "")
                    }
                    completion(resource : resource, error : error)
                }
                
                if (from.type == BMLResourceType.File) {
                    
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
    
    public func getResource(
        type: BMLResourceType,
        uuid: String,
        completion:(resource : BMLResource?, error : NSError?) -> Void) {
            
            if let url = self.authenticatedUrl("\(type.stringValue())/\(uuid)") {
                self.get(url) { (jsonObject, error) in
                    
                    var localError = error;
                    var resource : BMLResource? = nil
                    if let jsonDict = jsonObject as? [String : AnyObject], code = jsonDict["code"] as? Int {
                        
                        if (code == 200) {
                            if let type = jsonDict["resource"] as? String {
                                resource = BMLMinimalResource(name: jsonDict["name"] as! String, fullUuid:jsonDict["resource"] as! String)
                            }
                        } else {
                            if let message = jsonDict["status"]?["message"] as? String {
                                localError = NSError(code:code, message:message)
                            }
                        }
                        
                    }
                    if (resource == nil && localError == nil) {
                        localError = NSError(code:-10001, message:"Bad response format")
                        println("RESPONSE: \(jsonObject)")
                    }
                    completion(resource : resource, error : localError)
                }
            }
    }
    
}