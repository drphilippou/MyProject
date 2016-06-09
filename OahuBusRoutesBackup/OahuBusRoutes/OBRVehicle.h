//
//  OBRVehicle.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/6/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface OBRVehicle : NSManagedObject

@property (nonatomic) int32_t adherence;
@property (nonatomic, retain) NSString * direction;
@property (nonatomic) NSTimeInterval lastMessageDate;
@property (nonatomic) float lat;
@property (nonatomic) float lon;
@property (nonatomic) int32_t number;
@property (nonatomic, retain) NSString * numString;
@property (nonatomic) float orientation;
@property (nonatomic, retain) NSString * route;
@property (nonatomic, retain) NSString * trip;
@property (nonatomic ) float speed;

@end
