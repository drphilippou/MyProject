//
//  OBRFinalProcessingVC.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/15/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "OBRalgPoint.h"
#import "OBRMapViewAnnotation.h"
#import "OBRdataStore.h"
#import "IOSImage.h"
//#import <MKPolylineView.h>



@interface OBRFinalProcessingVC : UIViewController <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextField *routeStr;
@property (nonatomic) NSMutableDictionary* OSMnodes;
@property (nonatomic) NSMutableDictionary* OSMways;
@property (weak, nonatomic) IBOutlet UITextField *Streetfield;
@property (weak, nonatomic) IBOutlet UITextField *segment;


- (IBAction)LoadRoute:(id)sender;
- (IBAction)saveRoute:(id)sender;
- (IBAction)newPolyline:(id)sender;
- (IBAction)addEndPoint:(id)sender;
- (IBAction)addMidPoint:(id)sender;
- (IBAction)GenerateLines;
- (IBAction)addBeginPoint:(id)sender;
- (IBAction)editingEnded:(id)sender;

- (IBAction)LoadNewRoute:(id)sender;
- (IBAction)LoadStops:(id)sender;
- (IBAction)LoadWay:(id)sender;
- (IBAction)RemoveWay:(id)sender;
- (IBAction)RemoveLast:(id)sender;
- (IBAction)DeletePoint:(id)sender;
- (IBAction)SetStop:(id)sender;
- (IBAction)AddPoint:(id)sender;
@end
