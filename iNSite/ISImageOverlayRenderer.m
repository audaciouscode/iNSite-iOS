//
//  ISImageOverlayRenderer.m
//  iNSite
//
//  Created by Chris Karr on 8/6/16.
//  Copyright © 2016 iNSite AEC Hackathon Team. All rights reserved.
//

#import "ISImageOverlayRenderer.h"
#import "ISImageOverlay.h"

@implementation ISImageOverlayRenderer

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    ISImageOverlay * imageOverlay = (ISImageOverlay *) self.overlay;
    
    CGRect theRect = [self rectForMapRect:imageOverlay.boundingMapRect];
    
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextTranslateCTM(context, 0.0, -theRect.size.height);
    // CGContextRotateCTM(context, imageOverlay.rotation);

    CGContextDrawImage(context, theRect, imageOverlay.image.CGImage);
}

@end
