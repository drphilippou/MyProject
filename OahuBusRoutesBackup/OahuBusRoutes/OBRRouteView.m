//
//  OBRRouteView.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/10/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRRouteView.h"


@interface OBRRouteView ()
{
    OBRStopNew* selectedStop;
    id<MKAnnotation> selectedAnnotation;
    NSArray* stops;
    NSMutableArray* routeStops;
    NSTimer* overlayTimer;
    NSTimer* updateBusTimer;
    NSString* hideStopStr;
    BOOL stopsVisible;
    BOOL showBuses;
    NSArray* routePts;
    IOSImage* IOSI;
    IOSTimeFunctions* TF;
    OBRdataStore* db;
}

@property (nonatomic) NSArray* currentRoute;
@property (nonatomic) NSMutableSet* allRoutes;      //all the routes in the window
@property (nonatomic) NSMutableSet* selectedRoutes; //last tapped routes
@property (nonatomic) NSMutableArray* overlayQueue;
@property (nonatomic) NSMutableArray* overlayInfo;
@property (nonatomic) NSDictionary* routeColorDict;
@property (weak, nonatomic) IBOutlet UILabel *instructionLabel;



@end



@implementation OBRRouteView



#pragma mark - Declaration

-(NSDictionary*) routeColorDict {
    if (_routeColorDict == nil) {
        _routeColorDict = @{@"C":PURPLE,
                            @"A":CRANBERRY,
                            @"PH6":GREEN,
                            @"1":LIME,
                            @"1L":CYAN,
                            @"4":CRANBERRY,
                            @"5":BLUE,
                            @"6":REDISH_ORANGE,
                            @"7":YELLOW,
                            @"8":BLUISH_PURPLE,
                            @"9":BLUISH_GREEN,
                            @"10":ORANGE,
                            @"13":EMERALD,
                            @"11":REDISH_PURPLE,
                            @"14":MAGENTA,
                            @"15":CYAN,
                            @"16":PURPLE,
                            @"17":MAGENTA,
                            @"18":EMERALD,
                            @"19":LIME,
                            @"101":ORANGE,
                            @"102":RED,
                            @"20":BURNT_ORANGE,
                            @"22":BLUE,
                            @"23":RED,
                            @"234":LIME,
                            @"235":TOPAZ,
                            @"24":CRANBERRY,
                            @"31":BLUE,
                            @"32":RED,
                            @"40":YELLOW,
                            @"41":MAGENTA,
                            @"42":BLUE,
                            @"43":BLUISH_GREEN,
                            @"44":EMERALD,
                            @"401":RED,
                            @"402":BLUE,
                            @"403":GREEN,
                            @"411":CYAN,
                            @"412":GREEN,
                            @"413":RED,
                            @"414":BLUE,
                            @"415":AMBER,
                            @"432":TOPAZ,
                            @"501":LIME,
                            @"503":RED,
                            @"504":MAGENTA,
                            @"52":GREEN,
                            @"53":TOPAZ,
                            @"54":BLUISH_GREEN,
                            @"55":PURPLE,
                            @"56": BLUE,
                            @"57":MAGENTA,
                            @"57A":ORANGE,
                            @"62":YELLOW,
                            @"70":GREEN,
                            @"71":RED,
                            @"72":RED,
                            @"73":REDISH_PURPLE,
                            @"74":ORANGE,
                            @"76":BLUE,
                            @"77":CYAN,
                            @"80":PURPLE,
                            @"80A":AMBER,
                            @"80B":EMERALD,
                            @"81":GREEN,
                            @"82":ORANGE,
                            @"83":CYAN,
                            @"84":BLUE,
                            @"84A":ORANGE,
                            @"85":RED,
                            @"90":GREEN,
                            @"91":CYAN,
                            @"96":AMBER };
        
        
    }
    return _routeColorDict;
}


-(NSMutableSet*)selectedRoutes {
    if (_selectedRoutes==nil) {
        _selectedRoutes = [[NSMutableSet alloc] init];
    }
    return _selectedRoutes;
}

-(NSMutableSet*)allRoutes {
    if (_allRoutes==nil) {
        _allRoutes = [[NSMutableSet alloc] init];
    }
    return _allRoutes;
}


-(NSMutableArray*) overlayInfo{
    if (!_overlayInfo) {
        _overlayInfo = [[NSMutableArray alloc] init];
    }
    return _overlayInfo;
}

-(NSMutableArray*) overlayQueue{
    if (!_overlayQueue) {
        _overlayQueue = [[NSMutableArray alloc] init];
    }
    return _overlayQueue;
}

-(NSArray*)currentRoute{
    if(!_currentRoute) {
        _currentRoute = [[NSMutableArray alloc]init];
    }
    return _currentRoute;
}




