//
//  ColorHelper.m
//  Doozer
//
//  Created by Daniel Apone on 7/2/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import "ColorHelper.h"

@implementation ColorHelper

+ (NSString *)returnUIColorString:(int)numPicker{
    switch (numPicker) {
        case 0:
            return @"255,107,107,1"; //red
            break;
        case 1:
            return @"236,183,0,1"; //yellow
            break;
        case 2:
            return @"134,194,63,1"; //green
            break;
        case 3:
            return @"46,179,193,1"; //blue
            break;
        case 4:
            return @"198,99,175,1"; //purple
            break;
        default:
            return @"0,0,0,0";
            break;
    }
}

+ (UIColor *)getUIColorFromString:(NSString *)colorString :(float)alpha{
    
    NSArray *rgbValues = [colorString componentsSeparatedByString:@","];
    
    NSString *red = [rgbValues objectAtIndex:0];
    NSString *green = [rgbValues objectAtIndex:1];
    NSString *blue = [rgbValues objectAtIndex:2];
    
    UIColor *color = [UIColor colorWithRed:red.intValue/255. green:green.intValue/255. blue:blue.intValue/255. alpha:alpha];
    
    return color;
}


@end
