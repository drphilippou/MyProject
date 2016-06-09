//
//  OBRArrival.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/8/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRArrival.h"


@implementation OBRArrival

@dynamic stop;
@dynamic idNum;
@dynamic route;
@dynamic vehicle;
@dynamic estimated;
@dynamic canceled;
@dynamic lat;
@dynamic lon;
@dynamic timestamp;
@dynamic stoptime;
@dynamic trip;
@dynamic headsign;
@dynamic direction;

-(NSString*) description {
    
    NSDate* ts = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:self.timestamp];
    NSDate* st = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:self.stoptime];
    NSString* s = [NSString stringWithFormat:@"s:%d r:%d v:%d est:%d ts:%@ st:%@",self.stop,
                   self.route,
                   self.vehicle,
                   self.estimated,
                   ts,
                   st];
    return s;
}
@end
