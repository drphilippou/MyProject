//
//  OBRsolverView.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 3/21/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBRdatastore.h"
#import "palette.h"
#import "IOSLabel.h"
#import "IOSImage.h"
#import "IOSTimeFunctions.h"
#import <QuartzCore/QuartzCore.h>
#import "OBRTrip.h"

typedef enum {
    CURRENT_POS,
    MAP_POINT,
    NONE
} choiceMethod;

@interface OBRsolverView : UIViewController <UIActionSheetDelegate,MKMapViewDelegate>

@end
