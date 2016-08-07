//
//  ISShadowButton.m
//  iNSite
//
//  Created by Chris Karr on 8/6/16.
//  Copyright © 2016 iNSite AEC Hackathon Team. All rights reserved.
//

#import "ISShadowButton.h"

@implementation ISShadowButton

+ (instancetype)buttonWithType:(UIButtonType)buttonType {
    ISShadowButton * button = [super buttonWithType:buttonType];
    return button;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    CALayer * buttonLayer = self.layer;
    
    if (highlighted) {
        buttonLayer.shadowRadius = 1.0;
        buttonLayer.shadowOffset = CGSizeMake(0.0, 0.0);
    } else {
        buttonLayer.shadowRadius = 2.0;
        buttonLayer.shadowOffset = CGSizeMake(0.0, 2.0);
    }
}

@end
