//
//  OBRGuidanceVC.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 7/5/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRGuidanceVC.h"
#import "OBRMapViewAnnotation.h"
//#import <math.h>



@interface OBRGuidanceVC ()
{
    unsigned long numberOfSteps;
    unsigned long currentStep;
    float userLat;
    float userLon;
    //float destLat;
    //float destLon;
    BOOL  userLocationValid;
    BOOL  destLocationValid;
    BOOL  routeOverlayAdded;
    BOOL  mapSizeSet;
    BOOL  advanced;
    BOOL  pressedPrev;
    NSTimer* t1;
    NSTimer* t2;
    NSMutableArray* pointArray;
    NSMutableArray* labelArray;
    NSMutableArray* typeArray;
    NSString* currentBusTitle;
    OBRMapViewAnnotation* currentBusAnnotation;
    OBRRouteOverlay* routeOverlayFunc;
    IOSTimeFunctions* TF;
    IOSImage* IOSI;
    OBRdataStore* db;
}

@property (nonatomic) bool busArrived;
@property (nonatomic) bool alertSent;
@property (weak, nonatomic) IBOutlet UILabel *G1Label;
@property (weak, nonatomic) IBOutlet UILabel *G2Label;
@property (weak, nonatomic) IBOutlet UILabel *G3Label;
@property (weak, nonatomic) IBOutlet UILabel *G4Label;
@property (weak, nonatomic) IBOutlet UILabel *G5Label;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic) OBRsolvedRouteRecord* route;
@property (nonatomic) NSArray* routeArray;
@property (weak, nonatomic) IBOutlet UIButton *prevButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;

- (IBAction)prevPressed:(id)sender;
- (IBAction)nextPressed:(id)sender;

@end

@implementation OBRGuidanceVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    userLat = userLocation.location.coordinate.latitude;
    userLon = userLocation.location.coordinate.longitude;
    userLocationValid = true;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //init local variables
    userLat = 0;
    userLon = 0;
    userLocationValid = false;
    //destLat = 0;
    //destLon = 0;
    destLocationValid = false;
    pointArray = [[NSMutableArray alloc] init];
    labelArray = [[NSMutableArray alloc] init];
    typeArray = [[NSMutableArray alloc] init];
    routeOverlayAdded = false;
    advanced = true;
    pressedPrev = false;
    IOSI = [[IOSImage alloc] init];
    db = [OBRdataStore defaultStore];

    
    //retrive the chosen route in the datastore
    _route = db.chosenRoute;
    
    //create a route overlay class.  This contains all the route overlay functions
    routeOverlayFunc = [[OBRRouteOverlay alloc] init];
    
    //time functions
    TF = [[IOSTimeFunctions alloc] init];
    
    //convert to a route array
    _routeArray = [_route convertToArray:_route];
    numberOfSteps = _routeArray.count;
    currentStep = 0;
    
    //fill the missing data
    [self updateRouteInfo];
    
    //setup the map
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(21.5, -158.0);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(center, 87000, 87000)];
    [self.mapView setCenterCoordinate:center animated:YES];
    [self.mapView setZoomEnabled:YES];
    [self.mapView setRegion:adjustedRegion animated:YES];
    [self.mapView setDelegate:self];
    self.mapView.showsUserLocation = YES;
    
    //start the timers
    t1 = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateDirections) userInfo:nil repeats:YES];
    t2 = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(updateRouteInfo) userInfo:nil repeats:YES];
    
    //run initial update manually
    [self clearMap];
    [self updateDirections];
}


-(void)viewDidDisappear:(BOOL)animated {
    //stop the timers
    NSLog(@"stoping the timers");
    [t1 invalidate];
    [t2 invalidate];
    t1 = nil;
    t2 = nil;
}

-(void)viewWillAppear:(BOOL)animated {
        mapSizeSet = false;
}

-(void)viewDidAppear:(BOOL)animated {
    //stop searching for results if we are guiding
    db.interupt = true;
    
    //start updating the realtime data
    db.updateVehicles = true;
    
    //set the guiding flag to prevent database updates
    db.guiding = true;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    return [routeOverlayFunc viewForOverlay:overlay];
}

-(void)viewWillDisappear:(BOOL)animated {
    //stop updating the real time data
    db.updateVehicles = false;
    
    //clear the guidance flag to allow database updates
    db.guiding = false;
}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"Button 1"])
    {
        NSLog(@"Button 1 was selected.");
    }
}



-(void)addSingleRoute:(NSString*)routestr{
    if (!routeOverlayAdded) {
        [routeOverlayFunc addSingleRoute:routestr onMap:_mapView];
        routeOverlayAdded = true;
    }
}



