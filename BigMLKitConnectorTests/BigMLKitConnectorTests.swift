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
    
    var connector = BMLConnector(username:BigMLKitTestCredentials.username(), apiKey:BigMLKitTestCredentials.apiKey(), mode:BMLMode.BMLDevelopmentMode)
    
    override func setUp() {
        super.setUp()

        installSigHandler();
        self.connector = BMLConnector(username:BigMLKitTestCredentials.username(), apiKey:BigMLKitTestCredentials.apiKey(), mode:BMLMode.BMLDevelopmentMode)
}
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func runTest(name : String, test : XCTestExpectation -> Void) {
        
        let exp = self.expectationWithDescription(name)
        test(exp)
        self.waitForExpectationsWithTimeout(30) { (error) in
            println("Expect error \(error)")
        }
    }

    func testCreateDatasource() {
        
        self.runTest("testCreateDatasource") { (exp) in
            
            let filePath = NSBundle.pathForResource("iris.csv")
            let resource = BMLMinimalResource(name:"testCreateDatasource", type:BMLResourceType.File, uuid:filePath!)
            self.connector.createResource(BMLResourceType.Source, name: "testCreateDatasource", options: ["" : ""], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func testCreateDatasourceFail() {
        
        self.runTest("testCreateDatasourceFail") { (exp) in
            
            let filePath = NSBundle.pathForResource("iris.csv")
            let resource = BMLMinimalResource(name:"testCreateDatasourceFail", type:BMLResourceType.File, uuid:filePath!)
            self.connector.createResource(BMLResourceType.Dataset, name: "testCreateDatasourceFail", options: ["" : ""], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(error != nil, "Pass")
            }
        }
    }
    
    func testCreateDataset() {
        
        self.runTest("testCreateDataset") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateDataset", type:BMLResourceType.Source, uuid:"5540b821c0eea909d0000525")
            self.connector.createResource(BMLResourceType.Dataset, name: "testCreateDataset", options: ["" : ""], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func testCreateDatasetFromCSVFail() {
        
        self.runTest("testCreateDatasetFromCSVFail") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateDatasetFromCSVFail", type:BMLResourceType.File, uuid:NSBundle.pathForResource("iris.csv")!)
            self.connector.createResource(BMLResourceType.Dataset, name: "testCreateDatasetFromCSVFail", options: ["" : ""], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func testCreateAnomaly() {
        
        self.runTest("testCreateAnomaly") { (exp) in
            let resource = BMLMinimalResource(name:"testCreateAnomaly", type:BMLResourceType.Dataset, uuid:"554a3b4977920c09e3000431")
            self.connector.createResource(BMLResourceType.Anomaly, name: "testCreateAnomaly", options: ["" : ""], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func testListDataset() {
        
        self.runTest("testListDataset") { (exp) in
            self.connector.listResources(BMLResourceType.Dataset) { (resources, error) -> Void in
                exp.fulfill()
                XCTAssert(count(resources) > 0 && error == nil, "Pass")
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
    
    func testGetDatasetFail() {
        
        self.runTest("testGetDatasetFail") { (exp) in
            self.connector.getResource(BMLResourceType.Source, uuid: "no-uuid") { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(error != nil && resource == nil, "Pass")
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
