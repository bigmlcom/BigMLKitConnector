//
//  BMLConnector.swift
//  BigMLKitConnector
//
//  Created by sergio on 28/04/15.
//  Copyright (c) 2015 BigML Inc. All rights reserved.
//

import Foundation
import JavaScriptCore

public class BMLConnector : NSObject {
    
    var connector : BMLLLConnector
    
    public init(username: String, apiKey: String, mode:BMLMode) {
        
        self.connector = BMLLLConnector(username: username, apiKey: apiKey, mode: mode)
        super.init()
    }
    
    func authenticatedUrl(uri : String, arguments : [String : AnyObject]) -> NSURL? {
        
        var args = ""
        for (key, value) in arguments {
            args = "\(key)=\(value);\(args)"
        }
        let modeSelector = self.connector.mode == BMLMode.Development ? "dev/" : ""
        return NSURL(string:"https://bigml.io/\(modeSelector)andromeda/\(uri)?\(args)\(self.connector.authToken)")
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
                            localError = NSError(info: "Bad response format", code: -10001)
                        }
                    }
                    if (localError != nil) {
                        completion(resource : nil, error : localError)
                    }
                }
                
                if (from.type == BMLResourceType.File) {
                    
                    self.connector.upload(url, filename:name, filePath:from.uuid, body: options, completion: completionBlock)
                    
                } else {

                    var body = options
                    body.updateValue(name, forKey: "name")
                    if (from.type != BMLResourceType.Project) {
                        body.updateValue(from.fullUuid, forKey: from.type.stringValue())
                    }

                    self.connector.post(url, body: body, completion: completionBlock)
                }
            }
    }

    public func listResources(
        type: BMLResourceType,
        filters: [String : AnyObject],
        completion:(resources : [BMLResource], error : NSError?) -> Void) {
            
            if let url = self.authenticatedUrl(type.stringValue(), arguments: filters) {
                self.connector.get(url) { (jsonObject, error) in
                    
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
                                localError = NSError(info:"Bad response format", code:-10001)
                                return BMLMinimalResource(name: "Wrong Resource",
                                    fullUuid: "Wrong/Resource",
                                    definition: [:])
                            }
                        }
                    } else {
                        localError = NSError(info:"Bad response format", code:-10001)
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
                self.connector.delete(url) { (error) in
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
                
                self.connector.put(url, body: values) { (error) in
                    completion(error: error)
                }
            }
    }
    
    func getIntermediateResource(
        type: BMLResourceType,
        uuid: String,
        completion:(resourceDict : [String : AnyObject], error : NSError?) -> Void) {
            
            if let url = self.authenticatedUrl("\(type.stringValue())/\(uuid)", arguments:[:]) {
                self.connector.get(url) { (jsonObject, error) in
                    
                    var localError = error;
                    var resourceDict = ["" : "" as AnyObject]
                    if let jsonDict = jsonObject as? [String : AnyObject],
                        code = jsonDict["code"] as? Int {
                        resourceDict = jsonDict
                    } else {
                        localError = NSError(info:"Bad response format", code:-10001)
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
                        localError = NSError(status: resourceDict["status"], code: code)
                    }
                }
                if (resource == nil && localError == nil) {
                    localError = NSError(info: "Bad response format", code:-10001)
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
                        if let code = statusDict["error"] as? Int {
                            localError = NSError(status: statusDict, code: code)
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
                    localError = NSError(info: "Bad response format: no status found", code: -10001)
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
