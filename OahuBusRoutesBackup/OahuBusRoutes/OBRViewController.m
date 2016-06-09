//
//  OBRViewController.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/1/13.
//  Copyright (c) 2013 Paul Philippou. All rights reserved.
//

#import "OBRViewController.h"


@interface OBRViewController () {
    IOSImage* IOSI;
    IOSTimeFunctions* TF;
}

@property (nonatomic,copy) OBRdataStore* db;
@property (nonatomic) NSArray* currentRoute;
@property (nonatomic) NSMutableSet* allRoutes;      //all the routes in the window
@property (nonatomic) NSMutableSet* selectedRoutes; //last tapped routes
@property (nonatomic) NSDictionary* routeColorDict;
@property (nonatomic) NSTimer* overlayTimer;
@property (nonatomic) NSTimer* updateBusTimer;
@property (nonatomic) NSMutableArray* routeStops;
@property (nonatomic) NSArray* stops;
@property (nonatomic) OBRMapViewAnnotation* selectedAnnotation;
@property (nonatomic) OBRStopNew* selectedStop;

//new
@property (nonatomic) NSMutableDictionary* data;
@property (nonatomic) bool updateMap;
@property (nonatomic) NSMutableSet* badgesInWindow;
@property (nonatomic) UILabel* selectedLabel;
@property (nonatomic) OBRVehicle* selectedVehicle;

//these naarays are filled with schedule values when the user has selected timetable from a
//particular vehicle.  While these are not null we will display time labels
@property (nonatomic) NSArray* timeTableSchs;
@property (nonatomic) NSArray* lastTimetableSchs;

//this array holds the optimumRouteBadgeLocations.  It is erased whenever the map region changes
@property (nonatomic) NSMutableDictionary* optimumRouteBadgePositions;



@end



@implementation OBRViewController
@synthesize db;
@synthesize showAllBuses;
@synthesize showSelectedBuses;
@synthesize showSelectedBusLabels;
@synthesize showStopMode;
@synthesize lastShowStopMode;

@synthesize showBusMode;
@synthesize lastShowBusMode;

@synthesize overlayTimer;
@synthesize updateBusTimer;
@synthesize routeStops;
@synthesize selectedAnnotation;
@synthesize selectedStop;
@synthesize updateMap;
@synthesize selectedLabel;
@synthesize selectedVehicle;
@synthesize timeTableSchs;
@synthesize lastTimetableSchs;




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

-(NSMutableDictionary*)optimumRouteBadgePositions {
    if (!_optimumRouteBadgePositions) {
        _optimumRouteBadgePositions = [[NSMutableDictionary alloc] init];
    }
    return _optimumRouteBadgePositions;
}

-(NSMutableSet*) badgesInWindow {
    if (!_badgesInWindow) {
        _badgesInWindow = [[NSMutableSet alloc] init];
    }
    return _badgesInWindow;
}

-(NSMutableDictionary*) data {
    if (!_data || _data.count==0) {
        NSMutableDictionary* d  = [[NSMutableDictionary alloc] init];
        
        //create all the overlays
        NSTimeInterval start = [[OBRdataStore defaultStore] currentTimeSec];
        for (NSString* route in [[self routeColorDict] allKeys]) {
            
            [[self allRoutes] addObject:route];
            
            //check that we can get points
            NSArray* points = [db getPointsForRouteStr:route];            
            
            UIColor* routeColor = [self getColorOfRoute:route];
            if (routeColor == nil) {
                routeColor = GRAY;
                NSLog(@"couldn't find color of %@",route);
            }
            
            NSArray* polyLines = [self GeneratePolylines:points];
            NSMutableSet* polyViews = [[NSMutableSet alloc] init];
            
            //create a dictionary for this route
            long numPoints = [points count];
            if (numPoints>0) {
                
                NSMutableDictionary* rdict = [[NSMutableDictionary alloc] init];
                [rdict setObject:points forKey:@"points"];
                [rdict setObject:polyLines forKey:@"polylines"];
                [rdict setObject:polyViews forKey:@"polyViews"];
                [rdict setObject:routeColor forKey:@"color"];
                [rdict setObject:route forKey:@"route"];
                
                //add the dictionary to the data dictionary
                [d setObject:rdict forKey:route];
                
                //add these polylines to the map
                //[self.mapView addOverlays:polyLines];
            }
            
        }
        NSTimeInterval end = [[OBRdataStore defaultStore] currentTimeSec];
        NSLog(@"creating data %f",end-start);
        
        if (d.count>0) _data = d;
        
    }
    return _data;
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

-(NSArray*)currentRoute{
    if(!_currentRoute) {
        _currentRoute = [[NSMutableArray alloc]init];
    }
    return _currentRoute;
}

-(NSArray*)stops {
    if (!_stops) {
        _stops = [db getStops];
    }
    return _stops;
}




#pragma mark - view controller delegate





-(void)viewDidLoad{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    IOSI = [[IOSImage alloc] init];
    TF = [[IOSTimeFunctions alloc] init];
    db = [OBRdataStore defaultStore];
    showAllBuses = false;
    showSelectedBuses = false;
    showStopMode = NONE;
    lastShowStopMode = NONE;
    updateMap = true;
    
    //start timers
    [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateMapNew) userInfo:nil repeats:true];

    
    //add a data rx button
    UIImage *logo = [UIImage imageNamed:@"Data.png"];
    UIImageView *logoView = [[UIImageView alloc]initWithImage:logo];
    logoView.frame = CGRectMake(284, 0, 35, 35);
    logoView.alpha = 0.1;
    [self.navigationController.navigationBar addSubview:logoView];
    [db setDataRxButton:logoView];
    
    //add an activity indicator
    UIActivityIndicatorView *iv = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    iv.transform = CGAffineTransformMakeScale(0.75, 0.75);
    iv.hidesWhenStopped = false;
    iv.color = BLACK;
    iv.alpha = 0.1;
    iv.frame = CGRectMake( 252,3,35,35);
    [self.navigationController.navigationBar  addSubview:iv];
    [db setActivityIndicator:iv];
    
    selectedLabel = [[UILabel alloc ] initWithFrame:CGRectMake(10, 0.0, 240, 40) ];
    selectedLabel.text = @"";
    [self.navigationController.navigationBar addSubview:selectedLabel];
    
 
//    //add an number of solutions icon
//    [IOSI imageWithFilename:@"AtoBWide.png"];
//    [IOSI drawText:@"0" atPoint:CGPointMake(280, 20) FontSize:120];
//    UIImageView *dirView = [[UIImageView alloc]initWithImage:[IOSI getImage]];
//    dirView.frame = CGRectMake(190, 5, 60, 30);
//    dirView.alpha = 0.1;
//    [self.navigationController.navigationBar addSubview:dirView];
//    [db setNumSolsIcon:dirView];
    
    showAllBuses = false;
    showSelectedBuses = false;
    
    //turn on the location manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    // Use one or the other, not both. Depending on what you put in info.plist
    //[self.locationManager requestWhenInUseAuthorization];
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
    self.mapView.showsUserLocation = YES;
    
    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(21.4, -158.0);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(center, 4700, 4700)];
    
    [self.mapView setCenterCoordinate:center animated:YES];
    [self.mapView setZoomEnabled:YES];
    [self.mapView setRegion:adjustedRegion animated:YES];
    [self.mapView setDelegate:self];
    
    
    //add tap gesture
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(foundTap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [self.mapView addGestureRecognizer:tapRecognizer];
    
    [self.showStopsButton setImage:[IOSI imageWithFilename:@"BusStopButton.png" Color:RED Size:60]
                          forState:UIControlStateNormal];
    [self.showBusButton setImage:[IOSI imageWithFilename:@"BusButton.png" Color:RED Size:60]
                        forState:UIControlStateNormal];
    [self.trackButton setImage:[IOSI imageWithFilename:@"TrackButton.png" Color:RED Size:60]
                      forState:UIControlStateNormal];

    
    self.textBox.backgroundColor = GRAY;
    
    //create the data structure
    [self data];
    
    
}

