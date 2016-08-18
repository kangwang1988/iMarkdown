//
//  CMAttributedStringRenderer.m
//  CocoaMarkdown
//
//  Created by Indragie on 1/14/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

#import "CMAttributedStringRenderer.h"
#import "CMAttributeRun.h"
#import "CMCascadingAttributeStack.h"
#import "CMStack.h"
#import "CMHTMLElementTransformer.h"
#import "CMHTMLElement.h"
#import "CMHTMLUtilities.h"
#import "CMTextAttributes.h"
#import "CMNode.h"
#import "CMParser.h"
#import "Ono.h"

@interface CMAttributedStringRenderer () <CMParserDelegate>
@property (nonatomic,copy) NSString *sessionId;
@property (nonatomic,strong) NSMutableAttributedString *buffer;
@property (nonatomic,strong) CMCascadingAttributeStack *attributeStack;
@property (nonatomic,assign) NSInteger rangeOffset;
@end

@implementation CMAttributedStringRenderer {
    CMDocument *_document;
    CMTextAttributes *_attributes;
    CMStack *_HTMLStack;
    NSMutableDictionary *_tagNameToTransformerMapping;
}

- (instancetype)initWithDocument:(CMDocument *)document attributes:(CMTextAttributes *)attributes
{
    if ((self = [super init])) {
        _document = document;
        _attributes = attributes;
        _tagNameToTransformerMapping = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)registerHTMLElementTransformer:(id<CMHTMLElementTransformer>)transformer
{
    NSParameterAssert(transformer);
    _tagNameToTransformerMapping[[transformer.class tagName]] = transformer;
}

- (NSAttributedString *)render
{
    if (!self.buffer.length) {
        [self setSessionId:[NKHelper stringWithUUID]];
        _attributeStack = [[CMCascadingAttributeStack alloc] init];
        _HTMLStack = [[CMStack alloc] init];
        _buffer = [[NSMutableAttributedString alloc] init];
        
        CMParser *parser = [[CMParser alloc] initWithDocument:_document delegate:self];
        [parser parse];
        _attributeStack = nil;
        _HTMLStack = nil;
        [self setRangeOffset:0];
    }
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]  initWithAttributedString:self.buffer];
    CFStringTrimWhitespace((__bridge CFMutableStringRef)attributedString.mutableString);
    return attributedString;
}

#pragma mark - CMParserDelegate

- (void)parserDidStartDocument:(CMParser *)parser
{
    [self.attributeStack push:CMDefaultAttributeRun(_attributes.textAttributes)];
}

- (void)parserDidEndDocument:(CMParser *)parser
{
}

- (void)parser:(CMParser *)parser foundText:(NSString *)text
{
    CMHTMLElement *element = [_HTMLStack peek];
    if (element != nil) {
        [element.buffer appendString:text];
    }
    else{
        [self appendString:text];
    }
}

- (void)parser:(CMParser *)parser didStartHeaderWithLevel:(NSInteger)level
{
    [self.attributeStack push:CMDefaultAttributeRun([_attributes attributesForHeaderLevel:level])];
}

- (void)parser:(CMParser *)parser didEndHeaderWithLevel:(NSInteger)level
{
    [self appendString:@"\n"];
    [self.attributeStack pop];
//    [self appendLineBreak];
}

- (void)parserDidStartParagraph:(CMParser *)parser
{
    if (![self nodeIsInTightMode:parser.currentNode]) {
        NSDictionary *attributes = [[self.attributeStack peek] attributes];
        NSMutableParagraphStyle* paragraphStyle = attributes[NSParagraphStyleAttributeName];
        if(!paragraphStyle){
            paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.paragraphSpacingBefore = 12;
        }
        [self.attributeStack push:CMDefaultAttributeRun(@{NSParagraphStyleAttributeName: paragraphStyle})];
    }
}

- (void)parserDidEndParagraph:(CMParser *)parser
{
    if (![self nodeIsInTightMode:parser.currentNode]) {
        [self.attributeStack pop];
        [self appendString:@"\n"];
    }
}

