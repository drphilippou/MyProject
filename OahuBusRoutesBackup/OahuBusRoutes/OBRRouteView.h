//
//  OBRRouteView.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/10/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "OBRdataStore.h"
#import "OBRMapViewAnnotation.h"
#import "OBRalgPoint.h"
#import "OBRoverlayInfo.h"
#import "palette.h"
#import "IOSLabel.h"
#import "IOSTimeFunctions.h"



@interface OBRRouteView : UIViewController <MKMapViewDelegate,CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *routeViewMap;
@property (nonatomic,retain) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UIButton *showStopsButton;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UIButton *showBusButton;
@property (weak, nonatomic) IBOutlet UIButton *trackButton;

- (IBAction)pressedShowStops:(id)sender;
- (IBAction)pressedSearch:(id)sender;
- (IBAction)pressedShowBuses:(id)sender;
- (IBAction)pressedTrack:(id)sender;


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;
@end
