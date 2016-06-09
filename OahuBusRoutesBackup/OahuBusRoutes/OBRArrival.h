//
//  OBRArrival.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/8/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface OBRArrival : NSManagedObject

@property (nonatomic) int32_t stop;
@property (nonatomic) int32_t idNum;
@property (nonatomic) int32_t route;
@property (nonatomic) int32_t vehicle;
@property (nonatomic) int32_t estimated;
@property (nonatomic) int32_t canceled;
@property (nonatomic) float lat;
@property (nonatomic) float lon;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic) NSTimeInterval stoptime;
@property (nonatomic, retain) NSString * trip;
@property (nonatomic, retain) NSString * headsign;
@property (nonatomic, retain) NSString * direction;

@end
