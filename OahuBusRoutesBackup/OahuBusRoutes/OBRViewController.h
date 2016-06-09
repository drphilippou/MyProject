//
//  OBRViewController.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/1/13.
//  Copyright (c) 2013 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBRdataStore.h"
#import "palette.h"
#import "IOSimage.h"
#import "IOSLabel.h"
#import "POI.h"
#import "OBRNode.h"
#import "IOSTimefunctions.h"
#import "OBRoverlayInfo.h"
#import "OBRMapViewAnnotation.h"

typedef enum {
    NONE,
    LOCAL,
    SELECTED
} showStopModeEnum;

typedef enum {
    NO_BUS,
    ALL_BUS,
    EB_BUS,
    WB_BUS
} showBusModeEnum;


@interface OBRViewController : UIViewController <MKMapViewDelegate,CLLocationManagerDelegate>


@property (weak, nonatomic) IBOutlet UILabel *textBox;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UIButton *trackButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *showStopsButton;
@property (weak, nonatomic) IBOutlet UIButton *showBusButton;

@property (nonatomic) showStopModeEnum showStopMode;
@property (nonatomic) showStopModeEnum lastShowStopMode;
@property (nonatomic) bool showAllBuses;
@property (nonatomic) bool showSelectedBuses;
@property (nonatomic) bool showSelectedBusLabels;
//@property (nonatomic) bool showSelectedStops;
//@property (nonatomic) bool showLocalStops;
@property (nonatomic,retain) CLLocationManager *locationManager;

@property (nonatomic) showBusModeEnum showBusMode;
@property (nonatomic) showBusModeEnum lastShowBusMode;


- (IBAction)pressedSearch:(id)sender;
- (IBAction)pressedTrack:(id)sender;
- (IBAction)pressedShowBuses:(id)sender;
- (IBAction)pressedShowStops:(id)sender;


@end
