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

public class Ensemble {
    
    public var isReadyToPredict : Bool
    
    private var distributions : [[String : AnyObject]]
    private var multiModels : [MultiModel]
    
    static private func multiModels(models : [[String : AnyObject]], maxModels : Int)
        -> [MultiModel] {
            
            return 0.stride(to: models.count, by: maxModels)
                .map { MultiModel(models:Array(models[$0..<$0.advancedBy(maxModels, limit: models.count)])) }
    }
    
    public required init(models : [[String : AnyObject]],
        maxModels : Int = Int.max,
        distributions : [[String : AnyObject]] = []) {
        
            assert(models.count > 0)
            assert(maxModels >= 0)
        
            self.multiModels = Ensemble.multiModels(models, maxModels: maxModels)
            self.isReadyToPredict = true
            self.distributions = distributions
    }
    
    public func predict(arguments : [String : AnyObject], options : [String : AnyObject])
        -> [String : Any] {
        
        assert(self.isReadyToPredict)
        
        let method = options["method"] as? PredictionMethod ?? PredictionMethod.Plurality
        let missingStrategy = options["strategy"] as? MissingStrategy ??
            MissingStrategy.LastPrediction
        let byName = options["byName"] as? Bool ?? true
        let confidence = options["confidence"] as? Bool ?? true
        let distribution = options["distribution"] as? Bool ?? false
        let count = options["count"] as? Bool ?? false
        let median = options["median"] as? Bool ?? false
        let min = options["min"] as? Bool ?? false
        let max = options["max"] as? Bool ?? false
                
        let votes = self.multiModels.map{ (multiModel : MultiModel) in
            multiModel.generateVotes(arguments,
                byName: byName,
                missingStrategy: missingStrategy,
                median: median)
        }
        let multiVote = MultiVote(predictions: [])
        for v in votes {
            if (median) {
                v.addMedian()
            }
            multiVote.extend(v)
        }
        return multiVote.combine(method,
            confidence: confidence,
            distribution: distribution,
            count: count,
            median: median,
            addMin: min,
            addMax: max,
            options: options)
    }
}