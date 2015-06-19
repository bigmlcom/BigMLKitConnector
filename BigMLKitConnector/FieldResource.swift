//
//  FieldResource.swift
//  BigMLX
//
//  Created by sergio on 19/06/15.
//  Copyright (c) 2015 sergio. All rights reserved.
//

import Foundation


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