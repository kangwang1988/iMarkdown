//
//  CMTextAttributes.m
//  CocoaMarkdown
//
//  Created by Indragie on 1/15/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

#import "CMTextAttributes.h"
#import "CMPlatformDefines.h"

static NSDictionary * CMDefaultTextAttributes()
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:12.f]};
}

static NSDictionary * CMDefaultH1Attributes()
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:24.f]};
}

static NSDictionary * CMDefaultH2Attributes()
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:18.f]};
}

static NSDictionary * CMDefaultH3Attributes()
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:14.f]};
}

static NSDictionary * CMDefaultH4Attributes()
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:12.f]};
}

static NSDictionary * CMDefaultH5Attributes()
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:10.f]};
}

static NSDictionary * CMDefaultH6Attributes()
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:8.f]};
}

static NSDictionary * CMDefaultLinkAttributes()
{
    return @{
#if TARGET_OS_IPHONE
        NSForegroundColorAttributeName: UIColor.blueColor,
#else
        NSForegroundColorAttributeName: NSColor.blueColor,
#endif
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
}

#if TARGET_OS_IPHONE
static UIFont * MonospaceFont()
{
    CGFloat size = [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] pointSize];
    return [UIFont fontWithName:@"Menlo" size:size] ?: [UIFont fontWithName:@"Courier" size:size];
}
#endif

static NSParagraphStyle * DefaultIndentedParagraphStyle()
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.firstLineHeadIndent = 30;
    style.headIndent = 30;
    return style;
}

static NSDictionary * CMDefaultCodeBlockAttributes()
{
    return @{
        NSFontAttributeName: [UIFont systemFontOfSize:12.0],
        NSParagraphStyleAttributeName: DefaultIndentedParagraphStyle(),
        NSBackgroundColorAttributeName:[UIColor colorWithRGBHex:0XF6F6F6 alpha:1.f],
        NSForegroundColorAttributeName:[UIColor colorWithRGBHex:0X0000FF alpha:1.f]
    };
}

static NSDictionary * CMDefaultInlineCodeAttributes()
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:30],NSBackgroundColorAttributeName:[UIColor colorWithRGBHex:0XF6F6F6 alpha:1.f],
        NSForegroundColorAttributeName:[UIColor colorWithRGBHex:0X262626 alpha:1.f]};
}

static NSDictionary * CMDefaultBlockQuoteAttributes()
{
    return @{NSParagraphStyleAttributeName: DefaultIndentedParagraphStyle(),
             NSBackgroundColorAttributeName:[UIColor colorWithRGBHex:0XF6F6F6 alpha:1.f],
             NSForegroundColorAttributeName:[UIColor colorWithRGBHex:0X262626 alpha:1.f]};
}

static NSDictionary * CMDefaultOrderedListAttributes()
{
    return @{NSParagraphStyleAttributeName: DefaultIndentedParagraphStyle(),
             NSBackgroundColorAttributeName:[UIColor colorWithRGBHex:0XF6F6F6 alpha:1.f],
             NSForegroundColorAttributeName:[UIColor colorWithRGBHex:0X262626 alpha:1.f]};
}

static NSDictionary * CMDefaultUnorderedListAttributes()
{
    return @{NSParagraphStyleAttributeName: DefaultIndentedParagraphStyle(),
             NSBackgroundColorAttributeName:[UIColor colorWithRGBHex:0XF6F6F6 alpha:1.f],
             NSForegroundColorAttributeName:[UIColor colorWithRGBHex:0X262626 alpha:1.f]};
}

static NSDictionary * CMDefaultOrderedSublistAttributes()
{
    return @{NSParagraphStyleAttributeName: DefaultIndentedParagraphStyle(),
             NSBackgroundColorAttributeName:[UIColor colorWithRGBHex:0XF6F6F6 alpha:1.f],
             NSForegroundColorAttributeName:[UIColor colorWithRGBHex:0X262626 alpha:1.f]};
}

static NSDictionary * CMDefaultUnorderedSublistAttributes()
{
    return @{NSParagraphStyleAttributeName: DefaultIndentedParagraphStyle(),
             NSBackgroundColorAttributeName:[UIColor colorWithRGBHex:0XF6F6F6 alpha:1.f],
             NSForegroundColorAttributeName:[UIColor colorWithRGBHex:0X262626 alpha:1.f]};
}

@implementation CMTextAttributes

- (instancetype)init
{
    if ((self = [super init])) {
        _textAttributes = CMDefaultTextAttributes();
        _h1Attributes = CMDefaultH1Attributes();
        _h2Attributes = CMDefaultH2Attributes();
        _h3Attributes = CMDefaultH3Attributes();
        _h4Attributes = CMDefaultH4Attributes();
        _h5Attributes = CMDefaultH5Attributes();
        _h6Attributes = CMDefaultH6Attributes();
        _linkAttributes = CMDefaultLinkAttributes();
        _codeBlockAttributes = CMDefaultCodeBlockAttributes();
        _inlineCodeAttributes = CMDefaultInlineCodeAttributes();
        _blockQuoteAttributes = CMDefaultBlockQuoteAttributes();
        _orderedListAttributes = CMDefaultOrderedListAttributes();
        _unorderedListAttributes = CMDefaultUnorderedListAttributes();
        _orderedSublistAttributes = CMDefaultOrderedSublistAttributes();
        _unorderedSublistAttributes = CMDefaultUnorderedSublistAttributes();
    }
    return self;
}

- (NSDictionary *)attributesForHeaderLevel:(NSInteger)level
{
    switch (level) {
        case 1: return _h1Attributes;
        case 2: return _h2Attributes;
        case 3: return _h3Attributes;
        case 4: return _h4Attributes;
        case 5: return _h5Attributes;
        default: return _h6Attributes;
    }
}

@end
