//
//  IOSTimeFunctions.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/19/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "IOSTimeFunctions.h"

@interface IOSTimeFunctions() {
    NSDateFormatter* DF;
    NSTimeZone* TZ;
    

}

@end

@implementation IOSTimeFunctions

-(id) init {
    self = [super init];
    DF = [[NSDateFormatter alloc] init];
    TZ = [NSTimeZone timeZoneWithName:@"HST"];
    return self;
}


-(int)currentWeekday {
    //get the current weekday
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate:[NSDate date]];
    long weekday = [comps weekday];
    return (int) weekday;
}


-(NSTimeInterval)currentTimeSec {
    return [[NSDate date] timeIntervalSinceReferenceDate];
}

-(long)currentMinOfDay {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:[NSDate date]];
    long hour = [comps hour];
    long minute = [comps minute];
    
    return hour*60+minute;
}

-(NSString*)minOfDay2Str:(long)mod {
    mod %= 1440;
    
    long hour = mod/60;
    long min  = mod-(60*hour);
    
    if (hour<1) {
        return [NSString stringWithFormat:@"%ld:%02ld AM",hour+12,min];
    } else if (hour<=11) {
        return [NSString stringWithFormat:@"%ld:%02ld AM",hour,min];
    } else if (hour == 12) {
        return [NSString stringWithFormat:@"%ld:%02ld PM",hour,min];
    } else {
        return [NSString stringWithFormat:@"%ld:%02ld PM",hour-12,min];
    }
}



-(NSString*)localTime:(NSDate*)date{
    //NSDateFormatter* df = [[NSDateFormatter alloc] init];
    //NSTimeZone* tz = [NSTimeZone timeZoneWithName:@"HST"];
    [DF setDateFormat:@"hh:mm:ss a"];
    [DF setTimeZone:TZ];
    NSString* dateStr =[DF stringFromDate:date];
    return dateStr;
}



-(NSString*)localTimeI:(NSTimeInterval)interval{
    NSDate* date = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:interval];
    return [self localTime:date];
}

-(NSString*)localTimehhmmssa:(NSTimeInterval)secs {
    NSDate* date = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:secs];
    //NSTimeZone* tz = [NSTimeZone timeZoneWithName:@"HST"];
    [DF setDateFormat:@"hh:mm:ss a"];
    [DF setTimeZone:TZ];
    NSString* dateStr =[DF stringFromDate:date];
    return dateStr;
}

-(NSString*)nowhhmmssa {
    NSTimeInterval s = [self currentTimeSec];
    return [self localTimeHHmmss:s];
}


-(NSString*)localTimeHHmmss:(NSTimeInterval)secs {
    NSDate* date = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:secs];
    //NSTimeZone* tz = [NSTimeZone timeZoneWithName:@"HST"];
    [DF setDateFormat:@"HH:mm:ss"];
    [DF setTimeZone:TZ];
    NSString* dateStr =[DF stringFromDate:date];
    return dateStr;
}

-(NSString*)nowHHmmss {
    NSTimeInterval s = [self currentTimeSec];
    return [self localTimeHHmmss:s];
}

@end
