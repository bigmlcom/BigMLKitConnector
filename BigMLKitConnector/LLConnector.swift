//
//  LLConnector.swift
//  BigMLX
//
//  Created by sergio on 19/06/15.
//  Copyright (c) 2015 sergio. All rights reserved.
//

import Foundation

struct BMLLLConnector {
    
    let username : String
    let apiKey : String
    let mode : BMLMode
    let authToken : String
    
    lazy var session: NSURLSession = self.initializeSession()
    
    init(username: String, apiKey: String, mode:BMLMode) {
        
        self.username = username
        self.apiKey = apiKey
        self.mode = mode
        self.authToken = "username=\(username);api_key=\(apiKey);"
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
    
    mutating func dataWithRequest(request : NSURLRequest, completion:(data : NSData!, error : NSError!) -> Void) {
        
        let task = self.session.dataTaskWithRequest(request) { (data : NSData!, response : NSURLResponse!, error : NSError!) in
            var localError : NSError? = error;
            if (error == nil) {
                if let response = response as? NSHTTPURLResponse {
                } else {
                    localError = NSError(info:"Bad response format", code:-10001)
                }
            }
            var result = []
            completion(data: data, error: localError)
        }
        task.resume()
    }
    
    mutating func delete(url : NSURL, completion:(error : NSError?) -> Void) {
        
        let request = NSMutableURLRequest(URL:url)
        request.HTTPMethod = "DELETE";
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        self.dataWithRequest(request) { (data, error) in
            
            var localError : NSError? = error;
            if (localError == nil) {
                let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments, error:nil)
                if let jsonDict = jsonObject as? [String : AnyObject],
                    status = jsonDict["status"] as? [String : AnyObject],
                    code = jsonDict["code"] as? Int {
                        if (code != 204) {
                            localError = NSError(info: status.description, code: code)
                        }
                }
            }
            completion(error: localError)
        }
    }
    
    mutating func put(url : NSURL, body : [String : AnyObject], completion:(error : NSError?) -> Void) {
        
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
                                localError = NSError(status:status, code: code)
                            }
                    }
                }
                completion(error: localError)
            }
        } else {
            completion(error: localError)
        }
    }
    
    mutating func get(url : NSURL, completion:(jsonObject : AnyObject?, error : NSError?) -> Void) {
        
        self.dataWithRequest(NSMutableURLRequest(URL:url)) { (data, error) in
            
            var localError : NSError? = error;
            var jsonObject : AnyObject?
            if (error == nil) {
                jsonObject = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments, error:&localError)
            }
            completion(jsonObject: jsonObject, error: localError)
        }
    }
    
    mutating func post(url : NSURL, body: [String : AnyObject], completion:(result : [String : AnyObject], error : NSError?) -> Void) {
        
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
                            localError = NSError(status:jsonDict["status"], code: code)
                        }
                    } else {
                        localError = NSError(info: "Bad response format", code:-10001)
                    }
                }
                completion(result: result, error: localError)
            }
        } else {
            completion(result: [:], error: localError)
        }
    }
    
    mutating func upload(url : NSURL, filename: String, filePath: String, body: [String : AnyObject], completion:(result : [String : AnyObject], error : NSError?) -> Void) {
        
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
                        localError = NSError(status: jsonDict["status"], code: code)
                    }
                } else {
                    localError = NSError(info:"Bad response format", code:-10001)
                }
            }
            completion(result: result, error: localError)
        }
    }
    
}
