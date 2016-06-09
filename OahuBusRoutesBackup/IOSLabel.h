//
//  IOSLabel.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/3/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "IOSImage.h"
#import <Foundation/Foundation.h>

@interface IOSLabel : NSObject

@property (nonatomic) IOSImage* image;

-(id)init;
-(id)initWithText:(NSArray*)a Color:(UIColor*)c Sizex:(int)x Sizey:(int)y;
-(id)initNoBorderWithText:(NSArray*)a Color:(UIColor*)c Sizex:(int)x Sizey:(int)y ;
@end
