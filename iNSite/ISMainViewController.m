//
//  ISViewController.m
//  iNSite
//
//  Created by Chris Karr on 8/6/16.
//  Copyright © 2016 iNSite AEC Hackathon Team. All rights reserved.
//

#import <PassiveDataKit/PassiveDataKit.h>

#import "AFImageDownloader.h"
#import "MMDrawerController.h"

#import "AppDelegate.h"

#import "ISImageOverlay.h"
#import "ISImageOverlayRenderer.h"
#import "ISMainViewController.h"
#import "ISShadowButton.h"
#import "ISMaskedView.h"
#import "ISPointAnnotation.h"

@interface ISMainViewController ()

@property MKMapView * mapView;
@property UIImage * cachedImage;
@property ISShadowButton * refreshButton;
@property BOOL longPressing;
@property UIView * reportingDialog;

@property UIView * emergencyTab;
@property UIView * safetyTab;
@property UIView * deliveryTab;
@property UIView * otherTab;

@property UIView * createFields;
@property UITextField * descriptionField;

@property CLLocationCoordinate2D lastLocation;

@end

@implementation ISMainViewController

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    NSArray * sites = [defaults valueForKey:@"ISSitesList"];
    
    self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"title_main_view_controller", nil), sites[0][@"name"]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshMap)
                                                 name:@"sites_updated"
                                               object:nil];
    self.longPressing = NO;
    
    [self showSafetyTab];
}

