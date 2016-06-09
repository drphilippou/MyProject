//
//  OBRscheduleFile.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 8/3/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRscheduleFile.h"

@implementation OBRscheduleFile

@synthesize stop;
@synthesize route;
@synthesize stopDay;
@synthesize stopMin;
@synthesize trip;
@synthesize headsign;
@synthesize direction;
@synthesize routestr;


-(NSString*) description {
    int hour = self.stopMin/60;
    int min = (self.stopMin - (hour*60));
    
    return [NSString stringWithFormat:@"s:%d r:%d rs:%@ d:%d h:%d m:%d %@ %@ %@",self.stop,
            self.route,
            self.routestr,
            self.stopDay,
            hour,
            min,
            self.trip,
            self.headsign,
            self.direction];
}


@end
