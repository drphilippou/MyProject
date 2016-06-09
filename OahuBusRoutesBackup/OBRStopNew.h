//
//  OBRStopNew.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 11/11/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class OBRTrip;

@interface OBRStopNew : NSManagedObject

@property (nonatomic) float lat;
@property (nonatomic) float lon;
@property (nonatomic) int16_t number;
@property (nonatomic, retain) NSString * streets;
@property (nonatomic, retain) NSSet *trips;
@end

@interface OBRStopNew (CoreDataGeneratedAccessors)

-(NSString*)description;

- (void)addTripsObject:(OBRTrip *)value;
- (void)removeTripsObject:(OBRTrip *)value;
- (void)addTrips:(NSSet *)values;
- (void)removeTrips:(NSSet *)values;

@end
