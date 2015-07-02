//
//  ColorHelper.m
//  Doozer
//
//  Created by Daniel Apone on 7/2/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "ColorHelper.h"

@implementation ColorHelper

+ (UIColor *)returnUIColor:(int)numPicker :(float)alpha {
    UIColor *returnValue = nil;
    
    if (numPicker == 0) {
        returnValue = [UIColor colorWithRed:46/255. green:179/255. blue:193/255. alpha:alpha]; //blue
    }
    else if (numPicker == 1){
        returnValue = [UIColor colorWithRed:134/255. green:194/255. blue:63/255. alpha:alpha]; //green
    }
    else if (numPicker == 2){
        returnValue = [UIColor colorWithRed:255/255. green:107/255. blue:107/255. alpha:alpha]; //red
    }
    else if (numPicker == 3){
        returnValue = [UIColor colorWithRed:198/255. green:99/255. blue:175/255. alpha:alpha]; //purple
    }
    else if (numPicker == 4){
        returnValue = [UIColor colorWithRed:236/255. green:183/255. blue:0/255. alpha:alpha]; //yellow
    }
    else{
        returnValue = [UIColor whiteColor];
    }
    return returnValue;
}



@end