#pragma mark - View Controller Delegate

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    hideStopStr = @"  Hide Stops  ";
    IOSI = [[IOSImage alloc] init];
    TF = [[IOSTimeFunctions alloc] init];
    db = [OBRdataStore defaultStore];
    showBuses = false;
    
    //turn on the location manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    // Use one or the other, not both. Depending on what you put in info.plist
    //[self.locationManager requestWhenInUseAuthorization];
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
    self.routeViewMap.showsUserLocation = YES;

    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(21.4, -158.0);
    MKCoordinateRegion adjustedRegion = [self.routeViewMap regionThatFits:MKCoordinateRegionMakeWithDistance(center, 4700, 4700)];
    
    [self.routeViewMap setCenterCoordinate:center animated:YES];
    [self.routeViewMap setZoomEnabled:YES];
    [self.routeViewMap setRegion:adjustedRegion animated:YES];
    [self.routeViewMap setDelegate:self];
    
    //get list of bus stops
    stops = [[OBRdataStore defaultStore] getStops];
    
    //start the timer to show overlays
    overlayTimer = [NSTimer scheduledTimerWithTimeInterval:2
                                                    target:self
                                                  selector:@selector(cycleRoutes)
                                                  userInfo:nil
                                                   repeats:YES];
    updateBusTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                      target:self
                                                    selector:@selector(updateBusPos)
                                                    userInfo:nil
                                                     repeats:YES];
    //add tap gesture
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(foundTap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [self.routeViewMap addGestureRecognizer:tapRecognizer];
    
    stopsVisible = FALSE;
    self.showStopsButton.hidden = true;
    self.showBusButton.hidden = true;
    [self.showStopsButton setImage:[IOSI imageWithFilename:@"BusStopButton.png" Color:RED Size:60]
                          forState:UIControlStateNormal];
    [self.showBusButton setImage:[IOSI imageWithFilename:@"BusButton.png" Color:RED Size:60]
                          forState:UIControlStateNormal];
    [self.trackButton setImage:[IOSI imageWithFilename:@"TrackButton.png" Color:RED Size:60]
                          forState:UIControlStateNormal];
    
    
    self.instructionLabel.backgroundColor = GRAY;
}

-(void)viewWillAppear:(BOOL)animated {
    //set the map region
    MKCoordinateRegion r =[[OBRdataStore defaultStore] mapRegion];
    if (r.center.latitude != 0 && r.center.longitude != 0) {
        [self.routeViewMap setRegion:r];
    }
    
    //update the icon with the number of solutions
    [db updateNumSolIcon:db.solvedRoutes.count Color:BLACK Alpha:1.0];
    
   //act on a search selection
    if (db.searchSelection) {
        [self.searchButton setImage:[IOSI imageWithFilename:@"Search.png" Color:GREEN Size:60]
                          forState:UIControlStateNormal];
        
        if ([db.searchSelection containsString:@"Bus"]) {
            
        } else if ([db.searchSelection containsString:@"Route"]) {
            
            NSString* value = [db.searchSelection substringFromIndex:6];
            [[self selectedRoutes] removeAllObjects];
            [[self selectedRoutes] addObject:value];
            //[self completeSelection];
            
        } else if ([db.searchSelection containsString:@"Stop"]) {
            
            
        }
    } else {
        [[self selectedRoutes] removeAllObjects];
        [self.searchButton setImage:[IOSI imageWithFilename:@"Search.png" Color:RED Size:60]
                           forState:UIControlStateNormal];
        
    }
    [self completeSelection];
    
}

-(void)viewDidAppear:(BOOL)animated {
    
    //start updating buses
    db.updateVehicles = true;
    [db setVehicleTimer:0.5];
    
}

-(void)viewWillDisappear:(BOOL)animated {
    [overlayTimer invalidate];
    overlayTimer = nil;
    
    //stop updating buses
    db.updateVehicles = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [IOSI clearCache];
    [[OBRdataStore defaultStore] clearCache];
}




#pragma mark - Map Functions

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    //record the map position to the datastore
    [OBRdataStore defaultStore].mapRegion = self.routeViewMap.region;
    
    //redraw the overlays and annotations
    [self updateMap];
}

