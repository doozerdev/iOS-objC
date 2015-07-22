//
//  AddItemViewController.m
//  Doozer
//
//  Created by Daniel Apone on 7/20/15.
//  Copyright © 2015 Daniel Apone. All rights reserved.
//

#import "AddItemViewController.h"
#import "AppDelegate.h"
#import "ParentCustomCell.h"
#import "ColorHelper.h"
#import "MasterViewController.h"

@interface AddItemViewController ()

@end

@implementation AddItemViewController

- (IBAction)pressedCancelButton:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];

}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.showAllLists = NO;
    // Do any additional setup after loading the view.
    self.selectedList = [self.fetchedResultsController.fetchedObjects objectAtIndex:0];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    NSLog(@"text field is beginning editting");
    
    return YES;
}

// It is important for you to hide the keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
   /*
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    
    NSLog(@"text field ending editing");
    NSString *currentText = textField.text;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.rowOfExpandedCell inSection:0];
    
    Item *itemInCell = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.view.window endEditing: YES];
    
    NSLog(@"index path of added cell = %@", indexPath);
    
    if (currentText.length == 0) {
        if (self.addingAnItem) {
            
            NSLog(@"deleting just created row");
            [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
            self.addingAnItem = NO;
            
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
        
    }else{
        itemInCell.title = currentText;
        
        [textField resignFirstResponder];
        
        NSLog(@"aboout to save the new list");
        
        if (self.addingAnItem) {
            [AddItemsToServer addThisItem:itemInCell];
            self.addingAnItem = NO;
        }else{
            [UpdateItemsOnServer updateThisItem:itemInCell];
        }
    }
    
    
    
    self.rowOfExpandedCell = -1;
    [self.tableView reloadData];
    //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    return YES;
    
    */
    NSLog(@"finished editing");
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Number of rows is the number of time zones in the region for the specified section.
    NSInteger rowCount = [self.fetchedResultsController.fetchedObjects count];
    return rowCount+1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger rowCount = [self.fetchedResultsController.fetchedObjects count];
    
    if (self.showAllLists) {
        return 40;
    }else{
        if (indexPath.row == 0 || indexPath.row == rowCount) {
            return 40;
        }else{
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifier = @"CellsOfLists";
    ParentCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[ParentCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
    }
    
    NSInteger rowCount = [self.fetchedResultsController.fetchedObjects count];
    //Item *itemInCell = [[Item alloc]init];

    if (indexPath.row == rowCount){
        cell.cellItemTitle.userInteractionEnabled = YES;
        cell.cellItemTitle.text = nil;
        cell.cellItemTitle.textColor = [UIColor blackColor];
        [cell.cellItemTitle becomeFirstResponder];
        
    }else {
        Item *itemInCell = [self.fetchedResultsController objectAtIndexPath:indexPath];

        if (indexPath.row == 0) {
            cell.cellItemTitle.userInteractionEnabled = NO;
            cell.cellItemTitle.text = self.selectedList.title;
            //itemInCell = self.selectedList;
        }else{
            cell.cellItemTitle.text = itemInCell.title;
            cell.cellItemTitle.userInteractionEnabled = NO;
        }
        cell.cellItemTitle.textColor = [ColorHelper getUIColorFromString:itemInCell.color :1];

    }
    
    cell.cellItemTitle.textAlignment = NSTextAlignmentLeft;
    cell.cellItemTitle.font = [UIFont fontWithName:@"Avenir" size:20];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedList = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (self.showAllLists) {
        self.showAllLists = NO;
    }else {
        self.showAllLists = YES;
    }
    
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];

}


 #pragma mark - Segues
 
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 
     if ([[segue identifier] isEqualToString:@"unwindToMaster"]) {
         NSLog(@"prepare for segue unwind to master");
     }
 }



- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", nil];
    [fetchRequest setPredicate:predicate];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"Master2"];
    //aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"Master2"];
    
    
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
