//
//  OBRsolvedRouteRecord.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 3/24/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRsolvedRouteRecord.h"

@implementation OBRsolvedRouteRecord

-(OBRsolvedRouteRecord*)initStopRec:(OBRStopNew*) sr {
    self = [super init];
    _stop = sr.number;
    _route = nil;
    _location = sr.streets;
    _walk = -1;
    _type = STOP;
    return self;
}

-(OBRsolvedRouteRecord*)initScheduleArrive:(OBRScheduleNew*) rr {
    self = [super init];
    _route = rr.trip.route;
    _stop = rr.stop.number;
    _walk = -1;
    _day = rr.day;
    _minOfDayArrive = rr.minOfDay;
    _trip = rr.trip.tripStr;
    _type = ARRIVE;
    return self;
}

-(OBRsolvedRouteRecord*)initScheduleDepart:(OBRScheduleNew*) rr {
    self = [super init];
    _route = rr.trip.route;
    _stop = rr.stop.number;
    _walk = -1;
    _day = rr.day;
    _minOfDayDepart = rr.minOfDay;
    _trip = rr.trip.tripStr;
    _type = DEPART;
    return self;
}

-(OBRsolvedRouteRecord*)initStop:(int)stop {
    self = [super init];
    _stop = stop;
    _route = nil;
    _walk = -1;
    _type = STOP;
    return self;
}

-(OBRsolvedRouteRecord*)initRoute:(NSString *)route{
    self = [super init];
    _route= route;
    _stop = -1;
    _walk = -1;
    _type = ROUTE;
    return self;
}

-(OBRsolvedRouteRecord*)initWalk:(int)walk {
    self = [super init];
    _route = nil;
    _stop = -1;
    _walk = walk;
    _type = WALK;
    return self;
}

-(OBRsolvedRouteRecord*)initTimeArrive:(int)ta timeDepart:(int)td {
    self = [super init];
    _route = nil;
    _stop = -1;
    _walk = -1;
    _minOfDayArrive = ta;
    _minOfDayDepart = td;
    _type = TIMESTAMP;
    return self;
}

-(NSString*) description {
    return [NSString stringWithFormat:@"\n t:%d w:%d s:%d r:%@ t0:%d t1:%d w:%d l:%@ h:%@ d:%@ n:%@",_type,_walk,_stop,_route,_minOfDayArrive,_minOfDayDepart,_waitMin, _location,_headsign,_direction, _nextRec];
}

-(int)getEarliestDepart{
    int earliest = 32000;
    OBRsolvedRouteRecord* p = self;
    while (p !=nil) {
        if (p.minOfDayDepart <earliest && p.minOfDayDepart != -1) {
            earliest = p.minOfDayDepart;
        }
        p = p.nextRec;
    }
    return earliest;
}

-(int)getEarliestTimestamp{
    int earliest = 32000;
    OBRsolvedRouteRecord* p = self;
    while (p != nil) {
        if (p.minOfDayDepart <earliest && p.minOfDayDepart != -1) {
            earliest = p.minOfDayDepart;
        }
        if (p.minOfDayArrive <earliest && p.minOfDayArrive != -1) {
            earliest = p.minOfDayArrive;
        }
        p = p.nextRec;
    }
    return earliest;
}

-(int)getFirstStop{
    OBRsolvedRouteRecord* p = self;
    while (p != nil) {
        if (p.type ==STOP ) {
            return p.stop;
        }
        p = p.nextRec;
    }
    return -1;
}

-(int)getLastStop {
    int res = -1;
    OBRsolvedRouteRecord* p = self;
    while (p != nil) {
        if (p.type == STOP) {
            res = p.stop;
        }
        p = p.nextRec;
    }
    return res;
}

-(int)getFirstStopDepart{
    OBRsolvedRouteRecord* p = self;
    while (p != nil) {
        if (p.type == STOP) {
            return p.minOfDayDepart;
        }
        p = p.nextRec;
    }
    return -1;
}

-(int)getLastStopArrive {
    int res = -1;
    OBRsolvedRouteRecord* p = self;
    while (p != nil) {
        if (p.type == STOP) {
            res = p.minOfDayArrive;
        }
        p = p.nextRec;
    }
    return res;
}

-(int)getLatestArrive{
    int latest = -1;
    OBRsolvedRouteRecord* p = self;
    while (p != nil) {
        if (p.minOfDayArrive > latest) {
            latest = p.minOfDayArrive;
        }
        p = p.nextRec;
    }
    return latest;
}

