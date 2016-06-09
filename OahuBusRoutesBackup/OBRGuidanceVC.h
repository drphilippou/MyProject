//
//  OBRGuidanceVC.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 7/5/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBRdataStore.h"
#import "OBRsolvedRouteRecord.h"
#import "OBRoverlayInfo.h"
#import "OBRRouteOverlay.h"
#import <MapKit/MapKit.h>
#import "IOSLabel.h"
#import "IOSImage.h"
#import "IOSTimeFunctions.h"

@interface OBRGuidanceVC : UIViewController <MKMapViewDelegate,UIAlertViewDelegate>

@end