-(void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated {
    
    if (mode == MKUserTrackingModeFollow) {
        [_trackButton setImage:[[[IOSImage alloc] init  ]imageWithFilename:@"TrackButton.png" Color:GREEN Size:60] forState:UIControlStateNormal];
    } else {
        [_trackButton setImage:[[[IOSImage alloc] init] imageWithFilename:@"TrackButton.png" Color:RED Size:60] forState:UIControlStateNormal];
    }
}


-(MKOverlayView *)mapView:(MKMapView *)mapView  viewForOverlay:(id<MKOverlay>)overlay {
    if([overlay isKindOfClass:[MKPolyline class]]) {
        
        OBRoverlayInfo* info = [self getInfoForOverlay:overlay];
        UIColor* color = BLACK;
        if (info != nil) {
            color = info.color;
        }
        
        MKPolylineView *lineView = [[MKPolylineView alloc] initWithPolyline:overlay];
        lineView.lineWidth = 12;
        lineView.strokeColor = color;
        lineView.fillColor = color;
        return lineView;
    }
    return nil;
}

-(void)eraseMap{
    [self.routeViewMap removeOverlays:[self.routeViewMap overlays]];
    [self.routeViewMap removeAnnotations:[self.routeViewMap annotations]];
    [self.overlayInfo removeAllObjects];
    [self.overlayQueue removeAllObjects];
}

-(void)updateMap{
    NSTimeInterval start = [[OBRdataStore defaultStore] currentTimeSec];
    
    
    //clear the current map overlays
    [self.routeViewMap removeOverlays:[self.routeViewMap overlays]];
    [self.overlayInfo removeAllObjects];
    [self.overlayQueue removeAllObjects];
    
    //erase all routes
    [[self allRoutes] removeAllObjects];
    
    //connect to the datastore
    OBRdataStore* database = [OBRdataStore defaultStore];
    
    //get the map dimensions
    MKCoordinateRegion r  = [self.routeViewMap region];
    
    //determine which routes are included in region and save to a VC property
    routePts = [database getPointsForRegion:r];
    for (OBRRoutePoints* rp in routePts) {
        [[self allRoutes] addObject:rp.routestr];
    }
    
    //get the points for each route found
    for (NSString* s in self.allRoutes) {
        NSArray* points = [database getPointsForRouteStr:s];
        UIColor* routeColor = [self getColorOfRoute:s];
        if (routeColor == nil) {
            routeColor = GRAY;
            NSLog(@"couldn't find color of %@",s);
        }
        
        [self GenerateLines:points color:routeColor];
        [self addRouteToOverlayQueue:s];
        
    }
    
    NSTimeInterval end = [[OBRdataStore defaultStore] currentTimeSec];
    NSLog(@"updating map %f",end-start);
    
    [self redrawAnnotations];
    
}


#pragma mark - Annotation Functions

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation{

    
    //return if this is a user class
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    
    MKAnnotationView *annView= [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
    
    
    //get the properties
    OBRMapViewAnnotation* mva = annotation;
    UIColor* color = mva.color;
    NSString* title = mva.title;
    //OBRVehicle* v = mva.IDdict[@"vehicle"];
    
    if ([mva.type isEqualToString:@"routebadge"]) {
        
        //set the image size
        annView.image = [IOSI imageWithFilename:@"Route.png" FillColor:color TextColor:BLACK
                                           Size:50 At:CGPointMake(50, 80) Text:title FontSize:40 Cache:true];
        annView.layer.zPosition = 1000;
        return annView;
    }
    
    if ([mva.type isEqualToString:@"stop"]) {
        
        //set the image size
        annView.image = [IOSI imageWithFilename:@"BusStopSign.png" Size:30];
        annView.canShowCallout = true;
        
        // Create a UIButton object to add on the
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [rightButton setTitle:annotation.title forState:UIControlStateNormal];
        [annView setRightCalloutAccessoryView:rightButton];
        
        annView.layer.zPosition = 100;
        return annView;
    }
    if ([mva.type isEqualToString:@"arrow"]) {
        
        MKAnnotationView *annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"arrow"];
        
        //get the vehicle for this annotation
        OBRVehicle* v = mva.IDdict[@"vehicle"];
        
        //get the rotated and scaled icon
        UIColor* color = [self getColorOfRoute:v.route];
        annView.image = [self getImageForAnnotation:color orient:mva.orientation speed:v.speed];
        
        //set the callout properties
        annView.canShowCallout = YES;
        annView.calloutOffset = CGPointMake(-5, 5);
        annView.layer.zPosition = 2000;
        return annView;
    }
    if ([mva.type isEqualToString:@"buslabel"]) {
        annView.image = [[IOSLabel alloc] initWithText:@[mva.title,mva.subtitle] Color:LIGHT_YELLOW Sizex:-1 Sizey:40].image.image;
        annView.alpha = 0.85;
        annView.centerOffset = CGPointMake(0, 30);
        annView.layer.zPosition = 1999;
        return annView;
    }
    
    return nil;
}


-(UIImage*)getImageForAnnotation:(UIColor*)color orient:(float)orientation speed:(float)mps {
        
    
        //check for image in cache
        float angleRadians = orientation;
        float angleDegrees = (angleRadians*180.0/3.14159);
        if (angleDegrees > 180) angleDegrees -=180.0;
        if (angleDegrees < -180) angleDegrees += 180;
        
        //quantize the image to five degrees to use stored versions
        float oint = nearbyintf(angleDegrees/5.0);
        float qad =  oint*5.0;
    
        return [[db IOSI] imageWithFilename:@"bwarrow.png" Color:color Size:50 Orientation:-qad Cache:YES];
        
    }

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    [self performSegueWithIdentifier:@"StopDetail" sender:self];
}

