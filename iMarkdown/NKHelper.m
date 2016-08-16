//
//  NKHelper.m
//  iMarkdown
//
//  Created by KyleWong on 17/08/2016.
//  Copyright © 2016 KyleWong. All rights reserved.
//

#import "NKHelper.h"

@implementation NKHelper
+ (NSString*)stringWithUUID
{
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    NSString *uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(nil, uuidObj);//__bridge_transfer cf对象控制权交给arc
    CFRelease(uuidObj);
    return uuidString;
}
@end