-(void)viewWillAppear:(BOOL)animated {
    //update the icon with the number of solutions
    [db updateNumSolIcon:db.solvedRoutes.count Color:BLACK Alpha:0.1];
    
    //set the map region
    MKCoordinateRegion r =[[OBRdataStore defaultStore] mapRegion];
    if (r.center.latitude != 0 && r.center.longitude != 0) {
        [self.mapView setRegion:r];
    }
    
    //update the icon with the number of solutions
    [db updateNumSolIcon:db.solvedRoutes.count Color:BLACK Alpha:1.0];
    
    //act on a search selection
    if (db.searchSelection) {
        selectedVehicle = nil;
        
        [self.searchButton setImage:[IOSI imageWithFilename:@"Search.png" Color:GREEN Size:60]
                           forState:UIControlStateNormal];
        
        if ([db.searchSelection containsString:@"Bus"]) {
            
            NSString* value = [db.searchSelection substringFromIndex:3];
            int busNum = [value intValue];
            OBRVehicle* v = [db findVehicle:busNum];
            
            if (v != nil) {
                selectedVehicle = v;
                [_mapView removeOverlays:_mapView.overlays];
                [[self selectedRoutes] removeAllObjects];
                if (![v.route isEqualToString:@"-1"]) {
                    [[self selectedRoutes] addObject:v.route];
                }
                [self completeSelection];
                
                //these must be set after complete selection
                showSelectedBuses = true;
                showAllBuses = false;
                
                updateMap = true;
                [self updateMapNew];
                [_mapView setCenterCoordinate:CLLocationCoordinate2DMake(v.lat, v.lon)];
            }
            
            
        } else if ([db.searchSelection containsString:@"Route"]) {
            
            NSString* value = [db.searchSelection substringFromIndex:6];
            [_mapView removeOverlays:_mapView.overlays];
            [[self selectedRoutes] removeAllObjects];
            [[self selectedRoutes] addObject:value];
            [self completeSelection];
            updateMap = true;
            [self updateMapNew];
            [self zoomToRoute];
            
        } else if ([db.searchSelection containsString:@"Stop"]) {
            
            
        } else if ([db.searchSelection containsString:@"POI:"]) {
            NSLog(@"found the POI %@",db.searchSelection);
            
            //find this POI
            for (POI* p in [db pois]) {
                if ([db.searchSelection containsString:p.name]) {
                    NSLog(@"found a match");
                     [_mapView setCenterCoordinate:CLLocationCoordinate2DMake(p.node.lat, p.node.lon)];
                    [self addAnnotation:p.name subTitle:p.type lat:p.node.lat lon:p.node.lon type:@"POI" orientation:0 updateTime:0 alpha:1 IDdict:@{@"POI":p}];
                    
                    //since they added an icon to the map reset the search button
                    db.searchSelection = nil;
                    [self.searchButton setImage:[IOSI imageWithFilename:@"Search.png" Color:RED Size:60]
                                       forState:UIControlStateNormal];
                }
            }
        }
        
        
    } else {
        [[self selectedRoutes] removeAllObjects];
        [self.searchButton setImage:[IOSI imageWithFilename:@"Search.png" Color:RED Size:60]
                           forState:UIControlStateNormal];
        [self completeSelection];
        
    }
}

-(void)viewDidAppear:(BOOL)animated {
    
    //start updating buses
    db.updateVehicles = true;
    [db setVehicleTimer:0.5];
    
    //start the timer to update the route overlays
    overlayTimer = [NSTimer scheduledTimerWithTimeInterval:4
                                                    target:self
                                                  selector:@selector(cycleRoutesNew)
                                                  userInfo:nil
                                                   repeats:YES];
    //start the timer to update the buses
    updateBusTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                      target:self
                                                    selector:@selector(periodicUpdate)
                                                    userInfo:nil
                                                     repeats:YES];
    
    
    
}

-(void)viewWillDisappear:(BOOL)animated {
    [overlayTimer invalidate];
    overlayTimer = nil;
    
    //stop updating buses
    db.updateVehicles = false;
    
    //stop the thread that moves the buses
    [updateBusTimer invalidate];
    updateBusTimer = nil;

     //erase the selected label in the header
    selectedLabel.text = @"";
    
}


-(void)viewDidDisappear:(BOOL)animated {

    //erase the selected label in the header
    selectedLabel.text = @"";
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [IOSI clearCache];
    [[OBRdataStore defaultStore] clearCache];
}


#pragma mark - Map Functions


-(void)updateMapNew {
    if (updateMap) {
        db.vehiclesModified = true;
        
        //check that the overlays are on the map
        NSArray* overlays = [[self mapView] overlays];
        for (NSString* route in [[self data] allKeys]) {
            NSDictionary* rdict = [[self data] objectForKey:route];
            
            //check that this route is visible
            bool visible = false;
            if ([[self selectedRoutes] containsObject:route]) {
                visible = true;
            }
            if ([[self selectedRoutes] count] == 0) {
                visible = true;
            }
            
            for (MKPolyline* poly in rdict[@"polylines"]) {
                
                
                bool onMap = [overlays containsObject:poly];
                //check that the polylines are on the map
                if (visible && !onMap) {
                    //NSLog(@"missing");
                    [self.mapView addOverlay:poly];
                } else if (!visible && onMap) {
                    [self.mapView removeOverlay:poly];
                }
                
                
            }
            updateMap = false;
        }
        [self redrawBadgeAnnotations];
        [self periodicUpdate];
    }
}

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    //erase the last optimum route badge positions, they will be
    //recomputed for the new region
    [[self optimumRouteBadgePositions] removeAllObjects];
    
    //record the map position to the datastore
    [OBRdataStore defaultStore].mapRegion = self.mapView.region;
    
    //redraw the overlays and annotations
    updateMap = true;
    [self updateMapNew];
    [self addStopsNearMapCenter];
}

