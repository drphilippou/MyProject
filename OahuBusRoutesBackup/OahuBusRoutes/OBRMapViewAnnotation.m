//
//  OBRMapViewAnnotation.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/7/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRMapViewAnnotation.h"

@implementation OBRMapViewAnnotation
@synthesize title;
@synthesize subtitle;
@synthesize coordinate;
@synthesize pinColor;

-(id)initWithTitle:(NSString *)ttl andCoordinate:(CLLocationCoordinate2D)c2d
{
    self = [super init];
    title = ttl;
    _type = nil;
    _orientation = 0;
    coordinate = c2d;
    return self;
}

-(id)initWithTitle:(NSString *)ttl andCoordinate:(CLLocationCoordinate2D)c2d andSubtitle:(NSString*)st
{
    self = [super init];
    title = ttl;
    subtitle = st;
    _type = nil;
    _orientation = 0;
    coordinate = c2d;
    return self;
}


-(id)initWithTitle:(NSString *)ttl andCoordinate:(CLLocationCoordinate2D)c2d andSubtitle:(NSString*)st Type:(NSString *)ty
{
    self = [super init];
    title = ttl;
    subtitle = st;
    _type = ty;
    _orientation = 0;
    coordinate = c2d;
    return self;
}




-(id)initWithCoordinate:(CLLocationCoordinate2D)coord {
    coordinate=coord;
    return self;
}

-(CLLocationCoordinate2D)coord
{
    return coordinate;
}



- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    coordinate = newCoordinate;
}

-(void)setTitle:(NSString *)t{
    title = t;
}
@end
