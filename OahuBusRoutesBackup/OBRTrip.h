//
//  OBRTrip.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 11/11/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class OBRStopNew;

@interface OBRTrip : NSManagedObject

@property (nonatomic, retain) NSString * day;
@property (nonatomic, retain) NSString * direction;
@property (nonatomic) int16_t earliestTS;
@property (nonatomic, retain) NSString * headsign;
@property (nonatomic) int16_t latestTS;
@property (nonatomic, retain) NSString * route;
@property (nonatomic) int16_t tripNum;
@property (nonatomic, retain) NSString * tripStr;
@property (nonatomic, retain) NSSet *stops;
@end

@interface OBRTrip (CoreDataGeneratedAccessors)


-(NSString*)description;

- (void)addStopsObject:(OBRStopNew *)value;
- (void)removeStopsObject:(OBRStopNew *)value;
- (void)addStops:(NSSet *)values;
- (void)removeStops:(NSSet *)values;

@end