-(void)addAnnotation:(NSString*)title
            subTitle:(NSString*)subtitle
                 lat:(float)lat
                 lon:(float) lon
                type:(NSString*)type
         orientation:(float)orient
          updateTime:(NSTimeInterval)timesec
               alpha:(float) alpha
              IDdict:(NSDictionary*) iddict {
    
    //check the time and limit buses to ones with updates within ten minutes
    OBRVehicle* v = iddict[@"vehicle"];
    NSTimeInterval now = [TF currentTimeSec];
    NSTimeInterval updateSec = v.lastMessageDate;
    if (v && (now - updateSec)>600) return;
    
    // Set some coordinates for our position
    CLLocationCoordinate2D location;
    location.latitude = (double) lat;
    location.longitude = (double) lon;
    
    // Add the annotation to our map view
    OBRMapViewAnnotation *newAnnotation = [[OBRMapViewAnnotation alloc] initWithTitle:title
                                                                        andCoordinate:location
                                                                          andSubtitle:subtitle];
    newAnnotation.type = type;
    newAnnotation.orientation = orient;
    newAnnotation.lastUpdateTime = timesec;
    newAnnotation.alpha = alpha;
    newAnnotation.IDdict = [[NSMutableDictionary alloc] initWithDictionary:iddict];
    
    [self.routeViewMap addAnnotation:newAnnotation];
}

-(void)addAnnotation:(NSString*)title
                 lat:(float)lat
                 lon:(float)lon
               color:(UIColor*)color
            subtitle:(NSString*)st
                type:(NSString*)t {
    // Set some coordinates for our position
    CLLocationCoordinate2D location;
    location.latitude = (double) lat;
    location.longitude = (double) lon;
    
    // Add the annotation to our map view
    OBRMapViewAnnotation *mva = [[OBRMapViewAnnotation alloc] initWithTitle:title
                                                            andCoordinate:location
                                                              andSubtitle:st];
    
    //set the annotations properties
    mva.color = color;
    mva.type = t;
    
    [_routeViewMap addAnnotation:mva];
}

-(void)removeAllStopAnnotations {
    NSMutableArray* deleteList = [[NSMutableArray alloc] init];
    for (OBRMapViewAnnotation* mva in [[self routeViewMap] annotations]) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {
            if ([mva.type isEqualToString:@"stop"]) {
                [deleteList addObject:mva];
            }
        }
    }
    [_routeViewMap removeAnnotations:deleteList];
}

-(OBRRoutePoints*)addOptimumBadgePositionForRoutestr:(NSString*)r {
    //get the map dimensions
    MKCoordinateRegion reg  = [self.routeViewMap region];
    
    //compute a smaller span for the route annotations to prevent badges at the
    //window edges
    float latSpan = reg.span.latitudeDelta * 0.8;
    float lonSpan = reg.span.longitudeDelta * 0.9;
    float Nlat = reg.center.latitude + latSpan/2.0;
    float Slat = reg.center.latitude - latSpan/2.0;
    float Elon = reg.center.longitude + lonSpan/2.0;
    float Wlon = reg.center.longitude - lonSpan/2.0;

    //calculate the optimum point for the badge
    OBRRoutePoints* optimumPoint;
    optimumPoint.distance = 0;
    
    for (OBRRoutePoints* rpsearch in routePts) {
        
        //limit the route badges around the screen edges
        if (rpsearch.lat<Nlat && rpsearch.lat>Slat && rpsearch.lon>Wlon && rpsearch.lon<Elon ) {
            if ([rpsearch.routestr isEqualToString:r]) {
                //assure we have at least a single point
                if (optimumPoint == nil) {
                    optimumPoint = rpsearch;
                }
                
                if (rpsearch.distance > optimumPoint.distance) {
                    
                    //check to see if this point is too close to another annotation
                    if (![self isPointTooCloseToAnotherBadge:rpsearch]) {
                        optimumPoint = rpsearch;
                    }
                }
            }
        }
    }
    
    return optimumPoint;
}


-(BOOL)isPointTooCloseToAnotherBadge:(OBRRoutePoints*) rp {
    //determine the min delat lat/lon badge spacing for this scale
    //this should be moved to the zoom screen becuas eit only needs
    //to be calculated once
    CGPoint p1 = CGPointMake(0, 35);
    CGPoint p2 = CGPointMake(0, 0);
    CLLocationCoordinate2D c1 = [self.routeViewMap convertPoint:p1 toCoordinateFromView:self.routeViewMap];
    CLLocationCoordinate2D c2 = [self.routeViewMap convertPoint:p2 toCoordinateFromView:self.routeViewMap];
    float dla = c1.latitude - c2.latitude;
    float dlo = c1.longitude - c2.longitude;
    float mind = sqrt(dla*dla+dlo*dlo);
    
    for (OBRMapViewAnnotation* mva in self.routeViewMap.annotations) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {
            if ([mva.type isEqualToString:@"routebadge"]) {
                dla = mva.coordinate.latitude - rp.lat;
                dlo = mva.coordinate.longitude - rp.lon;
                float d = sqrt(dla*dla + dlo*dlo);
                if (d<mind) {
                    if (![rp.routestr isEqualToString:mva.title]) {
                        return true;
                    }
                }
            }
        }
    }
    
    return false;
}

-(void)addStopAnnotations{
    
    for (OBRStopNew* stop in routeStops) {
        
        //find markers
        NSRange rb = [stop.streets rangeOfString:@"(" options:NSBackwardsSearch];
        NSRange re = [stop.streets rangeOfString:@")" options:NSBackwardsSearch];
        
        //extract title
        NSRange r;
        r.location = rb.location+1;
        r.length = re.location - rb.location-1;
        NSString* title = [stop.streets substringWithRange:r];
        
        //extract subtitle
        NSString* subtitle = [stop.streets substringToIndex:rb.location];
        
        //add annotation
        [self addAnnotation:title lat:stop.lat lon:stop.lon color:0 subtitle:subtitle type:@"stop"];
    }
}

