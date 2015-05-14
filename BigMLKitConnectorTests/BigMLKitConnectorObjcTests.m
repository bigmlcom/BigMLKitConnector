//
//  BigMLKitConnectorObjcTests.m
//  BigMLKitConnector
//
//  Created by sergio on 06/05/15.
//  Copyright (c) 2015 BigML Inc. All rights reserved.
//
//  This file is only meant as interoperability check (i.e., how the Swift
//  classes can be used in ObjC code). Proper unit tests should be in
//  BigMLKitConnectorTests (Swift).
//

#import <XCTest/XCTest.h>

@import BigMLKitConnector;

@interface BigMLKitConnectorObjcTests : XCTestCase

@end

@implementation BigMLKitConnectorObjcTests {
    
    BMLConnector* _connector;
}

- (void)setUp {
    [super setUp];

    NSDictionary* dict = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"credentials" ofType:@"plist"]];
    
    _connector = [[BMLConnector alloc] initWithUsername:dict[@"username"]
                                                 apiKey:dict[@"apiKey"]
                                                   mode:BMLModeBMLDevelopmentMode];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)runTest:(NSString*)name test:(void(^)(XCTestExpectation*))test {

    XCTestExpectation* exp = [self expectationWithDescription:name];
    test(exp);
    [self waitForExpectationsWithTimeout:30 handler:^(NSError* error) {
        NSLog(@"Expect error %@", error);
    }];
}

- (void)testListDatasetObjc {
    
    [self runTest:@"testListDatasetObjc" test:^(XCTestExpectation* exp) {
        
        [_connector listResources:BMLResourceRawTypeDataset
                          filters:@{}
                       completion:^(NSArray * __nonnull resources, NSError * __nullable error) {

            [exp fulfill];
            XCTAssert([resources count] > 0 && error == nil, @"Pass");
        }];
        
    }];
}

- (void)testCreateAnomalyObjc {
    
    [self runTest:@"testCreateAnomalyObjc" test:^(XCTestExpectation* exp) {
        
        BMLMinimalResource* resource = [[BMLMinimalResource alloc]
                                        initWithName:@"testCreateAnomalyObjC"
                                        rawType:BMLResourceRawTypeDataset
                                        uuid:@"554a3b4977920c09e3000431"];
        
        [_connector createResource:BMLResourceRawTypeAnomaly
                              name:@"testCreateAnomalyObjc"
                           options:@{}
                              from:resource
                        completion:^(id<BMLResource> __nullable resource, NSError * __nullable error) {
                            [exp fulfill];
                            XCTAssert(resource && error == nil, @"Pass");
                        }];
    }];
}

@end
