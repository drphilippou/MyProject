//
//  OBRoverlayInfo.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 3/20/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRoverlayInfo.h"

@implementation OBRoverlayInfo

-(OBRoverlayInfo*)init {
    self = [super init];
    
    return self;
}

-(NSString*) description {
    NSString* colorstr = @"none";
    if (self.color == [UIColor redColor]) colorstr=@"red";
    if (self.color == [UIColor greenColor]) colorstr=@"green";
    if (self.color == [UIColor blueColor]) colorstr=@"blue";
    if (self.color == [UIColor purpleColor]) colorstr=@"purple";
    if (self.color == [UIColor orangeColor]) colorstr=@"orange";
    
    return [NSString stringWithFormat:@"overlay r:%@ c:%@",self.routestr,colorstr];
}

@end
