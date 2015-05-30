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


@interface DetailViewController ()


@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (IBAction)SaveItemDateButton:(id)sender {
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSString *currentSessionId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLoginIdSession"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:currentSessionId forHTTPHeaderField:@"sessionId"];
    
    Item *tempDetailItem = self.detailItem;
    NSString *updateURL = [NSString stringWithFormat:@"https://warm-atoll-6588.herokuapp.com/api/items/%@", tempDetailItem.itemId];
    
    tempDetailItem.title = self.ItemTitleField.text;
    
    NSDateFormatter* df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyyy-MM-dd"];
    
    NSString *tempDueDateString = self.DueDateTextField.text;
    NSDate *tempDueDateNSDate = [df dateFromString:tempDueDateString];
    tempDetailItem.duedate = tempDueDateNSDate;
    tempDetailItem.notes = self.NotesTextArea.text;
    
    NSDictionary *params = @{@"title": tempDetailItem.title,
                             @"duedate": tempDetailItem.duedate,
                             @"notes": tempDetailItem.notes
                             };
    
    [manager PUT:updateURL parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    
}

- (UIColor *)returnUIColor:(int)numPicker{
    UIColor *returnValue = nil;
    
    if (numPicker == 0) {
        returnValue = [UIColor colorWithRed:0.18 green:0.7 blue:0.76 alpha:1.0]; //blue
    }
    else if (numPicker == 1){
        returnValue = [UIColor colorWithRed:0.52 green:0.76 blue:0.25 alpha:1.0]; //green
    }
    else if (numPicker == 2){
        returnValue = [UIColor colorWithRed:1.0 green:0.42 blue:0.42 alpha:1.0]; //red
    }
    else if (numPicker == 3){
        returnValue = [UIColor colorWithRed:0.78 green:0.39 blue:0.69 alpha:1.0]; //purple
    }
    else if (numPicker == 4){
        returnValue = [UIColor colorWithRed:0.92 green:0.71 blue:0.0 alpha:1.0]; //yellow
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
    
    NSLog(@"here's the current ItemID = %@",currentItem.itemId);
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