- (void)parserDidStartEmphasis:(CMParser *)parser
{
    BOOL hasExplicitFont = _attributes.emphasisAttributes[NSFontAttributeName] != nil;
    [self.attributeStack push:CMTraitAttributeRun(_attributes.emphasisAttributes, hasExplicitFont ? 0 : CMFontTraitItalic)];
}

- (void)parserDidEndEmphasis:(CMParser *)parser
{
    [self.attributeStack pop];
}

- (void)parserDidStartStrong:(CMParser *)parser
{
    BOOL hasExplicitFont = _attributes.strongAttributes[NSFontAttributeName] != nil;
    [self.attributeStack push:CMTraitAttributeRun(_attributes.strongAttributes, hasExplicitFont ? 0 : CMFontTraitBold)];
}

- (void)parserDidEndStrong:(CMParser *)parse
{
    [self.attributeStack pop];
}

- (void)parser:(CMParser *)parser didStartLinkWithURL:(NSURL *)URL title:(NSString *)title
{
    NSMutableDictionary *baseAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:URL, NSLinkAttributeName, nil];
#if !TARGET_OS_IPHONE
    if (title != nil) {
        baseAttributes[NSToolTipAttributeName] = title;
    }
#endif
    [baseAttributes addEntriesFromDictionary:_attributes.linkAttributes];
    [self.attributeStack push:CMDefaultAttributeRun(baseAttributes)];
}

- (void)parser:(CMParser *)parser didEndLinkWithURL:(NSURL *)URL title:(NSString *)title
{
    [self.attributeStack pop];
}

- (void)parser:(CMParser *)parser didStartImageWithURL:(NSURL *)URL title:(NSString *)title
{
    if (![URL isFileURL]) {
        CMHTMLElement *element = [self newHTMLElementForTagName:@"img" HTML:@""];
        if (element != nil) {
            [_HTMLStack push:element];
        }
    }
}

- (void)parser:(CMParser *)parser didEndImageWithURL:(NSURL *)URL title:(NSString *)title
{
    CMHTMLElement *element = [_HTMLStack peek];
    NSString *alt = element.buffer;
    if(!alt.length){
        alt = [[URL.absoluteString lastPathComponent] stringByDeletingPathExtension];
    }
    NSRange range = NSMakeRange(self.buffer.length, alt.length);
    [self.buffer appendAttributedString:[[NSAttributedString alloc] initWithString:alt attributes:_attributes.h3Attributes]];
    if([self.delegate respondsToSelector:@selector(render:getImageWithURL:sessionId:completionBlock:)]){
        [self.delegate render:self getImageWithURL:URL sessionId:self.sessionId completionBlock:^(NSString *aSessionId, NSData *aImgData) {
            if([aSessionId isEqualToString:self.sessionId] && aImgData){
                NSTextAttachment *textAttachment = [NSTextAttachment new];
                [textAttachment setImage:[UIImage imageWithData:aImgData]];
                NSAttributedString *attrWithImg = [NSAttributedString attributedStringWithAttachment:textAttachment];
                [self.buffer replaceCharactersInRange:NSMakeRange(range.location+self.rangeOffset, range.length) withAttributedString:attrWithImg];
                [self setRangeOffset:self.rangeOffset+attrWithImg.length-range.length];
            }
        }];
    }
    [_HTMLStack pop];
}

- (void)parser:(CMParser *)parser foundHTML:(NSString *)HTML
{
    NSString *tagName = CMTagNameFromHTMLTag(HTML);
    if (tagName.length != 0) {
        CMHTMLElement *element = [self newHTMLElementForTagName:tagName HTML:HTML];
        if (element != nil) {
            [self appendHTMLElement:element];
        }
    }
}

