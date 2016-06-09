//
//  OBRdataStore.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/5/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>
#import "OBRVehicle.h"
#import "OBRArrival.h"
#import "OBRRoutePoints.h"
#import "OBRsolvedRouteRecord.h"
#import "IOSimage.h"
#import "OBRScheduleNew.h"
#import "OBRStopNew.h"
#import "OBRTrip.h"

@interface OBRdataStore : NSObject <UIAlertViewDelegate>

//database cache
@property (nonatomic) NSMutableArray* vehicles;
@property (nonatomic) NSMutableArray* stops;
@property (nonatomic) NSMutableArray* trips;
@property (nonatomic) NSMutableArray* routes;
@property (nonatomic) NSMutableArray* pois;


@property (nonatomic) NSMutableDictionary* stopsDict;
@property (nonatomic) NSMutableArray* vehiclesInMotion;
@property (nonatomic) NSMutableArray* stopRouteDict;
@property (nonatomic) NSMutableDictionary* routeStopDict;
@property (nonatomic) NSMutableDictionary* jointStops;
@property (nonatomic) NSMutableDictionary* routeWalkRoute;
@property (nonatomic) NSMutableDictionary* routeRouteRoute;
@property (nonatomic) NSTimeInterval currentTimeSec;
@property (nonatomic) long currentMinOfDay;
@property (nonatomic) long departureMin;
@property (nonatomic) long arrivalMin;
@property (nonatomic) long arrivalDay;
@property (nonatomic) int maxWalkingDistance;
@property (nonatomic) float minWalkingDistanceStart;
@property (nonatomic) float minWalkingDistanceEnd;
@property (nonatomic) int maxWaitMin;
@property (nonatomic) OBRsolvedRouteRecord* chosenRoute;
@property (nonatomic) MKCoordinateRegion mapRegion;
@property (nonatomic) int busy;  //when >0 is on
@property (nonatomic) int data;  //when >0 is on
@property (nonatomic) IOSImage* IOSI;

//search parameters
@property (nonatomic,copy) NSString* searchSelection;

//memory cache
@property (nonatomic) NSMutableDictionary* cache;

//state of the solver available to the other views
@property (nonatomic,copy) NSString* solvingLabelText;
@property (nonatomic) long solvingNumRoutesConsidered;
@property (nonatomic) long solvingNumRoutesFound;
@property (nonatomic) int  solvingEarliestArrival;
@property (nonatomic) int  solvingShortestTripDuration;
@property (nonatomic) BOOL forwardToSolving;
@property (nonatomic) BOOL forwardToList;
@property (nonatomic) BOOL routeListViewed;

//update functions
@property (nonatomic) BOOL downloadingUpdate;

//vehicle update
@property (nonatomic) BOOL updateVehicles;
@property (nonatomic) NSTimeInterval updateVehicleTime;
@property (nonatomic) BOOL vehiclesModified;
@property (nonatomic) BOOL fullUpdate;
@property (nonatomic,copy) NSString* lastVehicleEtag;
-(void)setVehicleTimer:(float) interval;


+(OBRdataStore *)defaultStore;

-(void)clearCache;

// database interface
-(BOOL)loadDatabase;
-(BOOL)saveDatabase;
-(void)deleteObject:(NSManagedObject*) ob;


//access vehicles
-(OBRVehicle*)createVehicle:(NSString *)numStr;
-(OBRVehicle*)findVehicle:(int) num;
-(OBRVehicle*)getVehicle:(NSString*)numStr;
-(OBRVehicle*)getVehicleForTrip:(NSString*)trip;


//access trip info
-(OBRTrip*)getTrip:(NSString*)tripStr;
-(NSArray*)getTripsForRoute:(NSString*)routeStr;
-(int)checkRouteForRealTimeInfo:(OBRsolvedRouteRecord*)r;

//overlays
-(NSArray*)getPointsForRoute:(int)route;
-(NSArray*)getPointsForRouteStr:(NSString*)route;
-(NSArray*)getPointsForRegion:(MKCoordinateRegion)r;


//solver
@property (nonatomic) NSMutableArray* solvedRoutes;
@property (nonatomic) NSTimeInterval solverTimeSetSec;
@property (nonatomic) BOOL solvedRoutesModified;
@property (nonatomic) BOOL solving;
@property (nonatomic) BOOL interupt;
-(NSArray*)getJointStopsOnRoute1:(NSString*)r1 Route2:(NSString*)r2;
-(NSArray*)getRouteWalkRoute1:(NSString*)r1 Route2:(NSString*)r2;
-(NSArray*)getRouteRouteRoute1:(NSString*)r1 Route2:(NSString*)r2;
-(long)addSolvedRoutes:(OBRsolvedRouteRecord*)rec;
-(void)eraseSolvedRoutes;
-(void)sortSolvedRoutesByDuration;
-(void)sortSolvedRoutesByArrival;
-(void)sortSolvedRoutesByDeparture;

//guidance
@property (nonatomic) bool guiding;


//stops
-(NSArray*)getStops;
-(OBRStopNew*)getStop:(int)stop;
-(NSArray*)getRoutesForStop:(int)stop;
-(NSArray*)getStopsForRoutestr:(NSString*)r;
-(BOOL)isStop:(long)stop onRouteStr:(NSString*)r;


//schedules
-(NSArray*)getCompleteSch;
-(NSArray*)getSchForTrip:(NSString*)trip;
-(NSArray*)getSchForTrip:(NSString*)trip OnDay:(int)day;
-(NSArray*)getSchForRoutestr:(NSString*)r Stop:(long)s Day:(long)d Min:(long)m Thread:(BOOL)t;
-(NSArray*)getNewSchForRoutestr:(NSString*)r Stop:(long)s Day:(long)d eMin:(long)em lMin:(long)lm Thread:(BOOL)t;
-(NSArray*)getSchForStop:(int) stop;


//icon interface
-(void)setDataRxButton:(UIImageView*)in;
-(UIImageView*)getDataRxButton;
-(void)setActivityIndicator:(UIActivityIndicatorView*)in;
-(UIActivityIndicatorView*)getActivityInd;
-(void)setNumSolsIcon:(UIImageView *)numSolsIcon;
-(UIImageView*)getNumSolsIcon;
-(void)updateNumSolIcon:(long)num Color:(UIColor*)c  Alpha:(float)a;


@end
