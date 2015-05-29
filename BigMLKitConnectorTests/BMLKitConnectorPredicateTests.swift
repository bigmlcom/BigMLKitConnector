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
    
    func testCreateNumPredicateEval() {
        
        var p = Predicate(op: ">", field: "F1", value: 1, term:.None)
        var res = p.apply(["F1" : 0.5], fields: ["F1" : [:]])
        XCTAssert(!res, "Pass")

        p = Predicate(op: ">", field: "F1", value: 1, term:.None)
        res = p.apply(["F1" : 100], fields: ["F1" : [:]])
        XCTAssert(res, "Pass")
        
        p = Predicate(op: ">=", field: "F1", value: 1, term:.None)
        res = p.apply(["F1" : 1], fields: ["F1" : [:]])
        XCTAssert(res, "Pass")
        
        p = Predicate(op: "<=", field: "F1", value: 1, term:.None)
        res = p.apply(["F1" : 0.5], fields: ["F1" : [:]])
        XCTAssert(res, "Pass")
        
        p = Predicate(op: "=", field: "F1", value: 5, term:.None)
        res = p.apply(["F1" : 5], fields: ["F1" : [:]])
        XCTAssert(res, "Pass")
        
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

    func testNumPredicatesEval() {
        
        let term1 = "T"
        let term2 = "T.T"
        let ps = Predicates(predicates: [
            "TRUE",
            ["op" : ">=", "field" : "F1", "value" : 1, "term" : term1],
            ["op" : "<=", "field" : "F2", "value" : 1, "term" : term1]])
        
        let result = ps.apply(["F1" : 5, "F2" : 1], fields: ["F1" : [:], "F2" : [:]])
        XCTAssert(result, "Pass")
    }
    
    func testNumPredicatesEvalFail() {
        
        let term1 = "T"
        let term2 = "T.T"
        let ps = Predicates(predicates: [
            "TRUE",
            ["op" : ">=", "field" : "F1", "value" : 1, "term" : term1],
            ["op" : ">", "field" : "F2", "value" : 1, "term" : term1]])
        
        let result = ps.apply(["F1" : 5, "F2" : 1], fields: ["F1" : [:], "F2" : [:]])
        XCTAssert(!result, "Pass")
    }
    
    func testAlphaPredicatesRule() {
        
        let term1 = "T"
        let term2 = "T.T"
        let ps = Predicates(predicates: [
            "TRUE",
            ["op" : ">=", "field" : "F1", "value" : 1, "term" : term1],
            ["op" : ">", "field" : "F1", "value" : 1, "term" : term1],
            ["op" : ">", "field" : "F1", "value" : 0, "term" : term1],
            ["op" : "<=", "field" : "F1", "value" : 0, "term" : term1],
            ["op" : ">=", "field" : "F2", "value" : 1, "term" : term2],
            ["op" : ">", "field" : "F2", "value" : 1, "term" : term2],
            ["op" : ">", "field" : "F2", "value" : 0, "term" : term2],
            ["op" : "<=", "field" : "F2", "value" : 0, "term" : term2]])
        
        println(ps.rule(["F1" : ["a" : "b", "name" : "F1"],
            "F2" : ["name": "f2", "term_analysis" : [ "token_mode" : "all" ]]]))
    }
}
