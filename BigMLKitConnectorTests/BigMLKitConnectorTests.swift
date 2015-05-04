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

@objc class BigMLKitTestCredentials {
    
    class func credentials() -> NSDictionary {

        for bundle in NSBundle.allBundles() {
            if let  f = bundle.pathForResource("credentials", ofType:"plist") {
                return NSDictionary.init(contentsOfFile:f)!
            }
        }
        return ["username" : "bad", "apiKey" : "bad"]
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

    func testCreateDataset() {
        
        self.runTest("testCreateDataset") { (exp) in
            let resource = BMLResource( name:"provaSwift", type:BMLResourceType.Source, uuid:"5540b821c0eea909d0000525")
            self.connector.createResource(BMLResourceType.Dataset, name: "provaDataset", options: ["" : ""], from: resource) { (resource, error) -> Void in
                println("HERE WE ARE")
                exp.fulfill()
            }
            XCTAssert(true, "Pass")
        }
    }
    
    func testListDataset() {
        
        self.runTest("testListDataset") { (exp) in
            let resource = BMLResource( name:"provaSwift", type:BMLResourceType.Source, uuid:"5540b821c0eea909d0000525")
            self.connector.listResources(BMLResourceType.Dataset) { (resource, error) -> Void in
                println("HERE WE ARE")
                exp.fulfill()
            }
            XCTAssert(true, "Pass")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
