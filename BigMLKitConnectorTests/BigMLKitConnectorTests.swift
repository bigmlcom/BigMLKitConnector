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
    
//    class func dictionaryWithContentsOfFile(filename : String) -> NSDictionary {
//        
//        for bundle in NSBundle.allBundles() {
//            if let  f = bundle.pathForResource("credentials", ofType:"plist") {
//                return NSDictionary.init(contentsOfFile:f)!
//            }
//        }
//        return NSDictionary()
//    }
}

@objc class BigMLKitTestCredentials {
    
    class func credentials() -> NSDictionary {
        return NSDictionary.init(contentsOfFile:NSBundle.pathForResource("credentials.plist")!)!
//        return NSBundle.dictionaryWithContentsOfFile("credentials.plist")
    }
    
    class func username() -> String {
        return self.credentials()["username"] as! String
    }
    
    class func apiKey() -> String {
        return self.credentials()["apiKey"] as! String
    }
}

class BigMLKitConnectorTests: XCTestCase {
    
    var connector = BMLConnector(username:BigMLKitTestCredentials.username(), apiKey:BigMLKitTestCredentials.apiKey(), mode:BMLMode.BMLDevelopmentMode)
    
    
    override func setUp() {
        super.setUp()

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
            let resource = BMLResource( name:"testCreateDatasource", type:BMLResourceType.File, uuid:filePath!)
            self.connector.createResource(BMLResourceType.Source, name: "provaDatasource", options: ["" : ""], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func testCreateDatasourceFail() {
        
        self.runTest("testCreateDatasourceFail") { (exp) in
            
            let filePath = NSBundle.pathForResource("iris.csv")
            let resource = BMLResource( name:"testCreateDatasourceFail", type:BMLResourceType.File, uuid:filePath!)
            self.connector.createResource(BMLResourceType.Dataset, name: "provaDatasource", options: ["" : ""], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(error != nil, "Pass")
            }
        }
    }
    
    func teistCreateDataset() {
        
        self.runTest("testCreateDataset") { (exp) in
            let resource = BMLResource( name:"provaSwift", type:BMLResourceType.Source, uuid:"5540b821c0eea909d0000525")
            self.connector.createResource(BMLResourceType.Dataset, name: "provaDataset", options: ["" : ""], from: resource) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(resource != nil && error == nil, "Pass")
            }
        }
    }
    
    func teistListDataset() {
        
        self.runTest("testListDataset") { (exp) in
            let resource = BMLResource( name:"provaSwift", type:BMLResourceType.Source, uuid:"5540b821c0eea909d0000525")
            self.connector.listResources(BMLResourceType.Dataset) { (resource, error) -> Void in
                exp.fulfill()
                XCTAssert(error == nil, "Pass")
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
