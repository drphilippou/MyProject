//
//  OBRBusStop.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/1/13.
//  Copyright (c) 2013 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBRBusStop : NSObject

//fills in all the values for a bus stop
-(id)initWithStopInfo:(NSString *) address
               latVal:(float) latitude
               lonVal:(float) longitude
               altVal:(float) altitude
             refidVal:(int) refid
           coveredVal:(BOOL) covered
          imageKeyVal:(NSString *) imageKey
             routeVal:(int) route;

//throws an exception if no data provided for init
-(id)init;

//adds a route number to the bus stop
-(void)addARouteNumberToBusStop:(OBRBusStop *) bs
                    route:(int) rt;


@property (nonatomic) float latitude;
@property (nonatomic) float longitude;
@property (nonatomic) float altitude;
@property (nonatomic) int refid;
@property (nonatomic) BOOL covered;
@property (nonatomic,strong) NSString *address;
@property (nonatomic,copy) NSString *imageKey;
@property (nonatomic,strong) NSMutableArray *routes;



@end