- (void)parser:(CMParser *)parser foundInlineHTML:(NSString *)HTML
{
    NSString *tagName = CMTagNameFromHTMLTag(HTML);
    if (tagName.length != 0) {
        CMHTMLElement *element = nil;
        if (CMIsHTMLVoidTagName(tagName)) {
            element = [self newHTMLElementForTagName:tagName HTML:HTML];
            if (element != nil) {
                [self appendHTMLElement:element];
            }
        } else if (CMIsHTMLClosingTag(HTML)) {
            if ((element = [_HTMLStack pop])) {
                NSAssert([element.tagName isEqualToString:tagName], @"Closing tag does not match opening tag");
                [element.buffer appendString:HTML];
                [self appendHTMLElement:element];
            }
        } else if (CMIsHTMLTag(HTML)) {
            element = [self newHTMLElementForTagName:tagName HTML:HTML];
            if (element != nil) {
                [_HTMLStack push:element];
            }
        }
    }
}

- (void)parser:(CMParser *)parser foundCodeBlock:(NSString *)code info:(NSString *)info
{
    [self.attributeStack push:CMDefaultAttributeRun(_attributes.codeBlockAttributes)];
    [self appendString:[NSString stringWithFormat:@"\n\n%@\n\n", code]];
    [self.attributeStack pop];
}

- (void)parser:(CMParser *)parser foundInlineCode:(NSString *)code
{
    [self.attributeStack push:CMDefaultAttributeRun(_attributes.inlineCodeAttributes)];
    [self appendString:code];
    [self.attributeStack pop];
}

- (void)parserFoundSoftBreak:(CMParser *)parser
{
    [self appendString:@" "];
}

- (void)parserFoundLineBreak:(CMParser *)parser
{
    [self appendString:@"\n"];
}

- (void)parserDidStartBlockQuote:(CMParser *)parser
{
    [self.attributeStack push:CMDefaultAttributeRun(_attributes.blockQuoteAttributes)];
}

- (void)parserDidEndBlockQuote:(CMParser *)parser
{
    [self.attributeStack pop];
}

- (void)parser:(CMParser *)parser didStartUnorderedListWithTightness:(BOOL)tight
{
    [self.attributeStack push:CMDefaultAttributeRun([self listAttributesForNode:parser.currentNode])];
    [self appendString:@"\n"];
}

- (void)parser:(CMParser *)parser didEndUnorderedListWithTightness:(BOOL)tight
{
    [self.attributeStack pop];
}

- (void)parser:(CMParser *)parser didStartOrderedListWithStartingNumber:(NSInteger)num tight:(BOOL)tight
{
    [self.attributeStack push:CMOrderedListAttributeRun([self listAttributesForNode:parser.currentNode], num)];
    [self appendString:@"\n"];
}

- (void)parser:(CMParser *)parser didEndOrderedListWithStartingNumber:(NSInteger)num tight:(BOOL)tight
{
    [self.attributeStack pop];
}

- (void)parserDidStartListItem:(CMParser *)parser
{
    CMNode *node = parser.currentNode.parent;
    switch (node.listType) {
        case CMListTypeNone:
            NSAssert(NO, @"Parent node of list item must be a list");
            break;
        case CMListTypeUnordered: {
            [self appendString:@"\u2022 "];
            [self.attributeStack push:CMDefaultAttributeRun(_attributes.unorderedListItemAttributes)];
            break;
        }
        case CMListTypeOrdered: {
            CMAttributeRun *parentRun = [self.attributeStack peek];
            [self appendString:[NSString stringWithFormat:@"%ld. ", (long)parentRun.orderedListItemNumber]];
            parentRun.orderedListItemNumber++;
            [self.attributeStack push:CMDefaultAttributeRun(_attributes.orderedListItemAttributes)];
            break;
        }
        default:
            break;
    }
}

- (void)parserDidEndListItem:(CMParser *)parser
{
    if (parser.currentNode.next != nil || [self sublistLevel:parser.currentNode] == 1) {
        [self appendString:@"\n"];
    }
    [self.attributeStack pop];
}

#pragma mark - Private

