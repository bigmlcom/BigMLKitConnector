//
//  BigMLKitConnectorEnsembleTests.swift
//  BigMLKitConnector
//
//  Created by sergio on 07/12/15.
//  Copyright © 2015 BigML Inc. All rights reserved.
//

import XCTest

import BigMLKitConnector

class BigMLKitConnectorEnsembleTests: BigMLKitConnectorBaseTest {
    
    func localPredictionFromEnsemble(resId : String,
        argsByName : [String : AnyObject],
        argsById : [String : AnyObject],
        completion : ([String : Any], [String : Any]) -> ()) {
            
            self.connector!.getResource(BMLResourceType.Ensemble, uuid: resId) {
                (resource, error) -> Void in
                
                if let ensemble = resource {
                    let pModel = Ensemble(models: ensemble.jsonDefinition["models"] as! [[String : AnyObject]])
                    let prediction1 = pModel.predict(
                        argsByName,
                        options: ["byName" : true])
                    
                    let prediction2 = pModel.predict(
                        argsById,
                        options: ["byName" : false])
                    
                    completion(prediction1, prediction2)
                    
                } else {
                    completion([:], [:])
                }
            }
    }
    
    func localPredictionFromDataset(dataset : BMLMinimalResource,
        argsByName : [String : AnyObject],
        argsById : [String : AnyObject],
        completion : ([String : Any], [String : Any]) -> ()) {
            
            self.connector!.createResource(BMLResourceType.Ensemble,
                name: dataset.name,
                options: [:],
                from: dataset) { (resource, error) -> Void in
                    if let error = error {
                        print("Error: \(error)")
                    }
                    XCTAssert(resource != nil && error == nil)
                    
                    if let resource = resource {
                        
                        self.localPredictionFromEnsemble(resource.uuid,
                            argsByName: argsByName,
                            argsById: argsById) { (prediction1 : [String : Any],
                                prediction2 : [String : Any]) in
                                
                                self.connector!.deleteResource(BMLResourceType.Ensemble,
                                    uuid: resource.uuid) {
                                    (error) -> Void in
                                    XCTAssert(error == nil, "Pass")
                                    completion(prediction1, prediction2)
                                }
                        }
                        
                    } else {
                        completion([:], [:])
                    }
            }
    }
    
    func testStoredIrisEnsemble() {
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let path = bundle.pathForResource("iris", ofType:"ensemble")
        let data = NSData(contentsOfFile:path!)!
        let ensemble = try! NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions.AllowFragments) as? [String : AnyObject] ?? [:]
        
        var models : [[String : AnyObject]] = []
        let m = (ensemble["models"] as? [String] ?? [])
        let semaphore = dispatch_semaphore_create(0)
        var remaining = m.count
        for model in m {
            
            self.connector!.getResource(BMLResourceType.Model, uuid: model){
                (resource, error) -> Void in
                models.append(resource as? [String:AnyObject] ?? [:])
                if --remaining == 0 {
                    dispatch_semaphore_signal(semaphore)
                }
            }
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        let prediction = Ensemble(models: models).predict([
            "sepal length": 6.02,
            "sepal width": 3.15,
            "petal width": 1.51,
            "petal length": 4.07],
            options: ["byName" : true])
            
            XCTAssert(prediction["prediction"] as! String == "Iris-versicolor" &&
                compareDoubles(prediction["confidence"] as! Double, d2: 0.92444))
    }
    
    func testWinePrediction() {
        
        self.runTest("testWinesPrediction") { (exp) in
            
            let filePath = NSBundle.pathForResource("wines.csv")
            let resource = BMLMinimalResource(name:"testWinePrediction",
                type:BMLResourceType.File,
                uuid:filePath!)
            
            self.connector!.createResource(BMLResourceType.Source,
                name: "testWinesPrediction",
                options: [:],
                from: resource) { (resource, error) -> Void in
                    XCTAssert(resource != nil && error == nil, "Pass")
                    
                    self.connector!.createResource(BMLResourceType.Dataset,
                        name: "testWinesPrediction",
                        options: [:],
                        from: resource!) { (resource, error) -> Void in
                            XCTAssert(resource != nil && error == nil, "Pass")
                            
                            self.localPredictionFromDataset(resource as! BMLMinimalResource,
                                argsByName:[
                                    "Price": 32.0,
                                    "Grape": "Cabernet Sauvignon",
                                    "Country": "France",
                                    "Rating": 90],
                                argsById:[
                                    "000004": 32.0,
                                    "000001": "Cabernet Sauvignon",
                                    "000000": "France",
                                    "000002": 90 ]) { (prediction1 : [String : Any], prediction2 : [String : Any]) in
                                        
                                        XCTAssert(compareDoubles(prediction1["prediction"] as! Double, d2: 78.5714) &&
                                            compareDoubles(prediction1["confidence"] as! Double, d2: 17.496))
                                        
                                        XCTAssert(compareDoubles(prediction2["prediction"] as! Double, d2: 78.5714) &&
                                            compareDoubles(prediction2["confidence"] as! Double, d2: 17.496))
                                        
                                        exp.fulfill()
                            }
                    }
            }
        }
    }
    
    func testIrisPrediction() {
        
        self.runTest("testIrisPrediction") { (exp) in
            
            self.localPredictionFromDataset(self.aDataset as! BMLMinimalResource,
                argsByName:[
                    "sepal width": 3.15,
                    "petal length": 4.07,
                    "petal width": 1.51],
                argsById:[
                    "000001": 3.15,
                    "000002": 4.07,
                    "000003": 1.51 ]) {
                        (prediction1 : [String : Any], prediction2 : [String : Any]) in
                        
                        XCTAssert(prediction1["prediction"] as! String == "Iris-versicolor" &&
                            compareDoubles(prediction1["confidence"] as! Double, d2: 0.92444))
                        
                        XCTAssert(prediction2["prediction"] as! String == "Iris-versicolor" &&
                            compareDoubles(prediction2["confidence"] as! Double, d2: 0.92444))
                        
                        exp.fulfill()
            }
        }
    }
}