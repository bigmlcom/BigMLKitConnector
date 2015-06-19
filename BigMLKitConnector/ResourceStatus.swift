//
//  ResourceStatus.swift
//  BigMLX
//
//  Created by sergio on 19/06/15.
//  Copyright (c) 2015 sergio. All rights reserved.
//

import Foundation

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
