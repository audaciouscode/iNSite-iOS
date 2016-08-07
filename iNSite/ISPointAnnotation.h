//
//  ISPointAnnotation.h
//  iNSite
//
//  Created by Chris Karr on 8/7/16.
//  Copyright © 2016 iNSite AEC Hackathon Team. All rights reserved.
//

@import CoreLocation;
@import MapKit;

@interface ISPointAnnotation : NSObject<MKAnnotation>

@property(nonatomic) CLLocationCoordinate2D coordinate;
@property NSDictionary * definition;

- (id) initWithDefinition:(NSDictionary *) definition;

@end
