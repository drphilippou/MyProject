//
//  OBRRouteDetailListVC.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/7/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRRouteDetailListVC.h"

@interface OBRRouteDetailListVC () {
    float maxlat;
    float minlon;
    float minlat;
    float maxlon;
    bool routeOverlayAdded;
    NSTimer* updateRouteTimer;
    OBRdataStore* db;
    OBRRouteOverlay* ro;
    IOSImage* IOSI;
}
@property (nonatomic) NSArray* route;
@property (weak, nonatomic) IBOutlet MKMapView *detailMap;
@property (weak, nonatomic) IBOutlet UITableView *tableView;



@end

@implementation OBRRouteDetailListVC

//- (id)initWithStyle:(UITableViewStyle)style
//{
//    self = [super initWithStyle:style];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    routeOverlayAdded = false;
    
    //init local variables
    maxlat = -999;
    minlat = -999;
    maxlon = -999;
    minlon = -999;
    NSLog(@"resetting local variables");
    
    //set a pointer to the datastore
    db = [OBRdataStore defaultStore];
    ro = [[OBRRouteOverlay alloc] init];
    IOSI = [[IOSImage alloc] init];
    
    //load the chosen route
    OBRsolvedRouteRecord* s = [db chosenRoute];
    _route = [s convertToArrayWithTime:s];
}

-(void)viewWillAppear:(BOOL)animated {
    [self updateRouteInfo];
    updateRouteTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                        target:self
                                                      selector:@selector(updateRouteInfo)
                                                      userInfo:nil
                                                       repeats:YES];
    
    [self populateMap];
    [self.tableView flashScrollIndicators];
}

-(void)viewDidAppear:(BOOL)animated {
    //set guiding to prevent database updates while in guidance views
    db.guiding = true;
}

