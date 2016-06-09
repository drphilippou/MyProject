//
//  OBRRoutePoints.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/10/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface OBRRoutePoints : NSManagedObject

@property (nonatomic) int32_t route;
@property (nonatomic) int32_t order;
@property (nonatomic) int32_t segment;
@property (nonatomic) float lat;
@property (nonatomic) float lon;
@property (nonatomic, retain) NSString * routestr;
@property (nonatomic) int32_t distance;

@end
