//
//  OrderMaintenance.swift
//  Doozer
//
//  Created by Foltz, Greg on 11/3/14.
//  Copyright (c) 2014 Doozer Enterprise LLC. All rights reserved.
//

import Foundation

class OrderMaintenance
{
    /**
    * An implementation of https://www.cs.cmu.edu/~sleator/papers/maintaining-order.pdf
    * The basic idea here is to simply divide the order value range in half if possible.
    * e.g. if you have order values 0,10 and you want an order value for a new item to be
    *      ordered in between those two, then assign it the value 5.
    *
    * If the insertion has to happen between items whose values differ by only one, then things
    * get more complicated. (e.g. [1,2], insert at index 1) In this case, we must reassign the
    * values to make room. But we want to minimize the number of updated values since every update
    * has real costs in terms of disk and network IO. So we look for a range of N order values whose
    * spread is greater than N^2. Given that range, we update all items within that range to have
    * evenly spaced order values.
    *
    * Note that the range of possible order values here is 0..INT_MAX. According to the paper,
    * this should allow for a total item count of around 43,000 items before the algorithm will
    * fail.
    */
    class func calculateOrderValues(insertPosition : Int, existingOrderValues : Array<Int>) -> (newOrderValue : Int, existingOrderValues : Array<Int>) {
        let absMaxOrderValue = Int(INT_MAX);
        
        var minOrderValue = Int(0);
        var maxOrderValue = absMaxOrderValue;
        var newOrderValue = (minOrderValue + maxOrderValue) / 2;
        
        if (existingOrderValues.count == 0)
        {
            return (newOrderValue, existingOrderValues);
        }
        
        if (insertPosition < 0)
        {
            maxOrderValue = existingOrderValues[0];
        }
        else if (insertPosition >= existingOrderValues.count - 1)
        {
            minOrderValue = existingOrderValues.last!;
        }
        else
        {
            minOrderValue = existingOrderValues[insertPosition];
            maxOrderValue = existingOrderValues[insertPosition + 1];
        }
        
        if (maxOrderValue - minOrderValue > 1)
        {
            return ((Int((maxOrderValue - minOrderValue)) / 2) + minOrderValue, existingOrderValues);
        }
        
        var minIndex = insertPosition as Int;
        var maxIndex = insertPosition + 1 as Int;
        while (Int(maxOrderValue - minOrderValue) <= Int(pow(Double(maxIndex - minIndex), Double(2))))
        {
            if (maxIndex < existingOrderValues.count - 1)
            {
                maxIndex++;
                maxOrderValue = existingOrderValues[maxIndex];
            }
            else if (minIndex > 0)
            {
                minIndex--;
                minOrderValue = existingOrderValues[minIndex];
            }
            else if (maxIndex == existingOrderValues.count - 1 && maxOrderValue < absMaxOrderValue) {
                maxOrderValue = absMaxOrderValue;
            }
            else if (minIndex == 0 && minOrderValue > 0)
            {
                minOrderValue = 0;
            }
            else
            {
                assert(false, "No range found");
                return (-1,existingOrderValues);
            }
        }
        
        return OrderMaintenance.adjustOrderValues(existingOrderValues,
            insertIndex:insertPosition + 1,
            minIndex:minIndex,
            maxIndex:maxIndex,
            minValue:minOrderValue,
            maxValue:maxOrderValue)
    }
    
    class func adjustOrderValues(existingOrderValues : [Int], insertIndex : Int, minIndex : Int, maxIndex : Int, minValue : Int, maxValue : Int) -> (newOrderValue : Int, existingOrderValues : Array<Int>) {
        
        assert(insertIndex >= minIndex && insertIndex <= maxIndex);
        assert(minIndex >= 0 && maxIndex < existingOrderValues.count);
        assert(maxIndex != minIndex);
        
        var newOrderValues = existingOrderValues;
        let increment = (maxValue - minValue) / (maxIndex - minIndex + 1);
        var newItemValue = -1;
        
        for (var index = minIndex; index <= maxIndex + 1; index++) {
            let value = ((index - minIndex) * increment) + minValue;
            if (index < insertIndex) {
                newOrderValues[index] = value;
            } else if (index == insertIndex) {
                newItemValue = value;
            } else {
                newOrderValues[index-1] = value;
            }
        }
        return (newItemValue, newOrderValues);
    }
}