//
//  ViewController.m
//  NKMarkDown
//
//  Created by KyleWong on 14/08/2016.
//  Copyright © 2016 KyleWong. All rights reserved.
//

#import "ViewController.h"
#import "CMDocument.h"
#import "CMAttributedStringRenderer.h"
#import "CMTextAttributes.h"
#import "CMHTMLStrikethroughTransformer.h"
#import "CMHTMLSuperscriptTransformer.h"
#import "CMHTMLUnderlineTransformer.h"
#import "CMHTMLSubscriptTransformer.h"

@interface ViewController ()
@property (nonatomic,strong) IBOutlet UITextView *textView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"md"];
    CMDocument *document = [[CMDocument alloc] initWithContentsOfFile:path options:0];
    CMAttributedStringRenderer *renderer =[[CMAttributedStringRenderer alloc] initWithDocument:document attributes:[CMTextAttributes new]];
    [renderer registerHTMLElementTransformer:[CMHTMLStrikethroughTransformer new]];
    [renderer registerHTMLElementTransformer:[CMHTMLSubscriptTransformer new]];
    [renderer registerHTMLElementTransformer:[CMHTMLSuperscriptTransformer new]];
    [renderer registerHTMLElementTransformer:[CMHTMLUnderlineTransformer new]];
    [self.textView setAttributedText:renderer.render];
    [self.textView setEditable:NO];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end