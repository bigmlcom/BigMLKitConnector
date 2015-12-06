//
//  BigMLKitConnectorTests.swift
//  BigMLKitConnectorTests
//
//  Created by sergio on 28/04/15.
//  Copyright (c) 2015 BigML Inc. All rights reserved.
//

import UIKit
import XCTest

import BigMLKitConnector

class BigMLKitConnectorTests: BigMLKitConnectorBaseTest {
    
    func test0Create1Datasource() {
        
        self.runTest("testCreateDatasource") { (exp) in
            
            let filePath = NSBundle.pathForResource("wines.csv")
            let resource = BMLMinimalResource(name:"testCreateDatasource", type:BMLResourceType.File, uuid:filePath!)
            self.connector!.createResource(BMLResourceType.Source,
                name: "testCreateDatasource",
                options: [:],
                from: resource) { (resource, error) -> Void in
                    
                XCTAssert(resource != nil && error == nil, "Pass")
                exp.fulfill()
            }
        }
    }
    
    func test0Create3Anomaly() {
        
        self.runTest("testCreateAnomaly") { (exp) in
            self.connector!.createResource(BMLResourceType.Anomaly,
                name: "testCreateAnomaly",
                options: [:],
                from: self.aDataset!) { (resource, error) -> Void in
                    XCTAssert(resource != nil && error == nil, "Pass")
                    exp.fulfill()
            }
        }
    }
    
