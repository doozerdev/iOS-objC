//
//  DoozerItem.swift
//  Doozer
//
//  Created by Foltz, Greg on 7/4/14.
//  Copyright (c) 2014 Doozer Enterprise LLC. All rights reserved.
//

import CoreData

class DoozerItem : NSManagedObject {
    @NSManaged var itemId : NSString?
    @NSManaged var parentItemId : NSString?
    @NSManaged var title : NSString
    @NSManaged var created : NSDate
    @NSManaged var order : Int32
}