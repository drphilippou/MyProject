//
//  IOSTimeFunctions.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/19/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IOSTimeFunctions : NSObject

-(id)init;

-(NSString*)minOfDay2Str:(long)mod;
-(NSString*)localTime:(NSDate*)date;
-(NSString*)localTimeI:(NSTimeInterval)interval;
-(long)currentMinOfDay;
-(NSTimeInterval)currentTimeSec;

-(int)currentWeekday;

-(NSString*)localTimehhmmssa:(NSTimeInterval)secs;
-(NSString*)localTimeHHmmss:(NSTimeInterval)secs;

-(NSString*)nowhhmmssa;
-(NSString*)nowHHmmss;

@end
