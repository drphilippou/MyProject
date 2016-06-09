//
//  OBRarrivalRecord.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/5/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRarrivalRecord.h"

@implementation OBRarrivalRecord
@synthesize stop,IDnum,route,vehicle,estimated,canceled;
@synthesize lat,lon;
@synthesize timestamp,stopTime,trip,headsign,direction;

-(OBRarrivalRecord*) init
{
    self = [super init];
    self.stop = -1;
    self.IDnum = -1;
    self.route = -1;
    self.vehicle = -1;
    self.estimated = -1;
    self.canceled = -1;
    self.lat = 0;
    self.lon = 0;
    self.timestamp = nil;
    self.stopTime = nil;
    self.trip = nil;
    self.headsign = nil;
    self.direction = nil;
    
    return self;
}

@end