//updates the lats and lons of stops and routes
//while the stops are static, the vehicles should move
-(void)updateRouteInfo {
    NSLog(@"updating route info");
    
    for (OBRsolvedRouteRecord* r in _routeArray) {
        if (r.type == STOP) {
            OBRStopNew* s = [db getStop:r.stop];
            
            //extract the (Stop) from the street string
            NSRange rb = [s.streets rangeOfString:@"("];
            r.location = [s.streets substringToIndex:rb.location];
            r.lat = s.lat;
            r.lon = s.lon;
        } else if (r.type == ROUTE) {
            OBRVehicle* v = [db getVehicleForTrip:r.trip];
            r.busNum = v.number;
            r.lat = v.lat;
            r.lon = v.lon;
            r.adherence = v.adherence;
            r.lastUpdateSec = v.lastMessageDate;
            r.orientation = v.orientation;
        }
    }
}


//-(float)calculateMeterBetweenUserAndDest {
//    if (userLocationValid && destLocationValid) {
//
//        double dlat = fabs(userLat-destLat);
//        double dlon = fabs(userLon-destLon);
//        float d = 111000*sqrt(dlat*dlat+dlon*dlon);
//        return d;
//    }
//    return 0;
//}

-(void) clearMap {
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    mapSizeSet = false;
    routeOverlayAdded = false;
    
    _statusLabel.hidden = true;
    _statusLabel.alpha = 1;
}

