//
//  BMLKitConnectorPredicateTests.swift
//  BigMLKitConnector
//
//  Created by sergio on 28/05/15.
//  Copyright (c) 2015 BigML Inc. All rights reserved.
//

import Foundation
import XCTest
import BigMLKitConnector

class BigMLKitConnectorPredicateTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreatePredicate1() {
        
        let p = Predicate(op: "A", field: "F1", value: 1, term:"T")
        XCTAssert(true, "Pass")
    }

    func testCreatePredicateFullTerm() {
        
        let p = Predicate(op: "A", field: "F1", value: 1, term:"T.T")
        let fields = ["F1" : ["term_analysis" : [ "token_mode" : "all" ]]]
        XCTAssert(p.isFullTerm(fields), "Pass")
    }

    func testCreatePredicateNonFullTerm() {
        
        let p = Predicate(op: "A", field: "F1", value: 1, term:"TT")
        let fields = ["F1" : ["term_analysis" : [ "token_mode" : "all" ]]]
        XCTAssert(!p.isFullTerm(fields), "Pass")
    }

    func testCreatePredicateRule() {
        
        let test = { (term : String, fields : [String : AnyObject]) -> Bool in
         
            var p = Predicate(op: ">=", field: "F1", value: 1, term: term)
            var rule = p.rule(fields)
            println("Predicate: \(rule)")
            
            p = Predicate(op: ">", field: "F1", value: 1, term: term)
            rule = p.rule(fields)
            println("Predicate: \(rule)")
            
            p = Predicate(op: ">", field: "F1", value: 0, term: term)
            rule = p.rule(fields)
            println("Predicate: \(rule)")
            
            p = Predicate(op: "<=", field: "F1", value: 0, term: term)
            rule = p.rule(fields)
            println("Predicate: \(rule)")
            
            return true
        }
        
        test("T.T", ["F1" : ["name": "f1", "term_analysis" : [ "token_mode" : "all" ]]])
        test("T", ["F1" : ["a" : "b", "name" : "F1"]])
        test("A.A", ["F1" : ["a" : "b", "name" : "F1"]])
        test("A.A", ["F2" : ["a" : "b", "name" : "F1"]])
        
        XCTAssert(true, "Pass")
    }

}
