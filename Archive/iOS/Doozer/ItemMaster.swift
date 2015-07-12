//
//  ListManager.swift
//  Doozer
//
//  Created by Foltz, Greg on 10/21/14.
//  Copyright (c) 2014 Doozer Enterprise LLC. All rights reserved.
//

import Foundation
import CoreData


class ItemMaster {
    class var sharedInstance : ItemMaster {
        struct Static {
            static let instance : ItemMaster = ItemMaster()
        }
        return Static.instance
    }
    
    func fetchItems() -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName:"DoozerItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"order", ascending:true)]
        return NSFetchedResultsController(fetchRequest:fetchRequest, managedObjectContext: self.moc, sectionNameKeyPath: nil, cacheName: nil)
    
    }
    
    func fetchItemsWithParent(itemId : NSString?) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName:"DoozerItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"order", ascending:true)]
        if (itemId != nil) {
            fetchRequest.predicate = NSPredicate(format:"parentItemId = %@", itemId!)
        } else {
            fetchRequest.predicate = NSPredicate(format:"parentItemId == nil");
        }
        return NSFetchedResultsController(fetchRequest:fetchRequest, managedObjectContext: self.moc, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func addItem(title : NSString!, position: Int, parentItemId: NSString?) {
        println("Adding item with title: \(title)")
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("DoozerItem", inManagedObjectContext:moc) as DoozerItem
        newItem.title = title;
        newItem.created = NSDate();
        newItem.itemId = NSUUID().UUIDString
        
        if (parentItemId != nil) {
            newItem.parentItemId = parentItemId
        }
        
        var order = calculateNewItemOrder(position, parentItemId:parentItemId);
        newItem.order = Int32(order);
        println("New item order: \(newItem.order)");
        var error : NSError? = nil
        moc.save(&error)
        
        if (error != nil) {
            println("Error adding item: \(error)")
        }
    }
    
    func calculateNewItemOrder(insertPosition : Int, parentItemId : NSString?) -> Int {
        let allItems = self.moc.executeFetchRequest(
                               self.fetchItemsWithParent(parentItemId).fetchRequest,
                               error:nil) as [DoozerItem]
        

        let existingItemOrderValues = allItems.map({doozerItem in Int(doozerItem.order)})
        let update = OrderMaintenance.calculateOrderValues(insertPosition, existingOrderValues:existingItemOrderValues);

        for (var i = 0; i < update.existingOrderValues.count; i++)
        {
            let item = allItems[i] as DoozerItem;
            
            if (Int(item.order) != update.existingOrderValues[i])
            {
                item.order = Int32(update.existingOrderValues[i]);
            }
        }
        
        return update.newOrderValue;
    }

    func updateItem(itemToUpdate : DoozerItem!, position: Int, parentItemId: NSString?) {
        println("Updating item \"\(itemToUpdate.title)\" to position \(position) (curOrder=\(itemToUpdate.order))")
        
        let fetchRequest = self.fetchItemsWithParent(parentItemId).fetchRequest
        var newPredicates = ([fetchRequest.predicate,
                              NSPredicate(format: "self != %@", itemToUpdate)] as [AnyObject!])
        
        fetchRequest.predicate = NSCompoundPredicate.andPredicateWithSubpredicates(newPredicates)
    
        let items = moc.executeFetchRequest(fetchRequest, error: nil)!;
        let existingItemOrderValues = items.map({doozerItem in Int(doozerItem.order)})
        
        let update = OrderMaintenance.calculateOrderValues(position-1, existingOrderValues:existingItemOrderValues);
        
        for (var i = 0; i < update.existingOrderValues.count; i++)
        {
            let item = items[i] as DoozerItem;
            
            if (Int(item.order) != update.existingOrderValues[i])
            {
                println("New order value=\(update.newOrderValue) for item \"\(itemToUpdate.title)\"")
                item.order = Int32(update.existingOrderValues[i]);
            }
        }
        println("New order value=\(update.newOrderValue) for item \"\(itemToUpdate.title)\"")
        itemToUpdate.order = Int32(update.newOrderValue);
    }
    
    func deleteItem(itemToDelete : DoozerItem) {
        self.moc.deleteObject(itemToDelete)
    }
    
    func clear() {
        for ps in self.persistentStoreCoordinator.persistentStores {
            let store = (ps as NSPersistentStore);
            if let store = ps as? NSPersistentStore {
                self.persistentStoreCoordinator.removePersistentStore(store, error: nil);
                NSFileManager.defaultManager().removeItemAtURL(store.URL!, error: nil);
            }
        }
        _moc = nil;
        _persistentStoreCoordinator = nil;
        _managedObjectModel = nil;
    }
    
    func saveContext () {
        var error: NSError? = nil
        
        if self.moc.hasChanges && !self.moc.save(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
    }
    
    var moc: NSManagedObjectContext {
        if _moc == nil {
            let coordinator = self.persistentStoreCoordinator
            _moc = NSManagedObjectContext()
            _moc!.persistentStoreCoordinator = coordinator
        }
        return _moc!
    }
    var _moc: NSManagedObjectContext? = nil
    
    // Returns the persistent store coordinator for the application.
    // If the coordinator doesn't already exist, it is created and the application's store added to it.
    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        if _persistentStoreCoordinator == nil {
            _persistentStoreCoordinator = self.loadPersistentStore();
        }
        return _persistentStoreCoordinator!
    }
    var _persistentStoreCoordinator: NSPersistentStoreCoordinator? = nil
    
    func loadPersistentStore() -> NSPersistentStoreCoordinator {
        let storeURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Doozer.sqlite")
        println(storeURL)
        let invalidStoreURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Doozer.sqlite.invalid")
        var error: NSError? = nil
        let newStore = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        enum StoreLoadStatus {
            case None
            case Failed
            case Loaded
        }
        
        var loadStatus = StoreLoadStatus.None
        while (loadStatus != StoreLoadStatus.Loaded) {
            if newStore.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true], error: &error) == nil {
                if loadStatus == StoreLoadStatus.Failed {
                    abort()
                } else if loadStatus == StoreLoadStatus.None {
                    NSFileManager.defaultManager().moveItemAtURL(storeURL, toURL:invalidStoreURL, error:nil)
                }
            }
            loadStatus = StoreLoadStatus.Loaded
        }
        return newStore;
    }
    
    // #pragma mark - Application's Documents directory
    
    // Returns the URL to the application's Documents directory.
    var applicationDocumentsDirectory: NSURL {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            return urls[urls.endIndex-1] as NSURL
    }
    
    // Returns the managed object model for the application.
    // If the model doesn't already exist, it is created from the application's model.
    var managedObjectModel: NSManagedObjectModel {
        if _managedObjectModel == nil {
            let modelURL = NSBundle.mainBundle().URLForResource("Doozer", withExtension: "momd")
            _managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL!)
            }
            return _managedObjectModel!
    }
    var _managedObjectModel: NSManagedObjectModel? = nil
}
