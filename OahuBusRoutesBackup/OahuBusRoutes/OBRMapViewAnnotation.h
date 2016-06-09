//
//  OBRMapViewAnnotation.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/7/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface OBRMapViewAnnotation : NSObject <MKAnnotation>
@property (nonatomic,copy) NSString* title;
@property (nonatomic,copy) NSString* subtitle;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) MKPinAnnotationColor pinColor;
@property (nonatomic,copy) NSString* type;
@property (nonatomic) float orientation;
@property (nonatomic) NSTimeInterval lastUpdateTime;
@property (nonatomic) UIColor* color;
@property (nonatomic) float alpha;
@property (nonatomic) long IDi;
@property (nonatomic) double IDd;
@property (nonatomic) NSString* IDs;
@property (nonatomic) NSMutableDictionary* IDdict;



-(id)initWithTitle:(NSString*)ttl andCoordinate:(CLLocationCoordinate2D)c2d;
-(id)initWithTitle:(NSString*)ttl andCoordinate:(CLLocationCoordinate2D)c2d andSubtitle:(NSString*)st;
-(id)initWithTitle:(NSString*)ttl andCoordinate:(CLLocationCoordinate2D)c2d andSubtitle:(NSString*)st Type:(NSString*)ty;
-(id)initWithCoordinate:(CLLocationCoordinate2D)coord;
-(CLLocationCoordinate2D)coord;
-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;
-(void)setTitle:(NSString *)title;
@end
