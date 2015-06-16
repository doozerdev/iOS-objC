//
//  DetailViewController.m
//  Dan2Doozer
//
//  Created by Daniel Apone on 5/1/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "DetailViewController.h"
#import "ListViewController.h"
#import "Item.h"
#import "AFNetworking.h"
#import "DoozerSyncManager.h"

@interface DetailViewController ()


@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (IBAction)SaveItemDateButton:(id)sender {
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    Item *tempDetailItem = self.detailItem;
   
    tempDetailItem.title = self.ItemTitleField.text;
    
    NSDateFormatter* df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyyy-MM-dd"];
    
    NSString *tempDueDateString = self.DueDateTextField.text;
    NSDate *tempDueDateNSDate = [df dateFromString:tempDueDateString];
    tempDetailItem.duedate = tempDueDateNSDate;
    tempDetailItem.notes = self.NotesTextArea.text;
    
    NSString *itemIdCharacter = [tempDetailItem.itemId substringToIndex:1];
    NSLog(@"first char = %@", itemIdCharacter);
    
    if ([itemIdCharacter isEqualToString:@"1"]) {
        //do nothing
    }else{
        NSMutableArray *newArrayOfItemsToUpdate = [[[NSUserDefaults standardUserDefaults] valueForKey:@"itemsToUpdate"]mutableCopy];
        [newArrayOfItemsToUpdate addObject:tempDetailItem.itemId];
        [[NSUserDefaults standardUserDefaults] setObject:newArrayOfItemsToUpdate forKey:@"itemsToUpdate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    [DoozerSyncManager syncWithServer:self.managedObjectContext];
    
}

- (UIColor *)returnUIColor:(int)numPicker{
    UIColor *returnValue = nil;
    
    if (numPicker == 0) {
        returnValue = [UIColor colorWithRed:46/255. green:179/255. blue:193/255. alpha:1]; //blue
    }
    else if (numPicker == 1){
        returnValue = [UIColor colorWithRed:134/255. green:194/255. blue:63/255. alpha:1]; //green
    }
    else if (numPicker == 2){
        returnValue = [UIColor colorWithRed:255/255. green:107/255. blue:107/255. alpha:1]; //red
    }
    else if (numPicker == 3){
        returnValue = [UIColor colorWithRed:198/255. green:99/255. blue:175/255. alpha:1]; //purple
    }
    else if (numPicker == 4){
        returnValue = [UIColor colorWithRed:236/255. green:183/255. blue:0/255. alpha:1]; //yellow
    }
    else{
        returnValue = [UIColor whiteColor];
    }
    
    return returnValue;
    
}

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
    }
}

- (void)setDisplayListOfItem:(id)newDisplayListOfItem {
    if (_displayListOfItem != newDisplayListOfItem) {
        _displayListOfItem = newDisplayListOfItem;
        
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    Item *displayListParent = self.displayListOfItem;
    
    UIColor *tempColor = [self returnUIColor:[displayListParent.list_color intValue]];
    self.view.backgroundColor = tempColor;
    
    
    if (self.detailItem) {
        Item *displayItem = self.detailItem;
        self.navigationItem.title = displayItem.title;
        self.ItemTitleField.text = displayItem.title;
        self.ItemIDTextLabel.text = [NSString stringWithFormat:@"Item ID = %@",displayItem.itemId];
        self.ParentIDTextLabel.text = [NSString stringWithFormat:@"Parent ID = %@",displayItem.parent];
        
        self.OrderValueLabel.text = [NSString stringWithFormat:@"Order Value = %@", displayItem.order.stringValue];
        
        if([displayItem.done intValue] == 1){
            NSString *doneText = @"Done = YES";
            self.DoneLabel.text = doneText;
        }else{
            NSString *notDoneText = @"Done = NO";
            self.DoneLabel.text = notDoneText;
        }
        
        if(displayItem.duedate){
            NSString *fullDateString = [NSString stringWithFormat:@"%@", displayItem.duedate];
            NSString *mySmallerString = [fullDateString substringToIndex:10];
            self.DueDateTextField.text = mySmallerString;
        }else{
            NSDate *currDate = [NSDate date];
            NSString *fullDateString = [NSString stringWithFormat:@"%@", currDate];
            NSString *mySmallerString = [fullDateString substringToIndex:10];
            self.DueDateTextField.text = mySmallerString;
            
        }

        
        
        self.NotesTextArea.text = displayItem.notes;
        
    }
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Fetched results controller



- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    Item *currentItem = self.detailItem;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemId == %@", currentItem.itemId];
    [fetchRequest setPredicate:predicate];
    
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Detail"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"Detail"];
    
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
}



@end