-(void)viewWillDisappear:(BOOL)animated {
    [updateRouteTimer invalidate];
    updateRouteTimer = nil;
    
    //disable the guiding (updates do not occur while guiding)
    db.guiding = false;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _route.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OBRsolvedRouteRecord* r = _route[indexPath.row];
    if (r.type == TIMESTAMP) return 20;
    if (r.type == WALK) return 56;
    if (r.type == STOP) return 60;
    return 70;
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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //tvp = tableView;
    
    //the number of cells is one greater then the number of rows in the _route array
    //the last one being the map.
    if (indexPath.row >= _route.count) {
        static NSString *CellIdentifier = @"RouteDetailMap";
        OBRmapDetailTVCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            [tableView registerNib:[UINib nibWithNibName:@"OBRmapDetailTVCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        }
        _detailMap = cell.mapRef;
        [_detailMap setDelegate:self];
        return cell;
    }
    
    OBRsolvedRouteRecord* r = _route[indexPath.row];
    if ([r isStop]) {
        
        //if it is a stop description get a stop cell
        static NSString *CellIdentifier = @"RouteDetailStop";
        OBRStopDescriptionTVCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            [tableView registerNib:[UINib nibWithNibName:@"OBRStopDescriptionTVCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        }
        
        return cell;
    } else if ([r isRoute]) {
        
        //if it is a route then get the bus cell
        static NSString* ci = @"RouteDetailBus";
        OBRBusDescriptionTVCell* c = [tableView dequeueReusableCellWithIdentifier:ci];
        if (c == nil) {
            [tableView registerNib:[UINib nibWithNibName:@"OBRBusDescriptionTVCell" bundle:nil] forCellReuseIdentifier:ci];
            
            c = [tableView dequeueReusableCellWithIdentifier:ci];
        }
        
        return c;
    } else if ([r isWalk]) {
        // This is a walking cell
        static NSString* ci = @"routeDetailWalk";
        OBRBusDescriptionTVCell* c = [tableView dequeueReusableCellWithIdentifier:ci];
        if (c == nil) {
            [tableView registerNib:[UINib nibWithNibName:@"OBRwalkTVCell" bundle:nil] forCellReuseIdentifier:ci];
            
            c = [tableView dequeueReusableCellWithIdentifier:ci];
        }
        
        return c;
        
    } else {
        // a timestamp is the default
        NSString* ci = @"timeStampCell";
        OBRTimestampTVCell* c = [tableView dequeueReusableCellWithIdentifier:ci];
        if (c == nil) {
            [tableView registerNib:[UINib nibWithNibName:@"OBRTimestampTVCell" bundle:nil] forCellReuseIdentifier:ci];
            c = [tableView dequeueReusableCellWithIdentifier:ci];
        }
        return c;
    }
}



-(NSString*)timestring:(int)min {
    int h = (int) min/60;
    int m = min - (60*h);
    if (h<12) {
        if (h==0) h=12;
        return [NSString stringWithFormat:@" %d:%02d AM",h,m];
    } else {
        if (h>=13) {
            h = h-12;
            if (h==12 & m==00) {
                h=11;
                m=59;
            }
        }
        return [NSString stringWithFormat:@" %d:%02d PM",h,m];
    }
}

-(void)expandBoundarylat:(float)lat lon:(float)lon {
    if (minlat == -999 || minlon == -999 || maxlat == -999 || maxlon == -999) {
        minlat = lat;
        maxlat = lat;
        minlon = lon;
        maxlon = lon;
        NSLog(@"setting first point");
        return;
    }
    
    if (lat > maxlat) maxlat = lat;
    if (lat < minlat) minlat = lat;
    if (lon > minlon) minlon = lon;
    if (lon < maxlon) maxlon = lon;
}

-(void)checkBoundary{
    if (maxlat >23 || minlat <20) {
        maxlat = 22;
        minlat = 21;;
        NSLog(@"Using lat limits");
    }
    if (maxlon > -156 || minlon <-159) {
        maxlon = -157;
        minlon = -158;
        NSLog(@"Using lon limits");
    }
}

-(void)resetBoundary{
    minlat = -999;
    maxlat = -999;
    minlon = -999;
    maxlon = -999;
}

-(void)addAnnotation:(NSString*)title lat:(float)lat lon:(float) lon color:(int)color type:(NSString*)type {
    // Set some coordinates for our position
	CLLocationCoordinate2D location;
	location.latitude = (double) lat;
	location.longitude = (double) lon;
    
	// Add the annotation to our map view
	OBRMapViewAnnotation *newAnnotation = [[OBRMapViewAnnotation alloc] initWithTitle:title
                                                                        andCoordinate:location
                                                                          andSubtitle:@"st"];
    newAnnotation.type = type;
    [_detailMap addAnnotation:newAnnotation];
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    
    MKAnnotationView *annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"busStop"];
    
    OBRMapViewAnnotation* a = (OBRMapViewAnnotation*) annotation;
    if ([a.type isEqualToString:@"stop"]) {
        
        annView.image = [IOSI imageWithFilename:@"BusStopSign.png" Size:40];
        return annView;
    }
    
    if ([a.type isEqualToString:@"stoplabel"]) {
        
        IOSLabel* stoplabel = [[IOSLabel alloc] initWithText:@[a.title] Color:YELLOW Sizex:-1 Sizey:35];
        annView.image = stoplabel.image.image;
        annView.centerOffset = CGPointMake(0, -25);
        return annView;
    }
    
    return annView;
}
    



//updates the lats and lons of stops and routes
//while the stops are static, the vehicles should move
-(void)updateRouteInfo {
    NSLog(@"updating route info OBRRouteDetailTVC");
    
    for (OBRsolvedRouteRecord* r in _route) {
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
    
    //reload the data after refreshing
    [self.tableView reloadData];
}


-(void)populateMap {
    //reset the map boundary
    [self resetBoundary];
    
    //add the distinct points
    for (OBRsolvedRouteRecord* r in _route) {
        if (r.stop > -1) {
            OBRStopNew* cs = [db getStop:r.stop];
            [self expandBoundarylat:cs.lat lon:cs.lon];
            NSString* title = @"blank";
            if (r.minOfDayArrive == 0) {
                title = [NSString stringWithFormat:@"Start: Stop %d",r.stop];
            } else if (r.minOfDayDepart == 0) {
                title = [NSString stringWithFormat:@"End: Stop %d",r.stop];
            } else {
                title = [NSString stringWithFormat:@"Stop %d",r.stop];
            }
            [self addAnnotation:title lat:cs.lat lon:cs.lon color:0 type:@"stop"];
            [self addAnnotation:title lat:cs.lat lon:cs.lon color:0 type:@"stoplabel"];
        }
    }
    
    //get the routes
    NSMutableSet* routeSet = [[NSMutableSet alloc] init];
    for (OBRsolvedRouteRecord* r in _route) {
        if (r.route != nil) {
            [routeSet addObject:r.route];
        }
    }
    
    //get the points on the routes
    for (NSString* rs in routeSet) {
        [self addSingleRoute:rs];
    }
    //check that we found some points
    [self checkBoundary];
    
    float alat = (maxlat+minlat)/2.0;
    float alon = (maxlon+minlon)/2.0;
    float dlat = maxlat - minlat;
    float dlon = maxlon - minlon;
    float dlatm = fabs(110723*dlat)*1.3;
    float dlonm = fabs(103620*dlon)*1.3;
    // NSLog(@"alat alon dlatm dlonm %f %f %f %f",alat,alon,dlatm,dlonm);
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(alat, alon);
    [_detailMap setCenterCoordinate:center];
    MKCoordinateRegion adjustedRegion = [_detailMap regionThatFits:MKCoordinateRegionMakeWithDistance(center, dlatm,dlonm)];
    [_detailMap setRegion:adjustedRegion];
    
}


//updates the lats and lons of stops and routes
//while the stops are static, the vehicles should move
-(void)fillInInitationMinForRouteArray:(NSArray*)ra {
    NSTimeInterval nowSec = [db currentTimeSec];
    
    for (OBRsolvedRouteRecord* r in ra) {
        if (r.isRoute) {
            OBRVehicle* v = [db getVehicleForTrip:r.trip];
            float elapsed = nowSec - v.lastMessageDate;
            if (elapsed <30*60) {
                r.busNum = v.number;
                r.lat = v.lat;
                r.lon = v.lon;
                r.adherence = v.adherence;
                r.lastUpdateSec = v.lastMessageDate;
            }
        }
    }
    
    //set the completion times
    OBRsolvedRouteRecord* r = [ra firstObject];
    if (r.summaryRouteType == SRS) {
        int ad = ((OBRsolvedRouteRecord*)ra[2]).adherence;
        for (OBRsolvedRouteRecord* ri in ra) {
            ri.initationMin = ri.minOfDayArrive - ad;
        }
    } else if (r.summaryRouteType == RSR) {
        NSArray* RSRadArr = [[NSArray alloc] initWithObjects:@"2",@"2",@"2",@"2",@"4",@"4",@"4", nil];
        for (int i=0 ; i<ra.count; i++) {
            OBRsolvedRouteRecord* r = ra[i];
            NSNumber* p = RSRadArr[i];
            int ad = ((OBRsolvedRouteRecord*)ra[[p intValue]]).adherence;
            r.initationMin= r.minOfDayArrive - ad;
        }
    } else if (r.summaryRouteType == RWR) {
        NSArray* RWRadArr = [[NSArray alloc] initWithObjects:@"2",@"2",@"2",@"2",@"2",@"2",@"6",@"6",@"6", nil];
        for (int i=0 ; i<ra.count; i++) {
            OBRsolvedRouteRecord* r = ra[i];
            NSNumber* p = RWRadArr[i];
            int ad = ((OBRsolvedRouteRecord*)ra[[p intValue]]).adherence;
            r.initationMin = r.minOfDayArrive - ad;
        }
    } else if (r.summaryRouteType == RRR) {
        NSArray* RRRadArr = [[NSArray alloc] initWithObjects:@"2",@"2",@"2",@"2",@"4",@"4",@"6",@"6",@"6", nil];
        for (int i=0 ; i<ra.count; i++) {
            OBRsolvedRouteRecord* r = ra[i];
            NSNumber* p = RRRadArr[i];
            int ad = ((OBRsolvedRouteRecord*)ra[[p intValue]]).adherence;
            r.initationMin = r.minOfDayArrive - ad;
        }
    }
}



- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    
//    if([overlay isKindOfClass:[MKPolyline class]])
//    {
//        MKPolylineView *lineView = [[MKPolylineView alloc] initWithPolyline:overlay];
//        lineView.lineWidth = 12;
//        lineView.strokeColor = [UIColor blueColor];
//        lineView.fillColor = [UIColor blueColor];
//        return lineView;
//    }
//    return nil;
    return [ro viewForOverlay:overlay];
}


//- (void)GenerateLines:(NSArray*)routePoints {
//    
//    //determine number of segments
//    int minSeg = 999;
//    int maxSeg = -999;
//    for (OBRRoutePoints* rp in routePoints) {
//        if (rp.segment>maxSeg) maxSeg = rp.segment;
//        if (rp.segment<minSeg) minSeg = rp.segment;
//    }
//    
//    for (int seg=minSeg ; seg<=maxSeg; seg++) {
//        //determine number of points in this segment
//        int numPoints=0;
//        NSString* routestr;
//        for (OBRRoutePoints* rp in routePoints) {
//            if (rp.segment == seg) {
//                routestr = rp.routestr;
//                numPoints++;
//            }
//        }
//        CLLocationCoordinate2D* pointArr = malloc(sizeof(CLLocationCoordinate2D)*numPoints);
//        
//        int Indx = 0;
//        for  (OBRRoutePoints* rp in routePoints) {
//            if (rp.segment == seg) {
//                pointArr[Indx++] = CLLocationCoordinate2DMake(rp.lat, rp.lon);
//            }
//        }
//        
//        if (Indx>0) {
//            MKPolyline* routeLine = [MKPolyline polylineWithCoordinates:pointArr count:numPoints ];
//            
//            //NSLog(@"adding routeline");
//            [self.detailMap addOverlay:routeLine];
//            OBRoverlayInfo* oi = [[OBRoverlayInfo alloc] init];
//            oi.overlay = routeLine;
//            oi.color = [UIColor blueColor];
//            oi.routestr = routestr;
//        }
//    }
//}


-(void)addSingleRoute:(NSString*)routestr{
    [ro addSingleRoute:routestr onMap:_detailMap];
    //NSArray* points = [[OBRdataStore defaultStore] getPointsForRouteStr:routestr];
    //[self GenerateLines:points];
    routeOverlayAdded = true;
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell*)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //get cell data
    OBRsolvedRouteRecord* r = _route[indexPath.row];
    
    //check for GPS
    [db checkRouteForRealTimeInfo:r];
    
    int arriveMin = r.minOfDayArrive;
    NSString* arriveStr = @"No GPS";
    
    //this is a stop
    if (r.isStop ) {
        OBRStopNew* stopinfo = [[OBRdataStore defaultStore] getStop:r.stop];
        OBRStopDescriptionTVCell* c = (OBRStopDescriptionTVCell*) cell;
        
        //remove the (Stop) from the string
        NSRange rg = [stopinfo.streets rangeOfString:@"("];
        NSString* streetStr = [stopinfo.streets substringToIndex:rg.location];
        c.streetLabel.text = streetStr;
        
        c.stopNumLabel.text = [NSString stringWithFormat:@"Stop #: %d",r.stop];
        if (arriveMin > 0) {
            c.arriveLabel.text = arriveStr;
            c.waitLabel.text = [NSString stringWithFormat:@"Wait: %d min",r.waitMin];
        } else {
            [c.arriveLabel setHidden:TRUE];
            [c.waitLabel setHidden:TRUE];
        }
        
    } else if ([r isRoute]) {
        
        NSLog(@"r.gps= %d",r.GPS);
        
        if (r.busNum != 0) {
            arriveStr = [NSString stringWithFormat:@"(%@)",[self adherenceStr:r.adherence]];
        }
        
        //set the labels
        OBRBusDescriptionTVCell* c = (OBRBusDescriptionTVCell*) cell;
        c.busNumLabel.text = [NSString stringWithFormat:@"Route: %@",r.route];
        c.headsignLabel.text = r.headsign;
        c.directionLabel.text = r.direction;
        c.arriveLabel.text = arriveStr;
        c.waitLabel.text = [NSString stringWithFormat:@"Ride: %d min",r.waitMin];
        
        //set the spacing
        CGPoint spacing = CGPointMake(36, 18);  //single character
        if (r.route.length == 2) spacing = CGPointMake(24, 18);  //two characte
        if (r.route.length == 3) spacing = CGPointMake(15, 18);  //three character
        
        //set the image
        [IOSI imageWithFilename:@"DataHollow.png"];
        UIColor* busColor = BLACK;
        if (r.GPS) {
            if (r.adherence>=0) busColor = GREEN;
            else if (r.adherence > -6) busColor = YELLOW;
            else busColor = RED;
            [IOSI drawText:r.route atPoint:spacing FontSize:40];
            [IOSI colorize:busColor];
            c.busImage.image = [IOSI getImage];
        } else {
            c.busImage.image = [IOSI drawText:r.route atPoint:spacing FontSize:40];
        }
        c.arriveLabel.textColor = busColor;
        
    } else if (r.walk>-1) {
        OBRwalkTVCell* c = (OBRwalkTVCell*) cell;
        c.distanceLabel.text = [NSString stringWithFormat:@"Distance: %d m",r.distanceMeters];
        
    }else {
        //timestamp
        
        //get the route arraay
        OBRsolvedRouteRecord* chosenRoute = [db chosenRoute];
        NSArray* raNoTimestamp = [chosenRoute convertToArray:chosenRoute];
        [self fillInInitationMinForRouteArray:raNoTimestamp];
        
        NSLog(@"start");
        //find the proper entry in the array without timestamps as the current row
        int adherence = 0;
        for (OBRsolvedRouteRecord* sr in raNoTimestamp) {
            if (sr.minOfDayDepart == r.minOfDayDepart && sr.minOfDayArrive == r.minOfDayArrive) {
                //these records should be the same
                adherence = sr.initationMin - sr.minOfDayArrive;
            }
        }
        
        //determine if any GPS data is available for this route
        bool gpsAvailable = false;
        for (OBRsolvedRouteRecord* sr in raNoTimestamp) {
            if (sr.GPS) gpsAvailable = true;
        }
        
        
        OBRTimestampTVCell* c = (OBRTimestampTVCell*) cell;
        if (r.minOfDayArrive == 0) {
            c.dateLabel.text = @"Current Time:";
        } else {
            NSString* actual = [NSString stringWithFormat:@"Actual:%@",[self timestring:(r.minOfDayArrive+adherence)]];
            c.dateLabel.text = [self timestring:r.minOfDayArrive];
            if (gpsAvailable) {
                c.actualTime.text =actual;
            } else {
                c.actualTime.text = @"";
            }
        }
        
    }
}


@end

