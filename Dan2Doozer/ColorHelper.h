//
//  ColorHelper.h
//  Doozer
//
//  Created by Daniel Apone on 7/2/15.
//  Copyright (c) 2015 Daniel Apone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ColorHelper : UIColor

+ (NSString *)returnUIColorString:(int)numPicker;

+ (UIColor *)getUIColorFromString:(NSString *)colorString :(float)alpha;

    
@end
