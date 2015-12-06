//
//  BIgMLKitConnectorBaseTest.swift
//  BigMLKitConnector
//
//  Created by sergio on 27/11/15.
//  Copyright © 2015 BigML Inc. All rights reserved.
//

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

class BigMLKitTestCredentials {
    
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

class BigMLKitConnectorBaseTest: XCTestCase {
    
    var aSource : BMLResource?
    var aDataset : BMLResource?
    var altDataset : BMLResource?
    var connector : BMLConnector?
    
    func createDataset(file : String, completion : (resource : BMLResource) -> ()) {
        
        self.runTest("setupTest") { (exp) in
            
            let filePath = NSBundle.pathForResource(file)
            let resource = BMLMinimalResource(name:"testCreateDatasource", type:BMLResourceType.File, uuid:filePath!)
            self.connector!.createResource(BMLResourceType.Source,
                name: "testCreateDatasource",
                options: [:],
                from: resource) { (resource, error) -> Void in
                    
                    XCTAssert(resource != nil && error == nil, "Pass")
                    self.aSource = resource
                    
                    self.connector!.createResource(BMLResourceType.Dataset,
                        name: "testCreateDataset",
                        options: [:],
                        from: self.aSource!) { (resource, error) -> Void in
                            XCTAssert(resource != nil && error == nil, "Pass")
                            completion(resource: resource!)
                            exp.fulfill()
                    }
            }
        }
    }
    
    override func setUp() {
        super.setUp()
        
        installSigHandler();
        self.connector = BMLConnector(username:BigMLKitTestCredentials.username(), apiKey:BigMLKitTestCredentials.apiKey(), mode:BMLMode.Development)
        
        self.createDataset("iris.csv") { resource in
            self.aDataset = resource
        }
        self.createDataset("salaries.csv") { resource in
            self.altDataset = resource
        }
    }
    
    func runTest(name : String, test : XCTestExpectation -> Void) {
        
        let exp = self.expectationWithDescription(name)
        test(exp)
        self.waitForExpectationsWithTimeout(360) { (error) in
            print("Expect error \(error)")
        }
    }
}