-(int)getLatestTimestamp {
    int latest = -1;
    OBRsolvedRouteRecord* p = self;
    while (p != nil) {
        if (p.minOfDayArrive > latest) {
            latest = p.minOfDayArrive;
        }
        if (p.minOfDayDepart > latest) {
            latest = p.minOfDayDepart;
        }
        
        p = p.nextRec;
    }
    return latest;
}

-(NSString*)getRoutes{
    NSMutableSet* routes = [[NSMutableSet alloc] init];
    OBRsolvedRouteRecord* p = self;
    while (p !=nil) {
        if (p.route != NULL) {
            [routes addObject:p.route];
        }
        p = p.nextRec;
    }
    
    NSString* out = [[NSString alloc] init];
    for (NSString* s in routes) {
        out = [out stringByAppendingString:s];
        out = [out stringByAppendingString:@","];
    }
    return out;
}

-(int)getWaitTime {
    int waittime = 0;
    OBRsolvedRouteRecord* p = self;
    while (p!=nil) {
        if (p.waitMin>0 && p.stop>0 && p.minOfDayArrive>0 && p.minOfDayDepart>0) {
            waittime +=p.waitMin;
        }
        p = p.nextRec;
    }
    return waittime;
}

-(int)getNumStops {
    int d = 0;
    OBRsolvedRouteRecord* p = self;
    while (p != nil) {
        if (p.type == STOP) d ++;
        p = p.nextRec;
    }
    return d;
}

-(int)getWalkedDistance {
    int d = 0;
    OBRsolvedRouteRecord* p = self;
    while (p != nil) {
        if (p.walk != -1) d += p.walk;
        p = p.nextRec;
    }
    return d;
}


-(OBRsolvedRouteRecord*)deepCopy:(OBRsolvedRouteRecord*) orig {
    OBRsolvedRouteRecord* copy = [[OBRsolvedRouteRecord alloc] init];
    copy.stop = orig.stop;
    copy.walk = orig.walk;
    copy.minOfDayArrive = orig.minOfDayArrive;
    copy.minOfDayDepart = orig.minOfDayDepart;
    copy.day = orig.day;
    copy.waitMin = orig.waitMin;
    copy.busNum = orig.busNum;
    copy.distanceMeters = orig.distanceMeters;
    copy.route = [orig.route copy];
    copy.location = [orig.location copy];
    copy.direction = [orig.direction copy];
    copy.headsign = [orig.headsign copy];
    copy.summaryDes = [orig.summaryDes copy];
    copy.trip = [orig.trip copy];
    copy.type = orig.type;
    copy.adherence = orig.adherence;
    copy.lat = orig.lat;
    copy.lon = orig.lon;
    copy.lastUpdateSec = orig.lastUpdateSec;
    copy.orientation = orig.orientation;
    copy.transition = orig.transition;
    copy.completeMin = orig.completeMin;
    copy.initationMin = orig.initationMin;
    
    copy.summaryFirstStop = orig.summaryFirstStop;
    copy.summaryLastStop= orig.summaryLastStop;
    copy.summaryFirstStopDepart= orig.summaryFirstStopDepart;
    copy.summaryEarliestTimestamp= orig.summaryEarliestTimestamp;
    copy.summaryEarliestDepart= orig.summaryEarliestDepart;
    copy.summaryLastStopArrive= orig.summaryLastStopArrive;
    copy.summaryLatestArrive= orig.summaryLatestArrive;
    copy.summaryLatestTimestamp= orig.summaryLatestTimestamp;
    copy.summaryWalkedDistance = orig.summaryWalkedDistance;
    copy.summaryFirstTrip = [orig.summaryFirstTrip copy];
    copy.summaryLastTrip = [orig.summaryLastTrip copy];
    copy.summaryRouteType = orig.summaryRouteType;
    copy.summaryWaitMin = orig.summaryWaitMin;
    copy.GPS = orig.GPS;
    
    if (orig.nextRec != nil) {
        copy.nextRec = [self deepCopy:orig.nextRec];
    }
    return copy;
    
    
}

//convert from a linked list to an array of records
-(NSArray*) convertToArray:(OBRsolvedRouteRecord *)r {
    NSMutableArray* arr = [[NSMutableArray alloc] init];
    OBRsolvedRouteRecord* p = [r deepCopy:r];
    while (p.nextRec != nil) {
        [arr addObject:p];
        p = p.nextRec;
    }
    [arr addObject:p];
    return arr;
}

