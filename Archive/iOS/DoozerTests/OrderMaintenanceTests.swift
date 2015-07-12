//
//  DoozerTests.swift
//  DoozerTests
//
//  Created by Foltz, Greg on 6/3/14.
//  Copyright (c) 2014 Doozer Enterprise LLC. All rights reserved.
//

import XCTest

class DoozerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInsertFirstItem() {
        let inputValues = [] as [Int];
        let inputInsertIndex = 0;
        let expectedUpdatedValues = [] as [Int];
        let expectedNewItemValue = Int(INT_MAX / 2);
        
        assertNewItemOrder(expectedNewItemValue, updatedOrderValues:expectedUpdatedValues,
            inputValues:inputValues, inputInsertIndex:inputInsertIndex);
    }
    
    func testInsertBeforeFront() {
        let inputValues = [10] as [Int];
        let inputInsertIndex = -1;
        let expectedUpdatedValues = [10] as [Int];
        let expectedNewItemValue = 5;
        
        assertNewItemOrder(expectedNewItemValue, updatedOrderValues:expectedUpdatedValues,
            inputValues:inputValues, inputInsertIndex:inputInsertIndex);
    }
    
    func testInsertAfterEnd() {
        let inputValues = [10] as [Int];
        let inputInsertIndex = 1;
        let expectedUpdatedValues = [10] as [Int];
        let expectedNewItemValue = (Int(INT_MAX - 10) / 2) + 10;
        
        assertNewItemOrder(expectedNewItemValue, updatedOrderValues:expectedUpdatedValues,
            inputValues:inputValues, inputInsertIndex:inputInsertIndex);
    }
    
    func testInsertMiddle() {
        let inputValues = [8,16] as [Int];
        let inputInsertIndex = 0;
        let expectedUpdatedValues = [8,16] as [Int];
        let expectedNewItemValue = 12
        
        assertNewItemOrder(expectedNewItemValue, updatedOrderValues:expectedUpdatedValues,
            inputValues:inputValues, inputInsertIndex:inputInsertIndex);
    }
    
    func testInsertReshuffleRequired_extendUpToMax() {
        let inputValues = [0,1] as [Int];
        let inputInsertIndex = 0;
        let expectedUpdatedValues = [0,Int(INT_MAX)-1] as [Int];
        let expectedNewItemValue = Int(INT_MAX) / 2;
        
        assertNewItemOrder(expectedNewItemValue, updatedOrderValues:expectedUpdatedValues,
            inputValues:inputValues, inputInsertIndex:inputInsertIndex);
    }
    
    func testInsertReshuffleRequired_extendDownToMin() {
        let inputValues = [Int(INT_MAX)-1,Int(INT_MAX)] as [Int];
        let inputInsertIndex = 0;
        let expectedUpdatedValues = [0,Int(INT_MAX)-1] as [Int];
        let expectedNewItemValue = Int(INT_MAX) / 2;
        
        assertNewItemOrder(expectedNewItemValue, updatedOrderValues:expectedUpdatedValues,
            inputValues:inputValues, inputInsertIndex:inputInsertIndex);
    }
    
    func testInsertReshuffleRequired_extendUp_notAll() {
        let inputValues = [0,1,2,4,8,16,32,64,128] as [Int];
        let inputInsertIndex = 0;
        let expectedUpdatedValues = [0,16,24,32,40,48,56,64,128] as [Int];
        let expectedNewItemValue = 8;
        
        assertNewItemOrder(expectedNewItemValue, updatedOrderValues:expectedUpdatedValues,
            inputValues:inputValues, inputInsertIndex:inputInsertIndex);
    }
    
    func testInsertReshuffleRequired_extendDown_notAll() {
        let inputValues = [Int(INT_MAX)-8, Int(INT_MAX)-1, Int(INT_MAX)] as [Int];
        let inputInsertIndex = 1;
        let expectedUpdatedValues = [Int(INT_MAX) - 8, Int(INT_MAX) - 6, Int(INT_MAX) - 2] as [Int];
        let expectedNewItemValue = Int(INT_MAX) - 4;
        
        assertNewItemOrder(expectedNewItemValue, updatedOrderValues:expectedUpdatedValues,
            inputValues:inputValues, inputInsertIndex:inputInsertIndex);
    }
    
    func testInsertReshuffleRequired_extendMiddle() {
        let inputValues = [0,10,11,12,24,30] as [Int];
        let inputInsertIndex = 2;
        let expectedUpdatedValues = [0,10,11,19,23,30] as [Int];
        let expectedNewItemValue = 15;
        
        assertNewItemOrder(expectedNewItemValue, updatedOrderValues:expectedUpdatedValues,
            inputValues:inputValues, inputInsertIndex:inputInsertIndex);
    }
    func testMutableArrays() {
        let ia = [1,2,3];
        var ma = ia;
        ma[1] = 4;
        XCTAssertEqual(ma[0], 1);
        XCTAssertEqual(ma[1], 4);
        XCTAssertEqual(ma[2], 3);

        XCTAssertEqual(ia[0], 1);
        XCTAssertEqual(ia[1], 2);
        XCTAssertEqual(ia[2], 3);
    }
    
    func assertNewItemOrder(expectedInsertValue : Int, updatedOrderValues : [Int], inputValues : [Int], inputInsertIndex : Int)
    {
        let result = OrderMaintenance.calculateOrderValues(inputInsertIndex, existingOrderValues: inputValues);
        XCTAssertEqual(result.newOrderValue, expectedInsertValue);
        XCTAssertEqual(result.existingOrderValues, updatedOrderValues);
    }
}
