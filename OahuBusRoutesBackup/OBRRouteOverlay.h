//
//  OBRRouteOverlay.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/19/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBRRoutePoints.h"
#import "OBRdataStore.h"
#import "OBRoverlayInfo.h"
//#import "OBRPolyline.h"
#import <MapKit/MapKit.h>
#import "palette.h"

@interface OBRRouteOverlay : NSObject
@property (nonatomic) NSDictionary* routeColorDict;
@property (nonatomic) NSMutableArray* overlayInfo;


-(void)addSingleRoute:(NSString*)rs onMap:(MKMapView *)mv;
-(MKOverlayView *)viewForOverlay:(id<MKOverlay>)overlay;
-(void)GenerateLines:(NSArray*)rp onMap:(MKMapView *)mv;
    
@end