//primary computing function
-(void) updateDirections {
    //get the current min of day
    long cMOD = [TF currentMinOfDay];
    
    //enable or disable the previous button
    if (currentStep==0) {
        _prevButton.enabled = false;
        _nextButton.enabled = true;
    } else if (currentStep >= numberOfSteps-1) {
        _prevButton.enabled = true;
        _nextButton.enabled = false;
    
    } else {
        _prevButton.enabled = true;
        _nextButton.enabled = true;
    }
        
    
    
    
    //get the references to the current steps
    OBRsolvedRouteRecord* cstep = [_routeArray objectAtIndex:currentStep];
    OBRsolvedRouteRecord* nstep = nil;
    if (currentStep < numberOfSteps-1) {
        nstep = [_routeArray objectAtIndex:currentStep+1];
    }
    OBRsolvedRouteRecord* nnstep = nil;
    if (currentStep < numberOfSteps-2) {
        nnstep = [_routeArray objectAtIndex:currentStep+2];
    }
    OBRsolvedRouteRecord* pstep = nil;
    if (currentStep >= 1) {
        pstep = [_routeArray objectAtIndex:currentStep-1];
    }
    
    //erase all the labels
    _G1Label.text = [NSString stringWithFormat:@"Step %lu",currentStep];
    _G2Label.text = @" ";
    _G3Label.text = @" ";
    _G4Label.text = @" ";
    _G5Label.text = @" ";
    _G1Label.backgroundColor = [UIColor whiteColor];
    _G2Label.backgroundColor = [UIColor whiteColor];
    _G3Label.backgroundColor = [UIColor whiteColor];
    _G4Label.backgroundColor = [UIColor whiteColor];
    _G5Label.backgroundColor = [UIColor whiteColor];
    self.mapView.alpha = 1;
    
    if (cstep.isWalk) {
        if (nstep.isStop) {
            
            long nextBusArrivalMOD = nnstep.minOfDayArrive;
            bool nextBusArrived = false;
            if (nnstep.isRoute) {
                nextBusArrivalMOD = nnstep.minOfDayArrive - nnstep.adherence;
                
                //alert if the arrival has already past
                if (cMOD>nextBusArrivalMOD) {
                    nextBusArrived = true;
                    _statusLabel.text = @"DEPARTED";
                    _statusLabel.hidden = false;
                    self.mapView.alpha = 0.2;
                }
            }
            
            //get the distance from user position to the stop
            NSString* dist = @"UNKNOWN";;
            if (userLocationValid) {
                dist = [self meterStrBetweenLat1:nstep.lat Lon1:nstep.lon Lat2:userLat Lon2:userLon];
            }
            
            if (!nextBusArrived) {
                _G1Label.text = [NSString stringWithFormat:@"Walk %@ to Stop %d",dist, nstep.stop];
                _G2Label.text = @"located at";
                _G3Label.text = nstep.location;
                _G4Label.text = [NSString stringWithFormat:@"next bus arrives at %@",[TF minOfDay2Str:nextBusArrivalMOD]];
                _G5Label.text = [NSString stringWithFormat:@"in %ld min",nextBusArrivalMOD-cMOD];
            } else {
                _G1Label.text = [NSString stringWithFormat:@"Walked to Stop #%d", nstep.stop];
                _G2Label.text = @"located at";
                _G3Label.text = nstep.location;
            }
            

            NSString* slabel = [NSString stringWithFormat:@"Stop %d",nstep.stop];
            [self addAnnotation:slabel Subtitle:nstep.location lat:nstep.lat lon:nstep.lon Type:@"stop" Orientation:0];
            [self addAnnotation:slabel Subtitle:nstep.location lat:nstep.lat lon:nstep.lon Type:@"stopLabel" Orientation:0];
            
            //add an annotation for the Starting Point
            [self addAnnotation:@"Starting point" Subtitle:@" " lat:cstep.lat lon:cstep.lon Type:@"gflag" Orientation:0];
            [self addAnnotation:@"START" Subtitle:@"st" lat:cstep.lat lon:cstep.lon Type:@"startLabel" Orientation:0];
            

        } else if (nstep == nil) {
            //walk to the destination
            _G1Label.text = [NSString stringWithFormat:@"Walk %d m to your destination",cstep.walk];
            if (pstep.type == STOP) {
                NSString* slabel = [NSString stringWithFormat:@"Stop %d",pstep.stop];
                [self addAnnotation:slabel Subtitle:pstep.location lat:pstep.lat lon:pstep.lon Type:@"stop" Orientation:0];
                [self addAnnotation:slabel Subtitle:pstep.location lat:pstep.lat lon:pstep.lon Type:@"stopLabel" Orientation:0];
            }
            
            //add an annotation for the destination
            [self addAnnotation:@"Destination" Subtitle:@" " lat:cstep.lat lon:cstep.lon Type:@"rflag" Orientation:0];
            [self addAnnotation:@"Destination" Subtitle:@" " lat:cstep.lat lon:cstep.lon Type:@"destLabel" Orientation:0];
        }
        [self setMapSize];
    }
    
    if (cstep.isStop) {
        if (nstep.isRoute) {
            
            //calculate the bus arrival time
            long bMOD = nstep.minOfDayArrive - nstep.adherence;
            
            float busLat = nstep.lat;
            float busLon = nstep.lon;
            float stopLat = cstep.lat;
            float stopLon = cstep.lon;
            NSString* distStr = [self meterStrBetweenLat1:busLat Lon1:busLon Lat2:stopLat Lon2:stopLon];
            
            //calculate the orientation Angle
            float oa = nstep.orientation;
            
            //update the text labels
            if (bMOD >= cMOD) {
                //bus arriving now or in the future
                _G2Label.text = [NSString stringWithFormat:@"traveling %@ on Rt:%@",nstep.direction,nstep.route];
                _G3Label.text = [NSString stringWithFormat:@"towards %@",nstep.headsign];
                
                if (nstep.busNum !=0) {
                    //RTData is available
                    NSString* ms = [TF minOfDay2Str:bMOD];
                    NSString* adStr = [self adherenceStr:nstep.adherence];
                    _G1Label.text = [NSString stringWithFormat:@"Wait at Stop %d for Bus %d",cstep.stop,nstep.busNum];
                    _G4Label.text = [NSString stringWithFormat:@"the bus was %@ away at %@",distStr,[TF localTimeI:nstep.lastUpdateSec]];
                    _G5Label.text = [NSString stringWithFormat:@"Expected Arrival:%@ (%@)",ms,adStr];
                } else {
                    //no RTData availble
                    _busArrived = false;
                    NSString* ms = [TF minOfDay2Str:nstep.minOfDayArrive];
                    _G1Label.text = [NSString stringWithFormat:@"Wait at Stop %d for the next bus",cstep.stop];
                    _G4Label.text = [NSString stringWithFormat:@"Scheduled Arrival:%@",ms];
                }
            } else {
                //Bus should have already arrived
                _G2Label.text = [NSString stringWithFormat:@"traveling %@ on Rt:%@",nstep.direction,nstep.route];
                _G3Label.text = [NSString stringWithFormat:@"towards %@",nstep.headsign];
                
                if (nstep.busNum !=0) {
                    //RTData available
                    _busArrived = true;
                    NSString* ms = [TF minOfDay2Str:bMOD];
                    NSString* adStr = [self adherenceStr:nstep.adherence];
                    _G1Label.text = [NSString stringWithFormat:@"Waited at Stop %d for Bus %d",cstep.stop,nstep.busNum];
                    _G5Label.text = [NSString stringWithFormat:@"Bus departed at %@ (%@)",ms,adStr];
                } else {
                    //no RTData available
                    
                    //ask the user in a notification if the bus arrived
                    //Create and show an alert view with this error displayed
                    if (!_busArrived && !_alertSent) {
                        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Did the Bus Arrive?"
                                                                     message:@"Bus GPS data is unavailable"
                                                                    delegate:self
                                                           cancelButtonTitle:@"Yes"
                                                           otherButtonTitles:@"Continue Waiting",nil];
                        
                        [av show];
                        _alertSent = true;
                    }

                    
                    
                    NSString* ms = [TF minOfDay2Str:nstep.minOfDayArrive];
                    _G1Label.text = [NSString stringWithFormat:@"Waited at Stop %d for the bus",cstep.stop];
                    _G4Label.text = [NSString stringWithFormat:@"Scheduled departure %@",ms];
                }
            }
            
            //add the overlay
            [self addSingleRoute:nstep.route];
            
            //dim the map and stamp message accross it if departed or arriving
            if (bMOD < cMOD) {
                _statusLabel.text = @"DEPARTED";
                _statusLabel.hidden = false;
                self.mapView.alpha = 0.2;
                
                //automatically forward to next step
                if (!advanced && !pressedPrev){
                    [self nextPressed:nil];
                }
            } else if (bMOD == cMOD) {
                //flash ARRIVING
                if ([_statusLabel   isHidden]) {
                    _statusLabel.text = @"ARRIVING";
                    _statusLabel.hidden = false;
                    _statusLabel.alpha = 0.8;
                } else {
                    _statusLabel.hidden = true;
                }
            }   else {
                advanced = false;
                _statusLabel.hidden = true;
                _mapView.alpha = 1;
            }
            
            //add  bus stop annotation
            NSString* slabel = [NSString stringWithFormat:@"Stop %d",cstep.stop];
            [self addAnnotation:slabel Subtitle:cstep.location lat:cstep.lat lon:cstep.lon Type:@"stop" Orientation:0];
            [self addAnnotation:slabel Subtitle:cstep.location lat:cstep.lat lon:cstep.lon Type:@"stopLabel" Orientation:0];

            //add the chosen bus annotations
            NSString* rlabel = [NSString stringWithFormat:@"Bus %d %@ Rt %@",nstep.busNum,nstep.direction,nstep.route];
            NSString* rtlabel = [TF localTimeI:nstep.lastUpdateSec];
            NSString* adlabel = [self adherenceStr:nstep.adherence];
            NSString* subtitle = [NSString stringWithFormat:@"%@ %@",rtlabel,adlabel];
            currentBusTitle = rlabel;
            
            //chose the icon color
            if (nstep.adherence >= 0) {
                [self addAnnotation:rlabel Subtitle:subtitle lat:nstep.lat lon:nstep.lon Type:@"greenbus" Orientation:oa];
            } else if ( nstep.adherence >= -5) {
                [self addAnnotation:rlabel Subtitle:subtitle lat:nstep.lat lon:nstep.lon Type:@"yellowbus" Orientation:oa];
            } else {
                [self addAnnotation:rlabel Subtitle:subtitle lat:nstep.lat lon:nstep.lon Type:@"redbus" Orientation:oa];
            }
            
            //set the bounds of the map
            [self setMapSize];
            
            //add the other buses on the same route
            [self addOtherBusesOnRoute:nstep.route Direction:nstep.direction BusNum:nstep.busNum];
            
            //add a route overlay
            [self addSingleRoute:nstep.route];
            
        } else if (nstep.isWalk) {
            _G1Label.text = [NSString stringWithFormat:@"Exit the bus at Stop %d",cstep.stop];
            _G2Label.text = [NSString stringWithFormat:@"%@",cstep.location];
            

            NSString* slabel = [NSString stringWithFormat:@"Stop %d",cstep.stop];
            [self addAnnotation:slabel Subtitle:cstep.location lat:cstep.lat lon:cstep.lon Type:@"stop" Orientation:0];
            [self addAnnotation:slabel Subtitle:cstep.location lat:cstep.lat lon:cstep.lon Type:@"stopLabel" Orientation:0];
            
            //start the walking step immediately
            if (pressedPrev) {
                [self prevPressed:self];
            } else {
                [self nextPressed:self];
            }
            
            [self setMapSize];
        }
    }
    
    if (cstep.isRoute  ) {
        if (nstep.isStop) {
            
            //calculate the bus arrival time
            long bat = cstep.minOfDayDepart - cstep.adherence;
            
            float busLat = cstep.lat;
            float busLon = cstep.lon;
            float stopLat = nstep.lat;
            float stopLon = nstep.lon;
            NSString* dist = [self meterStrBetweenLat1:busLat Lon1:busLon Lat2:stopLat Lon2:stopLon];
            
            //calculate the orientation Angle
            float oa = cstep.orientation;
            

            _G1Label.text = [NSString stringWithFormat:@"Ride %@ on Rt %@",cstep.direction,cstep.route];
            _G3Label.text = [NSString stringWithFormat:@"Exit at Stop %d",nstep.stop];
            _G4Label.text = [NSString stringWithFormat:@"At %@",nstep.location];
            if (cstep.busNum !=0) {
                NSString* ms = [TF minOfDay2Str:nstep.minOfDayArrive - cstep.adherence];
                NSString* adStr = [self adherenceStr:cstep.adherence];
                _G2Label.text = [NSString stringWithFormat:@"on Bus #%d for %@",cstep.busNum,dist];
                _G5Label.text = [NSString stringWithFormat:@"Reported Arrival %@ (%@)",ms,adStr];
            } else {
                NSString* ms = [TF minOfDay2Str:nstep.minOfDayArrive];
                _G5Label.text = [NSString stringWithFormat:@"Scheduled Arrival %@",ms];
            }


            //add annotations
            [self addOtherBusesOnRoute:cstep.route Direction:cstep.direction BusNum:cstep.busNum];
            NSString* slabel = [NSString stringWithFormat:@"Stop %d",nstep.stop];
            [self addAnnotation:slabel Subtitle:nstep.location lat:nstep.lat lon:nstep.lon Type:@"stop" Orientation:0];
            [self addAnnotation:slabel Subtitle:nstep.location lat:nstep.lat lon:nstep.lon Type:@"stopLabel" Orientation:0];
            NSString* rlabel = [NSString stringWithFormat:@"Bus %d %@ Rt %@",cstep.busNum,cstep.direction,cstep.route];
            NSString* rtlabel = [TF localTimeI:cstep.lastUpdateSec];
            NSString* adlabel = [self adherenceStr:cstep.adherence];
            NSString* subtitle = [NSString stringWithFormat:@"%@ %@",rtlabel,adlabel];
            currentBusTitle = rlabel;
            if (pstep.type == STOP) {
                slabel = [NSString stringWithFormat:@"Stop %d",pstep.stop];
                [self addAnnotation:slabel Subtitle:pstep.location lat:pstep.lat lon:pstep.lon Type:@"stop" Orientation:0];
                [self addAnnotation:slabel Subtitle:pstep.location lat:pstep.lat lon:pstep.lon Type:@"stopLabel" Orientation:0];
            }
            
            if (cstep.adherence >= 0) {
                [self addAnnotation:rlabel Subtitle:subtitle lat:cstep.lat lon:cstep.lon Type:@"greenbus" Orientation:oa];
            } else if ( cstep.adherence >= -5) {
                [self addAnnotation:rlabel Subtitle:subtitle lat:cstep.lat lon:cstep.lon Type:@"yellowbus" Orientation:oa];
            } else {
                [self addAnnotation:rlabel Subtitle:subtitle lat:cstep.lat lon:cstep.lon Type:@"redbus" Orientation:oa];
            }
            
            //update status tag
            if (bat == cMOD) {
                //flash ARRIVING
                if ([_statusLabel   isHidden]) {
                    _statusLabel.text = @"ARRIVING";
                    _statusLabel.hidden = false;
                    _statusLabel.alpha = 0.8;
                } else {
                    _statusLabel.hidden = true;
                }
                advanced = false;
                
            } else if (bat < cMOD) {
                _statusLabel.text = @"ARRIVED";
                _statusLabel.hidden = false;
                self.mapView.alpha = 0.2;
                if (!advanced && !pressedPrev) {
                    [self nextPressed:self];
                }
            } else {
                advanced = false;
            }
            
            
        }
        
        //add a route overlay
        [self addSingleRoute:cstep.route];
        
    }
    
    //now that the annotations are added set the map size
    [self setMapSize];
}

