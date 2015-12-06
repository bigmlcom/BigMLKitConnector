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

public typealias Centroid = (centroidId : Int, centroidName : String, centroidDistance : Double)

/** A local predictive Cluster.

This module defines a Cluster to make predictions (centroids) locally or
embedded into your application without needing to send requests to
BigML.io.

This module cannot only save you a few credits, but also enormously
reduce the latency for each prediction and let you use your models
offline.

**/

let kOptionalFields = ["categorical", "text"]

public class Cluster : FieldedResource {
    
    var termForms : [String : [String : [String]]] = [:]
    var tagCloud : [String : AnyObject] = [:]
    var termAnalysis : [String : AnyObject] = [:]
    var centroids : [PredictionCentroid]
    let scales : [String : Double]

    var clusterDescription : String
    var ready : Bool
    
    static func predict(jsonCluster : [String : AnyObject],
        arguments : [String : AnyObject],
        options : [String : AnyObject]) -> Centroid {
        
            let fields = (jsonCluster["clusters"]?["fields"] as? [String : AnyObject] ?? [:])
            let inputData : [String : AnyObject] = fields.filter{ (key, _) in
                if let name = fields[key]?["name"] as? String {
                    return (arguments[name] != nil)
                }
                return false
            }.map{ (key : String, _ : AnyObject) -> (String, AnyObject) in
                if let name = fields[key]?["name"] as? String {
                    return (key, arguments[name]!)
                }
                assert(false, "Cluster.predict(...), map got corrupted?")
                return (key, "")
            }
            
            return Cluster(jsonCluster: jsonCluster).centroid(inputData,
                byName: options["byName"] as? Bool ?? false)
    }
    
    required public init(jsonCluster : [String : AnyObject]) {
        
        if let clusters = jsonCluster["clusters"]?["clusters"] as? [[String : AnyObject]],
            status = jsonCluster["status"] as? [String : AnyObject],
            code = status["code"] as? Int where code == 5 {
                self.centroids = clusters.map{
                    PredictionCentroid(cluster: $0)
                }
        } else {
            self.centroids = []
        }
        self.scales = jsonCluster["scales"] as? [String : Double] ?? [:]
        let summaryFields = jsonCluster["summary_fields"] as? [String] ?? []
        let fields = (jsonCluster["clusters"]?["fields"] as? [String : AnyObject] ?? [:]).filter{
            (key : String, value : AnyObject) in
            !summaryFields.contains(key)
        }
        for fieldId in self.scales.keys {
            assert(fields.keys.contains(fieldId), "Some fields are missing")
        }
        for (fieldId, field) in fields {
            if let field = field as? [String : AnyObject],
                optype = field["optype"] as? String where optype == "text" {
                    if let termForms = field["summary"]?["term_forms"] as? [String : [String]] {
                        print("CLUSTER TERMFORMS: \(termForms)")
                        self.termForms[fieldId] = termForms
                    }
                    if let tagCloud = field["summary"]?["tag_cloud"] {
                        self.tagCloud[fieldId] = tagCloud
                        print("TAG CLOUD FOR FIELD \(fieldId) = \(tagCloud)")
                    }
                    if let termAnalysis = field["term_analysis"] {
                        self.termAnalysis[fieldId] = termAnalysis
                    }
            }
        }
        self.clusterDescription =  jsonCluster["description"] as? String ?? ""
        self.ready = true
        super.init(fields: fields)
    }
    
    /**
    * Returns the list of parsed terms
    */
    func parseTerms(text : String, caseSensitive : Bool) -> [String] {
        
        let expression = "(\\b|_)([^\\b_\\s]+?)(\\b|_)"
        var terms = [String]()
        for result in text =~ expression {
            let term = (text as NSString).substringWithRange(result.range)
            terms.append(caseSensitive ? term : term.lowercaseString)
        }
        return terms
    }
    
    /**
    * Extracts the unique terms that occur in one of the alternative forms in
    * term_forms or in the tag cloud
    */
    func uniqueTerms(terms : [String], forms : [String : [String]], filter : [String])
        -> [String] {
            
            var extendForms : [String : String] = [:]
            let tagCloud = self.tagCloud.keys
            for (term, formList) in forms {
                for form in formList {
                    extendForms[form] = term
                }
                extendForms[term] = term
            }
            var termSet = Set<String>()
            for term in terms {
                if tagCloud.contains(term) {
                    termSet.insert(term)
                } else if let t = extendForms[term] {
                    termSet.insert(t)
                }
            }
            return Array<String>(termSet)
    }
    
    /**
    * Parses the input data to find the list of unique terms in the
    * tag cloud
    */
    func uniqueTerms(arguments : [String : AnyObject]) -> [String : [String]] {
        
        var uniqueTerms = [String : [String]]()
        for fieldId in self.termForms.keys {
            if let inputDataField = arguments[fieldId] as? String {
                let caseSensitive = self.termAnalysis[fieldId]?["case_sensitive"] as? Bool ?? true
                let tokenMode = self.termAnalysis[fieldId]?["token_mode"] as? String ?? "all"
                var terms = [String]()
                if tokenMode == Predicate.TM_FULL_TERMS {
                    terms = self.parseTerms(inputDataField, caseSensitive: caseSensitive)
                }
                if tokenMode == Predicate.TM_TOKENS {
                    terms.append(caseSensitive ? inputDataField : inputDataField.lowercaseString)
                }
                uniqueTerms.updateValue(self.uniqueTerms(terms,
                    forms: self.termForms[fieldId] ?? [:],
                    filter: self.tagCloud[fieldId] as? [String] ?? []),
                    forKey: fieldId)
            } else if let inputDataField = arguments[fieldId] {
                uniqueTerms.updateValue(inputDataField as? [String] ?? [], forKey:fieldId)
            }
        }
        return uniqueTerms
    }
    
    public func centroid(arguments : [String : AnyObject], byName : Bool) -> Centroid {
        
        var filteredArguments = self.filteredInputData(arguments, byName: byName)
        for (fieldId, field) in self.fields {
            if let optype = field["optype"] as? String where !kOptionalFields.contains(optype) {
                assert(filteredArguments.keys.contains(fieldId),
                    "Failed to predict a centroid. Arguments must contain values for all numeric fields.")
            }
        }
        filteredArguments = castArguments(filteredArguments, fields: self.fields)
        let uniqueTerms = self.uniqueTerms(filteredArguments)
        
        return nearest(filteredArguments, uniqueTerms: uniqueTerms)
    }
    
    func nearest(arguments : [String : AnyObject], uniqueTerms : [String : [String]])
        -> Centroid {

            var nearestCentroid = (centroidId: -1,
                centroidName: "",
                centroidDistance: Double.infinity);
            for centroid in self.centroids {
                let squareDistance = centroid.squareDistance(arguments,
                    uniqueTerms: uniqueTerms,
                    scales: self.scales,
                    nearestDistance: nearestCentroid.centroidDistance)
                if !squareDistance.isNaN {
                    nearestCentroid = (centroidId: centroid.centroidId,
                        centroidName: centroid.name,
                        centroidDistance: squareDistance);
                }
            }
            return (centroidId: nearestCentroid.centroidId,
                centroidName: nearestCentroid.centroidName,
                centroidDistance: sqrt(nearestCentroid.centroidDistance))
    }
}