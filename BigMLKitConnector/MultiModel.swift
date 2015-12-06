//
//  MultiModel.swift
//  BigMLKitConnector
//
//  Created by sergio on 03/12/15.
//  Copyright © 2015 BigML Inc. All rights reserved.
//

import Foundation

class MultiModel {
    
    let models : [[String : AnyObject]]
    
    required init(models : [[String : AnyObject]]) {
        
        self.models = models
    }
    
    func generateVotes(arguments : [String : AnyObject],
        byName : Bool,
        missingStrategy : MissingStrategy,
        median : Bool) -> MultiVote {
        
            return MultiVote(predictions: self.models.map{
                Model(jsonModel: $0).predict(arguments,
                    options: [
                        "byName" : byName,
                        "strategy" : missingStrategy,
                        "median" : median,
                        "confidence" : true,
                        "count" : true,
                        "distribution" : true,
                        "multiple" : Int.max])
            })
    }
}