-(double)metersBetweenLat1:(double)lat1 Lon1:(double)lon1
                      Lat2:(double)lat2 Lon2:(double)lon2 {
    
    if (lat1>20 && lat1<22 && lat2>20 && lat2<22 && lon1>-159 && lon2>-159 && lon1<-157 && lon2<-157) {
        double x = 111122.0*(lat1-lat2);
        double y = 102288.0*(lon1-lon2);
        return sqrt(x*x+y*y);
    } else {
        return 0;
    }
}

-(NSString*)meterStrBetweenLat1:(double)lat1 Lon1:(double)lon1
                           Lat2:(double)lat2 Lon2:(double)lon2 {
    
    if (lat1>20 && lat1<22 && lat2>20 && lat2<22 && lon1>-159 && lon2>-159 && lon1<-157 && lon2<-157) {
        double x = 111122.0*(lat1-lat2);
        double y = 102288.0*(lon1-lon2);
        double d = sqrt(x*x+y*y);
        if (d>1000) {
            return [NSString stringWithFormat:@"%4.1f Km",d/1000];
        } else {
            return [NSString stringWithFormat:@"%4.1f m",d];
        }
        
    } else {
        return @"UNKNOWN";
    }
}



-(NSMutableAttributedString*)adherenceStr:(long)a label:(UILabel*)l{
    UIColor* black = [UIColor blackColor];
    UIColor* red = [UIColor redColor];
    UIColor* green = [UIColor greenColor];
    NSDictionary *attribs = @{
                              NSForegroundColorAttributeName:l.textColor,
                              NSFontAttributeName:l.font
                              };
    if (a==0) {
        NSString* s = @"On Time";
        NSMutableAttributedString *at = [[NSMutableAttributedString alloc] initWithString:s
                                                                               attributes:attribs];
        [at setAttributes:@{NSForegroundColorAttributeName:black} range:NSMakeRange(0, s.length)];
        return at;
        
    } else if (a<0) {
        NSString* s = [NSString stringWithFormat:@"%ldmin Late",-a];
        NSMutableAttributedString *at = [[NSMutableAttributedString alloc] initWithString:s
                                                                               attributes:attribs];
        [at setAttributes:@{NSForegroundColorAttributeName:red} range:NSMakeRange(0, s.length)];
        return at;
        
    } else {
        NSString* s = [NSString stringWithFormat:@"%ldmin Early",a];
        NSMutableAttributedString *at = [[NSMutableAttributedString alloc] initWithString:s
                                                                                                                                                  attributes:attribs];
        [at setAttributes:@{NSForegroundColorAttributeName:green} range:NSMakeRange(0, s.length)];
        return at;
        
    }
}

