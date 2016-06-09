//
//  OBRscheduleFile.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 8/3/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBRscheduleFile : NSObject


@property (nonatomic) int stop;
@property (nonatomic) int route;
@property (nonatomic) int stopDay;
@property (nonatomic) int stopMin;
@property (nonatomic, copy) NSString * trip;
@property (nonatomic, copy) NSString * headsign;
@property (nonatomic, copy) NSString * direction;
@property (nonatomic, copy) NSString * routestr;


@end
