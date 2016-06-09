//
//  OBRScheduleNew.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 11/9/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRScheduleNew.h"
#import "OBRStopNew.h"
#import "OBRTrip.h"


@implementation OBRScheduleNew

@dynamic day;
@dynamic minOfDay;
@dynamic stop;
@dynamic trip;

-(NSString*)description {
    return [NSString stringWithFormat:@"SCH day:%d min:%d trip;%@ stop %@",self.day,
            self.minOfDay, self.trip, self.stop];
}

@end
