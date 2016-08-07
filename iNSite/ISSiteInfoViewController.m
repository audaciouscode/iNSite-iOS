//
//  ISSiteInfoViewController.m
//  iNSite
//
//  Created by Chris Karr on 8/6/16.
//  Copyright © 2016 iNSite AEC Hackathon Team. All rights reserved.
//

@import WebKit;

#import "ISSiteInfoViewController.h"

@interface ISSiteInfoViewController ()

@property WKWebView * webView;
@property UIView * headerView;
@end

@implementation ISSiteInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.webView];
    
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 66)];
    
    self.headerView.backgroundColor = [UIColor colorWithRed:(0xff/255.0) green:(0xa0/255.0) blue:(0x00/255.0) alpha:1.0];
    
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(16, 40, self.view.frame.size.width - 32, 14)];
    label.text = NSLocalizedString(@"title_site_info_view_controller", nil).uppercaseString;
    label.font = [UIFont boldSystemFontOfSize:14];
    label.textColor = [UIColor whiteColor];
    
    [self.headerView addSubview:label];
    
    [self.view addSubview:self.headerView];
    
    NSString * filePath = [[NSBundle mainBundle] pathForResource:@"site-info" ofType:@"html"];
    
    NSMutableString * html = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    
    [self.webView loadHTMLString:html baseURL:nil];
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect frame = self.view.bounds;
    
    self.headerView.frame = CGRectMake(0, 0, frame.size.width, 66);
    self.webView.frame = CGRectMake(0, 66, frame.size.width, frame.size.height - 66);
}


@end