-(void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated {
    
    if (mode == MKUserTrackingModeFollow) {
        [_trackButton setImage:[[[IOSImage alloc] init  ]imageWithFilename:@"TrackButton.png" Color:GREEN Size:60] forState:UIControlStateNormal];
    } else {
        [_trackButton setImage:[[[IOSImage alloc] init] imageWithFilename:@"TrackButton.png" Color:RED Size:60] forState:UIControlStateNormal];
    }
}

-(NSMutableDictionary*)getDictForRoute:(NSString*)route {
    return [[self data] objectForKey:route];
}

-(NSMutableDictionary*)getDictForOverlay:(MKPolyline*)poly {
    for (NSString* route in [[self data] allKeys]) {
        NSMutableDictionary* rdict = [[self data] objectForKey:route];
        for (MKPolyline* p in rdict[@"polylines"]) {
            if (poly == p) {
                return rdict;
            }
        }
    }
    return nil;
}





#pragma mark - Annotation Functions





-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation{
    
    
    //return if this is a user class
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    
    MKAnnotationView *annView= [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
    
    
    //get the properties
    OBRMapViewAnnotation* mva = annotation;
    UIColor* color = mva.color;
    NSString* title = mva.title;
    float alpha = mva.alpha;
    
    

    if ([mva.type isEqualToString:@"arrow"]) {
        
        MKAnnotationView *annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"arrow"];
        
        //get the vehicle for this annotation
        OBRVehicle* v = mva.IDdict[@"vehicle"];
        
        //get the rotated and scaled icon
        UIColor* color = [self getColorOfRoute:v.route];
        annView.image = [self getImageForAnnotation:color orient:mva.orientation speed:v.speed];
        
        //add a timetable button
        UIImage* i = [IOSI imageWithFilename:@"TimeTable.png" Size:50];
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        rightButton.frame = CGRectMake(0, 0, 50, 50);
        [rightButton setImage:i forState:UIControlStateNormal];
        [annView setRightCalloutAccessoryView:rightButton];
        
        //set the callout properties
        annView.canShowCallout = YES;
        annView.calloutOffset = CGPointMake(-5, 5);
        annView.layer.zPosition = 2000;
        return annView;
    }

    
    if ([mva.type isEqualToString:@"routebadge"]) {
        
        //set the image size
        annView.image = [IOSI imageWithFilename:@"Route.png" FillColor:color TextColor:BLACK
                                           Size:50 At:CGPointMake(50, 80) Text:title FontSize:40 Cache:true];
        //record this annotation into data
        NSMutableDictionary* rdict = mva.IDdict[@"rdict"];
        [rdict setObject:mva forKey:@"badgeAnnotation"];
        [rdict setObject:@NO forKey:@"hidden"];
        
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
    
    if ([mva.type isEqualToString:@"stopNearCenter"]) {
        
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

    
    if ([mva.type isEqualToString:@"POI"]) {

        //set the new POI as the selected annotation
        selectedAnnotation = mva;
        
        //set the image size
        annView.image = [IOSI imageWithFilename:@"HollowFlag.png" Color:YELLOW Size:60];
        annView.canShowCallout = true;
        annView.selected = true;
        annView.layer.zPosition = 2000;
        annView.centerOffset = CGPointMake(20, -30);
        
        //create a trash can image
        UIImage* trashIcon = [IOSI imageWithFilename:@"TrashIcon.png" Size:40];
        
        // Create a UIButton object to add on the
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        rightButton.frame = CGRectMake(0, 0, 40, 40);
        [rightButton setTitle:@"POITrash" forState:UIControlStateNormal];
        [rightButton setImage:trashIcon forState:UIControlStateNormal];
        [annView setRightCalloutAccessoryView:rightButton];
        
        return annView;
    }

    
    if ([mva.type isEqualToString:@"buslabel"]) {
        annView.image = [self getVehicleLabelImageForAnnotation:mva];
        annView.alpha = 0.85;
        annView.centerOffset = CGPointMake(0, 40);
        annView.layer.zPosition = 1999;
        return annView;
    }
    
    if ([mva.type isEqualToString:@"timeLabel"]) {
        annView.image = [[IOSLabel alloc] initWithText:@[mva.title] Color:YELLOW Sizex:-1 Sizey:30].image.image;
        annView.alpha = alpha;
        annView.centerOffset = CGPointMake(0, 20);
        annView.layer.zPosition = 1999;
        return annView;
    }

    
//    if ([mva.type isEqualToString:@"allBusLabel"]) {
//        
//        //default is a timeLabel
//        MKAnnotationView *annView = [[MKAnnotationView alloc] initWithAnnotation:annotation
//                                                                 reuseIdentifier:@"allBusLabel"];
//        annView.image = [[IOSLabel alloc] initNoBorderWithText:@[mva.title] Color:LEMON_CHIFFON Sizex:-1 Sizey:45].image.image;
//        
//        //set the callout properties
//        annView.canShowCallout = NO;
//        annView.centerOffset = CGPointMake(0, 35);
//        annView.alpha = mva.alpha;
//        annView.layer.zPosition = 1999;
//        //[busLabels addObject:mva];
//        return annView;
//    }
    
    return nil;
}

-(UIImage*)getVehicleLabelImageForAnnotation:(OBRMapViewAnnotation*) mva {
    OBRVehicle* v = mva.IDdict[@"vehicle"];
    
    if (v.number >=2000) {
        return  [[IOSLabel alloc] initWithText:@[mva.title,mva.subtitle] Color:LIGHT_SKY_BLUE Sizex:-1 Sizey:45].image.image;
    } else {
        if (v.adherence < -5) {
            return [[IOSLabel alloc] initWithText:@[mva.title,mva.subtitle] Color:RED Sizex:-1 Sizey:45].image.image;
        } else if (v.adherence<0) {
            return [[IOSLabel alloc] initWithText:@[mva.title,mva.subtitle] Color:LIGHT_YELLOW Sizex:-1 Sizey:45].image.image;
        } else {
            return [[IOSLabel alloc] initWithText:@[mva.title,mva.subtitle] Color:LIGHT_GREEN Sizex:-1 Sizey:45].image.image;
        }
    }
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
    OBRMapViewAnnotation* mva = view.annotation;
    if ([mva.type isEqualToString:@"POI"]) {
        //delete the poi
        [_mapView removeAnnotation:mva];
    } else if ([mva.type isEqualToString:@"stop"] ||
               [mva.type isEqualToString:@"stopNearCenter"]) {
        [self performSegueWithIdentifier:@"stopDetail" sender:self];
    } else if ([mva.type isEqualToString:@"allBusArrow"] ||
               [mva.type isEqualToString:@"arrow"]) {
        
        //turn the time table labels on or off
        if (timeTableSchs == nil) {
            
            //get the current weekdday
            int weekday = [TF currentWeekday];
            
            OBRVehicle* v = mva.IDdict[@"vehicle"];
            //OBRTrip* t = [db getTrip:v.trip];
            timeTableSchs = [db getSchForTrip:v.trip OnDay:weekday];
        } else {
            timeTableSchs = nil;
        }
        
    }
    
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
    NSLog(@"addAnnotationWithDict type = %@",type);
    
    if ([type isEqualToString:@"arrow"]) {
        OBRVehicle* v = iddict[@"vehicle"];
        NSTimeInterval now = [TF currentTimeSec];
        NSTimeInterval updateSec = v.lastMessageDate;
        if (v && (now - updateSec)>600) return;
    }
    
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
    
    if ([type isEqualToString:@"routebadge"]) {
        newAnnotation.color = iddict[@"rdict"][@"color"];
    }
    
    [self.mapView addAnnotation:newAnnotation];
}

-(void)addAnnotation:(NSString*)title
                 lat:(float)lat
                 lon:(float)lon
               color:(UIColor*)color
            subtitle:(NSString*)st
                type:(NSString*)t {
    NSLog(@"addAnnotation simple type = %@",t);
    
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
    
    [_mapView addAnnotation:mva];
}

-(void)removeAllStopAnnotations {
    NSMutableArray* deleteList = [[NSMutableArray alloc] init];
    for (OBRMapViewAnnotation* mva in [[self mapView] annotations]) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {
            if ([mva.type isEqualToString:@"stop"]) {
                [deleteList addObject:mva];
            }
            if ([mva.type isEqualToString:@"stopNearCenter"]) {
                [deleteList addObject:mva];
            }
        }
    }
    [_mapView removeAnnotations:deleteList];
}

//this function fills a dictionary with the optimumbadgepositions.  The
//dictionary is erased everytime the map region changes
-(OBRRoutePoints*)addOptimumBadgePositionForRoutestr:(NSString*)r {
    
    //return the last computed value
    if ([[self optimumRouteBadgePositions] objectForKey:r]) {
        if ([[[self optimumRouteBadgePositions]objectForKey:r] isKindOfClass:[OBRRoutePoints class]]) {
            return [[self optimumRouteBadgePositions] objectForKey:r];
        } else {
            return nil;
        }
    }
    
    //get the map dimensions
    MKCoordinateRegion reg  = [self.mapView region];
    
    //compute a smaller span for the route annotations to prevent badges at the
    //window edges
    float latSpanNorth = reg.span.latitudeDelta * 0.8;
    float latSpanSouth = reg.span.latitudeDelta * 0.7;
    float lonSpan = reg.span.longitudeDelta * 0.9;
    float Nlat = reg.center.latitude + latSpanNorth/2.0;
    float Slat = reg.center.latitude - latSpanSouth/2.0;
    float Elon = reg.center.longitude + lonSpan/2.0;
    float Wlon = reg.center.longitude - lonSpan/2.0;
    
    //calculate the optimum point for the badge
    OBRRoutePoints* optimumPoint;
    optimumPoint.distance = 0;
    
    //get the data for this route
    NSDictionary* rdict = [self getDictForRoute:r];
    NSArray* routePts = rdict[@"points"];
    
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
    
    //store the computed value
    if (!optimumPoint) {
        [[self optimumRouteBadgePositions] setObject:@"nil" forKey:r];
    } else {
        [[self optimumRouteBadgePositions] setObject:optimumPoint forKey:r];
    }
    
    return optimumPoint;
}


-(BOOL)isPointTooCloseToAnotherBadge:(OBRRoutePoints*) rp {
    //determine the min delat lat/lon badge spacing for this scale
    //this should be moved to the zoom screen becuas eit only needs
    //to be calculated once
    CGPoint p1 = CGPointMake(0, 35);
    CGPoint p2 = CGPointMake(0, 0);
    CLLocationCoordinate2D c1 = [self.mapView convertPoint:p1 toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D c2 = [self.mapView convertPoint:p2 toCoordinateFromView:self.mapView];
    float dla = c1.latitude - c2.latitude;
    float dlo = c1.longitude - c2.longitude;
    float mind = sqrt(dla*dla+dlo*dlo);
    
    for (OBRMapViewAnnotation* mva in self.mapView.annotations) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {
            if ([mva.type isEqualToString:@"routebadge"] ||
                [mva.type isEqualToString:@"allBusArrow"] ||
                [mva.type isEqualToString:@"busArrow"]) {
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

//this is called when the stops button is pressed
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
        //NSString* subtitle = [stop.streets substringToIndex:rb.location];
        
        //add annotation
        [self addAnnotation:title subTitle:@"" lat:stop.lat lon:stop.lon type:@"stop" orientation:0 updateTime:0 alpha:1.0 IDdict:@{@"stop":stop}];
    }
    
    //add the stops near the center
    [self addStopsNearMapCenter];
}

-(void)redrawBadgeAnnotations{
    
    NSTimeInterval start = [[OBRdataStore defaultStore] currentTimeSec];
    
    NSMutableSet* updatedAnnotations = [[NSMutableSet alloc] init];
    NSMutableSet* routesNeedingBadges = [[NSMutableSet alloc] init];
    NSMutableSet* routes = [[NSMutableSet alloc] initWithSet:[self allRoutes]];
    
    //add any needed badges annotations
    for (NSString* route in routes) {
        NSMutableDictionary* rdict = [self getDictForRoute:route];
        
        //is this route selected
        bool isSelected = [[self selectedRoutes] containsObject:route];
        rdict[@"selected"] = @NO;
        if (isSelected) rdict[@"selected"] = @YES;
    
        //are any selected
        bool noneSelected = false;
        rdict[@"anySelected"] = @YES;
        if ([self selectedRoutes].count == 0) {
            noneSelected = true;
            rdict[@"anySelected"] = @NO;
        }
        
        
        if (isSelected) {
            
            
            //are we currently displaying this route badge? if so find the annotation
            OBRMapViewAnnotation* annotation;
            for (OBRMapViewAnnotation* mva in [_mapView annotations]) {
                if (![mva isKindOfClass:[MKUserLocation class]]) {
                    if ([mva.type isEqualToString:@"routebadge"]) {
                        if (mva.IDdict[@"rdict"] == rdict) {
                            annotation = mva;
                        }
                    }
                }
            }
            
            
            //if the region has changed then get the best badge location for this region
            OBRRoutePoints* rp = [self addOptimumBadgePositionForRoutestr:route];
            if (rp) {
                rdict[@"inWindow"] = @YES;
                [[self badgesInWindow] addObject:route];
            } else {
                rdict[@"inWindow"] = @NO;
                [[self badgesInWindow] removeObject:route];
            }
            
            //label this annotation as being found.  Any annotation not in this set by the
            //end of the function will be removed
            
            
            if(annotation) {
                
                //update this annotation if it is displayed
                [updatedAnnotations addObject:annotation];
                if (rp.lat != annotation.coordinate.latitude ||
                    rp.lon != annotation.coordinate.longitude) {
                    CLLocationCoordinate2D p = CLLocationCoordinate2DMake(rp.lat, rp.lon);
                    annotation.coordinate = p;
                }
            } else {
                
                //we found an badge position in the window but no corresponding route badge
                //add the point to a list of route badges we want to add
                if (rp) {
                    
                    //i can't add these badges until I delete the unused badges
                    [routesNeedingBadges addObject:rp];
                }
            }
            
        } //here
        
    }
    
    
    //do not display more then twenty badge routes
    long numSelectedRoutes = [[self selectedRoutes] count];
    long numBadgesInWindow = [[self badgesInWindow] count];
    if ((numSelectedRoutes==0 && numBadgesInWindow>20) || showAllBuses) {
        [routesNeedingBadges removeAllObjects];
        [updatedAnnotations removeAllObjects];
    }
    
    
    //delete any annotations not in the updated set
    NSMutableSet* allRouteBadgeAnn = [[NSMutableSet alloc] init];
    for (OBRMapViewAnnotation* mva in _mapView.annotations) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {
            if ([mva.type isEqualToString:@"routebadge"]) {
                [allRouteBadgeAnn addObject:mva];
            }
        }
    }
    [allRouteBadgeAnn minusSet:updatedAnnotations];
    [_mapView removeAnnotations:[allRouteBadgeAnn allObjects]];
    
    //add any missing badges
    for (OBRRoutePoints* rp in routesNeedingBadges) {
        NSDictionary* rdict = [self getDictForRoute:rp.routestr];
        if (rp != nil) {
            [self addAnnotation:rp.routestr subTitle:@"none" lat:rp.lat lon:rp.lon type:@"routebadge" orientation:0 updateTime:0 alpha:1.0 IDdict:@{@"rdict":rdict}];
        }
    }
    
    NSTimeInterval end = [[OBRdataStore defaultStore] currentTimeSec];
    NSLog(@"redrawing badge annotations %f",end-start);
    
}



#pragma mark - Touch Events



-(IBAction)foundTap:(UITapGestureRecognizer *)recognizer {
    
    //disable the search
    db.searchSelection = nil;
    [self.searchButton setImage:[IOSI imageWithFilename:@"Search.png" Color:RED Size:60] forState:UIControlStateNormal];
 
    //compute the lat and lon of the tap
    CGPoint tPoint = [recognizer locationInView:self.mapView];
    CLLocationCoordinate2D tapPoint = [self.mapView convertPoint:tPoint toCoordinateFromView:self.mapView];
    

    //check to see if they have selected an annotation
    OBRMapViewAnnotation* closestAnn = nil;
    float closestDist = 1e9;
    for (OBRMapViewAnnotation* mva in _mapView.annotations) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {

            CGPoint aPoint = [_mapView convertCoordinate:mva.coordinate toPointToView:_mapView];
            float xd = tPoint.x - aPoint.x;
            float yd = tPoint.y - aPoint.y;
            float dd = sqrt(xd*xd+yd*yd);
            
            if (dd<closestDist) {
                closestDist = dd;
                closestAnn = mva;
            }
        }
    }
    
    //if they selected an annotation then return
    NSLog(@"closest annotation is type %@ at %f meters",closestAnn.type,closestDist);
    if (closestDist<30) {
        NSLog(@"tap close to annotation returning");
        return;
    }
    
    //if there is a selected bus then unselect it and return
    if (selectedVehicle) {
        selectedVehicle = nil;
        db.vehiclesModified = true;
        updateMap = true;
        return;
    }
    
    
    // reset all the selections if they tap on the map with a selection
    long numSelectedRoutes = [[self selectedRoutes] count];
    if (showStopMode == SELECTED || showSelectedBuses || numSelectedRoutes>0) {
        selectedVehicle = nil;
        [_selectedRoutes removeAllObjects];
        [_mapView removeOverlays:[_mapView overlays]];
        showSelectedBuses = false;
        showAllBuses = false;
        [self completeSelection];
        updateMap = true;
        
        lastShowStopMode = NONE;
        if (showStopMode == SELECTED) showStopMode = LOCAL;
        return;
    }
    
    
    
    //get the map dimensions
    MKCoordinateRegion r  = MKCoordinateRegionMake(tapPoint, MKCoordinateSpanMake(.004, .004));
    
    //find the set of routes in this small span
    [[self selectedRoutes] removeAllObjects];
    NSArray* tapRoutePts = [db getPointsForRegion:r];
    for (OBRRoutePoints* rp in tapRoutePts) {
        [[self selectedRoutes] addObject:rp.routestr];
        
        //remove all the overlays so they can be redrawn in the new color
        [_mapView removeOverlays:[_mapView overlays]];
    }
    
    //set the proper stop mode based on new selection
    if (showStopMode==LOCAL && self.selectedRoutes.count>0) showStopMode = SELECTED;
    if (showStopMode==SELECTED && self.selectedRoutes.count==0) showStopMode = LOCAL;
    
    [self completeSelection];
    updateMap = true;
    
}

-(void)completeSelection {
    
    NSLog(@"complete selection");
    
    //force the periodic update to redraw the stop icons
    lastShowStopMode = NONE;
    
    //reset the showSelectedBuses state
    showSelectedBuses = false;
    [self.showBusButton setImage:[IOSI imageWithFilename:@"BusButton.png" Color:RED Size:60] forState:UIControlStateNormal];
    
    if ([[self selectedRoutes] count] == 0) {
        //no routes selected
        _textBox.text = @"Tap route to select";
        
        //enable the show bus button to show all buses
        _showBusButton.enabled = true;
        
        
        //erase the route stops
        routeStops = nil;

    } else {
        //check if any of the selected routes have vehicles
        long numVehicles = [[self getSelectedRouteVehicles] count];
        
        //disable the show bus button if no vehicles
        if (numVehicles == 0) {
            _showBusButton.enabled = false;
        } else {
            _showBusButton.enabled = true;
        }
        
        //if we were showing all the buses switch to only showing the selected
        if (showAllBuses) {
            showAllBuses = false;
            showSelectedBuses = true;
        }
        
        //route selected (may be different then last selection)
        _textBox.text = @"Tap map to select a different route";
        
        //determine the stops on the new set of selected routes
        [self populateRouteStops];
        
    }
    
    //redraw the routes.
    [self redrawBadgeAnnotations];
    
}

-(NSMutableSet*)getSelectedRouteVehicles {
    NSTimeInterval currentSec = [TF currentTimeSec];
    long currentMOD = [TF currentMinOfDay];
    
    //find the vehicles for the selected routes
    NSMutableSet* selectedVehicles = [[NSMutableSet alloc] init];
    for (OBRVehicle* v in [db vehicles]) {
        NSString* rs = v.route;
        
        NSTimeInterval busUpdateSec = v.lastMessageDate;
        float elapsed = currentSec - busUpdateSec;
        if (elapsed<600) {
            
            if ([[self selectedRoutes] containsObject:rs] ) {
                
                //check the trip information on this vehicle
                OBRTrip* tripInfo = [db getTrip:v.trip];
                
                //check that the bus is still on its route +/- 20 min
                bool onSch = true;
                if (currentMOD > (tripInfo.latestTS - v.adherence + 2)) onSch = false;
                if (currentMOD < (tripInfo.earliestTS - v.adherence - 2)) onSch  = false;
                
                //check that they user isnt requesting this bus info
                bool vehicleRequested = false;
                if (v == selectedVehicle) vehicleRequested = true;
                

                //add the appropraite vehicles to the selected vehicles set
                if (onSch || vehicleRequested) {
                    NSLog(@"Rt:%@ num:%d on Sch MOD = %ld adher=%d  e=%d l=%d",v.route,v.number, currentMOD,v.adherence,tripInfo.earliestTS,tripInfo.latestTS);
                    if (v.number < 2000) {
                        
                        //check if the direction is correct
                        bool directionOK = true;
                        if ([v.direction isEqualToString:@"Eastbound"] && showBusMode == WB_BUS) directionOK = false;
                        if ([v.direction isEqualToString:@"Westbound"] && showBusMode == EB_BUS) directionOK = false;
                        if (directionOK) {
                        
                            //add this bus to the list
                            [selectedVehicles addObject:v];
                        }
                    }
                } else if (tripInfo == nil) {
                    NSLog(@"Rt:%@ num:%d off schedule no trip found for %@",v.route,v.number,v.trip);
                } else {
                    NSLog(@"Rt:%@ num:%d off schedule MOD = %ld adher=%d  e=%d l=%d",v.route,v.number,currentMOD,v.adherence,tripInfo.earliestTS,tripInfo.latestTS);
                    
                }
                
    
            }
        }
    }
    
    //get the weekday
    int day = [TF currentWeekday];
    NSString* dayStr = [NSString stringWithFormat:@"%d",day];
    
    for (NSString* route in _selectedRoutes) {

        
        
        //look for scheduled trips that do not have an assigned vehicle
        NSMutableArray* tripsForRoute = [[NSMutableArray alloc] initWithArray:[db getTripsForRoute:route]];
        
        //filter the trips by the current time
        long mod = [TF currentMinOfDay];
        NSMutableArray* toDelete = [[NSMutableArray alloc] init];
        for (OBRTrip* t in tripsForRoute) {
            
            //check if the direction is correct
            bool directionOK = true;
            if ([t.direction isEqualToString:@"Eastbound"] && showBusMode == WB_BUS) directionOK = false;
            if ([t.direction isEqualToString:@"Westbound"] && showBusMode == EB_BUS) directionOK = false;
            
            if (mod < t.earliestTS || t.latestTS < mod) {
                [toDelete addObject:t];
            } else if (![t.day containsString:dayStr]) {
                NSLog(@"%@ day:%@ cday:%@",t.tripStr,t.day,dayStr);
                [toDelete addObject:t];
            } else if (t.earliestTS<20 && t.latestTS>1300 && mod>200 && mod<1200) {
                [toDelete addObject:t];
            } else if (!directionOK) {
                [toDelete addObject:t];
            }
        }
        [tripsForRoute removeObjectsInArray:toDelete];
        
        //now eliminate any routes that have real time updates
        [toDelete removeAllObjects];
        for (OBRVehicle* v in selectedVehicles) {
            for (OBRTrip* t in tripsForRoute) {
                if ([self compareTrip:t withTripStr:v.trip]) {
                    [toDelete addObject:t];
                }
            }
        }
        [tripsForRoute removeObjectsInArray:toDelete];
        
        
        //get the schedule for each of the remaining trips
        int vbusNumer = 2000;
        for (OBRTrip* t in tripsForRoute) {
            NSArray* schs = [db getSchForTrip:t.tripStr  OnDay:day];
            NSLog(@"trip %@ schs %d",t.tripStr,schs.count);
            
            //find the best stop to now
            OBRScheduleNew* bestSch = nil;
            float bestMinDiff = 2000;
            float lastLat = 0;
            float lastLon = 0;
            for (OBRScheduleNew* s in schs) {
                float d = currentMOD - s.minOfDay;
                if (d<bestMinDiff && d<60 && d>0) {
                    //NSLog(@"trip %@ found A better time %d",t.tripStr,s.minOfDay);
                    lastLat = bestSch.stop.lat;
                    lastLon = bestSch.stop.lon;
                    bestMinDiff = d;
                    bestSch = s;
                }
            }
            
            if (bestSch != nil) {
                float dlat = bestSch.stop.lat - lastLat;
                float dlon = bestSch.stop.lon - lastLon;
                float orientation = atan2f(dlat, dlon);
                
                //convert min of day to secs
                float diffMin = currentMOD - bestSch.minOfDay;
                double busSec = currentSec - 60.0*(diffMin);
                
                NSLog(@"best Sch = %@",bestSch);
                NSString* vnumStr = [NSString stringWithFormat:@"%d",vbusNumer++];
                OBRVehicle* v = [db getVehicle:vnumStr];
                v.adherence = 0;
                v.direction = t.direction;
                v.number = vbusNumer;
                v.numString = vnumStr;
                v.lastMessageDate = busSec;
                v.lat = bestSch.stop.lat;
                v.lon = bestSch.stop.lon;
                v.orientation = orientation;
                v.route = route;
                v.speed = 0;
                v.trip = t.tripStr;
                [selectedVehicles addObject:v];
            }
            
            
            //add a virtual vehicle for these trips
            //do I have to add it to the database if the object is managed?
            
        }
    }
    
    return selectedVehicles;
}

-(BOOL)compareTrip:(OBRTrip*)t withTripStr:(NSString*) ts {
    
    //check that the incoming tripStrings are the short versions
    NSString* ts0 = [self getShortTripString:ts];
    NSString* ts1 = [self getShortTripString:t.tripStr];
    
    if ([ts0 isEqualToString:ts1]) {
        return true;
    } else {
        return false;
    }
}


-(NSString*)getShortTripString:(NSString*)ts {
    //if this has the full length tripstr then shorten it
    NSArray* sa = [ts componentsSeparatedByString:@"."];
    if (sa.count == 3) {
        ts = [NSString stringWithFormat:@"%@.%@",sa[0],sa[1]];
    }
    return ts;
}


-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view  {
    selectedAnnotation = nil;
    selectedVehicle = nil;
    selectedStop = nil;
    timeTableSchs = nil;
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"did select annotation view");
    
    //get new point information
    OBRMapViewAnnotation* mva = view.annotation;
    if (![mva isKindOfClass:[MKUserLocation class]]) {
        NSString* type = mva.type;
        NSLog(@"selected annotation is type %@",type);
        
        //set the selected vehicle
        if ([type isEqualToString:@"allBusArrow"] ||
            [type isEqualToString:@"arrow"]) {
            OBRVehicle* v = mva.IDdict[@"vehicle"];
            selectedAnnotation = mva;
            selectedVehicle = v;
            [[self selectedRoutes] removeAllObjects];
            [[self selectedRoutes] addObject:v.route];
            updateMap = true;
            return;
        }
        
        if ([type isEqualToString:@"stopNearCenter"] ||
            [type isEqualToString:@"stop"]) {
            OBRStopNew* stop = mva.IDdict[@"stop"];
            selectedAnnotation = mva;
            selectedStop = stop;
            _textBox.text =@"Press information button for more details";
            
            return;
        }
    }
}



#pragma mark - Overlays



-(MKOverlayView *)mapView:(MKMapView *)mapView  viewForOverlay:(id<MKOverlay>)overlay {
    if([overlay isKindOfClass:[MKPolyline class]]) {
        
        //
        NSDictionary* rdict = [self getDictForOverlay:overlay];
        UIColor* color = LIGHT_GRAY  ;//  rdict[@"color"];
        NSMutableSet* polyViews = rdict[@"polyViews"];
        
        //check if this route is selected
        NSString* route = rdict[@"route"];
        if ([_selectedRoutes containsObject:route]) {
            color = rdict[@"color"];
        } else {
            color = LIGHT_GRAY;
        }
        
        
        MKPolylineView *lineView = [[MKPolylineView alloc] initWithPolyline:overlay];
        lineView.lineWidth = 12;
        lineView.strokeColor = color;
        lineView.fillColor = color;
        
        //add this view to the data structure
        [polyViews addObject:lineView];
        
        return lineView;
    }
    return nil;
}


-(void) zoomToRoute {
    
    float minlat = 9999.0;
    float maxlat = -9999.0;
    float minlon = 9999.0;
    float maxlon = -9999.0;

        
    NSString* route = [[self selectedRoutes] anyObject];
    NSArray* rps = [db getPointsForRouteStr:route];
    for (OBRRoutePoints* rp in rps) {
        NSLog(@"route point %@",rp);
        if (rp.lat <minlat) minlat = rp.lat;
        if (rp.lat >maxlat) maxlat = rp.lat;
        if (rp.lon <minlon) minlon = rp.lon;
        if (rp.lon >maxlon) maxlon = rp.lon;
        
    }
    float centerlat = (minlat+maxlat)/2.0;
    float centerLon = (minlon+maxlon)/2.0;
    float latspan = 100000*(maxlat-minlat)*1.2;
    float lonspan = 100000*(maxlon-minlon)*1.2;
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(centerlat, centerLon);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(center, latspan, lonspan);
    [_mapView setRegion:region animated:true];

}

-(NSArray*)GeneratePolylines:(NSArray*)routePoints {
    //create the output set
    NSMutableArray* out = [[NSMutableArray alloc] init];
    
    //determine number of segments
    int minSeg = 999;
    int maxSeg = -999;
    for (OBRRoutePoints* rp in routePoints) {
        if (rp.segment>maxSeg) maxSeg = rp.segment;
        if (rp.segment<minSeg) minSeg = rp.segment;
    }
    
    for (int seg=minSeg ; seg<=maxSeg; seg++) {
        
        //determine number of points in this segment
        int np=0;
        NSString* routestr;
        for (OBRRoutePoints* rp in routePoints) {
            if (rp.segment == seg) {
                routestr = rp.routestr;
                np++;
            }
        }
        
        CLLocationCoordinate2D* pa = malloc(sizeof(CLLocationCoordinate2D)*np);
        
        int Indx = 0;
        for  (OBRRoutePoints* rp in routePoints) {
            if (rp.segment == seg) {
                pa[Indx++] = CLLocationCoordinate2DMake(rp.lat, rp.lon);
            }
        }
        
        if (Indx>0) {
            MKPolyline* routeLine = [MKPolyline polylineWithCoordinates:pa
                                                                  count:np ];
            [out addObject:routeLine];
        }
    }
    return out;
}

-(UIColor*) getColorOfRoute:(NSString*)route {
    return [[self routeColorDict] objectForKey:route];
}

-(void)cycleRoutesNew{
    
    
 //    //experiment with exchangeoverlay: withoverlay:
    

    //return if less then two routes displayed
    long count = self.selectedRoutes.count;
    if (count <2 && count != 0) return;
    
    //find the route on the bottom and top
    NSString* minRoute;
    NSString* maxRoute;
    long minZvalue =  LONG_MAX;
    long maxZvalue = LONG_MIN;

    NSArray* overlayArray = [_mapView overlays];
 
    
    //either cycle all routes or just selected
    NSMutableSet* routes = [[NSMutableSet alloc] init];
    if (_selectedRoutes.count == 0) {
        routes = [[NSMutableSet alloc] initWithSet:_allRoutes];
    } else {
        routes = [[NSMutableSet alloc] initWithSet:_selectedRoutes];
    }
    
    //find the lowest route
    for (NSString* route in routes) {
        NSMutableDictionary* rdict = [self getDictForRoute:route];
        bool inWindow = [rdict[@"inWindow"] boolValue];
        if (inWindow) {
            NSMutableSet* polylines = rdict[@"polylines"];
            for (MKPolyline* polyline in polylines) {
                long zp = [overlayArray indexOfObject:polyline];
                if (zp > maxZvalue) {
                    maxZvalue = zp;
                    maxRoute = [route copy];
                }
                if (zp<minZvalue) {
                    minZvalue = zp;
                    minRoute = [route copy];
                }
            }
        }
    }
    
    if (!minRoute) return;

    //change the zposition of the lowest overlay to be above the highest
    NSLog(@"moving %@ to the top",minRoute);
    NSMutableDictionary* rdict = [self getDictForRoute:minRoute];
    NSMutableSet* polylines = rdict[@"polylines"];
    for (MKPolyline* polyline in polylines) {
        //NSLog(@"moving polyline %@",polyline);
        [_mapView removeOverlay:polyline];
        [_mapView addOverlay:polyline];
    }
    [_mapView setNeedsDisplay];
    
    //determine if we are only showing the highlighted route
    //do not display more then twenty badge routes
    long numSelectedRoutes = [[self selectedRoutes] count];
    long numBadgesInWindow = [[self badgesInWindow] count];
    if ((numSelectedRoutes==0 && numBadgesInWindow>20) || showAllBuses) {
        //delete last badge
        for (OBRMapViewAnnotation* mva in _mapView.annotations) {
            if (![mva isKindOfClass:[MKUserLocation class]]) {
                if ([mva.type isEqualToString:@"routebadge"] ) {
                    [_mapView removeAnnotation:mva];
                    break;
                }
            }
        }
        
     //add new highlighted route badge
     OBRRoutePoints* rp = [self addOptimumBadgePositionForRoutestr:minRoute];
    [self addAnnotation:rp.routestr subTitle:@"none" lat:rp.lat lon:rp.lon type:@"routebadge" orientation:0 updateTime:0 alpha:1.0 IDdict:@{@"rdict":rdict}];

    }
    

    

    
}



#pragma mark - vehicle functions

-(void)periodicUpdate{
    //make sure the selected annotation is still selected
    if (selectedAnnotation) {
        [_mapView selectAnnotation:selectedAnnotation animated:false];
    }
    
    //set the title bar
    if (_selectedRoutes.count >0) {
        NSString* label = @"Selected Rts:";
        for (NSString* r in _selectedRoutes) {
            if (![label isEqualToString:@"Selected Rts:"]) {
                label = [label stringByAppendingString:@","];
            }
            label = [label stringByAppendingFormat:@"%@",r];
        }
        
        //check for a selected vehicle
        if (selectedVehicle) {
            label = [NSString stringWithFormat:@"Selected Bus:%d Rt:%@",selectedVehicle.number,selectedVehicle.route];
        }
        
        selectedLabel.text = label;
    } else if (selectedVehicle) {
        NSString* label = [NSString stringWithFormat:@"Selected Bus:%d",selectedVehicle.number];
        selectedLabel.text = label;
    } else {
        selectedLabel.text = @"";
    }
    
    
    
    //experiment with setting the bus icon color here

    
    if (showBusMode != lastShowBusMode) {
        lastShowBusMode = showBusMode;
        
        
        if (showBusMode == NO_BUS) {
            [self.showBusButton setImage:[IOSI imageWithFilename:@"BusButton.png" Color:RED Size:60]
                        forState:UIControlStateNormal];
            NSLog(@"no bus icon");
        } else if (showBusMode == EB_BUS) {
            NSLog(@"eb bus icon");
            [self.showBusButton setImage:[IOSI imageWithFilename:@"BusButton.png" FillColor:GREEN TextColor:RED Size:60 At:CGPointMake(110, 5) Text:@"EB" FontSize:60 Cache:true]
                            forState:UIControlStateNormal];
            
        } else if (showBusMode == WB_BUS) {
            NSLog(@"eb bus icon");
            [self.showBusButton setImage:[IOSI imageWithFilename:@"BusButton.png" FillColor:GREEN TextColor:RED Size:60 At:CGPointMake(100, 5) Text:@"WB" FontSize:60 Cache:true]
                                forState:UIControlStateNormal];
            
        } else if (showBusMode == ALL_BUS) {
            NSLog(@"eb bus icon");
                [self.showBusButton setImage:[IOSI imageWithFilename:@"BusButton.png" Color:GREEN Size:60]
                        forState:UIControlStateNormal];
            
        }


    }
    
    
    //experiment with setting the stops icon color here
    if (showStopMode != NONE) {
        [self.showStopsButton setImage:[IOSI imageWithFilename:@"BusStopButton.png" Color:GREEN Size:60]
                            forState:UIControlStateNormal];
    } else {
        [self.showStopsButton setImage:[IOSI imageWithFilename:@"BusStopButton.png"  Color:RED Size:60]
                            forState:UIControlStateNormal];
    }
    
    
    
    //move any buses
    [self updateBusPositions];
    
    //update the stops
    if (lastShowStopMode != showStopMode) {
        lastShowStopMode = showStopMode;
        
        //erase all the current stops in case the mode has changed
        [self removeAllStopAnnotations];
        
        if (showStopMode == SELECTED) {
            [self addStopAnnotations];
        } else if (showStopMode == LOCAL) {
            [self addStopsNearMapCenter];
        }
    }
    
    //update the time labels
    if (timeTableSchs != lastTimetableSchs) {
        lastTimetableSchs = timeTableSchs;
        NSLog(@"found a change in the time table sch");
        
        
        //delete the time labels
        NSMutableArray* toDelete = [[NSMutableArray alloc] init];
        for (OBRMapViewAnnotation* mva in _mapView.annotations) {
            if (![mva isKindOfClass:[MKUserLocation class]]) {
                if ([mva.type isEqualToString:@"timeLabel"]) {
                    [toDelete addObject:mva];
                }
            }
        }
        [_mapView removeAnnotations:toDelete];
        
        
        //add the new labels
        if (timeTableSchs != nil) {
            //add the time labels
            long lastMOD = 0;
            long cMOD = [TF currentMinOfDay];
            for (OBRScheduleNew* sch in timeTableSchs) {
                if (sch.minOfDay != lastMOD) {
                    lastMOD = sch.minOfDay;
                    OBRStopNew* stop =sch.stop;
                    
                    //make the past time labels very translucent
                    float alpha = 0.2;
                    long bMOD = sch.minOfDay - selectedVehicle.adherence;
                    if (bMOD>=cMOD) alpha = 0.85;
                    
                    //create the time label adjusted by the adherence
                    NSString* title = [TF minOfDay2Str:bMOD];
                    
                    [self addAnnotation:title subTitle:@"" lat:stop.lat lon:stop.lon type:@"timeLabel" orientation:0 updateTime:0 alpha:alpha IDdict:@{}];
                }
            }
        }
    }
}


//called every 0.2 secs called from update
-(void)updateBusPositions{
    
    
    //return if vehciles have not changed
    if (!db.vehiclesModified) return;
    db.vehiclesModified = false;
    
    NSLog(@"update bus positions show:%d  showall:%d",showSelectedBuses,showAllBuses);
    
    //find all the buses
    NSMutableArray* selectedBusAnnotations = [[NSMutableArray alloc] init];
    NSMutableArray* allBusAnnotations = [[NSMutableArray alloc] init];
    NSMutableArray* selectedBusLabels = [[NSMutableArray alloc] init];
    NSMutableArray* allBusLabels = [[NSMutableArray alloc] init];
    for (OBRMapViewAnnotation* mva in _mapView.annotations) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {
            if ([mva.type isEqualToString:@"arrow"] ) {
                [selectedBusAnnotations addObject:mva];
            }
            if ([mva.type isEqualToString:@"allBusArrow"] ) {
                [allBusAnnotations addObject:mva];
            }
            
            if ([mva.type isEqualToString:@"buslabel"]) {
                [selectedBusLabels addObject:mva];
            }
            if ([mva.type isEqualToString:@"allBusLabel"]) {
                [allBusLabels addObject:mva];
            }
            
        }
    }
    
    //update or delete all the bus annotations
    if (!showSelectedBuses) {
        showSelectedBusLabels = false;
        [self.mapView removeAnnotations:selectedBusAnnotations];
    } else {
        showSelectedBusLabels = true;
         [self updateSelectedBusAnnotations:selectedBusAnnotations];
    }
    
    
    //update or delete all the bus labels
    if (showSelectedBusLabels && !selectedVehicle) {
        [self updateSelectedBusLabels:selectedBusLabels];
    } else {
        [self.mapView removeAnnotations:selectedBusLabels];
    }
    

    
    [self redrawBadgeAnnotations];
}

