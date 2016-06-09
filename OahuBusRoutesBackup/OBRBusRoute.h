//
//  OBRBusRoute.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/2/13.
//  Copyright (c) 2013 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBRBusStop.h"

@interface OBRBusRoute : NSObject

@property (nonatomic,strong) NSMutableDictionary *busStopsOnRoute;;
@property (nonatomic) int numOfStops;

-(void) addBusStop:(OBRBusStop *) busStopV time:(NSString *) time;
-(id) init;

@end
