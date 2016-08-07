//
//  ISPointAnnotation.m
//  iNSite
//
//  Created by Chris Karr on 8/7/16.
//  Copyright © 2016 iNSite AEC Hackathon Team. All rights reserved.
//

#import "ISPointAnnotation.h"

@implementation ISPointAnnotation

- (id) initWithDefinition:(NSDictionary *) definition;
{
    self.definition = definition;
    
    NSNumber * latitude = [self.definition valueForKey:@"latitude"];
    NSNumber * longitude = [self.definition valueForKey:@"longitude"];
    
    self.coordinate = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
    
    return self;
}

- (NSString *) title
{
    return [self.definition valueForKey:@"name"];
}

- (NSString *) subtitle
{
    return @"(Description coming soon!)";
}

@end