//convert from a linked list to an array of records each one will have a time stamp
//preceeding and after
-(NSArray*) convertToArrayWithTime:(OBRsolvedRouteRecord *)or {
    
    
    //get the array of objects
    NSArray* arr = [self convertToArray:or];
    
    //add the time stamps
    NSMutableArray* arrT = [[NSMutableArray alloc] init];
    for (int p1=0 ; p1<arr.count ; p1++) {
        OBRsolvedRouteRecord* r = arr[p1];
        int timeArrive = r.minOfDayArrive;
        int timeDepart = r.minOfDayDepart;
        OBRsolvedRouteRecord* s  = [[OBRsolvedRouteRecord alloc] initTimeArrive:timeArrive timeDepart:timeDepart];
        r.nextRec = nil;
        [arrT addObject:s];
        [arrT addObject:r];
    }
    
    //add one final time stamp after the last object
    //this should have two of the departs because it is the last timestamp
    OBRsolvedRouteRecord* r = [arr lastObject];
    int timeArrive = r.minOfDayDepart;
    int timeDepart = r.minOfDayDepart;
    OBRsolvedRouteRecord* s  = [[OBRsolvedRouteRecord alloc] initTimeArrive:timeArrive timeDepart:timeDepart];
    [arrT addObject:s];
    
    return arrT;
}


//recalculates the summary information for each route
-(void)refreshSummary:(OBRsolvedRouteRecord *)r {
    
    int firstStop = -1;
    int lastStop = -1;
    int firstStopDepart = -1;
    int earliestTimestamp = 32000;
    int earliestDepart = 32000;
    int lastStopArrive = -1;
    int latestArrive = -1;
    int latestTimestamp = -1;
    int walkedDistance = 0;
    int waitMin = 0;
    NSString* firstTrip;
    NSString* lastTrip;
    
    
    OBRsolvedRouteRecord* p = self;
    while (p != nil) {
        if (p.walk != -1) walkedDistance += p.walk;
        if (p.type == STOP) {
            if (firstStop == -1 ) firstStop = p.stop;
            if (firstStopDepart == -1) firstStopDepart = p.minOfDayDepart;
            lastStop = p.stop;
            lastStopArrive = p.minOfDayArrive;
            waitMin += p.waitMin;
        }
        if (p.isRoute) {
            if (firstTrip==nil) firstTrip = p.trip;
            lastTrip = p.trip;
        }
        
        if (p.minOfDayDepart <earliestTimestamp && p.minOfDayDepart != -1) {
            earliestTimestamp = p.minOfDayDepart;
        }
        if (p.minOfDayArrive <earliestTimestamp && p.minOfDayArrive != -1) {
            earliestTimestamp = p.minOfDayArrive;
        }
        if (p.minOfDayDepart <earliestDepart && p.minOfDayDepart != -1) {
            earliestDepart = p.minOfDayDepart;
        }
        if (p.minOfDayArrive > latestArrive) {
            latestArrive = p.minOfDayArrive;
        }
        if (p.minOfDayArrive > latestTimestamp) {
            latestTimestamp = p.minOfDayArrive;
        }
        if (p.minOfDayDepart > latestTimestamp) {
            latestTimestamp = p.minOfDayDepart;
        }
        
        p = p.nextRec;
    }
    
    r.summaryFirstStop = firstStop;
    r.summaryLastStop = lastStop;
    r.summaryFirstStopDepart = firstStopDepart;
    r.summaryEarliestTimestamp = earliestTimestamp;
    r.summaryEarliestDepart = earliestDepart;
    r.summaryLastStopArrive = lastStopArrive;
    r.summaryLatestArrive = latestArrive;
    r.summaryLatestTimestamp = latestTimestamp;
    r.summaryWalkedDistance = walkedDistance;
    r.summaryFirstTrip = [firstTrip copy];
    r.summaryLastTrip = [lastTrip copy];
    r.summaryWaitMin = waitMin;

}

-(bool)isRoute {
    OBRsolvedRouteRecord* p = self;
    if (p.type == ROUTE) {
        return true;
    }
    return false;
}

-(bool)isStop {
    OBRsolvedRouteRecord* p = self;
    if (p.type == STOP) {
        return true;
    }
    return false;
}

-(bool)isWalk {
    OBRsolvedRouteRecord* p = self;
    if (p.type == WALK) {
        return true;
    }
    return false;
}




 @end