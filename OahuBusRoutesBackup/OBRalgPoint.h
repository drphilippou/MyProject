//
//  OBRalgPoint.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/13/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBRalgPoint : NSObject

@property   (nonatomic) float lat;
@property   (nonatomic) float lon;
@property   (nonatomic) BOOL saved;
@property   (nonatomic) BOOL dropped;
@property   (nonatomic) int index;
@property   (nonatomic) float findex;
@property   (nonatomic) int segment;

-(OBRalgPoint*)createAlgPoint:(float)lat lon:(float)lon;
@end