//-(void)updateAllBusLabels:(NSMutableArray*) busLabels {
//    
//    NSLog(@"update all bus labels");
//    bool labelsNeedUpdate = true;
//    if (labelsNeedUpdate) {
//        labelsNeedUpdate = false;
//        
//        //delete labels if there is a selected icon
//        if (selectedAnnotation != nil) {
//            [_mapView removeAnnotations:busLabels];
//            [busLabels removeAllObjects];
//            return;
//        }
//        
//        //get the visible annotations
//        NSSet* visible = [_mapView annotationsInMapRect:_mapView.visibleMapRect];
//        NSMutableSet* visibleBusIcons = [[NSMutableSet alloc] init];
//        
//        //limit set to bus icons
//        for (OBRMapViewAnnotation* mva in visible) {
//            if (![mva isKindOfClass:[MKUserLocation class]]) {
//                if ([mva.type isEqualToString:@"allBusArrow"]) {
//                    [visibleBusIcons addObject:mva];
//                }
//            }
//        }
//        
//        //delete labels if more then five
//        if (visibleBusIcons.count >5) {
//            [_mapView removeAnnotations:busLabels];
//            [busLabels removeAllObjects];
//            return;
//        }
//        
//        //update and remove annotations
//        NSMutableArray* forDeletion = [[NSMutableArray alloc] init];
//        for (OBRMapViewAnnotation* mva in busLabels) {
//            OBRMapViewAnnotation* busAnnotation = mva.IDdict[@"busAnnotation"];
//            if ([visibleBusIcons containsObject:busAnnotation] ) {
//                //update
//                mva.coordinate = busAnnotation.coordinate;
//            } else {
//                //mark for deletion
//                [forDeletion addObject:mva];
//            }
//        }
//        
//        //delete any buslabels that were not visible
//        [_mapView removeAnnotations:forDeletion];
//        [busLabels removeObjectsInArray:forDeletion];
//        
//        //add any new bus labels needed
//        for (OBRMapViewAnnotation* visibleBus in visibleBusIcons) {
//            bool found = false;
//            for (OBRMapViewAnnotation* busLabel in busLabels) {
//                OBRMapViewAnnotation* busForLabel = busLabel.IDdict[@"busAnnotation"];
//                if (busForLabel == visibleBus) {
//                    found = true;
//                    break;
//                }
//            }
//            if (!found) {
//                //add this new bus
//                OBRVehicle* v = visibleBus.IDdict[@"vehicle"];
//                NSString* label = [self buildBusLabelTitleForVehicle:v];
//                [self addAnnotation:label
//                           subTitle:@""
//                                lat:visibleBus.coordinate.latitude
//                                lon:visibleBus.coordinate.longitude
//                               type:@"allBusLabel"
//                        orientation:0
//                         updateTime:[TF currentTimeSec]
//                              alpha:0.75
//                             IDdict:@{@"busAnnotation":visibleBus}];
//            }
//        }
//        
//        //add the route if their is only one visible route
//    }
//}

