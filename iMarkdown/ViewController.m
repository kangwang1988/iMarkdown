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
#import "CMHTMLImgTransformer.h"

@interface ViewController ()<CMAttributedStringRendererDelegate>
@property (nonatomic,strong) IBOutlet UITextView *textView;
@property (nonatomic,strong) IBOutlet UIButton *btn;
@end

@implementation ViewController
- (IBAction)onBtnRender:(id)sender{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"md"];
    CMDocument *document = [[CMDocument alloc] initWithContentsOfFile:path options:0];
    CMAttributedStringRenderer *renderer =[[CMAttributedStringRenderer alloc] initWithDocument:document attributes:[CMTextAttributes new]];
    [renderer registerHTMLElementTransformer:[CMHTMLStrikethroughTransformer new]];
    [renderer registerHTMLElementTransformer:[CMHTMLSubscriptTransformer new]];
    [renderer registerHTMLElementTransformer:[CMHTMLSuperscriptTransformer new]];
    [renderer registerHTMLElementTransformer:[CMHTMLUnderlineTransformer new]];
    [renderer registerHTMLElementTransformer:[CMHTMLImgTransformer new]];
    [renderer setDelegate:self];
    [self.textView setAttributedText:renderer.render];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.textView setEditable:NO];
    [self onBtnRender:self.btn];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CMAttributedStringRendererDelegate
- (void)render:(CMAttributedStringRenderer *)aRender getImageWithURL:(NSURL *)aURL sessionId:(NSString *)sessionId completionBlock:(void (^)(NSString *, NSData *))aCompletionBlock{
    [[[NSURLSession sharedSession] dataTaskWithURL:aURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(aCompletionBlock){
                aCompletionBlock(sessionId,(error?nil:data));
            }
            [self.textView setAttributedText:aRender.render];
        });
    }] resume];
}
@end