-(void)redrawAnnotations{
    
    NSTimeInterval start = [[OBRdataStore defaultStore] currentTimeSec];
    
    NSMutableSet* updatedAnnotations = [[NSMutableSet alloc] init];
    NSMutableSet* routesNeedingBadges = [[NSMutableSet alloc] init];
    
    //add any needed badges annotations
    for (NSString* route in [self allRoutes]) {
        bool isSelected = [[self selectedRoutes] containsObject:route];
        bool noneSelected = false;
        if ([self selectedRoutes].count == 0) {
            noneSelected = true;
        }
        
        if (noneSelected || isSelected) {
            
            //check to see if this annotation is found
            bool found = false;
            OBRMapViewAnnotation* annotation = nil;
            for (OBRMapViewAnnotation* mva in [[self routeViewMap] annotations]) {
                if (![mva isKindOfClass:[MKUserLocation class]] ) {
                    if ([mva.title isEqualToString:route]) {
                        found = true;
                        annotation = mva;
                        break;
                    }
                }
            }
            
            //get the best badge location for this region
            OBRRoutePoints* rp = [self addOptimumBadgePositionForRoutestr:route];
            
            //label this annotation as being found.  Any annotation not in this set by the
            //end of the function will be removed
            
            if(found) {
                //update this annotation
                [updatedAnnotations addObject:annotation];
                if (rp.lat != annotation.coordinate.latitude ||
                    rp.lon != annotation.coordinate.longitude) {
                    CLLocationCoordinate2D p = CLLocationCoordinate2DMake(rp.lat, rp.lon);
                    annotation.coordinate = p;
                }
            } else {
                if (rp) {
                    //i can't add these badges until I delete the unused badges
                    [routesNeedingBadges addObject:rp];
                }
            }
            
        }
    }
    
    //do not display more then twenty badge routes
    long numSelectedRoutes = [[self selectedRoutes] count];
    long numTotalRoutes = [[self allRoutes] count];
    if (numSelectedRoutes==0 && numTotalRoutes>20) {
        [routesNeedingBadges removeAllObjects];
        [updatedAnnotations removeAllObjects];
    }
    
    //delete any annotations not in the updated set
    NSMutableSet* allBadgeAnn = [[NSMutableSet alloc] init];
    for (OBRMapViewAnnotation* mva in _routeViewMap.annotations) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {
            if ([mva.type isEqualToString:@"routebadge"]) {
                [allBadgeAnn addObject:mva];
            }
        }
    }
    [allBadgeAnn minusSet:updatedAnnotations];
    [_routeViewMap removeAnnotations:[allBadgeAnn allObjects]];
    
    //add any missing badges
    for (OBRRoutePoints* rp in routesNeedingBadges) {
        UIColor* routeColor = [self getColorOfOverlayWithRoutestr:rp.routestr];
        if (rp != nil) {
            [self addAnnotation:rp.routestr
                            lat:rp.lat
                            lon:rp.lon
                          color:routeColor
                       subtitle:@"none"
                           type:@"routebadge"];
        }
    }
    
    NSTimeInterval end = [[OBRdataStore defaultStore] currentTimeSec];
    NSLog(@"redrawing annotations %f",end-start);

}



#pragma mark - Touch Events

-(IBAction)foundTap:(UITapGestureRecognizer *)recognizer {
    
    if (stopsVisible || showBuses) {
        _instructionLabel.text = @"Turn off Buses and Stops to continue";
        return;
    }
    
    //disable the search
    db.searchSelection = nil;
    [self.searchButton setImage:[IOSI imageWithFilename:@"Search.png" Color:RED Size:60] forState:UIControlStateNormal];
   

    
    //compute the lat and lon of the tap
    CGPoint point = [recognizer locationInView:self.routeViewMap];
    CLLocationCoordinate2D tapPoint = [self.routeViewMap convertPoint:point toCoordinateFromView:self.routeViewMap];
    
    //connect to the datastore
    OBRdataStore* database = [OBRdataStore defaultStore];
    
    //get the map dimensions
    MKCoordinateRegion r  = MKCoordinateRegionMake(tapPoint, MKCoordinateSpanMake(.004, .004));
    
    //erase the last selected routes
    [[self selectedRoutes] removeAllObjects];
    
    //find the set of routes in this small span
    NSArray* tapRoutePts = [database getPointsForRegion:r];
    for (OBRRoutePoints* rp in tapRoutePts) {
        [[self selectedRoutes] addObject:rp.routestr];
    }
    
    [self completeSelection];
    
}

