//
//  OBRarrivalRecord.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/5/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBRarrivalRecord : NSObject
{
    int stop;
    int IDnum;
    int route;
    int vehicle;
    int estimated;
    int canceled;
    float lat;
    float lon;
    NSDate* timestamp;
    NSDate* stopTime;
    NSString* trip;
    NSString* headsign;
    NSString* direction;
}

@property(nonatomic,readwrite) int stop;
@property(nonatomic,readwrite) int IDnum;
@property(nonatomic,readwrite) int route;
@property(nonatomic,readwrite) int vehicle;
@property(nonatomic,readwrite) int estimated;
@property(nonatomic,readwrite) int canceled;
@property(nonatomic,readwrite) float lat;
@property(nonatomic,readwrite) float lon;
@property(nonatomic,readwrite,copy) NSDate* timestamp;
@property(nonatomic,readwrite,copy) NSDate* stopTime;
@property(nonatomic,readwrite,copy) NSString* trip;
@property(nonatomic,readwrite,copy) NSString* headsign;
@property(nonatomic,readwrite,copy) NSString* direction;



@end
