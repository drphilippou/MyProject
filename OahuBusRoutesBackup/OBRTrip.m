//
//  OBRTrip.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 11/11/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRTrip.h"
#import "OBRStopNew.h"


@implementation OBRTrip

@dynamic day;
@dynamic direction;
@dynamic earliestTS;
@dynamic headsign;
@dynamic latestTS;
@dynamic route;
@dynamic tripNum;
@dynamic tripStr;
@dynamic stops;

-(NSString*)description {
    return [NSString stringWithFormat:@"OBRTrip %@ rt:%@ dir:%@ head:%@ early:%d late:%d",self.tripStr,
            self.route, self.direction,self.headsign,self.earliestTS,self.latestTS];
}

@end
