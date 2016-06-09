//
//  OBRStopNew.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 11/11/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRStopNew.h"
#import "OBRTrip.h"


@implementation OBRStopNew

@dynamic lat;
@dynamic lon;
@dynamic number;
@dynamic streets;
@dynamic trips;


-(NSString*)description {
    return [NSString stringWithFormat:@"STOPNew %d lat:%f lon:%f streets:%@ trips:%ld",self.number,self.lat,self.lon,self.streets,(unsigned long)self.trips.count];
}
@end