-(void)completeSelection {
    //delete all the stop annotations
    [self removeAllStopAnnotations];
    
    //reset the stops button
    stopsVisible = FALSE;
    [_showStopsButton setTitle:@"  Show Stops  " forState:UIControlStateNormal];
    
    //reset the showBuses state
    showBuses = false;
    [self.showBusButton setImage:[IOSI imageWithFilename:@"BusButton.png" Color:RED Size:60] forState:UIControlStateNormal];
    
    if ([[self selectedRoutes] count] == 0) {
        //no routes selected
        _instructionLabel.text = @"Tap route to select";
        
        //hide the button
        _showStopsButton.hidden = true;
        _showBusButton.hidden = true;
    } else {
        //route selected (may be different then last selection)
        _instructionLabel.text = @"Tap map to select a different route";
        
        //determine the stops on the new set of selected routes
        [self populateRouteStops];
        
        _showStopsButton.hidden = false;
        _showBusButton.hidden = false;
    }
    
    //redraw the routes.
    [self redrawOverlays];
    [self redrawAnnotations];
 
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"did select annotation view");

    //unselect old annotation
    MKPinAnnotationView *annView=[[MKPinAnnotationView alloc]
                                  initWithAnnotation:selectedAnnotation
                                  reuseIdentifier:@"pin"];
    annView.pinColor = MKPinAnnotationColorRed;
    
    
    //select the new annotation
    annView =[[MKPinAnnotationView alloc]
              initWithAnnotation:view.annotation
              reuseIdentifier:@"pin"];
    annView.pinColor = MKPinAnnotationColorGreen;
    
    
    //get new point information
    selectedAnnotation = view.annotation;
    CLLocationCoordinate2D c = selectedAnnotation.coordinate;
    
    for (OBRStopNew* s in stops) {
        if (c.latitude == s.lat && c.longitude== s.lon) {
            selectedStop = s;
            _instructionLabel.text =@"Press information button for more details";
            break;
        }
    }
    
}



#pragma mark - Overlays
-(void)GenerateLines:(NSArray*)routePoints
                color:(UIColor*)color {

    //determine number of segments
    int minSeg = 999;
    int maxSeg = -999;
    for (OBRRoutePoints* rp in routePoints) {
        if (rp.segment>maxSeg) maxSeg = rp.segment;
        if (rp.segment<minSeg) minSeg = rp.segment;
    }
    
    for (int seg=minSeg ; seg<=maxSeg; seg++) {
        
        //determine number of points in this segment
        int numPoints=0;
        NSString* routestr;
        for (OBRRoutePoints* rp in routePoints) {
            if (rp.segment == seg) {
                routestr = rp.routestr;
                numPoints++;
            }
        }
        
        CLLocationCoordinate2D* pointArr = malloc(sizeof(CLLocationCoordinate2D)*numPoints);
        
        int Indx = 0;
        for  (OBRRoutePoints* rp in routePoints) {
            if (rp.segment == seg) {
                pointArr[Indx++] = CLLocationCoordinate2DMake(rp.lat, rp.lon);
            }
        }
        
        if (Indx>0) {
            MKPolyline* routeLine = [MKPolyline polylineWithCoordinates:pointArr count:numPoints ];
            
            //NSLog(@"adding routeline");
            OBRoverlayInfo* oi = [[OBRoverlayInfo alloc] init];
            oi.overlay = routeLine;
            oi.color = color;
            oi.routestr = routestr;
            [self.overlayInfo addObject:oi];
            if ([self.selectedRoutes containsObject:routestr] || self.selectedRoutes.count==0) {
                [self.routeViewMap addOverlay:routeLine];
            }
        }
    }
}

-(OBRoverlayInfo*)getInfoForOverlay:(MKPolyline*)o {
    for (OBRoverlayInfo* oi in self.overlayInfo) {
        if (oi.overlay == o) {
            return oi;
        }
    }
    return nil;
}

-(UIColor*) getColorOfRoute:(NSString*)route {
    return [[self routeColorDict] objectForKey:route];
}

-(void)cycleRoutes{
    
    //experiment with exchangeoverlay: withoverlay:

    //return if less then two routes displayed
    if (self.overlayQueue.count <2) return;
    
    //find the first selected route
    bool foundARoute = false;
    NSString* first = nil;
    int count = 0;
    while (!foundARoute && count<1000) {
        count++;
        for (NSString* r in [self overlayQueue]) {
            if (_selectedRoutes.count==0 || [_selectedRoutes containsObject:r]) {
                first = r;
                foundARoute = true;
                break;
            }
        }
    }
    
    
    //change the order in the array
    if (first != nil) {
        
        //experiment with exchangeoverlay withoverlay to see if it speeds up.
        
        
        
        [[self overlayQueue] removeObject:first];
        [[self overlayQueue] addObject:first];
    }
    
    //reapply overlays in the new order
    for (NSString* s in self.overlayQueue) {
        for (OBRoverlayInfo* oi in self.overlayInfo) {
            
            //find the information that corresponds to the route
            if ([s isEqualToString:oi.routestr]) {
                
                //remove this overlay from the map
                [_routeViewMap removeOverlay:oi.overlay];
                
                //are there any selected routes?
                BOOL selectedRoutesExist = false;
                if (_selectedRoutes.count>0) selectedRoutesExist = true;
                
                //is this a selected route?
                BOOL isSelectedRoute = false;
                isSelectedRoute = [_selectedRoutes containsObject:oi.routestr];
                
                if (!selectedRoutesExist || isSelectedRoute) {
                    [_routeViewMap addOverlay:oi.overlay];
                }
            }
        }
    }
}


