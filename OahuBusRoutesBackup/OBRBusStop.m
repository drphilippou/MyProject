//
//  OBRBusStop.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/1/13.
//  Copyright (c) 2013 Paul Philippou. All rights reserved.
//

#import "OBRBusStop.h"

@implementation OBRBusStop

@synthesize latitude;
@synthesize longitude;
@synthesize altitude;
@synthesize refid;
@synthesize covered;
@synthesize address;
@synthesize imageKey,routes;

//fills in all the values for a bus stop
-(id)initWithStopInfo:(NSString *) addressV
               latVal:(float) latitudeV
               lonVal:(float) longitudeV
               altVal:(float) altitudeV
             refidVal:(int) refidV
           coveredVal:(BOOL) coveredV
          imageKeyVal:(NSString *) imageKeyV
             routeVal:(int) routeV
{
    //call the superclasses init
    self = [super init];
    
    if (self) {
        //initialize the routes array
        self.routes = [[NSMutableArray alloc] init];
        
           //init with the values
        self.address = addressV;
        self.latitude = latitudeV;
        self.longitude = longitudeV;
        self.altitude = altitudeV;
        self.refid = refidV;
        self.covered = coveredV;
        self.imageKey = imageKeyV;
        [[self routes] addObject:[[NSNumber alloc] initWithInt:routeV]];
    }
     
    return self;
}


-(void)addARouteNumberToBusStop:(OBRBusStop *)bs
                    route:(int) rt
{
    [bs.routes addObject:[[NSNumber alloc] initWithInt:rt]];
}



//creates an empty bus stop
-(id)init{
    self = [super init];
     NSLog(@"creating a blank bus stop");
    
    if (self) {
        //init with the values
        self.routes = [[NSMutableArray alloc] init];
        self.latitude = 0;
        self.longitude = 0;
        self.altitude = 0;
        self.refid = -1;
        self.covered = NO;
        self.imageKey = nil;
    }
    
    return self;
}



@end


