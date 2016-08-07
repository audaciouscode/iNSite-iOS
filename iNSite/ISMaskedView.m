//
//  ISMaskedView.m
//  iNSite
//
//  Created by Chris Karr on 8/7/16.
//  Copyright © 2016 iNSite AEC Hackathon Team. All rights reserved.
//

#import "ISMaskedView.h"

@implementation ISMaskedView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CAShapeLayer * mask = nil;
    
    for (CALayer * child in self.layer.sublayers) {
        if ([@"mask" isEqualToString:child.name]) {
            mask = (CAShapeLayer *) child;
        }
    }
    
    if (mask != nil) {
        CGPathRef path = mask.path;
        
        return CGPathContainsPoint(path, NULL, point, FALSE);
    }
    
    return NO;
}

@end