-(NSString*)adherenceStr:(long)a {
    if (a==0) {
        return @"On Time";
    } else if (a<0) {
        return [NSString stringWithFormat:@"%ldmin Late",-a];
    } else {
        return [NSString stringWithFormat:@"%ldmin Early",a];
    }
}

-(void)setMapSize {
    //skip if the map size is already set
    if (mapSizeSet) return;
    
    //calculate the bounds for user positions and any buses that match the currentbustitle
    float maxLat = 0;
    float minLat = 180;
    float maxLon = -999;
    float minLon = 0;
    for (id<MKAnnotation> a in self.mapView.annotations) {
        BOOL userPosition = false;
        BOOL currentBusPosition = false;
        BOOL isStop = false;
        BOOL isFlag = false;
        if ([a isKindOfClass:[MKUserLocation class]]) {
            userPosition = true;
        } else {
            OBRMapViewAnnotation* mva = a;
            if ([a.title isEqualToString:currentBusTitle]) currentBusPosition = true;
            if ([mva.type isEqualToString:@"stop"]) isStop = true;
            if ([mva.type isEqualToString:@"destLabel"]) isFlag = true;
            if ([mva.type isEqualToString:@"startLabel"]) isFlag = true;
        }
        
        //do not let user position set the map size
        //if (userPosition || currentBusPosition || isStop) {
        if (currentBusPosition || isStop || isFlag) {
            if (a.coordinate.latitude > maxLat) maxLat = a.coordinate.latitude;
            if (a.coordinate.latitude < minLat) minLat = a.coordinate.latitude;
            if (a.coordinate.longitude > maxLon) maxLon = a.coordinate.longitude;
            if (a.coordinate.longitude < minLon) minLon = a.coordinate.longitude;
        }
    }
    
    float dlat = maxLat - minLat;
    float dlon = maxLon - minLon;
    float alat = (maxLat+minLat)/2.0;
    float alon = (maxLon+minLon)/2.0;
    
    
    //set range when only a single point
    if (dlat <= 0) dlat = 0.01;
    if (dlon <= 0) dlon = 0.01;
    
    //check alat and alon
    if (alat>20 && alat<22 && alon>-159 && alon<-157) {
        
        //convert to meters
        float dlatm = dlat*111000*2;
        float dlonm = dlon*111000*2;
        
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(alat, alon);
        MKCoordinateRegion region = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(center, dlatm, dlonm)];
        [self.mapView setCenterCoordinate:center animated:YES];
        [self.mapView setRegion:region animated:YES];
        mapSizeSet = true;
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)addOtherBusesOnRoute:(NSString*)routeStr Direction:(NSString*)dirStr BusNum:(long)bn {
    
    OBRdataStore* db = [OBRdataStore defaultStore];
    NSTimeInterval nowSec = [db currentTimeSec];
    
    NSArray* vehicles = [db vehicles];
    for (OBRVehicle* v in vehicles) {
        if ([routeStr isEqualToString:v.route]) {
            if ([dirStr isEqualToString:v.direction]) {
                if (bn != v.number) {
                    
                    //limit the buses to those with updates within a half hour
                    float elapsedHours = (nowSec - v.lastMessageDate)/3600;
                    if ((elapsedHours <0.5)) {
                        
                        
                        //create the title string
                        NSString* rlabel = [NSString stringWithFormat:@"Bus %d %@ Rt %@",v.number,v.direction,v.route];
                        
                        //remove the old annotations for this other bus
                        NSMutableArray* toDelete = [[NSMutableArray alloc] init];
                        for (OBRMapViewAnnotation* a in self.mapView.annotations) {
                            if (![a isKindOfClass:[MKUserLocation class]]) {
                                bool isStop = [a.type isEqualToString:@"stop"];
                                bool isStopLabel = [a.type isEqualToString:@"stopLabel"];
                                if (!isStop && !isStopLabel) {
                                    //erase any old annotations
                                    if ((nowSec-a.lastUpdateTime)>600) {
                                        if (![a.title isEqualToString:currentBusTitle]) {
                                            [toDelete addObject:a];
                                        }
                                    }
                                    
                                    //erase any old other buses
                                    if ([a.title isEqualToString:rlabel]) {
                                        if (a.coordinate.latitude != v.lat) {
                                            if (a.coordinate.longitude != v.lon) {
                                                [toDelete addObject:a];
                                            }
                                        }
                                    }
                                }
                            }
                            
                        }
                        [self.mapView removeAnnotations:toDelete];
                        
                        
                        NSString* rtlabel = [TF localTimeI:v.lastMessageDate];
                        NSString* adlabel = [self adherenceStr:v.adherence];
                        NSString* subtitle = [NSString stringWithFormat:@"%@ %@",rtlabel,adlabel];
                        
                        
                        if (v.adherence >= 0) {
                            [self addAnnotation:rlabel Subtitle:subtitle lat:v.lat lon:v.lon Type:@"greenbus" Orientation:v.orientation];
                        } else if (v.adherence >= -5) {
                            [self addAnnotation:rlabel Subtitle:subtitle lat:v.lat lon:v.lon Type:@"yellowbus" Orientation:v.orientation];
                        } else {
                            [self addAnnotation:rlabel Subtitle:subtitle lat:v.lat lon:v.lon Type:@"redbus" Orientation:v.orientation];
                        }
                    }
                }
            }
        }
    }
}

