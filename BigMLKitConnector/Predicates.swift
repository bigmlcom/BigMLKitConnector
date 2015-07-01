//
//  Predicates.swift
//  BigMLX
//
//  Created by sergio on 19/06/15.
//  Copyright (c) 2015 sergio. All rights reserved.
//

import Foundation

func plural(string : String, multiplicity : Int) -> String {
    
    if (multiplicity == 1) {
        return string
    }
    return "\(string)s"
}

class Predicate {
    
    static let TM_TOKENS = "tokens_only"
    static let TM_FULL_TERMS = "full_terms_only"
    static let TM_ALL = "all"
    static let FULL_TERM_PATTERN = "^.+\\b.+$"
    
    var op : String
    var field : String
    var value : AnyObject
    var term : String?
    var missing : Bool
    
    init (op : String, field : String, value : AnyObject, term : String? = .None) {
        
        self.op = op
        self.field = field
        self.value = value
        self.term = term
        self.missing = false
        if self.op =~ "\\*$" {
            self.missing = true
            self.op = self.op.substringToIndex(advance(self.op.startIndex, count(self.op)-1))
        }
    }
    
    func isFullTerm(fields : [String : AnyObject]) -> Bool {
        
        if let term = self.term,
            fieldDict = fields[self.field] as? [String : AnyObject],
            options = fieldDict["term_analysis"] as? [String : AnyObject],
            tokenMode = options["token_mode"] as? String {
                
                if tokenMode == Predicate.TM_FULL_TERMS {
                    return true
                }
                if tokenMode == Predicate.TM_ALL {
                    return term =~ Predicate.FULL_TERM_PATTERN
                }
        }
        return false
    }
    
    func rule(fields : [String : AnyObject], label : String = "name") -> String {
        
        if let fieldDict = fields[self.field] as? [String : AnyObject],
            name = fieldDict[label] as? String {
                
                let fullTerm = self.isFullTerm(fields)
                let relationMissing = self.missing ? " or missing " : ""
                if let term = self.term, value = self.value as? Int {
                    var relationSuffix = ""
                    let relationLiteral : String
                    if ((self.op == "<" && value <= 1) || (self.op == "<=" && value == 0)) {
                        relationLiteral = fullTerm ? " is not equal to " : " does not contain "
                    } else {
                        relationLiteral = fullTerm ? " is equal to " : " contains "
                        if !fullTerm {
                            if self.op != ">" || value != 0 {
                                let times = plural("time", value)
                                if self.op == ">=" {
                                    relationSuffix = "\(value) \(times) at most"
                                } else if self.op == "<=" {
                                    relationSuffix = "no more than \(value) \(times)"
                                } else if self.op == ">" {
                                    relationSuffix = "more than \(value) \(times)"
                                } else if self.op == "<" {
                                    relationSuffix = "less than \(value) \(times)"
                                }
                            }
                        }
                    }
                    return "\(name) \(relationLiteral) \(term) \(relationSuffix)\(relationMissing)"
                }
                if let value = self.value as? NSNull {
                    let v = (self.op == "=") ? " is None " : " is not None "
                    return "\(name) \(self.op) \(self.value) \(relationMissing)"
                } else {
                    return "\(name) \(self.op) \(self.value) \(relationMissing)"
                }
        } else {
            return self.op
        }
    }
    
    func termCount(text : String, forms : [String], options : [String : AnyObject]?) -> Int {

        var tokenMode = Predicate.TM_TOKENS
        if let options = options,
            letTokenMode = options["token_mode"] as? String {
                tokenMode = letTokenMode
        }
        var caseSensitive = true
        if let options = options,
            letCaseSensitive = options["case_sensitive"] as? Bool {
                caseSensitive = letCaseSensitive
        }
        let firstTerm = forms[0]
        if (tokenMode == Predicate.TM_FULL_TERMS) {
            return self.fullTermCount(text, fullTerm: firstTerm, caseSensitive: caseSensitive)
        }
        if (tokenMode == Predicate.TM_ALL && count(forms) == 1) {
            if (firstTerm =~ Predicate.FULL_TERM_PATTERN) {
                return self.fullTermCount(text, fullTerm: firstTerm, caseSensitive: caseSensitive)
            }
        }
        
        return self.tokenTermCount(text, forms: forms, caseSensitive: caseSensitive)
    }
    
