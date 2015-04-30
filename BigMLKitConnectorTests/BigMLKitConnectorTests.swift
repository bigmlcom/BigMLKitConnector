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

class BigMLKitConnectorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
            let connector = BMLConnector(username:"", apiKey:"", mode:BMLMode.BMLDevelopmentMode)
            let resource = BMLResource( name:"provaSwift", type:BMLResourceType.Source, uuid:"5540b821c0eea909d0000525")
            connector.createResource(BMLResourceType.Dataset, name: "provaDataset", options: ["" : ""], from: resource) { (resource, error) -> Void in
                println("HERE WE ARE")
                exp.fulfill()
            }
            XCTAssert(true, "Pass")
        }
    }
    
    func testListDataset() {
        
        self.runTest("testListDataset") { (exp) in
            let connector = BMLConnector(username:"", apiKey:"", mode:BMLMode.BMLDevelopmentMode)
            let resource = BMLResource( name:"provaSwift", type:BMLResourceType.Source, uuid:"5540b821c0eea909d0000525")
            connector.listResources(BMLResourceType.Dataset) { (resource, error) -> Void in
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
