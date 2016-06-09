//
//  OBRScheduleNew.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 11/9/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class OBRStopNew, OBRTrip;

@interface OBRScheduleNew : NSManagedObject

@property (nonatomic) int16_t day;
@property (nonatomic) int16_t minOfDay;
@property (nonatomic, retain) OBRStopNew *stop;
@property (nonatomic, retain) OBRTrip *trip;

-(NSString*)description;

@end
