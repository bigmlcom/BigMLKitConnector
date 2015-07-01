//
//  Anomaly.swift
//  BigMLX
//
//  Created by sergio on 19/06/15.
//  Copyright (c) 2015 sergio. All rights reserved.
//

import Foundation

let DEPTH_FACTOR : Double = 0.5772156649

/**
* Tree structure for the BigML anomaly detector
*
* This class defines an auxiliary tree that is used when calculating
* anomaly scores without needing to send requests to BigML.io.
*
*/
class AnomalyTree {
    
    internal let fields : [String : AnyObject]
    let anomaly : Anomaly
    var predicates : Predicates
    var id : String = ""
    var children : [AnomalyTree] = []
    
    init(tree : [String : AnyObject], anomaly : Anomaly) {
        
        self.anomaly = anomaly
        self.fields = anomaly.fields
        self.predicates = Predicates(predicates: ["True"])
        if let predicates = tree["predicates"] as? [[String : AnyObject]] {
            self.predicates = Predicates(predicates: predicates)
        }
        if let id = tree["id"] as? String {
            self.id = id
        }
        if let children = tree["children"] as? [[String : AnyObject]] {
            self.children = children.map {
                AnomalyTree(tree: $0, anomaly: anomaly)
            }
        }
    }
    
    /**
    *
    * Returns the depth of the tree that the input data "verifies"
    * and the associated set of rules.
    *
    * If a node has any child whose predicates are all true for the given
    * input, then the depth is incremented and we flow through.
    * If the node has no children or no children with all valid predicates,
    * then it outputs the depth of the node.
    *
    * @return
    */
    func depth(input : [String : AnyObject], path : [String] = [], depth : Int = 0) -> (Int, [String]) {
        
        var depth = depth
        if depth == 0 {
            if !self.predicates.apply(input, fields: self.fields) {
                return (depth, path)
            }
            depth++
        }
        var path = path
        for child in self.children {
            if child.predicates.apply(input, fields: self.fields) {
                path.append(child.predicates.rule(self.fields))
                return child.depth(input, path: path, depth: depth+1)
            }
            if self.anomaly.stopped {
                return (0, [])
            }
        }
        return (depth, path)
    }
}

public class Anomaly : FieldedResource {
    
    let sampleSize : Double?
    let inputFields : [String]?
    var meanDepth : Double?
    var expectedMeanDepth : Double? = .None
    var iforest : [AnomalyTree?]?
    internal var stopped : Bool = false
    var anomalyCount : Int = 0
    
    public init(anomaly : BMLResource) {
        
        assert(anomaly.type == BMLResourceType.Anomaly, "Wrong resource passed in -- anomaly expected")
        //        println("RESOURCE \(anomaly.jsonDefinition)")
        if let sampleSize = anomaly.jsonDefinition["sample_size"] as? Double,
            inputFields = anomaly.jsonDefinition["input_fields"] as? [String] {
                
                self.sampleSize = sampleSize
                self.inputFields = inputFields
                
        } else {
            
            self.sampleSize = .None
            self.inputFields = .None
        }
        if let model = anomaly.jsonDefinition["model"] as? [String : AnyObject],
            fields = model["fields"] as? [String : AnyObject] {
                
                if let topAnomalies = model["top_anomalies"] as? [AnyObject] {
                    
                    super.init(fields: fields)
                    
                    self.meanDepth = model["mean_depth"] as? Double
                    if let status = anomaly.jsonDefinition["status"] as? [String : AnyObject],
                        intCode = status["code"] as? Int {
                            
                            let code = BMLResourceStatus(integerLiteral: intCode)
                            if (code == BMLResourceStatus.Ended) {
                                if let sampleSize = self.sampleSize, let meanDepth = self.meanDepth {
                                    let defaultDepth = 2 * (DEPTH_FACTOR + log(sampleSize - 1) - ((sampleSize - 1) / sampleSize))
                                    self.expectedMeanDepth = min(meanDepth, defaultDepth)
                                } else {
                                    //-- HANDLE ERROR HERE: anomaly is not complete
                                }
                                if let iforest = model["trees"] as? [AnyObject] {
                                    self.iforest = iforest.map {
                                        if let tree = $0 as? [String : AnyObject],
                                            root = tree["root"] as? [String : AnyObject] {
                                                return AnomalyTree(tree: root, anomaly: self)
                                        } else {
                                            return .None
                                        }
                                    }
                                }
                            } else {
                                //-- HANDLE ERROR HERE: anomaly is not complete
                            }
                    }
                } else {
                    self.meanDepth = 0
                    super.init(fields: fields)
                }
        } else {
            self.meanDepth = 0
            super.init(fields: [:])
        }
    }
    
    public func score(input : [String : AnyObject], byName : Bool = true) -> Double {
        
        self.stopped = false
        assert(self.iforest != nil, "Could not find forest info. The anomaly was possibly not completely created")
        if let iforest = self.iforest {
            let inputData = self.filterInputData(input, byName: byName)
            var depthSum = iforest.reduce(0) {
                if let tree = $1 {
                    return $0 + (self.stopped ? 0 : tree.depth(inputData).0)
                }
                assert(false, "Should not be here: non-tree found in forest!")
                return 0
            }
            let observedMeanDepth = Double(depthSum) / Double(iforest.count)
            return pow(2.0, -observedMeanDepth / self.expectedMeanDepth!)
        }
        return 0
    }
    
    public func stop() {
        self.stopped = true
    }
    
    public func unstop() {
        self.stopped = false
    }
    
    public func isStopped() -> Bool {
        return self.stopped
    }
}