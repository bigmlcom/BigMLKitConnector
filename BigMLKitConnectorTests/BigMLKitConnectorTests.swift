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

extension NSBundle {
    
    class func pathForResource(resource : String) -> String? {
        
        for bundle in NSBundle.allBundles() {
            if let filePath = bundle.pathForResource(resource, ofType:.None) {
                return filePath
            }
        }
        return nil
    }
}

@objc class BigMLKitTestCredentials {
    
    class func credentials() -> NSDictionary {
        return NSDictionary.init(contentsOfFile:NSBundle.pathForResource("credentials.plist")!)!
    }
    
    class func username() -> String {
        return self.credentials()["username"] as! String
    }
    
    class func apiKey() -> String {
        return self.credentials()["apiKey"] as! String
    }
}

//let signalHandler = CFunctionPointer<((Int32) -> Void)>(COpaquePointer(UnsafePointer<(Int32)->Void>(sigHandler)))

class BigMLKitConnectorTests: XCTestCase {
    
    var connector = BMLConnector(username:BigMLKitTestCredentials.username(), apiKey:BigMLKitTestCredentials.apiKey(), mode:BMLMode.Development)
    
    override func setUp() {
        super.setUp()

        installSigHandler();
        self.connector = BMLConnector(username:BigMLKitTestCredentials.username(), apiKey:BigMLKitTestCredentials.apiKey(), mode:BMLMode.Development)
}
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func runTest(name : String, test : XCTestExpectation -> Void) {
        
        let exp = self.expectationWithDescription(name)
        test(exp)
        self.waitForExpectationsWithTimeout(360) { (error) in
            println("Expect error \(error)")
        }
    }

