//
//  DoozerUITests.m
//  DoozerUITests
//
//  Created by Daniel Apone on 7/16/15.
//  Copyright © 2015 Daniel Apone. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface DoozerUITests : XCTestCase

@end

@implementation DoozerUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    

    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *tablesQuery = app.tables;
    [[[tablesQuery.cells containingType:XCUIElementTypeTextField identifier:@"╋︎"] childrenMatchingType:XCUIElementTypeTextField].element tap];
    NSString *listTimestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    [app typeText:listTimestamp];
    [app typeText:@"\r"];
    
    [app pressForDuration:1];
    
    [[[tablesQuery.cells containingType:XCUIElementTypeTextField identifier:listTimestamp] childrenMatchingType:XCUIElementTypeTextField].element tap];
    [app.navigationBars[listTimestamp].buttons[@"Add"] tap];
    NSString *itemTimestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    [app typeText:itemTimestamp];
    [app typeText:@"\r"];
    
    //XCTAssertEqualObjects(<#expression1#>, <#expression2, ...#>)
    
}

@end