- (void) refreshMap {
    NSArray * overlays = [self.mapView overlays];
    
    [self.mapView removeOverlays:overlays];
    
    NSMutableArray * toRemove = [NSMutableArray array];
    
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MKUserLocation class]] == NO) {
            [toRemove addObject:annotation];
        }
    }
    
    [self.mapView removeAnnotations:toRemove];

    [self drawOverlay];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem * usersItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_nav_map_filter"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(showMapFilter)];
    self.navigationItem.leftBarButtonItem = usersItem;
    
    UIBarButtonItem * profileItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_nav_site_info"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(showSiteInfo)];
    self.navigationItem.rightBarButtonItem = profileItem;
    
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectZero];
    self.mapView.delegate = self;
    self.mapView.mapType = MKMapTypeHybrid;
    self.mapView.showsUserLocation = YES;

    UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(mapLongPress:)];
    longPress.minimumPressDuration = 1.0;
    [self.mapView addGestureRecognizer:longPress];

    [self.view addSubview:self.mapView];

    self.refreshButton = [ISShadowButton buttonWithType:UIButtonTypeCustom];
    [self.refreshButton setImage:[UIImage imageNamed:@"ic_button_refresh"] forState:UIControlStateNormal];
    [self.refreshButton addTarget:self action:@selector(requestRefresh) forControlEvents:UIControlEventTouchUpInside];
    self.refreshButton.showsTouchWhenHighlighted = YES;
    
    [self.view addSubview:self.refreshButton];
    self.view.clipsToBounds = NO;
    
    self.view.userInteractionEnabled = YES;
    self.refreshButton.userInteractionEnabled = YES;
    
    self.reportingDialog = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 300, 360)];
    self.reportingDialog.layer.cornerRadius = 8;
    self.reportingDialog.backgroundColor = [UIColor whiteColor];
    
    UIButton * closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(268, 8, 24, 24);
    [closeButton setImage:[UIImage imageNamed:@"ic_button_dialog_close"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeDialog) forControlEvents:UIControlEventTouchUpInside];
    [self.reportingDialog addSubview:closeButton];
    
    UILabel * dialogTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 8, 252, 24)];
    dialogTitle.font = [UIFont boldSystemFontOfSize:16];
    dialogTitle.text = NSLocalizedString(@"title_dialog_report_insite", nil);
    dialogTitle.textColor = [UIColor blackColor];
    [self.reportingDialog addSubview:dialogTitle];
    
    self.emergencyTab = [[ISMaskedView alloc] initWithFrame:CGRectMake(0, 40, 300, 320)];
    self.emergencyTab.userInteractionEnabled = YES;
    self.emergencyTab.clipsToBounds = NO;

    self.createFields = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 260)];
    
    CGFloat top = 16;
    UIFont * fieldFont = [UIFont systemFontOfSize:18];
    UIFont * labelFont = [UIFont systemFontOfSize:10 weight:500];

    self.descriptionField = [[UITextField alloc] initWithFrame:CGRectMake(16, top, 300 - 32, 18)];
    self.descriptionField.font = fieldFont;
    self.descriptionField.placeholder = NSLocalizedString(@"label_insite_description", nil);
    self.descriptionField.delegate = self;
    self.descriptionField.keyboardType = UIKeyboardTypeASCIICapable;
    self.descriptionField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    self.descriptionField.autocorrectionType =  UITextAutocorrectionTypeYes;
    self.descriptionField.returnKeyType = UIReturnKeyDone;

    [self.createFields addSubview:self.descriptionField];
    
    UIView * descriptionLine = [[UIView alloc] initWithFrame:CGRectMake(16, top + 18, 300 - 32, 1)];
    descriptionLine.backgroundColor = [UIColor colorWithRed:(0x3e/255.0) green:(0x50/255.0) blue:(0xb4/255.0) alpha:0.75];

    [self.createFields addSubview:descriptionLine];

    UILabel * descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, descriptionLine.frame.origin.y + 1, descriptionLine.frame.size.width, 14)];
    descriptionLabel.textColor = [UIColor colorWithRed:(0x3e/255.0) green:(0x50/255.0) blue:(0xb4/255.0) alpha:0.75];
    descriptionLabel.font = labelFont;
    descriptionLabel.text = [NSLocalizedString(@"label_insite_description", nil) uppercaseString];

    [self.createFields addSubview:descriptionLabel];

    UIButton * pictureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    pictureButton.frame = CGRectMake(27, 80, 64, 64);
    [pictureButton setImage:[UIImage imageNamed:@"ic_action_camera"] forState:UIControlStateNormal];
    [self.createFields addSubview:pictureButton];

    UILabel * buttonLabel = [[UILabel alloc] initWithFrame:CGRectMake(13, 80 + 64, 92, 14)];
    buttonLabel.font = labelFont;
    buttonLabel.textAlignment = NSTextAlignmentCenter;
    buttonLabel.textColor = [UIColor colorWithRed:(0x3e/255.0) green:(0x50/255.0) blue:(0xb4/255.0) alpha:0.75];
    buttonLabel.text = NSLocalizedString(@"button_action_camera", nil).uppercaseString;
    [self.createFields addSubview:buttonLabel];
    
    UIButton * videoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    videoButton.frame = CGRectMake(118, 80, 64, 64);
    [videoButton setImage:[UIImage imageNamed:@"ic_action_video"] forState:UIControlStateNormal];
    [self.createFields addSubview:videoButton];

    buttonLabel = [[UILabel alloc] initWithFrame:CGRectMake(104, 80 + 64, 92, 14)];
    buttonLabel.font = labelFont;
    buttonLabel.textAlignment = NSTextAlignmentCenter;
    buttonLabel.textColor = [UIColor colorWithRed:(0x3e/255.0) green:(0x50/255.0) blue:(0xb4/255.0) alpha:0.75];
    buttonLabel.text = NSLocalizedString(@"button_action_video", nil).uppercaseString;
    [self.createFields addSubview:buttonLabel];
    
    UIButton * recordingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recordingButton.frame = CGRectMake(209, 80, 64, 64);
    [recordingButton setImage:[UIImage imageNamed:@"ic_action_recording"] forState:UIControlStateNormal];
    [self.createFields addSubview:recordingButton];

    buttonLabel = [[UILabel alloc] initWithFrame:CGRectMake(195, 80 + 64, 92, 14)];
    buttonLabel.font = labelFont;
    buttonLabel.textAlignment = NSTextAlignmentCenter;
    buttonLabel.textColor = [UIColor colorWithRed:(0x3e/255.0) green:(0x50/255.0) blue:(0xb4/255.0) alpha:0.75];
    buttonLabel.text = NSLocalizedString(@"button_action_audio", nil).uppercaseString;
    [self.createFields addSubview:buttonLabel];
    
    UIButton * sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sendButton.frame = CGRectMake(152, 192, 132, 44);
    [sendButton addTarget:self action:@selector(transmit) forControlEvents:UIControlEventTouchUpInside];
    [sendButton setTitle:NSLocalizedString(@"button_action_send_insite", nil).uppercaseString forState:UIControlStateNormal];
    sendButton.titleLabel.textColor = [UIColor whiteColor];
    sendButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:500];
    sendButton.backgroundColor = [UIColor colorWithRed:(0x3e/255.0) green:(0x50/255.0) blue:(0xb4/255.0) alpha:1.0];
    sendButton.layer.cornerRadius = 4;
    sendButton.layer.shadowRadius = 2.0;
    sendButton.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    sendButton.layer.shadowOpacity = 0.5;
    sendButton.layer.masksToBounds = NO;

    [self.createFields addSubview:sendButton];

    UIBezierPath * maskPath = [UIBezierPath bezierPath];
    [maskPath moveToPoint:CGPointMake(0, 0)];
    [maskPath addLineToPoint:CGPointMake(300, 0)];
    [maskPath addLineToPoint:CGPointMake(300, 252)];
    [maskPath addLineToPoint:CGPointMake(60, 252)];
    [maskPath addLineToPoint:CGPointMake(60, 312)];
    [maskPath addArcWithCenter:CGPointMake(52, 312) radius:8 startAngle:0 endAngle:(M_PI / 2) clockwise:YES];
    [maskPath addLineToPoint:CGPointMake(8, 320)];
    [maskPath addArcWithCenter:CGPointMake(8, 312) radius:8 startAngle:(M_PI / 2) endAngle:M_PI clockwise:YES];
    [maskPath closePath];
    
    CAShapeLayer * mask = [CAShapeLayer layer];
    mask.path = maskPath.CGPath;
    mask.fillColor = [UIColor colorWithRed:(0x21/255.0) green:(0x96/255.0) blue:(0xf3/255.0) alpha:1.0].CGColor;
    mask.strokeColor = [UIColor colorWithWhite:(0xbd/255.0) alpha:1.0].CGColor;
    mask.name = @"mask";

    [self.emergencyTab.layer addSublayer:mask];
    
    UIButton * emergencyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    emergencyButton.tag = 100;
    emergencyButton.frame = CGRectMake(8, 260, 44, 44);
    [emergencyButton setImage:[UIImage imageNamed:@"ic_button_alert"] forState:UIControlStateNormal];
    [emergencyButton addTarget:self action:@selector(showEmergencyTab) forControlEvents:UIControlEventTouchUpInside];
    [self.emergencyTab addSubview:emergencyButton];

    [self.reportingDialog addSubview:self.emergencyTab];

    self.safetyTab = [[ISMaskedView alloc] initWithFrame:CGRectMake(0, 40, 300, 320)];
    self.safetyTab.userInteractionEnabled = YES;
    self.safetyTab.clipsToBounds = NO;

    maskPath = [UIBezierPath bezierPath];
    [maskPath moveToPoint:CGPointMake(0, 0)];
    [maskPath addLineToPoint:CGPointMake(300, 0)];
    [maskPath addLineToPoint:CGPointMake(300, 252)];
    [maskPath addLineToPoint:CGPointMake(120, 252)];
    [maskPath addLineToPoint:CGPointMake(120, 312)];
    [maskPath addArcWithCenter:CGPointMake(112, 312) radius:8 startAngle:0 endAngle:(M_PI / 2) clockwise:YES];
    [maskPath addLineToPoint:CGPointMake(68, 320)];
    [maskPath addArcWithCenter:CGPointMake(68, 312) radius:8 startAngle:(M_PI / 2) endAngle:M_PI clockwise:YES];
    [maskPath addLineToPoint:CGPointMake(60, 252)];
    [maskPath addLineToPoint:CGPointMake(0, 252)];
    [maskPath closePath];
    
    mask = [CAShapeLayer layer];
    mask.path = maskPath.CGPath;
    mask.fillColor = [UIColor colorWithRed:(0x96/255.0) green:(0x21/255.0) blue:(0xf3/255.0) alpha:1.0].CGColor;
    mask.strokeColor = [UIColor colorWithWhite:(0xbd/255.0) alpha:1.0].CGColor;
    mask.name = @"mask";
    
    [self.safetyTab.layer addSublayer:mask];

    UIButton * safetyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    safetyButton.tag = 100;
    safetyButton.frame = CGRectMake(68, 260, 44, 44);
    [safetyButton setImage:[UIImage imageNamed:@"ic_button_safety"] forState:UIControlStateNormal];
    [safetyButton addTarget:self action:@selector(showSafetyTab) forControlEvents:UIControlEventTouchUpInside];
    [self.safetyTab addSubview:safetyButton];

    [self.reportingDialog addSubview:self.safetyTab];

    self.deliveryTab = [[ISMaskedView alloc] initWithFrame:CGRectMake(0, 40, 300, 320)];
    self.deliveryTab.userInteractionEnabled = YES;
    self.deliveryTab.clipsToBounds = NO;
    
    maskPath = [UIBezierPath bezierPath];
    [maskPath moveToPoint:CGPointMake(0, 0)];
    [maskPath addLineToPoint:CGPointMake(300, 0)];
    [maskPath addLineToPoint:CGPointMake(300, 252)];
    [maskPath addLineToPoint:CGPointMake(180, 252)];
    [maskPath addLineToPoint:CGPointMake(180, 312)];
    [maskPath addArcWithCenter:CGPointMake(172, 312) radius:8 startAngle:0 endAngle:(M_PI / 2) clockwise:YES];
    [maskPath addLineToPoint:CGPointMake(128, 320)];
    [maskPath addArcWithCenter:CGPointMake(128, 312) radius:8 startAngle:(M_PI / 2) endAngle:M_PI clockwise:YES];
    [maskPath addLineToPoint:CGPointMake(120, 252)];
    [maskPath addLineToPoint:CGPointMake(0, 252)];
    [maskPath closePath];
    
    mask = [CAShapeLayer layer];

    mask.path = maskPath.CGPath;
    mask.fillColor = [UIColor colorWithRed:(0x21/255.0) green:(0x96/255.0) blue:(0xf3/255.0) alpha:1.0].CGColor;
    mask.strokeColor = [UIColor colorWithWhite:(0xbd/255.0) alpha:1.0].CGColor;
    mask.name = @"mask";
    [self.deliveryTab.layer addSublayer:mask];

    UIButton * deliveryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    deliveryButton.tag = 100;
    deliveryButton.frame = CGRectMake(128, 260, 44, 44);
    [deliveryButton setImage:[UIImage imageNamed:@"ic_button_delivery"] forState:UIControlStateNormal];
    [deliveryButton addTarget:self action:@selector(showDeliveryTab) forControlEvents:UIControlEventTouchUpInside];
    [self.deliveryTab addSubview:deliveryButton];

    [self.reportingDialog addSubview:self.deliveryTab];

    self.otherTab = [[ISMaskedView alloc] initWithFrame:CGRectMake(0, 40, 300, 320)];
    self.otherTab.userInteractionEnabled = YES;
    self.otherTab.clipsToBounds = NO;
    
    maskPath = [UIBezierPath bezierPath];
    [maskPath moveToPoint:CGPointMake(0, 0)];
    [maskPath addLineToPoint:CGPointMake(300, 0)];
    [maskPath addLineToPoint:CGPointMake(300, 252)];
    [maskPath addLineToPoint:CGPointMake(300, 312)];
    [maskPath addArcWithCenter:CGPointMake(292, 312) radius:8 startAngle:0 endAngle:(M_PI / 2) clockwise:YES];
    [maskPath addLineToPoint:CGPointMake(248, 320)];
    [maskPath addArcWithCenter:CGPointMake(248, 312) radius:8 startAngle:(M_PI / 2) endAngle:M_PI clockwise:YES];
    [maskPath addLineToPoint:CGPointMake(240, 252)];
    [maskPath addLineToPoint:CGPointMake(0, 252)];
    [maskPath closePath];
    
    mask = [CAShapeLayer layer];
    mask.path = maskPath.CGPath;
    mask.fillColor = [UIColor colorWithRed:(0x96/255.0) green:(0xf3/255.0) blue:(0x21/255.0) alpha:1.0].CGColor;
    mask.strokeColor = [UIColor colorWithWhite:(0xbd/255.0) alpha:1.0].CGColor;
    mask.name = @"mask";
    [self.otherTab.layer addSublayer:mask];

    UIButton * moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.tag = 100;
    moreButton.frame = CGRectMake(248, 260, 44, 44);
    [moreButton setImage:[UIImage imageNamed:@"ic_button_more"] forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(showOtherTab) forControlEvents:UIControlEventTouchUpInside];
    [self.otherTab addSubview:moreButton];

    [self.reportingDialog addSubview:self.otherTab];
    self.reportingDialog.hidden = YES;
    
    [self.view addSubview:self.reportingDialog];
}