-(NSString*)buildBusLabelTitleForVehicle:(OBRVehicle*) v {
    NSString* dir = @"?";
    if ([v.direction isEqualToString:@"Westbound"]) dir = @"WB";
    if ([v.direction isEqualToString:@"Eastbound"]) dir = @"EB";
    NSString* label;
    if ([dir isEqualToString:@"?"] ) {
        label = [NSString stringWithFormat:@"Bus %d ",v.number];
    } else {
        label= [NSString stringWithFormat:@"Bus %d  Rt %@ %@",v.number,v.route,dir];
    }
    return label;
}

-(void)updateSelectedBusLabels:(NSArray*) busLabels {
    
    //loop through all the annotations
    for (OBRMapViewAnnotation* mva in _mapView.annotations) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {
     
            //find the buses
            if ([mva.type isEqualToString:@"arrow"]) {
                OBRVehicle* v = mva.IDdict[@"vehicle"];
                
                //find the coresponding label
                OBRMapViewAnnotation* label = nil;
                for (OBRMapViewAnnotation* mvaLabel in _mapView.annotations) {
                    if (![mvaLabel isKindOfClass:[MKUserLocation class]]) {
                        if ([mvaLabel.type isEqualToString:@"buslabel"]) {
                            OBRVehicle* vLabel = mvaLabel.IDdict[@"vehicle"];
                            if (vLabel == v) {
                                label = mvaLabel;
                                break;
                            }
                        }
                    }
                }
                
                if (label) {
                    //update
                    MKAnnotationView* av = [self.mapView viewForAnnotation:label];
                    label.coordinate = mva.coordinate;
                    label.title = [self makeTitleForVehicle:v];
                    label.subtitle = [self makeSubtitleForVehicle:v];
                    av.image =[self getVehicleLabelImageForAnnotation:mva];
                } else {
                    //add
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
                
            }
        }
    }
    
    //check for any bus labels missing a bus
    NSMutableArray* toDelete = [[NSMutableArray alloc] init];
    //loop through all the annotations
    for (OBRMapViewAnnotation* mva in _mapView.annotations) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {
            
            
            //find the labels
            if ([mva.type isEqualToString:@"buslabel"]) {
                OBRVehicle* v = mva.IDdict[@"vehicle"];
                
                //find the coresponding bus
                OBRMapViewAnnotation* Bus = nil;
                for (OBRMapViewAnnotation* mvaArrow in _mapView.annotations) {
                    if (![mvaArrow isKindOfClass:[MKUserLocation class]]) {
                        if ([mvaArrow.type isEqualToString:@"arrow"]) {
                            OBRVehicle* vv = mvaArrow.IDdict[@"vehicle"];
                            if (vv == v) {
                                Bus = mvaArrow;
                            }
                        }
                    }
                }
                
                
                if (!Bus) {
                    [toDelete addObject:mva];
                }
            }
        }
    }
    [_mapView removeAnnotations:toDelete];
}



