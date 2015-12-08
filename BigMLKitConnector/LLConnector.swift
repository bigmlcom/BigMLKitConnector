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

extension NSHTTPURLResponse {
    
    func isStrictlyValid() -> Bool {
        return self.statusCode >= 200 && self.statusCode <= 206
    }
}

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
        for (_, value) in options {
            if (value.characters.count > 0) {
                let trimmedOption = value.substringWithRange(Range<String.Index>(start: value.startIndex.advancedBy(1), end: value.endIndex.advancedBy(-1)))
                result = "\(result), \(trimmedOption)"
            }
        }
    }
    
    mutating func dataWithRequest(request : NSURLRequest, completion:(data : NSData!, error : NSError!) -> Void) {

        let task = self.session.dataTaskWithRequest(request) { (data : NSData?, response : NSURLResponse?, error : NSError?) in
            var localError : NSError? = error;
            if (error == nil) {
                if let response = response as? NSHTTPURLResponse {
                    if !response.isStrictlyValid() {
                        let url = response.URL?.absoluteString ?? ""
                        print("ERROR: \(url)")
                        let code = response.statusCode
                        localError = NSError(info:"Bad response format for URL: \(url)", code:code)
                    }
                } else {
                    let url = response?.URL?.absoluteString ?? ""
                    localError = NSError(info:"Bad response format for URL: \(url)", code:-10001)
                }
            }
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
                let jsonObject: AnyObject? = try? NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments)
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
        do {
            let bodyData = try NSJSONSerialization.dataWithJSONObject(body, options: [])
            let request = NSMutableURLRequest(URL:url)
            request.HTTPBody = bodyData
            request.HTTPMethod = "PUT";
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            self.dataWithRequest(request) { (data, error) in
                
                var localError : NSError? = error;
                if (error == nil) {
                    let jsonObject: AnyObject? = try? NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments)
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
        } catch let error1 as NSError {
            localError = error1
            completion(error: localError)
        }
    }
    
    mutating func get(url : NSURL, completion:(jsonObject : AnyObject?, error : NSError?) -> Void) {
        
        self.dataWithRequest(NSMutableURLRequest(URL:url)) { (data, error) in
            
            var localError : NSError? = error;
            var jsonObject : AnyObject?
            if (error == nil) {
                do {
                    jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments)
                } catch let error as NSError {
                    localError = error
                    jsonObject = nil
                } catch {
                    fatalError()
                }
            }
            completion(jsonObject: jsonObject, error: localError)
        }
    }
    
    mutating func post(url : NSURL, body: [String : AnyObject], completion:(result : [String : AnyObject], error : NSError?) -> Void) {
        
        var localError : NSError? = nil
        do {
            let bodyData = try NSJSONSerialization.dataWithJSONObject(body, options: [])
            let request = NSMutableURLRequest(URL:url)
            request.HTTPBody = bodyData
            request.HTTPMethod = "POST";
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            
            self.dataWithRequest(request) { (data, error) in
                
                var localError : NSError? = error;
                var result = ["" : "" as AnyObject]
                if (error == nil) {
                    
                    let jsonObject : AnyObject?
                    do {
                        jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments)
                    } catch let error as NSError {
                        localError = error
                        jsonObject = nil
                    } catch {
                        fatalError()
                    }
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
        } catch let error1 as NSError {
            localError = error1
            completion(result: [:], error: localError)
        }
    }
    
    mutating func upload(url : NSURL, filename: String, filePath: String, body: [String : AnyObject], completion:(result : [String : AnyObject], error : NSError?) -> Void) {
        
        let request = NSMutableURLRequest(URL:url)
        let boundary = "---------------------------14737809831466499882746641449"
        
        let bodyData : NSMutableData = NSMutableData()
        for (name, value) in body {
            let fieldData = try? NSJSONSerialization.dataWithJSONObject(value, options: [])
            if let fieldData = fieldData, value = NSString(data: fieldData, encoding:NSUTF8StringEncoding) {
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
                
                let jsonObject : AnyObject?
                do {
                    jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments)
                } catch let error as NSError {
                    localError = error
                    jsonObject = nil
                } catch {
                    fatalError()
                }
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
