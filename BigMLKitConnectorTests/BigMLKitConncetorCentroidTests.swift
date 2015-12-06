//
//  BigMLKitConncetorCentroidTests.swift
//  BigMLKitConnector
//
//  Created by sergio on 30/11/15.
//  Copyright © 2015 BigML Inc. All rights reserved.
//

import XCTest

import BigMLKitConnector

class BigMLKitConncetorCentroidTests: BigMLKitConnectorBaseTest {
    
    func localCentroidFromCluster(modelId : String,
        argsByName : [String : AnyObject],
        argsById : [String : AnyObject],
        completion : (Centroid, Centroid) -> ()) {
            
            self.connector!.getResource(BMLResourceType.Cluster, uuid: modelId) {
                (resource, error) -> Void in
                
                if let model = resource {
                    let pCluster = Cluster(jsonCluster: model.jsonDefinition)
                    let prediction1 = pCluster.centroid(
                        argsByName,
                        byName: true)
                    
                    let prediction2 = pCluster.centroid(
                        argsById,
                        byName: false)
                    
                    completion(prediction1, prediction2)
                    
                } else {
                    completion(Centroid(0, "", Double.NaN), Centroid(0, "", Double.NaN))
                }
            }
    }
    
    func localCentroidFromDataset(dataset : BMLMinimalResource,
        argsByName : [String : AnyObject],
        argsById : [String : AnyObject],
        completion : (Centroid, Centroid) -> ()) {
            
            self.connector!.createResource(BMLResourceType.Cluster,
                name: dataset.name,
                options: [:],
                from: dataset) { (resource, error) -> Void in
                    if let error = error {
                        print("Error: \(error)")
                    }
                    XCTAssert(resource != nil && error == nil)
                    
                    if let resource = resource {
                        
                        self.localCentroidFromCluster(resource.uuid,
                            argsByName: argsByName,
                            argsById: argsById) { (prediction1 : Centroid, prediction2 : Centroid) in
                                
                                self.connector!.deleteResource(BMLResourceType.Cluster, uuid: resource.uuid) {
                                    (error) -> Void in
                                    XCTAssert(error == nil, "Pass")
                                    completion(prediction1, prediction2)
                                }
                        }
                        
                    } else {
                        completion(Centroid(0, "", Double.NaN), Centroid(0, "", Double.NaN))
                    }
            }
    }

    func testIrisCentroid() {
        
        self.runTest("testIrisCentroid") { (exp) in
            
            self.localCentroidFromDataset(self.aDataset as! BMLMinimalResource,
                argsByName:[
                    "sepal length": 4.0,
                    "sepal width": 3.15,
                    "petal length": 4.07,
                    "petal width": 1.51,
                    "species": "iris-setosa"],
                argsById:[
                    "000000": 4.6,
                    "000001": 3.15,
                    "000002": 4.07,
                    "000003": 1.51,
                    "000005": "iris-virginica"]) {
                        (centroid1 : Centroid, centroid2 : Centroid) in
                        
                        XCTAssert(centroid1.centroidName == "Cluster 1" &&
                            compareDoubles(centroid1.centroidDistance, d2: 0.4382))
                        
                        XCTAssert(centroid2.centroidName == "Cluster 0" &&
                            compareDoubles(centroid2.centroidDistance, d2: 0.37444))
                        
                        exp.fulfill()
            }
        }
    }
    
    func testSalariesCentroid() {
        
        self.runTest("testSalariesCentroid") { (exp) in
            
            self.localCentroidFromDataset(self.altDataset as! BMLMinimalResource,
                argsByName:[
                    "Team": "Atlanta Braves",
                    "Salary": 1000000,
                    "Position": "Pitcher"],
                argsById:[
                    "000000": "Atlanta Braves",
                    "000001": 30000000000,
                    "000002": "Shortstop" ]) {
                        (centroid1 : Centroid, centroid2 : Centroid) in
                        
                        XCTAssert(centroid1.centroidName == "Cluster 1" &&
                            compareDoubles(centroid1.centroidDistance, d2: 0.5000))
                        
                        XCTAssert(centroid2.centroidName == "Cluster 2" &&
                            compareDoubles(centroid2.centroidDistance, d2: 4299.1490))
                        
                        exp.fulfill()
            }
        }
    }
    
}
