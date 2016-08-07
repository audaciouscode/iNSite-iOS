//
//  ISImageOverlay.m
//  iNSite
//
//  Created by Chris Karr on 8/6/16.
//  Copyright © 2016 iNSite AEC Hackathon Team. All rights reserved.
//

#import "ISImageOverlay.h"

@interface ISImageOverlay ()

@property CLLocationCoordinate2D center;

@end

@implementation ISImageOverlay

- (instancetype) initWithImage:(UIImage *) image coordinate:(CLLocationCoordinate2D) coordinate scale:(CGFloat) scale rotation:(CGFloat) rotation {
    if (self = [super init]) {
        self.image = image;
        self.center = coordinate;
        self.scale = scale;
        self.rotation = rotation;
    }
    
    return self;
}

- (MKMapRect) boundingMapRect {
    CGFloat delta = 2 * 1000 * 1000 * self.scale;
    
    CLLocationCoordinate2D bottomLeft = CLLocationCoordinate2DMake(self.center.latitude - (self.image.size.height / delta), self.center.longitude - (self.image.size.width / delta));
    CLLocationCoordinate2D topRight = CLLocationCoordinate2DMake(self.center.latitude + (self.image.size.height / delta), self.center.longitude + (self.image.size.width / delta));
    
    MKMapPoint p1 = MKMapPointForCoordinate (bottomLeft);
    MKMapPoint p2 = MKMapPointForCoordinate (topRight);

    return MKMapRectMake(fmin(p1.x,p2.x), fmin(p1.y,p2.y), fabs(p1.x-p2.x), fabs(p1.y-p2.y));
}

- (void) setCoordinate:(CLLocationCoordinate2D) coordinate {
    self.center = coordinate;
}

- (CLLocationCoordinate2D) coordinate {
    return self.center;
}

@end
