//
//  ISImageOverlay.h
//  iNSite
//
//  Created by Chris Karr on 8/6/16.
//  Copyright © 2016 iNSite AEC Hackathon Team. All rights reserved.
//

@import Foundation;
@import CoreLocation;
@import MapKit;

@interface ISImageOverlay : NSObject<MKOverlay>

@property UIImage * image;
@property CGFloat scale;
@property CGFloat rotation;

- (instancetype) initWithImage:(UIImage *) image coordinate:(CLLocationCoordinate2D) coordinate scale:(CGFloat) scale rotation:(CGFloat) rotation ;

@end