-(void)updateSelectedBusAnnotations:(NSMutableArray*) busAnnotations {
    
    NSLog(@"update selected bus annotations");

    //find the vehicles for the selected routes
    NSMutableSet* selectedVehicles = [self getSelectedRouteVehicles];
    
    //clean any bus annotations off the map that arn't in selected vehicles
    NSMutableArray* deleteMe = [[NSMutableArray alloc] init];
    for (OBRMapViewAnnotation* mva in busAnnotations) {
        OBRVehicle* v = mva.IDdict[@"vehicle"];
        if (![selectedVehicles containsObject:v]) {
            [deleteMe addObject:mva];
        }
    }
    [_mapView removeAnnotations:deleteMe];
    
    
    
    //loop through all map annotations looking for any that correspond to
    //selected vehicles and add them to the ...needingUpdatesSet
    NSMutableSet* annotationsNeedingUpdates = [[NSMutableSet alloc] init];
    NSMutableSet* vehiclesNeedingUpdates = [[NSMutableSet alloc] init];
    for (OBRMapViewAnnotation* mva in _mapView.annotations) {
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
        
        //build the title and subtitle
        NSString* t = [self makeTitleForVehicle:v];
        NSString* st = [self makeSubtitleForVehicle:v];
        
        //check the last message date and filter buses with data older then 10 min
        NSTimeInterval busUpdateSec = v.lastMessageDate;
        NSTimeInterval currentSec = [TF currentTimeSec];
        float elapsed = currentSec - busUpdateSec;
        if (elapsed < 600) {
            
            //add a new annotation if not found
            [self addAnnotation:t
                       subTitle:st
                            lat:v.lat
                            lon:v.lon
                           type:@"arrow"
                    orientation:v.orientation
                     updateTime:v.lastMessageDate
                          alpha:1.0
                         IDdict:@{@"vehicle":v}];
            
        }
    }
    
    //update the vehicle annotations alreay present
    for (OBRMapViewAnnotation* mva in annotationsNeedingUpdates) {
        OBRVehicle* v = mva.IDdict[@"vehicle"];
        
        if (v == selectedVehicle) {
            //trigger the time table labels to redraw with new data
            lastTimetableSchs = nil;
            
        }
        
        CLLocationCoordinate2D point = CLLocationCoordinate2DMake(v.lat, v.lon);
        MKAnnotationView* av = [self.mapView viewForAnnotation:mva];
        mva.coordinate = point;
        if ([mva.type isEqualToString:@"arrow"]) {
            
            UIColor* color = [[self routeColorDict] objectForKey:v.route];
            av.image = [self getImageForAnnotation:color orient:v.orientation speed:v.speed];
            mva.subtitle = [self makeSubtitleForVehicle:v];
            mva.title = [self makeTitleForVehicle:v];
            
            
        }
    }
}