- (void) transmit {
    NSString * description = self.descriptionField.text;
    
    PassiveDataKit * pdk = [PassiveDataKit sharedInstance];
    
    NSMutableDictionary * properties = [NSMutableDictionary dictionary];
    properties[@"latitude"] = [NSNumber numberWithDouble:self.lastLocation.latitude];
    properties[@"longitude"] = [NSNumber numberWithDouble:self.lastLocation.longitude];
    properties[@"description"] = description;
    properties[@"tags"] = @[@"todo, not-implemented"];
    
    [pdk logDataPoint:@"inSite (1.0 iOS)" generatorId:@"insite_report" source:@"my-test-user-id" properties:properties];
    
    NSURL * uploadUrl = [NSURL URLWithString:[NSBundle mainBundle].infoDictionary[@"iNSite Upload URL"]];
    
    [pdk uploadDataPoints:uploadUrl window:30.0 complete:^(BOOL success, int uploaded) {
        NSLog(@"SUCCESS");
        
        self.reportingDialog.hidden = YES;
    }];
    
    NSLog(@"SEND '%@' (%f, %f)", description, self.lastLocation.latitude, self.lastLocation.longitude);
}

- (void) disableTabs {
    NSArray * tabs = @[self.emergencyTab, self.safetyTab, self.deliveryTab, self.otherTab];
    
    for (UIView * tab in tabs) {
        UIButton * button = [tab viewWithTag:100];
        
        button.alpha = 0.5;
        
        for (CALayer * child in tab.layer.sublayers) {
            if ([@"mask" isEqualToString:child.name]) {
                ((CAShapeLayer *) child).fillColor = [UIColor colorWithWhite:(0xE0/255.0) alpha:1.0].CGColor;
            }
        }
    }
}