- (NSDictionary *)listAttributesForNode:(CMNode *)node
{
    if (node.listType == CMListTypeNone) {
        return nil;
    }
    
    NSUInteger sublistLevel = [self sublistLevel:node.parent];
    if (sublistLevel == 0) {
        return node.listType == CMListTypeOrdered ? _attributes.orderedListAttributes : _attributes.unorderedListAttributes;
    }
    
    NSParagraphStyle *rootListParagraphStyle = [NSParagraphStyle defaultParagraphStyle];
    NSMutableDictionary *listAttributes;
    if (node.listType == CMListTypeOrdered) {
        listAttributes = [_attributes.orderedSublistAttributes mutableCopy];
        rootListParagraphStyle = _attributes.orderedListAttributes[NSParagraphStyleAttributeName];
    } else {
        listAttributes = [_attributes.unorderedSublistAttributes mutableCopy];
        rootListParagraphStyle = _attributes.unorderedListAttributes[NSParagraphStyleAttributeName];
    }
    
    if (listAttributes[NSParagraphStyleAttributeName] != nil) {
        NSMutableParagraphStyle *paragraphStyle = [((NSParagraphStyle *)listAttributes[NSParagraphStyleAttributeName]) mutableCopy];
        paragraphStyle.headIndent = rootListParagraphStyle.headIndent + paragraphStyle.headIndent * sublistLevel;
        paragraphStyle.firstLineHeadIndent = rootListParagraphStyle.firstLineHeadIndent + paragraphStyle.firstLineHeadIndent * sublistLevel;
        listAttributes[NSParagraphStyleAttributeName] = paragraphStyle;
    }
    
    return [listAttributes copy];
}

- (NSUInteger)sublistLevel:(CMNode *)node
{
    if (node.parent == nil) {
        return 0;
    } else {
        return (node.listType == CMListTypeNone ? 0 : 1) + [self sublistLevel:node.parent];
    }
}

- (CMHTMLElement *)newHTMLElementForTagName:(NSString *)tagName HTML:(NSString *)HTML
{
    NSParameterAssert(tagName);
    id<CMHTMLElementTransformer> transformer = _tagNameToTransformerMapping[tagName];
    if (transformer != nil) {
        CMHTMLElement *element = [[CMHTMLElement alloc] initWithTransformer:transformer];
        [element.buffer appendString:HTML];
        return element;
    }
    return nil;
}

- (BOOL)nodeIsInTightMode:(CMNode *)node
{
    CMNode *grandparent = node.parent.parent;
    return grandparent.listTight;
}

- (void)appendString:(NSString *)string
{
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string attributes:self.attributeStack.cascadedAttributes];
    [self.buffer appendAttributedString:attrString];
}

- (void)appendHTMLElement:(CMHTMLElement *)element
{
    NSError *error = nil;
    ONOXMLDocument *document = [ONOXMLDocument HTMLDocumentWithString:element.buffer encoding:NSUTF8StringEncoding error:&error];
    if (document == nil) {
        NSLog(@"Error creating HTML document for buffer \"%@\": %@", element.buffer, error);
        return;
    }
    
    ONOXMLElement *XMLElement = document.rootElement[0][0];
    NSDictionary *attributes = self.attributeStack.cascadedAttributes;
    NSAttributedString *attrString = [element.transformer attributedStringForElement:XMLElement attributes:attributes];
    
    if (attrString != nil) {
        CMHTMLElement *parentElement = [_HTMLStack peek];
        if (parentElement == nil) {
            [self.buffer appendAttributedString:attrString];
        } else {
            [parentElement.buffer appendString:attrString.string];
        }
    }
}

- (void)appendLineBreak{
    NSString *unicodeStr = @"\u00a0\t\t";
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:unicodeStr];
    NSRange strRange = NSMakeRange(0, str.length);
    NSMutableParagraphStyle *const tabStyle = [[NSMutableParagraphStyle alloc] init];
    tabStyle.headIndent = 10;
    tabStyle.firstLineHeadIndent = 1;
    tabStyle.tailIndent = -1;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    NSTextTab *listTab = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentCenter location:width - tabStyle.headIndent + tabStyle.tailIndent options:@{}];
    tabStyle.tabStops = @[listTab];
    [str  addAttribute:NSParagraphStyleAttributeName value:tabStyle range:strRange];
    [str addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInt:1] range:strRange];
    [str addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:strRange];
    [self.buffer appendAttributedString:str];
}
@end
