//
//  UIColor+Extension.m
//  iMarkdown
//
//  Created by KyleWong on 17/08/2016.
//  Copyright © 2016 KyleWong. All rights reserved.
//

#import "UIColor+Extension.h"

@implementation UIColor (Extension)
+ (UIColor*) colorWithRGBHex: (UInt32) hex alpha:(CGFloat)alphaValue
{
    int r = (hex >> 16) & 0xFF;
    int g = (hex >> 8) & 0xFF;
    int b = (hex) & 0xFF;
    
    return [UIColor colorWithRed: r / 255.0f
                           green: g / 255.0f
                            blue: b / 255.0f
                           alpha: alphaValue];
}
@end
