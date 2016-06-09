//
//  OBRBuildDatabaseVC.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 11/8/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "IOSTimeFunctions.h"
#import "OBRTrip.h"
#import "OBRStopNew.h"
#import "POI.h"
#import "OBRNode.h"
#import "OBRScheduleNew.h"
#import <MapKit/MapKit.h>

@interface OBRBuildDatabaseVC : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *textField;
@property (nonatomic,copy) NSString* text;
@property (nonatomic) NSMutableDictionary* tripData;

- (IBAction)pressedStart:(id)sender;
- (IBAction)pressedTest:(id)sender;
@end