    func testCreateDatasource() {
        
        self.runTest("testCreateDatasource") { (exp) in
            
            let filePath = NSBundle.pathForResource("iris.csv")
            let resource = BMLMinimalResource(name:"testCreateDatasource", rawType:BMLResourceType.File, uuid:filePath!)
            self.connector.createResource(BMLResourceType.Source, name: "testCreateDatasource", options: ["" : ""], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func testCreateDatasourceWithOptions() {
        
        self.runTest("testCreateDatasourceWithOptions") { (exp) in
            
            let filePath = NSBundle.pathForResource("iris.csv")
            let resource = BMLMinimalResource(name:"testCreateDatasourceWithOptions", rawType:BMLResourceType.File, uuid:filePath!)
            self.connector.createResource(BMLResourceType.Source,
                name: "testCreateDatasourceWithOptions",
                options: ["source_parser" : ["header" : false, "missing_tokens" : ["x"]]],
                from: resource) { (resource, error) -> Void in
                    exp.fulfill()
                    if let error = error {
                        println("Error: \(error)")
                    }
                    XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func testCreateDatasourceFail() {
        
        self.runTest("testCreateDatasourceFail") { (exp) in
            
            let filePath = NSBundle.pathForResource("iris.csv")
            let resource = BMLMinimalResource(name:"testCreateDatasourceFail", rawType:BMLResourceType.File, uuid:filePath!)
            self.connector.createResource(BMLResourceType.Dataset, name: "testCreateDatasourceFail", options: ["" : ""], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(error != nil, "Pass")
            }
        }
    }

    func testCreateDataset() {
        
        self.runTest("testCreateDataset") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateDataset", rawType:BMLResourceType.Source, uuid:"5540b821c0eea909d0000525")
            self.connector.createResource(BMLResourceType.Dataset,
                name: "testCreateDataset",
                options: [:], from: resource) { (resource, error) -> Void in
                    exp.fulfill()
                    XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func testCreateDatasetWithOptions() {
        
        self.runTest("testCreateDatasetWithOptions") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateDatasetWithOptions", rawType:BMLResourceType.Source, uuid:"5540b821c0eea909d0000525")
            self.connector.createResource(BMLResourceType.Dataset,
                name: "testCreateDatasetWithOptions",
                options: ["size" : 400,
                    "fields" : ["000001" : ["name" : "field_1"]]],
                from: resource) { (resource, error) -> Void in
                    exp.fulfill()
                    if let error = error {
                        println("Error: \(error)")
                    }
                    XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func testCreateDatasetWithOptionsFail() {
        
        self.runTest("testCreateDatasetWithOptionsFail") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateDatasetWithOptionsFail", rawType:BMLResourceType.Source, uuid:"5540b821c0eea909d0000525")
            self.connector.createResource(BMLResourceType.Dataset,
                name: "testCreateDatasetWithOptionsFail",
                options: ["size" : "400",
                    "fields" : ["000001" : ["name" : "field_1"]]],
                from: resource) { (resource, error) -> Void in
                    exp.fulfill()
                    if let error = error {
                        println("Error: \(error)")
                    }
                    XCTAssert(resource == nil && error != nil, "Pass")
            }
        }
    }
    
    func testCreateDatasetFromCSVFail() {
        
        self.runTest("testCreateDatasetFromCSVFail") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateDatasetFromCSVFail", rawType:BMLResourceType.File, uuid:NSBundle.pathForResource("iris.csv")!)
            self.connector.createResource(BMLResourceType.Dataset, name: "testCreateDatasetFromCSVFail", options: ["" : ""], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func testCreateAnomaly() {
        
        self.runTest("testCreateAnomaly") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateAnomaly", rawType:BMLResourceType.Dataset, uuid:"554a3b4977920c09e3000431")
            self.connector.createResource(BMLResourceType.Anomaly, name: "testCreateAnomaly", options: ["" : ""], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func testCreateProject() {
        
        self.runTest("testCreateProject") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateProject", rawType:BMLResourceType.Project, uuid:"")
            self.connector.createResource(BMLResourceType.Project,
                name: "testCreateProject",
                options: ["description" : "This is a test project", "tags" : ["a", "b", "c"]],
                from: resource) { (resource, error) -> Void in
                    if let error = error {
                        println("Error: \(error)")
                    }
                    println("Project: \(resource?.uuid)")
                    XCTAssert(resource != nil && error == nil, "Pass")
                    exp.fulfill()
            }
        }
    }
    
    func testUpdateProject() {
        
        self.runTest("testCreateProject") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateProject", rawType:BMLResourceType.Project, uuid:"")
            self.connector.createResource(BMLResourceType.Project,
                name: "testCreateProject",
                options: ["description" : "This is a test project", "tags" : ["a", "b", "c"]],
                from: resource) { (resource, error) -> Void in
                    if let resource = resource {
                        self.connector.updateResource(BMLResourceType.Project,
                            uuid: resource.uuid,
                            values: ["name" : "testUpdateProject"]) { (error) -> Void in
                                if (error == nil) {
                                    self.connector.getResource(BMLResourceType.Project, uuid: resource.uuid) { (resource, error) -> Void in
                                        XCTAssert(error != nil && resource?.name == "testUpdateProject", "Pass")
                                    }
                                } else {
                                    XCTAssert(false, "Pass")
                                }
                                exp.fulfill()
                        }
                    } else {
                        println("Error: \(error)")
                    }
                    XCTAssert(resource != nil && error == nil, "Pass")
                    exp.fulfill()
            }
        }
    }
    
    func testDeleteProject() {
        
        self.runTest("testDeleteProject") { (exp) in
            self.connector.listResources(BMLResourceType.Project, filters: ["limit" : 5]) { (resources, error) -> Void in
                self.connector.deleteResource(BMLResourceType.Project, uuid: resources[0].uuid) { (error) -> Void in
                    if (error == nil) {
                        self.connector.getResource(BMLResourceType.Project, uuid: resources[0].uuid) { (resource, error) -> Void in
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
            self.connector.listResources(BMLResourceType.Dataset, filters: ["limit" : 5]) { (resources, error) -> Void in
                exp.fulfill()
                XCTAssert(count(resources) == 4 && error == nil, "Pass")
            }
        }
    }
    
    func testGetDataset() {
        
        self.runTest("testGetDataset") { (exp) in
            self.connector.getResource(BMLResourceType.Source, uuid: "5540b821c0eea909d0000525") { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(error == nil && resource != nil, "Pass")
            }
        }
    }
    
    func testDeleteDataset() {
        
        self.runTest("testDeleteDataset") { (exp) in
            self.connector.listResources(BMLResourceType.Dataset, filters: ["limit" : 5]) { (resources, error) -> Void in
                self.connector.deleteResource(BMLResourceType.Dataset, uuid: resources[0].uuid) { (error) -> Void in
                    if (error == nil) {
                        self.connector.getResource(BMLResourceType.Source, uuid: resources[0].uuid) { (resource, error) -> Void in
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
            self.connector.deleteResource(BMLResourceType.Source, uuid: "testDeleteDatasetFail") { (error) -> Void in
                exp.fulfill()
                if let error = error {
                    println("Error: \(error)")
                }
                XCTAssert(error != nil, "Pass")
            }
        }
    }
    
    func testUpdateDataset() {
        
        self.runTest("testUpdateDataset") { (exp) in
            self.connector.listResources(BMLResourceType.Dataset, filters: ["limit" : 5]) { (resources, error) -> Void in
                self.connector.updateResource(BMLResourceType.Dataset,
                    uuid: resources[0].uuid,
                    values: ["name" : "testUpdateDataset"]) { (error) -> Void in
                        if (error == nil) {
                            self.connector.getResource(BMLResourceType.Source, uuid: resources[0].uuid) { (resource, error) -> Void in
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
            self.connector.listResources(BMLResourceType.Dataset, filters: ["limit" : 5]) { (resources, error) -> Void in
                self.connector.updateResource(BMLResourceType.Dataset,
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
            self.connector.getResource(BMLResourceType.Source, uuid: "no-uuid") { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(error != nil && resource == nil, "Pass")
            }
        }
    }
    
    func testRunScoreTest() {
        
        self.runTest("testRunScoreTest") { (exp) in
            self.connector.getResource(BMLResourceType.Anomaly, uuid: "55672e798a318f0717000598") { (resource, error) -> Void in
                XCTAssert(error == nil && resource != nil, "Pass")
                let a = Anomaly(anomaly: resource!)
                let score = a.score(["Country" : "France", "Price" : "25", "Total Sales" : "133"])
                println("Score: \(score)")
                exp.fulfill()
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