-(void)addAnnotation:(NSString*)title Subtitle:(NSString*)st lat:(float)lat lon:(float) lon Type:(NSString*)t Orientation:(float)o{
    
    //check for annotations outside of hawaii
    if (lat<20 || lat>22 || lon < -159 || lon> -157) {
        return;
    }
    
    // Set some coordinates for our position
    CLLocationCoordinate2D location;
    location.latitude = (double) lat;
    location.longitude = (double) lon;
    
    //Create a new annotation
    OBRMapViewAnnotation *na = [[OBRMapViewAnnotation alloc] initWithTitle:title
                                                             andCoordinate:location
                                                               andSubtitle:st
                                                                      Type:t];
    //check to see if this annotation already exists
    for (id<MKAnnotation> a in self.mapView.annotations) {
        if (![a isKindOfClass:[MKUserLocation class]]) {
            OBRMapViewAnnotation* mva = a;
            //float d = [self metersBetweenLat1:mva.coordinate.latitude Lon1:mva.coordinate.longitude Lat2:lat Lon2:lon];
            if (mva.coordinate.latitude == lat &&
                mva.coordinate.longitude == lon &&
                [mva.type isEqualToString:t]) {
                    return;
            }
        }
    }
    
    //set the annotations properties
    na.orientation = o;
    
    [self.mapView addAnnotation:na];
    
    //check if the new annotation is for the current bus
    if ([title isEqualToString:currentBusTitle]) {
        currentBusAnnotation = na;
        [self.mapView selectAnnotation:na animated:true];
    }
}