    func fullTermCount(text : String, fullTerm : String, caseSensitive : Bool) -> Int {
        return (caseSensitive ? ((text == fullTerm) ? 1 : 0) : ((text =~ "/^\(fullTerm)$/i") ? 1 : 0));
    }

    func tokenTermCount(text : String, forms : [String], caseSensitive : Bool) -> Int {

        let fre = "(\\b|_)".join(forms)
        let re = "(\\b|_)\(fre)(\\b|_)"
        return text =~~ re
    }

    func eval(predicate : String, args : [String : AnyObject]) -> Bool {
        
        let p = NSPredicate(format:predicate)
        //            println("PREDICATE \(p)")
        return p.evaluateWithObject(args)
    }
    
    func apply(input : [String : AnyObject], fields : [String : AnyObject]) -> Bool {
        
        if (self.op == "TRUE") {
            return true
        }
        //        println("APPLYING: \(input) to field \(self.field)")
        if input[self.field] == nil {
            return self.missing || (self.op == "=" && self.value as! NSObject == NSNull())
        } else if self.op == "!=" && self.value as! NSObject == NSNull() {
            return true
        }
        
        //        println("INPUT: \(input[self.field]!) -- FIELD: \(self.field) -- VALUE: \(self.value)")
        if self.op == "in" {
            return self.eval("ls \(self.op) rs",
                args: [ "ls" : input[self.field]!, "rs" : self.value])
        }
        if let term = self.term,
            text = input[self.field] as? String,
            field = fields[self.field] as? [String : AnyObject] {

                var termForms : [String] = []
                if let summary = fields["summary"] as? [String : AnyObject],
                    allForms = summary["term_forms"] as? [String : AnyObject],
                    letTermForms = allForms[term] as? [String] {
                 
                        termForms = letTermForms
                }
                let terms = [term] + termForms
                let options = field["term_analysis"] as? [String : AnyObject]
                
                return self.eval("ls \(self.op) rs",
                    args: ["ls" : self.termCount(text, forms: terms, options: options),
                           "rs" : self.value])
        }
        if let inputValue : AnyObject = input[self.field] {
            return self.eval("ls \(self.op) rs",
                args: ["ls" : input[self.field]!, "rs" : self.value])
        }
        assert(false, "Should not be here: no input value provided!")
        return false
    }
}

class Predicates {
    
    let predicates : [Predicate]
    
    init(predicates : [AnyObject]) {
        self.predicates = predicates.map() {
            
            //            println("PREDICATE: \($0)")
            if let p = $0 as? String {
                return Predicate(op: "TRUE", field: "", value: 1, term: "")
            }
            if let p = $0 as? [String : AnyObject] {
                if let op = p["op"] as? String, field = p["field"] as? String, value : AnyObject = p["value"] {
                    if let term = p["term"] as? String {
                        return Predicate(op: op, field: field, value: value, term: term)
                    } else {
                        return Predicate(op: op, field: field, value: value)
                    }
                }
            }
            assert(false, "COULD NOT CREATE PREDICATE")
            return Predicate(op: "", field: "", value: "")
        }
    }
    
    func rule(fields : [String : AnyObject], label : String = "name") -> String {
        
        let strings = self.predicates.filter({ $0.op != "TRUE" }).map() {
            return $0.rule(fields, label: label)
        }
        return " and ".join(strings)
    }
    
    func apply(input : [String : AnyObject], fields : [String : AnyObject]) -> Bool {
        
        return predicates.reduce(true) {
            let result = $1.apply(input, fields: fields)
            //            println("Applying predicate: \(result)")
            return $0 && result
        }
    }
}
