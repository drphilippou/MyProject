//
//  OBRalgPoint.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/13/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRalgPoint.h"

@implementation OBRalgPoint


-(NSString*)description {
    return [NSString stringWithFormat:@"%d %f %f %f",_segment,_findex,_lat,_lon];
}


-(OBRalgPoint*)createAlgPoint:(float)lat lon:(float)lon {
    OBRalgPoint* r = [[OBRalgPoint alloc] init];
    r.lat = lat;
    r.lon = lon;
    r.saved = NO;
    r.dropped = NO;
    return r;
}
@end
