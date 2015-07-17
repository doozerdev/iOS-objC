//
//  MasterViewControllerTests.m
//  Doozer
//
//  Created by Daniel Apone on 7/14/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MasterViewController.h"

@interface MasterViewControllerTests : XCTestCase

@property (nonatomic) MasterViewController *masterVC;

@end

/*
@interface MasterViewController (Test)

- (void)addItemList;

@end
 */

@implementation MasterViewControllerTests

- (void)setUp {
    [super setUp];
    
    self.masterVC = [[MasterViewController alloc]init];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


-(void)testAddItem {
    
    //[MasterViewController press: [self.masterVC.view viewWithTag:111]];
}


@end
