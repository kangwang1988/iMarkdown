//
//  CMHTMLImgTransformer.m
//  iMarkdown
//
//  Created by KyleWong on 16/08/2016.
//  Copyright © 2016 KyleWong. All rights reserved.
//

#import "CMHTMLImgTransformer.h"
#import "Ono.h"

@implementation CMHTMLImgTransformer
+ (NSString *)tagName { return @"img"; };
- (NSAttributedString *)attributedStringForElement:(ONOXMLElement *)element attributes:(NSDictionary *)attributes{
    CMAssertCorrectTag(element);
    NSMutableDictionary *allAttributes = [attributes mutableCopy];
    return [[NSAttributedString alloc] initWithString:element.stringValue attributes:allAttributes];
}
@end