    func testCreateDatasourceWithOptions() {
        
        self.runTest("testCreateDatasourceWithOptions") { (exp) in
            
            let filePath = NSBundle.pathForResource("iris.csv")
            let resource = BMLMinimalResource(name:"testCreateDatasourceWithOptions",
                type:BMLResourceType.File,
                uuid:filePath!)
            self.connector!.createResource(BMLResourceType.Source,
                name: "testCreateDatasourceWithOptions",
                options: ["source_parser" : ["header" : false, "missing_tokens" : ["x"]]],
                from: resource) { (resource, error) -> Void in
                    exp.fulfill()
                    if let error = error {
                        print("Error: \(error)")
                    }
                    XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func testCreateDatasourceFail() {
        
        self.runTest("testCreateDatasourceFail") { (exp) in
            
            let filePath = NSBundle.pathForResource("iris.csv")
            let resource = BMLMinimalResource(name:"testCreateDatasourceFail",
                type:BMLResourceType.File,
                uuid:filePath!)
            self.connector!.createResource(BMLResourceType.Dataset, name: "testCreateDatasourceFail", options: [:], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(error != nil, "Pass")
            }
        }
    }

    func test1Create1DatasetWithOptions() {
        
        self.runTest("testCreateDatasetWithOptions") { (exp) in
            self.connector!.createResource(BMLResourceType.Dataset,
                name: "testCreateDatasetWithOptions",
                options: ["size" : 400,
                    "fields" : ["000001" : ["name" : "field_1"]]],
                from: self.aSource!) { (resource, error) -> Void in
                    exp.fulfill()
                    if let error = error {
                        print("Error: \(error)")
                    }
                    XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func test1Create1DatasetWithOptionsFail() {
        
        self.runTest("testCreateDatasetWithOptionsFail") { (exp) in
            self.connector!.createResource(BMLResourceType.Dataset,
                name: "testCreateDatasetWithOptionsFail",
                options: ["size" : "400",
                    "fields" : ["000001" : ["name" : "field_1"]]],
                from: self.aSource!) { (resource, error) -> Void in
                    exp.fulfill()
                    if let error = error {
                        print("Error: \(error)")
                    }
                    XCTAssert(resource == nil && error != nil, "Pass")
            }
        }
    }
    
    func testCreateDatasetFromCSVFail() {
        
        self.runTest("testCreateDatasetFromCSVFail") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateDatasetFromCSVFail", type:BMLResourceType.File, uuid:NSBundle.pathForResource("iris.csv")!)
            self.connector!.createResource(BMLResourceType.Dataset,
                name: "testCreateDatasetFromCSVFail",
                options: [:],
                from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(resource == nil && error?.code == 400, "Pass")
            }
        }
    }
    
    func testCreateProject() {
        
        self.runTest("testCreateProject") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateProject", type:BMLResourceType.Project, uuid:"")
            self.connector!.createResource(BMLResourceType.Project,
                name: "testCreateProject",
                options: ["description" : "This is a test project", "tags" : ["a", "b", "c"]],
                from: resource) { (resource, error) -> Void in
                    if let error = error {
                        print("Error: \(error)")
                    }
                    print("Project: \(resource?.uuid)")
                    XCTAssert(resource != nil && error == nil, "Pass")
                    exp.fulfill()
            }
        }
    }
    
    func testUpdateProject() {
        
        self.runTest("testCreateProject") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateProject", type:BMLResourceType.Project, uuid:"")
            self.connector!.createResource(BMLResourceType.Project,
                name: "testCreateProject",
                options: ["description" : "This is a test project", "tags" : ["a", "b", "c"]],
                from: resource) { (resource, error) -> Void in
                    if let resource = resource {
                        self.connector!.updateResource(BMLResourceType.Project,
                            uuid: resource.uuid,
                            values: ["name" : "testUpdateProject"]) { (error) -> Void in
                                if (error == nil) {
                                    self.connector!.getResource(BMLResourceType.Project, uuid: resource.uuid) { (resource, error) -> Void in
                                        XCTAssert(error != nil && resource?.name == "testUpdateProject", "Pass")
                                    }
                                } else {
                                    XCTAssert(false, "Pass")
                                }
                                exp.fulfill()
                        }
                    } else {
                        print("Error: \(error)")
                    }
                    XCTAssert(resource != nil && error == nil, "Pass")
                    exp.fulfill()
            }
        }
    }
    
    func testDeleteProject() {
        
        self.runTest("testDeleteProject") { (exp) in
            self.connector!.listResources(BMLResourceType.Project, filters: ["limit" : 5]) { (resources, error) -> Void in
                self.connector!.deleteResource(BMLResourceType.Project, uuid: resources[0].uuid) { (error) -> Void in
                    if (error == nil) {
                        self.connector!.getResource(BMLResourceType.Project, uuid: resources[0].uuid) { (resource, error) -> Void in
                            XCTAssert(error != nil, "Pass")
                        }
                    } else {
                        XCTAssert(false, "Pass")
                    }
                    exp.fulfill()
                }
            }
        }
    }
    
    func testListDataset() {
        
        self.runTest("testListDataset") { (exp) in
            self.connector!.listResources(BMLResourceType.Dataset, filters: ["limit" : 5]) { (resources, error) -> Void in
                exp.fulfill()
                XCTAssert(resources.count == 5 && error == nil, "Pass")
            }
        }
    }
    
    func testGetDataset() {
        
        self.runTest("testGetDataset") { (exp) in
            let source = self.aDataset!
            self.connector!.getResource(source.type, uuid: source.uuid) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(error == nil && resource != nil, "Pass")
            }
        }
    }
    
    func testDeleteDataset() {
        
        self.runTest("testDeleteDataset") { (exp) in
            self.connector!.listResources(BMLResourceType.Dataset, filters: ["limit" : 5]) { (resources, error) -> Void in
                self.connector!.deleteResource(BMLResourceType.Dataset, uuid: resources[0].uuid) { (error) -> Void in
                    if (error == nil) {
                        self.connector!.getResource(BMLResourceType.Source, uuid: resources[0].uuid) { (resource, error) -> Void in
                            XCTAssert(error != nil, "Pass")
                        }
                    } else {
                        XCTAssert(false, "Pass")
                    }
                    exp.fulfill()
                }
            }
        }
    }
    
    func testDeleteDatasetFail() {
        
        self.runTest("testDeleteDatasetFail") { (exp) in
            self.connector!.deleteResource(BMLResourceType.Source, uuid: "testDeleteDatasetFail") { (error) -> Void in
                exp.fulfill()
                if let error = error {
                    print("Error: \(error)")
                }
                XCTAssert(error != nil, "Pass")
            }
        }
    }
    
    func testUpdateDataset() {
        
        self.runTest("testUpdateDataset") { (exp) in
            self.connector!.listResources(BMLResourceType.Dataset, filters: ["limit" : 5]) { (resources, error) -> Void in
                self.connector!.updateResource(BMLResourceType.Dataset,
                    uuid: resources[0].uuid,
                    values: ["name" : "testUpdateDataset"]) { (error) -> Void in
                        if (error == nil) {
                            self.connector!.getResource(BMLResourceType.Source, uuid: resources[0].uuid) { (resource, error) -> Void in
                                XCTAssert(error != nil && resource?.name == "testUpdateDataset", "Pass")
                            }
                        } else {
                            XCTAssert(false, "Pass")
                        }
                        exp.fulfill()
                }
            }
        }
    }
    
    func testUpdateDatasetFail() {
        
        self.runTest("testUpdateDatasetFail") { (exp) in
            self.connector!.listResources(BMLResourceType.Dataset, filters: ["limit" : 5]) { (resources, error) -> Void in
                self.connector!.updateResource(BMLResourceType.Dataset,
                    uuid: resources[0].uuid,
                    values: [:]) { (error) -> Void in

                        XCTAssert(error != nil, "Pass")
                        exp.fulfill()
                }
            }
        }
    }
    
    func testGetDatasetFail() {
        
        self.runTest("testGetDatasetFail") { (exp) in
            self.connector!.getResource(BMLResourceType.Source, uuid: "no-uuid") { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(error != nil && resource == nil, "Pass")
            }
        }
    }
    
    func testRunScoreTest() {
        
        self.runTest("testRunScoreTest") { (exp) in
            
            
            self.connector!.createResource(BMLResourceType.Anomaly,
                name: "testCreateAnomaly",
                options: [:],
                from: self.aDataset!) { (resource, error) -> Void in
                    XCTAssert(resource != nil && error == nil, "Pass")
                    let anAnomaly = resource
                    self.connector!.getResource(anAnomaly!.type, uuid: anAnomaly!.uuid) { (resource, error) -> Void in
                        XCTAssert(error == nil && resource != nil, "Pass")
                        let a = Anomaly(anomaly: resource!)
                        let score = a.score(["Country" : "France", "Price" : 20, "Total Sales" : 133])
                        print("Score: \(score)")
                        exp.fulfill()
                    }
            }
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