-(void)dimOldIconsForBusTitled:(NSString*)title {
    //set the last bus to faded out
    for (OBRMapViewAnnotation* a in self.mapView.annotations) {
        BOOL isUserPos = [a isKindOfClass:[MKUserLocation class]];
        if (!isUserPos) {
            if (a != currentBusAnnotation) {
                if ([a.type isEqualToString:@"greenbus"] || [a.type isEqualToString:@"redbus"] || [a.type isEqualToString:@"yellowbus"]) {
                    MKAnnotationView* lv = [self.mapView viewForAnnotation:a];
                    if ([a.title isEqualToString:title]) {
                        lv.alpha = 0.5;
                    }
                }
            }
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {

    //check for a user position
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    //get the type
    OBRMapViewAnnotation* myAnn = annotation;
    
    if ([myAnn.type isEqualToString:@"stop"]) {
        MKAnnotationView *annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"busStop"];
        annView.image = [IOSI imageWithFilename:@"BusStopSign.png" Size:40];
        annView.canShowCallout = YES;
        annView.layer.zPosition = 1999;
        return annView;
    } else if ([myAnn.type isEqualToString:@"greenbus"] || [myAnn.type isEqualToString:@"yellowbus"] || [myAnn.type isEqualToString:@"redbus"]) {
        //dim the past icons on the current route
        [self dimOldIconsForBusTitled:currentBusTitle];
        
        //return if the orientation is unknown
        if (myAnn.orientation ==0 ) return nil;
        
        //label the annotation with the current time added
        myAnn.lastUpdateTime = [[OBRdataStore defaultStore] currentTimeSec];
        
        //compute the orientation angle
        float angleDegrees = myAnn.orientation*180.0/3.14159;
        if (angleDegrees>180) angleDegrees -= 180;
        if (angleDegrees<-180) angleDegrees += 180;
        
        MKAnnotationView *annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"bus"];
        UIColor* busColor = BLUE;
        if ([myAnn.type isEqualToString:@"redbus"]) busColor = RED;
        if ([myAnn.type isEqualToString:@"greenbus"]) busColor = GREEN;
        if ([myAnn.type isEqualToString:@"yellowbus"]) busColor = YELLOW;
        annView.image = [IOSI imageWithFilename:@"bwarrow.png" Color:busColor Size:35 Orientation:-angleDegrees Cache:false];
        annView.canShowCallout = YES;
        annView.layer.zPosition = 2000;
        return annView;
        
    } else if ([myAnn.type isEqualToString:@"rflag"]) {
        //label the annotation with the current time added
        myAnn.lastUpdateTime = [[OBRdataStore defaultStore] currentTimeSec];
        MKAnnotationView *annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"rflag"];
        annView.image = [IOSI imageWithFilename:@"HollowFlag.png" Color:RED Size:35];
        annView.centerOffset = CGPointMake(14, -15);
        annView.layer.zPosition = 2001;
        return annView;
        
    } else if ([myAnn.type isEqualToString:@"gflag"]) {
        //label the annotation with the current time added
        myAnn.lastUpdateTime = [TF currentTimeSec];
        MKAnnotationView *annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"gflag"];
        annView.image = [IOSI imageWithFilename:@"HollowFlag.png" Color:GREEN Size:35];
        annView.centerOffset = CGPointMake(14, -15);
        annView.layer.zPosition = 2002;
        return annView;
        
    } else if ([myAnn.type isEqualToString:@"startLabel"]) {
        MKAnnotationView *annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"startLabel"];
        IOSLabel* label = [[IOSLabel alloc]initNoBorderWithText:@[myAnn.title] Color:GREEN Sizex:-1 Sizey:30];
        annView.image = label.image.image;
        annView.alpha = 0.9;
        annView.centerOffset = CGPointMake(14,-48);
        return annView;
        
    } else if ([myAnn.type isEqualToString:@"destLabel"]) {
        MKAnnotationView *annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"destLabel"];
        IOSLabel* label = [[IOSLabel alloc] initNoBorderWithText:@[myAnn.title] Color:RED Sizex:-1 Sizey:30];
        annView.image = label.image.image;
        annView.alpha = 0.9;
        annView.centerOffset = CGPointMake(14,-48);
        return annView;
        
    } else if ([myAnn.type isEqualToString:@"stopLabel"]) {
        MKAnnotationView *annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"stopLabel"];
        annView.image = [[[IOSLabel alloc] initNoBorderWithText:@[myAnn.title,myAnn.subtitle] Color:YELLOW Sizex:-1 Sizey:40].image getImage];
        annView.alpha = 0.85;
        annView.centerOffset = CGPointMake(0,-35);
        return annView;
    }
    
    return nil;
}





- (IBAction)prevPressed:(id)sender {
    _alertSent = false;
    pressedPrev = true;
    NSLog(@"prev pressed");
    if (currentStep>0) currentStep--;
    [self clearMap];
    [self updateDirections];
}

- (IBAction)nextPressed:(id)sender {
    _alertSent = false;
    NSLog(@"next pressed");
    advanced = true;
    pressedPrev = false;
    if (currentStep <numberOfSteps-1) currentStep++;
    [self clearMap];
    [self updateDirections];
}
@end