- (void) showEmergencyTab {
    [self disableTabs];
    
    [self.createFields removeFromSuperview];
    [self.emergencyTab addSubview:self.createFields];

    UIButton * button = [self.emergencyTab viewWithTag:100];
    
    button.alpha = 1.0;

    for (CALayer * child in self.emergencyTab.layer.sublayers) {
        if ([@"mask" isEqualToString:child.name]) {
            ((CAShapeLayer *) child).fillColor = [UIColor colorWithWhite:(0xff/255.0) alpha:1.0].CGColor;
        }
    }
    
    [self.reportingDialog bringSubviewToFront:self.emergencyTab];
}

- (void) showSafetyTab {
    [self disableTabs];

    [self.createFields removeFromSuperview];
    [self.safetyTab addSubview:self.createFields];

    UIButton * button = [self.safetyTab viewWithTag:100];
    
    button.alpha = 1.0;

    for (CALayer * child in self.safetyTab.layer.sublayers) {
        if ([@"mask" isEqualToString:child.name]) {
            ((CAShapeLayer *) child).fillColor = [UIColor colorWithWhite:(0xff/255.0) alpha:1.0].CGColor;
        }
    }

    [self.reportingDialog bringSubviewToFront:self.safetyTab];
}

- (void) showDeliveryTab {
    [self disableTabs];

    [self.createFields removeFromSuperview];
    [self.deliveryTab addSubview:self.createFields];

    UIButton * button = [self.deliveryTab viewWithTag:100];
    
    button.alpha = 1.0;

    for (CALayer * child in self.deliveryTab.layer.sublayers) {
        if ([@"mask" isEqualToString:child.name]) {
            ((CAShapeLayer *) child).fillColor = [UIColor colorWithWhite:(0xff/255.0) alpha:1.0].CGColor;
        }
    }

    [self.reportingDialog bringSubviewToFront:self.deliveryTab];
}