-(void)addRouteToOverlayQueue:(NSString*) routestr {
    if ([[self overlayQueue] containsObject:routestr]) {
        return;
    }
    [[self overlayQueue] addObject:routestr];
}


-(UIColor*)getColorOfOverlayWithRoutestr:(NSString*)rs {
    for (OBRoverlayInfo* oi in self.overlayInfo){
        if ([oi.routestr isEqual:rs]){
            return oi.color;
        }
    }
    return GRAY;
}



-(void)redrawOverlays{
    //determine if we have selected routes
    
    [_routeViewMap removeOverlays:[_routeViewMap overlays]];
    for (OBRoverlayInfo* oi in self.overlayInfo) {
        if ([self.selectedRoutes containsObject:oi.routestr] || self.selectedRoutes.count==0)
            [_routeViewMap addOverlay:oi.overlay];
    }
}



#pragma mark - other functions
-(void)updateBusPos{
    
    

    //find all the buses
    NSMutableArray* busAnnotations = [[NSMutableArray alloc] init];
    NSMutableArray* busLabels = [[NSMutableArray alloc] init];
    for (OBRMapViewAnnotation* mva in _routeViewMap.annotations) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {
            if ([mva.type isEqualToString:@"arrow"] ) {
                [busAnnotations addObject:mva];
            }
            if ([mva.type isEqualToString:@"buslabel"]) {
                [busLabels addObject:mva];
            }
        }
    }
    
    //delete all bus annotations if user unselected button
    if (!showBuses) {
        [self.routeViewMap removeAnnotations:busAnnotations];
        [self.routeViewMap removeAnnotations:busLabels];
        return;
    }
    
    //find the vehicles for the selected routes
    NSMutableSet* selectedVehicles = [[NSMutableSet alloc] init];
    for (OBRVehicle* v in [db vehicles]) {
        NSString* rs = v.route;
        if ([[self selectedRoutes] containsObject:rs] ) {
            [selectedVehicles addObject:v];
        }
    }
    
    //clean any annotations off the map that arn't in selected vehciles
    NSMutableArray* deleteMe = [[NSMutableArray alloc] init];
    for (OBRMapViewAnnotation* mva in busAnnotations) {
        OBRVehicle* v = mva.IDdict[@"vehicle"];
        if (![selectedVehicles containsObject:v]) {
            [deleteMe addObject:mva];
        }
    }
    [self.routeViewMap removeAnnotations:deleteMe];
    
    
    //return if no selectedvehicles
    if (selectedVehicles.count == 0) {
        return;
    }
    
    //check if these annotations exist
    NSMutableSet* annotationsNeedingUpdates = [[NSMutableSet alloc] init];
    NSMutableSet* vehiclesNeedingUpdates = [[NSMutableSet alloc] init];
    for (OBRMapViewAnnotation* mva in _routeViewMap.annotations) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {
            OBRVehicle* v = mva.IDdict[@"vehicle"];
            if ([selectedVehicles containsObject:v]) {
                [vehiclesNeedingUpdates addObject:v];
                [annotationsNeedingUpdates addObject:mva];
            }
        }
    }
    
    //determine vehicles without annotations
    NSMutableSet* vehiclesWithoutAnnotation = [[NSMutableSet alloc] initWithSet:selectedVehicles];
    [vehiclesWithoutAnnotation minusSet:vehiclesNeedingUpdates];
    
    //add the new vehicles
    for (OBRVehicle* v in vehiclesWithoutAnnotation) {
        
        //set the icon type based on adherence
        NSString* type = @"arrow";
      
        //rebuild the strings
        NSString* adStr =@"adStr"; //[self adherenceStr:v.adherence];
        NSString* t = v.numString;
        NSString* st = [NSString stringWithFormat:@"Rt:%@ %@ (%@) ",v.route,v.direction,adStr];
        
        //add a new annotation if not found
        [self addAnnotation:t
                   subTitle:st
                        lat:v.lat
                        lon:v.lon
                       type:type
                orientation:v.orientation
                 updateTime:v.lastMessageDate
                      alpha:1.0
                     IDdict:@{@"vehicle":v}];
        
        [self addAnnotation:[self makeTitleForVehicle:v]
                   subTitle:[self makeSubtitleForVehicle:v]
                        lat:v.lat
                        lon:v.lon
                       type:@"buslabel"
                orientation:v.orientation
                 updateTime:v.lastMessageDate
                      alpha:1.0
                     IDdict:@{@"vehicle":v}];
    }
    
    //update the vehicle annotations alreay present
    for (OBRMapViewAnnotation* mva in annotationsNeedingUpdates) {
        OBRVehicle* v = mva.IDdict[@"vehicle"];
        if (v.lat != mva.coordinate.latitude || v.lon != mva.coordinate.longitude) {
            CLLocationCoordinate2D point = CLLocationCoordinate2DMake(v.lat, v.lon);
            MKAnnotationView* av = [self.routeViewMap viewForAnnotation:mva];
            mva.coordinate = point;
            if ([mva.type isEqualToString:@"buslabel"]) {
                //update the lable image here
                NSString* t = [self makeTitleForVehicle:v];
                NSString* st = [self makeSubtitleForVehicle:v];
                av.image = [[IOSLabel alloc] initWithText:@[t,st] Color:LIGHT_YELLOW Sizex:-1 Sizey:40].image.image;
            } else {
                UIColor* color = [[self routeColorDict] objectForKey:v.route];
                av.image = [self getImageForAnnotation:color orient:v.orientation speed:v.speed];
            }
        }
    }
}


