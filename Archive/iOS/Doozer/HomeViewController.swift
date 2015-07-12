//
//  HomeViewController.swift
//  Doozer
//
//  Created by Foltz, Greg on 6/3/14.
//  Copyright (c) 2014 Doozer Enterprise LLC. All rights reserved.
//

import UIKit
import CoreData

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet var addItemTextField : UITextField?
    @IBOutlet var tableView: UITableView!
    @IBOutlet var itemLongPressGestureRecognizer: UILongPressGestureRecognizer!

    var moveStartIndexPath :NSIndexPath? = nil
    var moveCurrentIndexPath :NSIndexPath? = nil
    var movingCellSnapshotView :UIView? = nil
    var scrollRate :CGFloat = 0
    var scrollDisplayLink :CADisplayLink? = nil
    
    var userEditing: Bool = false
    var listId: String? = nil
    
    var itemMaster : ItemMaster {
        get {
            if (_itemMaster == nil) {
                _itemMaster = ItemMaster.sharedInstance;
            }
            return _itemMaster!
        }
    }
    var _itemMaster : ItemMaster?
    
    var items : NSFetchedResultsController! {
    get {
        if (_items == nil) {
            _items = ItemMaster.sharedInstance.fetchItemsWithParent(self.listId)
            _items!.delegate = self
            _items!.performFetch(nil);
        }
        return _items!
    }
    }
    var _items : NSFetchedResultsController?
    
    override func viewDidLoad() {
        
        if (DoozerSessionManager.sharedInstance.activeSession == nil)
        {
            self.showLoginView();
        }

        // Google Analytics
        let tracker = GAI.sharedInstance().defaultTracker;
        tracker.set(kGAIScreenName, value: "List");
        tracker.send(GAIDictionaryBuilder.createScreenView().build());
        
        var error : NSError? = nil
        self.navigationItem.hidesBackButton = true
        if (error != nil) {
            println(error!)
        }
        if (self.listId == nil) {
            self.addItemTextField!.placeholder = NSLocalizedString("New List", comment:"Placeholder text for creating a new list")
        } else {
            self.navigationItem.hidesBackButton = false
        }
        if let longPress = self.itemLongPressGestureRecognizer {
            longPress.addTarget(self, action:"itemLongPress:")
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onLogout", name: "DoozerLogout", object: nil);
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }
    
    func onLogout() {
        self.addItemTextField?.resignFirstResponder()
        self.showLoginView();
        
        // Make sure the table is cleared
        // since it will be briefly visible before
        // the login screen is shown.
        _items = nil;
        self.tableView.reloadData();
        
        // Google Analytics
        let tracker = GAI.sharedInstance().defaultTracker;
        let event = GAIDictionaryBuilder.createEventWithCategory("User", action: "Logout", label: "", value: nil).build()
        tracker.send(event)
    }
    
    func showLoginView() {
        self.performSegueWithIdentifier("ShowLoginSegue", sender:self);
        
        // Google Analytics
        let tracker = GAI.sharedInstance().defaultTracker;
        let event = GAIDictionaryBuilder.createEventWithCategory("User", action: "Login", label: "", value: nil).build()
        tracker.send(event)
    }
    
    func itemLongPress(gestureRecognizer: UILongPressGestureRecognizer!) {
        let point = gestureRecognizer.locationInView(self.tableView)
        let indexPath = self.tableView.indexPathForRowAtPoint(point)

        if (indexPath == nil || self.tableView.cellForRowAtIndexPath(indexPath!) == nil) {
            return;
        }

        if (gestureRecognizer.state == UIGestureRecognizerState.Began && indexPath != nil) {
            self.addItemTextField?.resignFirstResponder()
            self.startMoveAtIndexPath(indexPath!, atPoint:point);
        } else if (gestureRecognizer.state == UIGestureRecognizerState.Changed && indexPath != nil) {
            self.handleMoveToIndexPath(indexPath!, withPoint: point)
        } else if (gestureRecognizer.state == UIGestureRecognizerState.Ended){
            self.finishMoveAtIndexPath(indexPath, withPoint: point)
        }
    }
    
    func startMoveAtIndexPath(indexPath :NSIndexPath, atPoint point:CGPoint) {
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
            self.moveStartIndexPath = indexPath
            self.moveCurrentIndexPath = indexPath
            self.movingCellSnapshotView = self.snapshotViewForCell(cell)
            self.movingCellSnapshotView?.center = cell.center
            self.movingCellSnapshotView?.alpha = 0.0
            self.tableView.addSubview(self.movingCellSnapshotView!)
            UIView.animateWithDuration(0.25, delay:0.0, options:nil, animations: { () -> Void in
                self.movingCellSnapshotView!.center.y = point.y
                self.movingCellSnapshotView!.transform = CGAffineTransformMakeScale(1.05, 1.05)
                self.movingCellSnapshotView!.alpha = 0.98
                cell.alpha = 0.0
                }, completion: { (Bool) -> Void in
                    cell.hidden = true
                    
                    // enable scrolling for cell
                    self.scrollDisplayLink = CADisplayLink(target: self, selector: "scrollTableWithCell:");
                    self.scrollDisplayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode:NSDefaultRunLoopMode);
                })
        }
    }
    
    func snapshotViewForCell(cell :UITableViewCell) -> UIView {
        UIGraphicsBeginImageContextWithOptions(cell.bounds.size, false, 0.0)
        cell.layer.renderInContext(UIGraphicsGetCurrentContext())
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        var snapshot = UIImageView(image: image)
        snapshot.layer.masksToBounds = false
        snapshot.layer.cornerRadius = 0.0
        snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0)
        snapshot.layer.shadowRadius = 5.0
        snapshot.layer.shadowOpacity = 0.4
        
        return snapshot
    }
    
    func handleMoveToIndexPath(indexPath :NSIndexPath?, withPoint point:CGPoint) {
        if (self.movingCellSnapshotView == nil || self.moveCurrentIndexPath == nil) {
            return
        }
        let movingCell = self.movingCellSnapshotView!
        let sourceIndexPath = self.moveCurrentIndexPath!
        let destIndexPath = indexPath!
        
        
        var tableViewRect = self.tableView.bounds;
        // adjust rect for content inset as we will use it below for calculating scroll zones
        tableViewRect.size.height -= self.tableView.contentInset.top;
        
        // tell us if we should scroll and which direction
        var scrollZoneHeight = tableViewRect.size.height / 6;
        var bottomScrollBeginning = self.tableView.contentOffset.y + self.tableView.contentInset.top + tableViewRect.size.height - scrollZoneHeight;
        var topScrollBeginning = self.tableView.contentOffset.y + self.tableView.contentInset.top  + scrollZoneHeight;
        // we're in the bottom zone
        if (point.y >= bottomScrollBeginning) {
            self.scrollRate = (point.y - bottomScrollBeginning) / scrollZoneHeight;
        }
            // we're in the top zone
        else if (point.y <= topScrollBeginning) {
            self.scrollRate = (point.y - topScrollBeginning) / scrollZoneHeight;
        }
        else {
            self.scrollRate = 0;
        }

        var center = movingCell.center
        center.y = point.y
        movingCell.center = center
        
        self.tableView.moveRowAtIndexPath(sourceIndexPath, toIndexPath: destIndexPath)
        self.moveCurrentIndexPath = destIndexPath
    }
    
    func finishMoveAtIndexPath(gestureIndexPath :NSIndexPath?, withPoint point:CGPoint) {
        var indexPath = (gestureIndexPath != nil ? gestureIndexPath : self.moveCurrentIndexPath)!
        var snapshot = self.movingCellSnapshotView
        var cell = self.tableView.cellForRowAtIndexPath(indexPath)
        if (cell == nil) {
            return
        }
        cell!.hidden = false
        cell!.alpha = 0.0
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            snapshot!.center = cell!.center;
            snapshot!.transform = CGAffineTransformIdentity;
            snapshot!.alpha = 0.0;
            
            // Undo fade out.
            cell!.alpha = 1.0
        }) { (Bool) -> Void in
            self.moveStartIndexPath = nil;
            self.moveCurrentIndexPath = nil;
            self.movingCellSnapshotView?.removeFromSuperview()
            self.movingCellSnapshotView = nil
            self.scrollRate = 0.0
        }
        
        if let dl = self.scrollDisplayLink {
            dl.invalidate()
            self.scrollDisplayLink = nil
        }
        
        if let itemToUpdate = self.items.objectAtIndexPath(self.moveStartIndexPath!) as? DoozerItem
        {
            println("Moving item (\"\(itemToUpdate.title)\") to position \(indexPath.row)")
            self.itemMaster.updateItem(itemToUpdate, position: indexPath.row, parentItemId:listId);
        }

        self.itemMaster.saveContext()
        self.tableView.reloadData()
        
    }
    
    func scrollTableWithCell(timer: NSTimer) {
        var gesture = self.itemLongPressGestureRecognizer
        var location = gesture.locationInView(self.tableView)
        if (location.x.isNaN || location.y.isNaN || self.movingCellSnapshotView == nil) {
            return
        }
        
        var currentOffset = self.tableView.contentOffset;
        var newOffset = CGPointMake(currentOffset.x, currentOffset.y + self.scrollRate * 10);
        
        if (newOffset.y < -self.tableView.contentInset.top) {
            newOffset.y = -self.tableView.contentInset.top;
        } else if (self.tableView.contentSize.height + self.tableView.contentInset.bottom < self.tableView.frame.size.height) {
            newOffset = currentOffset;
        } else if (newOffset.y > (self.tableView.contentSize.height + self.tableView.contentInset.bottom) - self.tableView.frame.size.height) {
            newOffset.y = (self.tableView.contentSize.height + self.tableView.contentInset.bottom) - self.tableView.frame.size.height;
        }
        
        self.tableView.contentOffset = newOffset
        
        if (location.y >= 0 && location.y <= self.tableView.contentSize.height + 50) {
            self.movingCellSnapshotView!.center = CGPointMake(self.tableView.center.x, location.y);
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView?) -> Int
    {
        return (self.items!.sections != nil) ? self.items!.sections!.count : 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (self.listId != nil) {
            return;
        }
        let selectedItem = self.items.objectAtIndexPath(indexPath) as? DoozerItem
        if (self.navigationController != nil && self.storyboard != nil) {
            var newHomeViewController =
                self.storyboard!.instantiateViewControllerWithIdentifier("HomeViewController") as? HomeViewController
            newHomeViewController?.listId = selectedItem?.itemId
            self.navigationController!.pushViewController(newHomeViewController!, animated: true)
        }
        
    }

    func tableView(tableView: UITableView,
        moveRowAtIndexPath fromIndexPath: NSIndexPath,
        toIndexPath: NSIndexPath)
    {
        self.userEditing = true;
        if let itemToUpdate = self.items.objectAtIndexPath(fromIndexPath) as? DoozerItem
        {
            println("Moving item at position \(fromIndexPath.row) (\"\(itemToUpdate.title)\") to position \(toIndexPath.row)")
            self.itemMaster.updateItem(itemToUpdate, position: toIndexPath.row, parentItemId:listId);
        }
        self.userEditing = false;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.items!.sections![section].numberOfObjects!;
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (tableView.editing)
        {
            return .None
        }
        else
        {
            return .Delete
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item = self.items!.objectAtIndexPath(indexPath) as DoozerItem
        let cell = tableView.dequeueReusableCellWithIdentifier("DoozerItemCell") as UITableViewCell
        self.configureCell(cell, forItem:item)
        return cell
    }
   
    func tableView(tableView: UITableView?, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            let objectToDelete = items.objectAtIndexPath(indexPath) as DoozerItem
            self.itemMaster.deleteItem(objectToDelete)
            self.itemMaster.saveContext();
        }
    }
    
   
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false;
    }
    
    func textFieldShouldReturn(textField: UITextField!) {
        if (textField.text.utf16Count == 0) {
            return;
        }
        
        var insertPosition = 0;
        if let indexPaths = tableView.indexPathsForVisibleRows() {
            if (indexPaths.count > 0) {
                insertPosition = indexPaths[0].row;
            }
        }
        
        itemMaster.addItem(textField.text, position:insertPosition, parentItemId:listId)
        textField.text = ""
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController!) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController!, didChangeSection sectionInfo: NSFetchedResultsSectionInfo!, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch(type) {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index:sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            break;
            
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index:sectionIndex), withRowAnimation:UITableViewRowAnimation.Fade)
            break;
        default:
            println("Unrecognized change type")
            break;
        }
    }
    
    func controller(controller: NSFetchedResultsController!, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    
        var typeString = "NA"
        
        switch(type) {
            case .Insert:
                typeString = "Insert"
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade);
                
                if (newIndexPath!.row < tableView.numberOfRowsInSection(newIndexPath!.section))
                {
                    self.tableView.scrollToRowAtIndexPath(newIndexPath!, atScrollPosition:.None, animated:true)
                }
                break;
                
            case .Delete:
                typeString = "Delete"
                tableView.deleteRowsAtIndexPaths([indexPath!],
                    withRowAnimation:UITableViewRowAnimation.Fade);
                break;
                
            case .Update:
                typeString = "Update"
                self.configureCell(tableView.cellForRowAtIndexPath(indexPath!),
                    atIndexPath:indexPath!);
                break;
                
            case .Move:
                typeString = "Move"
                if (!self.userEditing)
                {
                    tableView.deleteRowsAtIndexPaths([indexPath!],
                        withRowAnimation:UITableViewRowAnimation.Fade);
                    tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade);
                }
                else
                {
                    self.tableView.reloadData();
                }
                break;
        default:
            println("Unrecognized change type");
        }

        // Google Analytics
        let tracker = GAI.sharedInstance().defaultTracker;
        let event = GAIDictionaryBuilder.createEventWithCategory("Item", action: typeString, label: "item", value: nil).build()
        tracker.send(event)
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController!) {
        tableView.endUpdates()
    }
    
    func configureCell(cell: UITableViewCell!, atIndexPath indexPath:NSIndexPath!) {
        let item = self.items!.objectAtIndexPath(indexPath) as DoozerItem
        self.configureCell(cell, forItem: item)
    }
    
    func configureCell(cell: UITableViewCell!, forItem item:DoozerItem) {
        cell.textLabel!.text = item.title
        if (item.parentItemId == nil) {
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        }
    }
}