//-(void)updateAllBusAnnotations:(NSMutableArray*) busAnnotations{
//  
//    NSLog(@"update all bus annotations");
//    
//    //check if these annotations exist
//    NSMutableSet* annotationsNeedingUpdates = [[NSMutableSet alloc] init];
//    NSMutableSet* vehiclesNeedingUpdates = [[NSMutableSet alloc] init];
//    for (OBRMapViewAnnotation* mva in _mapView.annotations) {
//        if (![mva isKindOfClass:[MKUserLocation class]]) {
//            OBRVehicle* v = mva.IDdict[@"vehicle"];
//            if ([mva.type isEqualToString:@"allBusArrow"]) {
//                [vehiclesNeedingUpdates addObject:v];
//                [annotationsNeedingUpdates addObject:mva];
//            }
//        }
//    }
//    
//    //determine vehicles without annotations
//    NSMutableSet* vehiclesWithoutAnnotation = [[NSMutableSet alloc] initWithArray:[db vehicles]];
//    [vehiclesWithoutAnnotation minusSet:vehiclesNeedingUpdates];
//    
//    //add the new vehicles
//    for (OBRVehicle* v in vehiclesWithoutAnnotation) {
//        
//        long strLen = [v.numString length];
//        if (strLen <=3 ) {
//            
//            //rebuild the strings
//            NSString* t = [self makeTitleForVehicle:v];
//            NSString* st = [self makeSubtitleForVehicle:v];
//            
//            //check the last message date and filter buses with data older then 30 min
//            NSTimeInterval busUpdateSec = v.lastMessageDate;
//            NSTimeInterval currentSec = [TF currentTimeSec];
//            float elapsed = currentSec - busUpdateSec;
//            if (elapsed < 600) {
//                
//                //add a new annotation if not found
//                [self addAnnotation:t
//                           subTitle:st
//                                lat:v.lat
//                                lon:v.lon
//                               type:@"allBusArrow"
//                        orientation:v.orientation
//                         updateTime:v.lastMessageDate
//                              alpha:1.0
//                             IDdict:@{@"vehicle":v}];
//            }
//            
//        }
//    }
//    
//    //update the vehicle annotations alreay present
//    for (OBRMapViewAnnotation* mva in annotationsNeedingUpdates) {
//        OBRVehicle* v = mva.IDdict[@"vehicle"];
//        if (v.lat != mva.coordinate.latitude || v.lon != mva.coordinate.longitude) {
//            CLLocationCoordinate2D point = CLLocationCoordinate2DMake(v.lat, v.lon);
//            MKAnnotationView* av = [self.mapView viewForAnnotation:mva];
//            mva.coordinate = point;
//            UIColor* color = [[self routeColorDict] objectForKey:v.route];
//            av.image = [self getImageForAnnotation:color orient:v.orientation speed:v.speed];
//        }
//    }
//}