-(NSString*)makeTitleForVehicle:(OBRVehicle*)v {
    if ([v.direction isEqualToString:@"Eastbound"]) {
        return [NSString stringWithFormat:@"Bus %d   Rt:%@ EB",v.number,v.route];
    } else {
        return [NSString stringWithFormat:@"Bus %d   Rt:%@ WB",v.number,v.route];
    }
}

-(NSString*)makeSubtitleForVehicle:(OBRVehicle*)v {
    NSString* adStr = [self adherenceStr:v.adherence];
    NSString* timeStr = [[[IOSTimeFunctions alloc] init] localTimehhmmssa:v.lastMessageDate];
    NSString* labelst = [NSString stringWithFormat:@"%@ %@",timeStr,adStr];
    return labelst;
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



-(void) populateRouteStops{
    
    //alloc a new array containing all the stops
    routeStops = [[NSMutableArray alloc] init];
    
    //add the stops for each selected route
    for (NSString* rs in self.selectedRoutes) {
        
        NSArray* srs = [[OBRdataStore defaultStore] getStopsForRoutestr:rs];
        
        [routeStops addObjectsFromArray:srs];
    }
}



-(float)distance:(OBRalgPoint*)start
              p2:(OBRalgPoint*)end {
    float x = (start.lat - end.lat)*(start.lat - end.lat);
    float y = (start.lon - end.lon)*(start.lon - end.lon);
    return  sqrt(x+y);
}


-(float)distanceRP:(OBRRoutePoints*)start
                p2:(OBRRoutePoints*)end {
    float x = (start.lat - end.lat)*(start.lat - end.lat);
    float y = (start.lon - end.lon)*(start.lon - end.lon);
    return  111000*sqrt(x+y);
}









-(NSString*)localTime:(NSDate*)date{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    NSTimeZone* tz = [NSTimeZone timeZoneWithName:@"HST"];
    [df setDateFormat:@"MM-dd HH:mm:ss"];
    [df setTimeZone:tz];
    NSString* dateStr =[df stringFromDate:date];
    return dateStr;
}


-(NSString*)localTimeI:(NSTimeInterval)interval{
    NSDate* date = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:interval];
    return [self localTime:date];
}



#pragma mark - button Actions

- (IBAction)pressedShowStops:(id)sender {
    if (stopsVisible) {
        stopsVisible = FALSE;
        [_showStopsButton setTitle:@"  Show Bus Stops  " forState:UIControlStateNormal];
        [_showStopsButton setImage:[IOSI imageWithFilename:@"BusStopButton.png" Color:RED Size:60]
                              forState:UIControlStateNormal];
        //erase the past stop annotations and redraw
        [self removeAllStopAnnotations];
        [self redrawAnnotations];
        
        
    } else {
        stopsVisible = TRUE;
        //show the stops
        _instructionLabel.text = @"Select Stop for Detailed Information";
        [_showStopsButton setTitle:hideStopStr forState:UIControlStateNormal];
        [_showStopsButton setImage:[IOSI imageWithFilename:@"BusStopButton.png" Color:GREEN Size:60]
                          forState:UIControlStateNormal];
        [self addStopAnnotations];
    }
 }

- (IBAction)pressedSearch:(id)sender {
    if (db.searchSelection == nil) {
        [self performSegueWithIdentifier:@"RouteToSearchSegue" sender:self];
    } else {
        db.searchSelection = nil;
        [[self selectedRoutes] removeAllObjects];
        [self completeSelection];
        [self.searchButton setImage:[IOSI imageWithFilename:@"Search.png" Color:RED Size:60]
                           forState:UIControlStateNormal];
    }
}

- (IBAction)pressedShowBuses:(id)sender {
    if (showBuses) {
        showBuses = false;
        [self.showBusButton setImage:[IOSI imageWithFilename:@"BusButton.png" Color:RED Size:60]
                        forState:UIControlStateNormal];
    } else {
        showBuses = true;
        [self.showBusButton setImage:[IOSI imageWithFilename:@"BusButton.png" Color:GREEN Size:60]
                        forState:UIControlStateNormal];
    }
    
}

- (IBAction)pressedTrack:(id)sender {
    if (_routeViewMap.userTrackingMode == MKUserTrackingModeNone) {
        _routeViewMap.userTrackingMode = MKUserTrackingModeFollow;
    } else {
        _routeViewMap.userTrackingMode = MKUserTrackingModeNone;
    }
}
@end
