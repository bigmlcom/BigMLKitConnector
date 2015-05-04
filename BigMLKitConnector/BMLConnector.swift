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

public enum BMLMode {

    case BMLDevelopmentMode
    case BMLProductionMode
}

public enum BMLResourceType : String, StringLiteralConvertible {
    
    case File = "file"
    case Source = "source"
    case Dataset = "dataset"
    case Model = "model"
    case Cluster = "cluster"
    case Anomaly = "anomaly"
    case Prediction = "prediction"
    case Project = "project"
    case InvalidType = ""
    
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
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self = BMLResourceType(stringLiteral:value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        self = BMLResourceType(stringLiteral:value)
    }
}

public class BMLResource : NSObject {
    
    public var name : String
    public var type : BMLResourceType
    public var uuid : String
    public var fullUuid : String {
        get {
            return "\(type.rawValue)/\(uuid)"
        }
    }
    
    public init(name: String, type: BMLResourceType, uuid: String) {
        
        self.name = name
        self.type = type
        self.uuid = uuid
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
    
    func dataWithRequest(request : NSURLRequest, completion:(result : AnyObject?, error : NSError?) -> Void) {
        
        let task = self.session.dataTaskWithRequest(request) { (data : NSData!, response : NSURLResponse!, error : NSError!) in
            var error : NSError? = error;
            if (error == nil) {
                if let response = response as? NSHTTPURLResponse {
                    let jsonObject : AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments, error:&error)
                    if let jsonDict = jsonObject as? [String : AnyObject], code = jsonDict["code"] as? Int {
                        if (code != 201) {
                            error = NSError(code: code, message: jsonDict["status"]!.description)
                        }
                    } else {
                        error = NSError(code:-10001, message:"Bad response format")
                        //                    println("RESPONSE: \(jsonObject)")
                    }
                }
            } else {
                
                println("ERROR: \(error)")
            }
            var result = []
            completion(result: result, error: error)
        }
        task.resume()
    }
    
    func get(url : NSURL, completion:(result : AnyObject?, error : NSError?) -> Void) {
        
        self.dataWithRequest(NSMutableURLRequest(URL:url)) { (result, error) in
            completion(result: result, error: error)
        }
    }
    
    func post(url : NSURL, body: [String : String], completion:(result : AnyObject?, error : NSError?) -> Void) {
        
        var error : NSError? = nil
        if let bodyData = NSJSONSerialization.dataWithJSONObject(body, options: nil, error:&error) {
            let request = NSMutableURLRequest(URL:url)
            request.HTTPBody = bodyData
            request.HTTPMethod = "POST";
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            
            self.dataWithRequest(request) { (result, error) in
                completion(result: result, error: error)
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

            if let url = self.authenticatedUrl(type.rawValue) {
                
                let completionBlock : (result : AnyObject?, error : NSError?) -> Void = { (result, error) in
                    
                    var resource : BMLResource?
                    if (error == nil) {
                        resource = BMLResource(name: name, type: type, uuid: "")
                    }
                    completion(resource : resource, error : error)
                }
                
                if (from.type == BMLResourceType.File) {
                    
                    self.upload(url, filename:name, filePath:from.uuid, body: [String : String](), completion: completionBlock)
                    
                } else {

                    let body : [String : String] = [
                        from.type.rawValue : from.fullUuid,
                        "name" : name,
                    ]
                    self.post(url, body: body, completion: completionBlock)
                }
            }
    }

    public func listResources(
        type: BMLResourceType,
        completion:(resources : [BMLResource], error : NSError?) -> Void) {
            
            if let url = self.authenticatedUrl(type.rawValue) {
                self.get(url) { (result, error) in
                    completion(resources : [], error : nil)
                }
            }
    }

}