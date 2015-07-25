//
//  DueItemsViewController.m
//  Doozer
//
//  Created by Daniel Apone on 7/23/15.
//  Copyright © 2015 Daniel Apone. All rights reserved.
//

#import "DueItemsViewController.h"
#import "Item.h"
#import "AppDelegate.h"
#import "ColorHelper.h"
#import "ItemViewController.h"

@interface DueItemsViewController ()

@end

@implementation DueItemsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    }

- (void)viewWillAppear:(BOOL)animated{
    
    self.sectionsToShow = [[NSMutableArray alloc]init];
    self.navigationController.navigationBar.barStyle  = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];

    self.tableView.backgroundColor = [UIColor whiteColor];
    
    [self.navigationController.navigationBar setTitleTextAttributes: @{
                                                                       NSForegroundColorAttributeName: [UIColor blackColor],
                                                                       NSFontAttributeName: [UIFont fontWithName:@"Avenir" size:20],
                                                                       }];
    
    self.navigationItem.title = @"Due Tasks";
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyyyMMdd"];
    NSString *currentDateString = [df stringFromDate:[NSDate date]];
    
    NSInteger numberOfTotalLists = [self.fetchedResultsController.fetchedObjects count];
    NSInteger numberOfListsWithDueItems = 0;
    
    for (int i = 0; i <+ numberOfTotalLists; i++) {
        
        Item *parent = [self.fetchedResultsController.fetchedObjects objectAtIndex:i];
        NSArray *children = [self getItemsOnList:parent.itemId];
        int count = 0;
        for (Item *eachItem in children){
            if (eachItem.done.intValue == 0) {
                NSString *dueDateString = [df stringFromDate:eachItem.duedate];
                if (dueDateString.intValue > 0 && dueDateString.intValue <= currentDateString.intValue) {
                    NSLog(@"due item is = %@", eachItem.title);
                    count += 1;
                }
            }
        }
        if (count > 0) {
            numberOfListsWithDueItems += 1;
            [self.sectionsToShow addObject:parent];
        }
    }
    self.numberOfLists = numberOfListsWithDueItems;

    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSArray *)getItemsOnList :(NSString *)parentId{
    
    AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext* context = appDelegate.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemRecord" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", parentId];
    [fetchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"Master3"];
    [NSFetchedResultsController deleteCacheWithName:@"Master3"];
    
    NSError *error = nil;
    if (![aFetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
        
    NSArray *itemsOnSelectedList = aFetchedResultsController.fetchedObjects;
    return itemsOnSelectedList;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //NSLog(@"count = %lu", [self.fetchedResultsController.fetchedObjects count]);
    //NSLog(@"num sections called");

    return [self.sectionsToShow count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyyyMMdd"];
    NSString *currentDateString = [df stringFromDate:[NSDate date]];
    
    Item *parent = [self.sectionsToShow objectAtIndex:section];
    NSArray *children = [self getItemsOnList:parent.itemId];
    int count = 0;
    for (Item *eachItem in children){
        if (eachItem.done.intValue == 0) {
            NSString *dueDateString = [df stringFromDate:eachItem.duedate];
            if (dueDateString.intValue > 0 && dueDateString.intValue <= currentDateString.intValue) {
                count += 1;
            }
        }
    }
    return count;

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}


-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    Item *itemInHeader = [self.sectionsToShow objectAtIndex:section];

    UIView *tempView=[[UIView alloc]initWithFrame:CGRectMake(0,200,300,244)];
    tempView.backgroundColor=[ColorHelper getUIColorFromString:itemInHeader.color :1];
    
    UILabel *tempLabel=[[UILabel alloc]initWithFrame:CGRectMake(15,0,300,44)];
    tempLabel.backgroundColor=[UIColor clearColor];
    tempLabel.textColor = [UIColor whiteColor];
    tempLabel.font = [UIFont fontWithName:@"Avenir" size:20];
    tempLabel.text= itemInHeader.title;
    
    [tempView addSubview:tempLabel];
    
    return tempView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dueCells" forIndexPath:indexPath];
    
    // Configure the cell...
    NSInteger section = indexPath.section;
    
    Item *parentList = [self.sectionsToShow objectAtIndex:section];
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyyyMMdd"];
    NSString *currentDateString = [df stringFromDate:[NSDate date]];
    
    NSArray *children = [self getItemsOnList:parentList.itemId];
    NSMutableArray *dueItems = [[NSMutableArray alloc]init];
    for (Item *eachItem in children){
        if (eachItem.done.intValue == 0) {
            NSString *dueDateString = [df stringFromDate:eachItem.duedate];
            if (dueDateString.intValue > 0 && dueDateString.intValue <= currentDateString.intValue) {
                [dueItems addObject:eachItem];
            }
        }
    }
    Item *itemInCell = [dueItems objectAtIndex:indexPath.row];
    
    cell.textLabel.text = itemInCell.title;
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showItemFromDue"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        
        ItemViewController *itemController = segue.destinationViewController;
        
        AppDelegate* appDelegate = [AppDelegate sharedAppDelegate];
        NSManagedObjectContext* context = appDelegate.managedObjectContext;
        
        itemController.managedObjectContext = context;
        
        NSLog(@"indexpath clicked section = %ld, row = %ld", (long)indexPath.section, (long)indexPath.row);
        
        Item *list = [self.sectionsToShow objectAtIndex:indexPath.section];
        NSArray *itemsOnList = [self getItemsOnList:list.itemId];
        
        NSDateFormatter *df = [[NSDateFormatter alloc]init];
        [df setDateFormat:@"yyyyMMdd"];
        NSString *currentDateString = [df stringFromDate:[NSDate date]];
        
        NSMutableArray *dueItems = [[NSMutableArray alloc]init];
        for (Item *eachItem in itemsOnList){
            NSLog(@"items %@", eachItem.title);
            if (eachItem.done.intValue == 0) {
                NSString *dueDateString = [df stringFromDate:eachItem.duedate];
                if (dueDateString.intValue > 0 && dueDateString.intValue <= currentDateString.intValue) {
                    [dueItems addObject:eachItem];
                }
            }
        }
        
        
        Item *itemInCell = [dueItems objectAtIndex:indexPath.row];
        
        [itemController setDetailItem:itemInCell];
        [itemController setDisplayListOfItem:list];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];

        
    }
}


#pragma mark - Fetched results controller


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
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"Master"];
    self.fetchedResultsController = aFetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    
    
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
