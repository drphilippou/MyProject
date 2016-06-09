//
//  OBRRoutePoints.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/10/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRRoutePoints.h"


@implementation OBRRoutePoints

@dynamic route;
@dynamic order;
@dynamic routestr;
@dynamic segment;
@dynamic lat;
@dynamic lon;
@dynamic distance;

-(NSString*) description {
    return [NSString stringWithFormat:@"r:%d rs:%@ o:%d s:%d la:%f lo:%f d:%d",self.route,
            self.routestr,
            self.order,
            self.segment,
            self.lat,
            self.lon,
            self.distance];
}

@end