-(NSString*)makeTitleForVehicle:(OBRVehicle*)v {
    if ([v.direction isEqualToString:@"Eastbound"]) {
        if (v.number<2000) {
            return [NSString stringWithFormat:@"Bus %d   Rt:%@ EB",v.number,v.route];
        } else {
            return [NSString stringWithFormat:@"Bus ???   Rt:%@ EB",v.route];
        }
    } else {
        if (v.number<2000) {
            return [NSString stringWithFormat:@"Bus %d   Rt:%@ WB",v.number,v.route];
        } else {
            return [NSString stringWithFormat:@"Bus ???   Rt:%@ WB",v.route];
        }
    }
}

-(NSString*)makeSubtitleForVehicle:(OBRVehicle*)v {
    NSString* adStr = [self adherenceStr:v.adherence];
    if (v.number>=2000) adStr = @" Scheduled";
    NSString* timeStr = [[[IOSTimeFunctions alloc] init] localTimehhmmssa:v.lastMessageDate];
    NSString* labelst = [NSString stringWithFormat:@"%@  %@",timeStr,adStr];
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






#pragma mark - other functions




-(void) populateRouteStops{
    
    //alloc a new array containing all the stops
    routeStops = [[NSMutableArray alloc] init];
    
    //add the stops for each selected route
    for (NSString* rs in self.selectedRoutes) {
        
        NSArray* srs = [[OBRdataStore defaultStore] getStopsForRoutestr:rs];
        
        [routeStops addObjectsFromArray:srs];
    }
}


-(float)distanceRP:(OBRRoutePoints*)start
                p2:(OBRRoutePoints*)end {
    float x = (start.lat - end.lat)*(start.lat - end.lat);
    float y = (start.lon - end.lon)*(start.lon - end.lon);
    return  111000*sqrt(x+y);
}


-(double)metersBetweenLat1:(double)lat1 Lon1:(double)lon1
                      Lat2:(double)lat2 Lon2:(double)lon2 {
    double x = 111122.0*(lat1-lat2);
    double y = 102288.0*(lon1-lon2);
    return sqrt(x*x+y*y);
}


//-(NSString*)localTime:(NSDate*)date{
//    NSDateFormatter* df = [[NSDateFormatter alloc] init];
//    NSTimeZone* tz = [NSTimeZone timeZoneWithName:@"HST"];
//    [df setDateFormat:@"MM-dd HH:mm:ss"];
//    [df setTimeZone:tz];
//    NSString* dateStr =[df stringFromDate:date];
//    return dateStr;
//}
//
//
//-(NSString*)localTimeI:(NSTimeInterval)interval{
//    NSDate* date = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:interval];
//    return [self localTime:date];
//}







#pragma mark - button Actions





-(IBAction)pressedShowStops:(id)sender {
    
    long numSelected = _selectedRoutes.count;
    if (showStopMode != NONE) {
        showStopMode = NONE;

        [_showStopsButton setImage:[IOSI imageWithFilename:@"BusStopButton.png" Color:RED Size:60]
                          forState:UIControlStateNormal];
        
    } else {
        _textBox.text = @"Select Stop for Detailed Information";
        [_showStopsButton setImage:[IOSI imageWithFilename:@"BusStopButton.png" Color:GREEN Size:60]
                              forState:UIControlStateNormal];
        if (numSelected>0) {
            showStopMode = SELECTED;
        } else {
            showStopMode = LOCAL;
        }
    }
}

-(IBAction)pressedSearch:(id)sender {
    
    [[self selectedRoutes] removeAllObjects];
    
    if (db.searchSelection == nil) {
        selectedStop = nil;
        selectedVehicle = nil;
        selectedLabel.text = @"";
        showStopMode = NONE;
        [self performSegueWithIdentifier:@"RouteToSearchSegue" sender:self];
    } else {
        db.searchSelection = nil;
        
        //remove any selected routes
        if (showStopMode == SELECTED) showStopMode = LOCAL;
        [self completeSelection];
        [self.searchButton setImage:[IOSI imageWithFilename:@"Search.png" Color:RED Size:60]
                           forState:UIControlStateNormal];
    }
    updateMap = true;
}

//function is called when the stops button is activated or the region changes
-(void)addStopsNearMapCenter{
    
    if (showStopMode != LOCAL) return;
    //if (!showLocalStops) return;
    
    //get the location of the center of the map
    CLLocationCoordinate2D center = _mapView.region.center;
    
    //find the new stops in range
    NSMutableSet* nearCenter = [[NSMutableSet alloc] init];
    for (OBRStopNew* stop in [db stops]) {
        
        //add stops near crosshairs
        float d = [self metersBetweenLat1:center.latitude Lon1:center.longitude Lat2:stop.lat Lon2:stop.lon];
        if (d<1000) {
            [nearCenter addObject:stop];
        }
    }
    
    //remove any stops that arnt in one or the other sets
    for (OBRMapViewAnnotation* mva in self.mapView.annotations) {
        if (![mva isKindOfClass:[MKUserLocation class]]) {
            if ([mva.type isEqualToString:@"stopNearCenter"]) {
                bool found = false;
                for (OBRStopNew* stop in nearCenter) {
                    if (stop.lat == mva.coordinate.latitude &&
                        stop.lon == mva.coordinate.longitude) {
                        found = true;
                        break;
                    }
                }
                if (!found) [self.mapView removeAnnotation:mva];  //question this step
            }
        }
    }
    
    //add any stops that aren't already present
    //add any stops that aren't already present
    for (OBRStopNew* stop in nearCenter) {
        bool found = false;
        for (OBRMapViewAnnotation* mva in self.mapView.annotations) {
            if (stop.lat == mva.coordinate.latitude &&
                stop.lon == mva.coordinate.longitude) {
                found = true;
                break;
            }
        }
        [self addAnnotation:@"stop" subTitle:@"" lat:stop.lat lon:stop.lon type:@"stopNearCenter" orientation:0 updateTime:0 alpha:1.0 IDdict:@{@"stop":stop}];
    }
}

- (IBAction)pressedTrack:(id)sender {
    if (_mapView.userTrackingMode == MKUserTrackingModeNone) {
        _mapView.userTrackingMode = MKUserTrackingModeFollow;
    } else {
        _mapView.userTrackingMode = MKUserTrackingModeNone;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if ([alertView.title isEqualToString:@"Show All Buses?"]) {
        
        //return if this is just an acknowledgement
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]) {
            showAllBuses = true;
            [self.showBusButton setImage:[IOSI imageWithFilename:@"BusButton.png"
                                                           Color:GREEN Size:60]
                                forState:UIControlStateNormal];
            db.vehiclesModified = true;
            
        } else {
            showAllBuses = false;
        }

    }
    [self redrawBadgeAnnotations];
}

- (IBAction)pressedShowBuses:(id)sender {
    
    //allow immediate updating of the buses
    db.vehiclesModified = true;
    
    long numSelected = _selectedRoutes.count;
    

    if (numSelected>0) {
        if (showBusMode == NO_BUS && numSelected>0) {
            showBusMode = ALL_BUS;
            showSelectedBuses = true;
        } else if (showBusMode == ALL_BUS && numSelected>0) {
            showBusMode = EB_BUS;
            showSelectedBuses = true;
        } else if (showBusMode == EB_BUS && numSelected>0 ) {
            showBusMode = WB_BUS;
            showSelectedBuses = true;
        }else if (showBusMode == WB_BUS) {
            showBusMode = NO_BUS;
            showSelectedBuses = false;
        }
    } else {
        //turn off the bus button
        showBusMode = NO_BUS;
        showSelectedBuses = false;
    }
    

    [self redrawBadgeAnnotations];
}



@end
