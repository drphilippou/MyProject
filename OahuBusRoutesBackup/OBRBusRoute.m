//
//  OBRBusRoute.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/2/13.
//  Copyright (c) 2013 Paul Philippou. All rights reserved.
//

#import "OBRBusRoute.h"
#import "OBRBusStop.h"

@implementation OBRBusRoute

@synthesize busStopsOnRoute;
@synthesize numOfStops;


-(id)init {
    self = [super init];
    if (self) {
        busStopsOnRoute = [[NSMutableDictionary alloc] init];
        numOfStops = 0;
    }
    return self;
}



-(void) addBusStop:(OBRBusStop *) bs
              time:(NSString *)time
{
    //add the bus stop reference id
    [busStopsOnRoute setObject:bs forKey:time];
    [bs addARouteNumberToBusStop:bs route:10];
    numOfStops++;
}

@end
