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

let ML_DEFAULT_LOCALE = "en_US.UTF-8"

public class Model : FieldedResource {
    
//    var fieldImportance : [String : Double]
//    let resourceId : String
    let description : String
    
    let tree : PredictionTree
    var idsMap : [Int : AnyObject]
//    let terms : [String : AnyObject]
    var treeInfo : [String : AnyObject]
    
    let model : [String : AnyObject]
    
    required public init(jsonModel : [String : AnyObject]) {
        
//        let status = jsonModel["status"] as? [String : AnyObject] ?? [:]
//        assert(status["code"] as? Int == 5, "Model is not ready")
        
        var fields : [String : AnyObject]

        let model = jsonModel["model"] as? [String : AnyObject] ?? [:]
        fields = model["model_fields"] as? [String : AnyObject] ?? [:]
        let modelFields = model["fields"] as? [String : AnyObject] ?? [:]
        
        for fieldName in fields.keys {
            let modelField = modelFields[fieldName] as? [String : AnyObject] ?? [:]
            var field = fields[fieldName] as? [String : AnyObject] ?? [:]
            field.updateValue(modelField["summary"] ?? "", forKey:"summary")
            field.updateValue(modelField["name"] ?? "", forKey:"name")
        }
        
//        let objectiveField : String
//        if let objectiveFields = model["objective_field"] as? [String] {
//            objectiveField = objectiveFields[0]
//        } else {
            let objectiveField = model["objective_field"] as? String ?? ""
//        }
        
        let locale = jsonModel["locale"] as? String ?? ML_DEFAULT_LOCALE
        
        self.treeInfo = ["maxBins" : 0]
        self.model = jsonModel
        self.description = jsonModel["description"] as? String ?? ""
        
//        if let modelFieldImportance = model["importance"] as? [[AnyObject]] {
//            self.fieldImportance = modelFieldImportance.filter {
//                if  let x = $0.first as? String {
//                    return fields[x] != nil
//                }
//                return false
//            }
//        }
        
        let distribution = model["distribution"] as? [String : AnyObject] ?? [:]
        self.idsMap = [:]
        self.tree = PredictionTree(tree: model["root"] as? [String : AnyObject] ?? [:],
            fields: fields,
            objectiveFields: [objectiveField],
            rootDistribution: distribution["training"] as? [String : AnyObject] ?? [:],
            parentId:-1,
            idsMap: &idsMap,
            isSubtree: true,
            treeInfo: &self.treeInfo)
        
//        if self.tree.isRegression() {
//            self.maxBins = self.tree.maxBins
//        }
        super.init(fields: fields, objectiveId: objectiveField, locale: locale, missingTokens: [])
    }
    
    func roundedConfidence(confidence : Double, precision : Double = 0.001) -> Double {
        return floor(confidence / precision) * precision
    }
    
    public func predict(arguments : [String : AnyObject], options : [String : Any])
        -> [String : Any] {
            
            assert(arguments.count > 0, "Prediction arguments missing")
            let byName = options["byName"] as? Bool ?? false
            let missingStrategy = options["strategy"] as? MissingStrategy ?? MissingStrategy.LastPrediction
            let multiple = options["multiple"] as? Int ?? 0
            
            let arguments = castArguments(self.filteredInputData(arguments, byName: byName),
                fields: self.fields)
            
            var prediction = self.tree.predict(arguments,
                path: [],
                strategy: missingStrategy).prediction
            
            var output : [String : Any] = [:]
            let distribution = prediction.distribution
            if multiple > 0 && !self.tree.isRegression() {
                for var i = 0; i < [multiple, distribution.count].minElement(); ++i {
                    let distributionElement = distribution[i]
                    let category = distributionElement.0
                    let confidence = wsConfidence(category, distribution: distribution)
                    let probability = ((Double(distributionElement.1) ?? Double.NaN) /
                        (Double(prediction.count) ?? Double.NaN))
                    output = [
                        "prediction" : category,
                        "confidence" : self.roundedConfidence(confidence),
                        "probability" : probability,
                        "distribution" : distribution,
                        "count" : distributionElement.value
                    ]
                }
            } else {
                
                let children = prediction.children
                if let firstChild = children.first {
                    let field = firstChild.predicate.field
                    if let _ = self.fields[field],
                        field = self.fieldNameById[field] {
                            prediction.next = field
                    }
                }
                output = [
                    "prediction" : prediction.prediction,
                    "confidence" : self.roundedConfidence(prediction.confidence),
                    "distribution" : distribution,
                    "count" : prediction.count
                ]
            }
            return output
    }
}