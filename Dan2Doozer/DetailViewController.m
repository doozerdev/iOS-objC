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
        self.ItemTitleField.text = displayItem.title;
        self.OrderValueField.text = displayItem.order.stringValue;
        if(displayItem.done == YES){
            NSString *doneText = @"DONE!!";
            self.CompletedField.text = doneText;
        }else{
            NSString *notDoneText = @"Not done yet....";
            self.CompletedField.text = notDoneText;
        }
        
        self.ItemIDTextField.text = displayItem.itemId;
        self.ParentIDTextField.text = displayItem.parent;
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
