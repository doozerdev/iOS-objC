//
//  ColorHelperTests.m
//  Doozer
//
//  Created by Daniel Apone on 7/15/15.
//  Copyright © 2015 Daniel Apone. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ColorHelper.h"

@interface ColorHelperTests : XCTestCase

@end


@implementation ColorHelperTests

- (void)setUp {
    [super setUp];
    
    //self.colorHelper = [[ColorHelper alloc]init];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testReturnUIColorString{
    
    int testInt = 3;
    NSString *returnedString = [ColorHelper returnUIColorString:testInt];
    NSString *expectedString = @"46,179,193,1";
    XCTAssertEqualObjects(expectedString, returnedString, @"The returned string did not match the expected one");

}

- (void)testGetUIColorFromString{
    
    NSString *testString = @"198,99,175,1";
    
    UIColor *expectedUIColor = [UIColor colorWithRed:198/255. green:99/255. blue:175/255. alpha:1];
    UIColor *returnedUIColor = [ColorHelper getUIColorFromString:testString :1];
    XCTAssertEqualObjects(expectedUIColor, returnedUIColor, @"the colors are equal!");

}



@end
