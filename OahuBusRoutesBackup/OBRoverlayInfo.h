//
//  OBRoverlayInfo.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 3/20/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface OBRoverlayInfo : NSObject

@property (nonatomic,copy) UIColor* color;
@property (nonatomic,copy) NSString* routestr;
@property (nonatomic) MKPolyline* overlay;

@end
