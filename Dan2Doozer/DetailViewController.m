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

@interface DetailViewController ()


@end

@implementation DetailViewController

#pragma mark - Managing the detail item


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
        
    }
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
