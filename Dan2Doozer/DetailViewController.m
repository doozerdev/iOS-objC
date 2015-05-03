//
//  DetailViewController.m
//  Dan2Doozer
//
//  Created by Daniel Apone on 5/1/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "DetailViewController.h"
#import "Item.h"

@interface DetailViewController ()


@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
            
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
        Item *displayItem = self.detailItem;
        self.ItemTitleField.text = displayItem.itemName;
        self.OrderValueField.text = displayItem.order.stringValue;
        self.CompletedField.text = displayItem.completed.stringValue;
        
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
        NSString *labelData = [dateFormatter stringFromDate:displayItem.createdDate];
        self.CreationDateField.text = labelData;
        
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
