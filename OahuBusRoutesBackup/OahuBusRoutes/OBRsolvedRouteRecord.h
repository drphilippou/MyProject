//
//  OBRsolvedRouteRecord.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 3/24/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBRStopNew.h"
#import "OBRScheduleNew.h"
#import "OBRTrip.h"

typedef enum {
    SRS,
    RSR,
    RWR,
    RRR,
    none
} SolvedRouteType;

typedef enum {
    WALK,
    STOP,
    ROUTE,
    ARRIVE,
    DEPART,
    TIMESTAMP
}solvedRouteEntryType;

@interface OBRsolvedRouteRecord : NSObject
@property (nonatomic) int stop;
@property (nonatomic) int walk;
@property (nonatomic) int minOfDayArrive;
@property (nonatomic) int minOfDayDepart;
@property (nonatomic) int day;
@property (nonatomic) int waitMin;
@property (nonatomic) int busNum;
@property (nonatomic) int distanceMeters;
@property (nonatomic) int adherence;
@property (nonatomic) float lat;
@property (nonatomic) float lon;
@property (nonatomic) NSTimeInterval lastUpdateSec;
@property (nonatomic) float orientation;
@property (nonatomic) bool transition;
@property (nonatomic) int completeMin;
@property (nonatomic) int initationMin;
@property (nonatomic) solvedRouteEntryType type;
@property (nonatomic) BOOL GPS;

@property (nonatomic,copy) NSString* route;
@property (nonatomic,copy) NSString* location;
@property (nonatomic,copy) NSString* direction;
@property (nonatomic,copy) NSString* headsign;
@property (nonatomic,copy) NSString* trip;
@property (nonatomic,copy) NSString* summaryDes;

@property (nonatomic) int summaryFirstStop;
@property (nonatomic) int summaryLastStop;
@property (nonatomic) int summaryFirstStopDepart;
@property (nonatomic) int summaryEarliestTimestamp;
@property (nonatomic) int summaryEarliestDepart;
@property (nonatomic) int summaryLastStopArrive;
@property (nonatomic) int summaryLatestArrive;
@property (nonatomic) int summaryLatestTimestamp;
@property (nonatomic) int summaryWaitMin;
@property (nonatomic) int summaryWalkedDistance;
@property (nonatomic,copy) NSString* summaryFirstTrip;
@property (nonatomic,copy) NSString* summaryLastTrip;
@property (nonatomic) SolvedRouteType summaryRouteType;



@property (nonatomic,readonly) bool isRoute;
@property (nonatomic,readonly) bool isStop;
@property (nonatomic,readonly) bool isWalk;


@property (nonatomic) OBRsolvedRouteRecord* nextRec;



-(void)refreshSummary:(OBRsolvedRouteRecord*)r;
-(OBRsolvedRouteRecord*)initStop:(int)stop;
-(OBRsolvedRouteRecord*)initStopRec:(OBRStopNew*)sr;
-(OBRsolvedRouteRecord*)initScheduleArrive:(OBRScheduleNew*)sr;
-(OBRsolvedRouteRecord*)initScheduleDepart:(OBRScheduleNew*)sr;
-(OBRsolvedRouteRecord*)initRoute:(NSString*)route;
-(OBRsolvedRouteRecord*)initWalk:(int)walk;
-(OBRsolvedRouteRecord*)initTimeArrive:(int)ta timeDepart:(int)td;
-(int)getEarliestDepart;
-(int)getEarliestTimestamp;
-(int)getLatestArrive;
-(int)getLatestTimestamp;
-(int)getWaitTime;
-(int)getFirstStop;
-(int)getLastStop;
-(int)getFirstStopDepart;
-(int)getNumStops;
-(int)getLastStopArrive;
-(int)getWalkedDistance;
-(NSString*)getRoutes;
-(OBRsolvedRouteRecord*)deepCopy:(OBRsolvedRouteRecord*)orig;

-(NSArray*)convertToArray:(OBRsolvedRouteRecord*) r;
-(NSArray*)convertToArrayWithTime:(OBRsolvedRouteRecord*) r;
@end
