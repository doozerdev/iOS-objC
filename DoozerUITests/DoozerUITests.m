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

NSString *listTitle;

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

- (void)testCreateList{
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *tablesQuery = app.tables;
    [[[tablesQuery.cells containingType:XCUIElementTypeTextField identifier:@"╋︎"] childrenMatchingType:XCUIElementTypeTextField].element tap];
    listTitle = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    [app typeText:listTitle];
    [app typeText:@"\r"];
    
    [app pressForDuration:1];
    
    [[[tablesQuery.cells containingType:XCUIElementTypeTextField identifier:listTitle] childrenMatchingType:XCUIElementTypeTextField].element tap];
    
    [app.navigationBars[listTitle].buttons[@"Add"] tap];
    
    for (int i = 0; i < 7; i++) {
        NSString *itemTimestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
        [app typeText:itemTimestamp];
        [app typeText:@"\r"];
    }
    
    XCUIApplication *app2 = [[XCUIApplication alloc] init];
    [[[[app2.tables childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:1] childrenMatchingType:XCUIElementTypeTextField].element tap];
    
    int rows = (int)[tablesQuery.cells count];
    
    int count = 8;
    
    [[[[[[XCUIApplication alloc] init].tables childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:2] childrenMatchingType:XCUIElementTypeTextField].element pressForDuration:1.7];
    
        
    XCTAssertEqual(rows, count , @"list created successfuly!");
    
}

-(void)testDeleteItems{
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *tablesQuery = app.tables;
   [[[[tablesQuery childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeTextField].element tap];
    
    XCUIElement *textField2 = [[[tablesQuery childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeTextField].element;
    [textField2 swipeLeft];
    
    XCUIElement *deleteButton = tablesQuery.buttons[@"DELETE"];
    [deleteButton tap];
    [textField2 swipeLeft];
    [deleteButton tap];
    [textField2 swipeLeft];
    [deleteButton tap];
    
    int rows = (int)[tablesQuery.cells count];
    int count = 5;

    XCTAssertEqual(rows, count , @"list created successfuly!");
    
}

-(void)testSetDueDate{
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *tablesQuery = app.tables;
    [[[[tablesQuery childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeTextField].element tap];
    
    [[[[tablesQuery childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeTextField].element tap];
    [app.buttons[@"Due Someday"] tap];
    [app.buttons[@"Today"] tap];
    
    [app.navigationBars[@"Master"].buttons[@"Back"] tap];
        [[[[tablesQuery childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeTextField].element tap];
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"EEE MMM dd, yyyy"];
    NSString * dateString = [NSString stringWithFormat:@"Due %@", [df stringFromDate:[NSDate date]]];
    
    [app.buttons[dateString] tap];

    
}

@end