- (void) showOtherTab {
    [self disableTabs];

    [self.createFields removeFromSuperview];
    [self.otherTab addSubview:self.createFields];

    UIButton * button = [self.otherTab viewWithTag:100];
    
    button.alpha = 1.0;

    for (CALayer * child in self.otherTab.layer.sublayers) {
        if ([@"mask" isEqualToString:child.name]) {
            ((CAShapeLayer *) child).fillColor = [UIColor colorWithWhite:(0xff/255.0) alpha:1.0].CGColor;
        }
    }

    [self.reportingDialog bringSubviewToFront:self.otherTab];
}

- (void) closeDialog {
    self.reportingDialog.hidden = YES;
}


- (void) mapLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.longPressing == NO) {
        self.longPressing = YES;

        CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
        CLLocationCoordinate2D location = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
        
        [self showReportingDialog:location];
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        self.longPressing = NO;
    }
}

- (void) showReportingDialog:(CLLocationCoordinate2D) location {
    self.lastLocation = location;
        
    self.reportingDialog.hidden = NO;
}

- (MKOverlayRenderer *) mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[ISImageOverlay class]]) {
        return [[ISImageOverlayRenderer alloc] initWithOverlay:overlay];
    }
    
    return nil;
}

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>) annotation
{
    if ([annotation isKindOfClass:[ISPointAnnotation class]]) {
        ISPointAnnotation * point = (ISPointAnnotation *) annotation;
        
        MKAnnotationView * view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[point.definition[@"id"] description]];
        
        if (([point.definition[@"id"] integerValue] % 4) == 0) {
            view.image = [UIImage imageNamed:@"ic_pin_alert"];
        }
        else if (([point.definition[@"id"] integerValue] % 4) == 1) {
            view.image = [UIImage imageNamed:@"ic_pin_cone"];
        }
        else if (([point.definition[@"id"] integerValue] % 4) == 2) {
            view.image = [UIImage imageNamed:@"ic_pin_lumber"];
        }
        else if (([point.definition[@"id"] integerValue] % 4) == 3) {
            view.image = [UIImage imageNamed:@"ic_pin_info"];
        }

        view.canShowCallout = YES;
        
        return view;
    }

    return nil;
}


- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.mapView.frame = self.view.bounds;
    
    CGRect frame = self.view.frame;
    
    CGRect buttonFrame = CGRectMake(frame.size.width - 64, frame.size.height - 64, 56, 56);
    self.refreshButton.frame = buttonFrame;
    
    CALayer * buttonLayer = self.refreshButton.layer;
    buttonLayer.masksToBounds = NO;
    buttonLayer.cornerRadius = 28;
    buttonLayer.shadowOffset = CGSizeMake(0.0, 0.0);
    buttonLayer.shadowRadius = 2.0;
    buttonLayer.shadowOpacity = 0.5;
    
    CGRect dialogFrame = self.reportingDialog.frame;
    dialogFrame.origin.x = (frame.size.width - dialogFrame.size.width) / 2;
    dialogFrame.origin.y = (frame.size.height - dialogFrame.size.height) / 2;
    
    self.reportingDialog.frame = dialogFrame;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self refreshMap];
}

- (void) requestRefresh {
    AppDelegate * delegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
    
    [delegate refreshSites];
}

- (void) drawOverlay {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

    NSArray * sites = [defaults valueForKey:@"ISSitesList"];
    
    NSDictionary * siteOverlay = sites[0][@"overlays"][0];
    
    AFImageDownloader * downloader = [[AFImageDownloader alloc] init];
    
    [downloader downloadImageForURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:siteOverlay[@"overlay_url"]]]
                                   success:^(NSURLRequest *request, NSHTTPURLResponse  * response, UIImage *responseObject) {
                                       self.cachedImage = responseObject;
                                       
                                       CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([siteOverlay[@"overlay_center_y"] doubleValue], [siteOverlay[@"overlay_center_x"] doubleValue]);
                                       
                                       ISImageOverlay * overlay = [[ISImageOverlay alloc] initWithImage:self.cachedImage
                                                                                             coordinate:coord
                                                                                                  scale:[siteOverlay[@"overlay_scale"] doubleValue]
                                                                                               rotation:[siteOverlay[@"overlay_rotation"] doubleValue]];
                                       
                                       [self.mapView addOverlay:overlay];
                                   }
                                   failure:^(NSURLRequest *request, NSHTTPURLResponse * response, NSError *error) {
                                       NSLog(@"ERROR: %@", error);
                                   }];
    

    NSArray * points = siteOverlay[@"points"];
    
    for (NSDictionary * aoi in points) {
        // Add an annotation
        ISPointAnnotation * point = [[ISPointAnnotation alloc] initWithDefinition:aoi];
        
        [self.mapView addAnnotation:point];
    }
}

- (void) showMapFilter {
    MMDrawerController * root = (MMDrawerController *) self.view.window.rootViewController;
    
    [root toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void) showSiteInfo {
    MMDrawerController * root = (MMDrawerController *) self.view.window.rootViewController;
    
    [root toggleDrawerSide:MMDrawerSideRight animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}


@end
