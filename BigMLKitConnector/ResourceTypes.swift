//
//  ResourceTypes.swift
//  BigMLX
//
//  Created by sergio on 19/06/15.
//  Copyright (c) 2015 sergio. All rights reserved.
//

import Foundation

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
    case Evaluation
    case Prediction
    case Project
    case Configuration
    case WhizzmlScript
    case WhizzmlExecution
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
        case "evaluation":
            self = Evaluation
        case "configuration":
            self = Configuration
        case "script":
            self = WhizzmlScript
        case "execution":
            self = WhizzmlExecution
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
        case Configuration:
            return "configuration"
        case Evaluation:
            return "evaluation"
        case WhizzmlScript:
            return "script"
        case WhizzmlExecution:
            return "execution"
        case Project:
            return "project"
        default:
            return "invalid"
        }
    }
}

/*
 * This class works as a high-level bridge to BMLResourceType to overcome C-enum limitations.
 * Indeed, BMLResourceType is bridged to Objective-C through a C-enum, which is a very poor
 * abstraction and makes it trivial.
 * You should always use BMLResourceType in Swift code and only resort to BMLResourceTypeIdentifier
 * in Objective-C.
 */

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

