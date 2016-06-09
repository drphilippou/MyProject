//
//  OBRFinalProcessingVC.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/15/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#define CASE(str)                       if ([__s__ isEqualToString:(str)])
#define SWITCH(s)                       for (NSString *__s__ = (s); ; )
#define DEFAULT


#import "OBRFinalProcessingVC.h"

@interface OBRFinalProcessingVC () {
    NSMutableArray* points;
    OBRMapViewAnnotation* selectedAnnotation;
    CLLocationCoordinate2D pinGrabbedAt;
    int selectedAnnotationIndex;
    int selectedPointIndex;
    int selectedSegment;
    int selectedFindex;
    int numSeg;
    int routeNum;
    CLLocationCoordinate2D lastTapPoint;
    OBRdataStore* db;
    NSDictionary* selectedWay;
    IOSImage* IOSI;
    NSMutableSet* routeAnnotations;
}
@property (nonatomic) NSMutableArray *myOverlays;
@end

@implementation OBRFinalProcessingVC

-(NSMutableArray*) myOverlays{
    if (!_myOverlays) {
        _myOverlays = [[NSMutableArray alloc] init];
    }
    return _myOverlays;
}

-(NSMutableDictionary*)OSMnodes {
    if (_OSMnodes == nil) {
        //get the version files form the website
        NSError *error = nil;
        NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"OSMHawaiiData" ofType:@"json"];
        NSDictionary* a = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath] options:kNilOptions error:&error];
        //parse the json file
        _OSMnodes = [[NSMutableDictionary alloc] initWithDictionary:a[@"nodes"]];
        
    }
    return _OSMnodes;
}

-(NSMutableDictionary*)OSMways {
    if (_OSMways == nil) {
        //get the version files form the website
        NSError *error = nil;
        NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"OSMHawaiiData" ofType:@"json"];
        NSDictionary* a = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath] options:kNilOptions error:&error];
        //parse the json file
        _OSMways = a[@"ways"];
        
     }
    return _OSMways;
}

-(void) newFunction {
    
    for (NSNumber* waykey in [[self OSMways] keyEnumerator]) {
        
        NSDictionary* way = [[self OSMways] objectForKey:waykey];
        NSLog(@"way = %@ %@",waykey,way);
        if ([[way allKeys] containsObject:@"highway"]) {
            if ([[way allKeys] containsObject:@"nd"]) {
                NSArray* waynodes = way[@"nd"];
                NSString* name = way[@"name"];
                
                for (NSNumber* waynode in waynodes ) {
                    
                    [self getnode:waynode from:[self OSMnodes]];
                    CLLocationCoordinate2D p = [self getLocationOfNode:waynode from:[self OSMnodes]];
                    if (p.latitude > 20.264 && p.latitude<22.385 && p.longitude> -257.745 && p.longitude<-157.7) {
                        [self addAnnotation:name
                                        lat:p.latitude
                                        lon:p.longitude
                                       type:@"node" dict:@{@"node":waynode,@"way":way,@"wayid":waykey,@"nodeid":waynode}];
                    }
                    
                }
            }
        }
    }
 
}





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
    db = [OBRdataStore defaultStore];
    IOSI = [[IOSImage alloc] init];
    [self OSMnodes];
    [self OSMways];
    routeAnnotations = [[NSMutableSet alloc] init];
    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(21.4, -158.0);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(center, 47000, 47000)];
    
    [self.mapView setCenterCoordinate:center animated:YES];
    [self.mapView setZoomEnabled:YES];
    [self.mapView setRegion:adjustedRegion animated:YES];
    [self.mapView setDelegate:self];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(foundTap:)];
    
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [self.mapView addGestureRecognizer:tapRecognizer];
}

-(void)viewWillAppear:(BOOL)animated {
    [[_mapView superview] sendSubviewToBack:_mapView];
}

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>) a {
    
    OBRMapViewAnnotation* mva = a;
    
    SWITCH (mva.type) {
        CASE (@"node") {
            MKAnnotationView* av = [[MKAnnotationView alloc] initWithAnnotation:mva reuseIdentifier:@"node"];
            av.image = [self getAnnotationImage:mva];
            av.layer.zPosition = 100;
            av.canShowCallout = true;
            return av;
        }
        CASE (@"stop") {
            MKAnnotationView* av = [[MKAnnotationView alloc] initWithAnnotation:mva reuseIdentifier:@"stop"];
            av.image = [self getAnnotationImage:mva];
            av.layer.zPosition = 1000;
            av.canShowCallout = true;
            return av;
        }
        CASE (@"start") {
            MKAnnotationView* av = [[MKAnnotationView alloc] initWithAnnotation:mva reuseIdentifier:@"start"];
            av.image = [self getAnnotationImage:mva];
            av.layer.zPosition = 99;
            av.canShowCallout = true;
            return av;
        }
        CASE (@"route") {
            MKAnnotationView* av = [[MKAnnotationView alloc] initWithAnnotation:mva reuseIdentifier:@"start"];
            av.image = [self getAnnotationImage:mva];
            av.layer.zPosition = 200;
            av.canShowCallout = true;
            return av;
        }

        CASE (@"growthStop") {
            MKAnnotationView* av = [[MKAnnotationView alloc] initWithAnnotation:mva reuseIdentifier:@"start"];
            av.image = [self getAnnotationImage:mva];
            av.layer.zPosition = 200;
            av.canShowCallout = true;
            return av;
        }

        DEFAULT {
            
            MKPinAnnotationView *annView=[[MKPinAnnotationView alloc]
                                          initWithAnnotation:a
                                          reuseIdentifier:@"pin"];
            
            
            annView.draggable = YES;
            
            // Create a UIButton object to add on the
            UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
            [rightButton setTitle:a.title forState:UIControlStateNormal];
            [annView setRightCalloutAccessoryView:rightButton];
            
            annView.canShowCallout = YES;
            
            return annView;
        }
    }
    return nil;
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {

    //set the color back on the old selection
    OBRMapViewAnnotation* mva = selectedAnnotation;
    MKAnnotationView* oldav = [_mapView viewForAnnotation:selectedAnnotation];
    oldav.image = [self getAnnotationImage:mva];
    [self unHighlightTheWayForAnnotation:mva];
    
    mva = view.annotation;
    view.image = [IOSI imageWithFilename:@"Circle.png" Color:MAGENTA Size:7];
    
    //get new point information
    selectedAnnotation = view.annotation;
    
    //highlight the way
    [self highlightTheWayForAnnotation:mva];
    
    CLLocationCoordinate2D c = selectedAnnotation.coordinate;
    OBRalgPoint* p = [self getPointAtLat:c.latitude lon:c.longitude];
    
    if (p) {
        selectedPointIndex = (int)[points indexOfObject:p];
        selectedSegment = p.segment;
        selectedFindex = p.findex;
        [_segment setText:[NSString stringWithFormat:@"%d",selectedSegment]];
    } else {
        NSLog(@"Couldnt find point");
    }
    
//    annView =[[MKPinAnnotationView alloc]
//              initWithAnnotation:view.annotation
//              reuseIdentifier:@"pin"];
//    annView.pinColor = MKPinAnnotationColorGreen;

}

- (void)mapView:(MKMapView *)mapView  annotationView:(MKAnnotationView *)annotationView
                                didChangeDragState:(MKAnnotationViewDragState)newState
                                    fromOldState:(MKAnnotationViewDragState)oldState {
    if (newState == MKAnnotationViewDragStateStarting) {
        pinGrabbedAt = annotationView.annotation.coordinate;
    }
    
    
    if (newState == MKAnnotationViewDragStateEnding)
    {
        CLLocationCoordinate2D droppedAt = annotationView.annotation.coordinate;
        OBRalgPoint* p = [self getPointAtLat:pinGrabbedAt.latitude
                                         lon:pinGrabbedAt.longitude];
        p.lat = droppedAt.latitude;
        p.lon = droppedAt.longitude;
        [self GenerateLines];
    }
}


- (void)mapView:(MKMapView *)map annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    //called when the annotation button is pressed?
    
    OBRalgPoint* p = [self getPointAtLat:view.annotation.coordinate.latitude
                                     lon:view.annotation.coordinate.longitude];
    
    [points removeObject:p];
    [self.mapView removeAnnotation:view.annotation];
    [self GenerateLines];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    if([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolylineView *lineView = [[MKPolylineView alloc] initWithPolyline:overlay];
        lineView.lineWidth = 8;
        lineView.lineDashPattern = [NSArray arrayWithObjects:[NSNumber numberWithFloat:2],[NSNumber numberWithFloat:8], nil];
        lineView.strokeColor = [UIColor redColor];
        lineView.fillColor = [UIColor redColor];
        return lineView;
    }
    return nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}








//new functions
- (IBAction)LoadStops:(id)sender {
    NSArray* stopsOnRoute = [db getStopsForRoutestr:self.routeStr.text];
    for (OBRStopNew* stop in db.stops) {
        if ([stopsOnRoute containsObject:stop]) {
           //found stop
            [self addAnnotation:[NSString stringWithFormat:@"%d %@",stop.number, stop.streets]
                            lat:stop.lat
                            lon:stop.lon
                           type:@"stop" dict:@{@"stop":stop}];

            
        }
    }
}

- (IBAction)LoadNewRoute:(id)sender {
    
    if (!points) {
        points = [[NSMutableArray alloc] init];
    }
    
    FILE* fp = fopen("/Users/Paul/Desktop/Routes/102 102 finished.txt", "r");
    
    //record the last data point
    OBRalgPoint* ldp = [[OBRalgPoint alloc] init];
    
    float lat = 0.0;
    float lon = 0.0;
    float index = 0;
    int segment = 0;
    char empty[100];
    while (fscanf(fp, "%d %s %d %f %f",&routeNum,empty,&segment,&lat,&lon) != EOF) {;
        BOOL contained = false;
        for (OBRalgPoint* p in points) {
            if (p.lat == lat && p.lon==lon && p.segment==numSeg) {
                contained = true;
            }
        }
        if (!contained) {
            
            if (segment>numSeg) numSeg = segment+1;
            
            OBRalgPoint* ap = [[OBRalgPoint alloc] createAlgPoint:lat lon:lon];
            ap.segment = segment;
            ap.findex = index;
            [self addAnnotation:[NSString stringWithFormat:@"%d %f",ap.segment,index++ ]
                            lat:lat
                            lon:lon
                           type:@"route" dict:@{}];
            
            //check the distance between points in meters
            float d = 111000*[self distance:ldp p2:ap];
            if (d>300) NSLog(@"Distance is %f",d);
            
            
            [points addObject:ap];
            
            ldp = ap;
        }
        //NSLog(@"seg:%d %f %f",numSeg,lat,lon);
    }
    fclose(fp);
    numSeg++;
    
    
}

- (IBAction)LoadWay:(id)sender {
    
    NSArray* nd = selectedWay[@"nd"];
    NSString* selectedname = selectedWay[@"name"];
    NSString* selectedref = selectedWay[@"ref"];
    for (NSNumber* n in nd) {
        CLLocationCoordinate2D p = [self getLocationOfNode:n from:_OSMnodes];
        NSDictionary* node = [self getnode:n from:_OSMnodes];
        [self addAnnotation:@"node" lat:p.latitude lon:p.longitude type:@"node" dict:@{@"node":node,@"way":selectedWay,@"wayid":selectedWay,@"nodeid":n}];
    }
    for (id waykey in _OSMways) {
        NSDictionary* way = _OSMways[waykey];
        NSString* name = way[@"name"];
        NSString* ref = way[@"ref"];
        if ([selectedname isEqualToString:name] && selectedname != nil)    {
            
              NSArray* waynd = way[@"nd"];
             for (NSNumber* n in waynd) {
                CLLocationCoordinate2D p = [self getLocationOfNode:n from:_OSMnodes];
                 NSDictionary* node = [self getnode:n from:_OSMnodes];
                 [self addAnnotation:@"node" lat:p.latitude lon:p.longitude type:@"node" dict:@{@"node":node,@"way":way,@"wayid":waykey,@"nodeid":n}];
             }

        } else if ([selectedref isEqualToString:ref]) {
            NSArray* waynd = way[@"nd"];
            for (NSNumber* n in waynd) {
                CLLocationCoordinate2D p = [self getLocationOfNode:n from:_OSMnodes];
                NSDictionary* node = [self getnode:n from:_OSMnodes];
                [self addAnnotation:@"node" lat:p.latitude lon:p.longitude  type:@"node" dict:@{@"node":node,@"way":way,@"wayid":waykey,@"nodeid":n}];
            }

        }
    }
    
}

- (IBAction)RemoveWay:(id)sender {
    NSMutableArray* fordeletion = [[NSMutableArray alloc] init];

    NSArray* nd = selectedWay[@"nd"];
    for (NSNumber* n in nd) {
        NSDictionary* desirednode = [self getnode:n from:_OSMnodes];
        for (OBRMapViewAnnotation* mva in [self.mapView annotations]) {
                NSDictionary* anode = mva.IDdict[@"node"];
                if (anode == desirednode) {
                    //MKAnnotationView* av = [[self mapView] viewForAnnotation:mva];
                    //av.image = [IOSI imageWithFilename:@"Circle.png" Color:PURPLE Size:5];
                    [fordeletion addObject:mva];
                }
        }
    }
    
    [self.mapView removeAnnotations:fordeletion];
    
}

- (IBAction)RemoveLast:(id)sender {
//    NSArray* nd = selectedWay[@"nd"];
//    NSString* selectedname = selectedWay[@"name"];
//    NSString* selectedref = selectedWay[@"ref"];
//    for (NSNumber* n in nd) {
//        CLLocationCoordinate2D p = [self getLocationOfNode:n from:_OSMnodes];
//        [self addAnnotation:@"node" lat:p.latitude lon:p.longitude color:0 type:@"none"];
//    }
//    for (id waykey in _OSMways) {
//        NSDictionary* way = _OSMways[waykey];
//        NSString* name = way[@"name"];
//        NSString* ref = way[@"ref"];
//        if ([selectedname isEqualToString:name] && selectedname != nil)    {
//            
//            NSArray* waynd = way[@"nd"];
//            for (NSNumber* n in waynd) {
//                CLLocationCoordinate2D p = [self getLocationOfNode:n from:_OSMnodes];
//                [self addAnnotation:@"node" lat:p.latitude lon:p.longitude color:0 type:@"none"];
//            }
//            
//        } else if ([selectedref isEqualToString:ref]) {
//            NSArray* waynd = way[@"nd"];
//            for (NSNumber* n in waynd) {
//                CLLocationCoordinate2D p = [self getLocationOfNode:n from:_OSMnodes];
//                [self addAnnotation:@"node" lat:p.latitude lon:p.longitude color:0 type:@"none"];
//            }
//            
//        }
//    }
//
}

- (IBAction)DeletePoint:(id)sender {
    [self.mapView removeAnnotation:selectedAnnotation];
    [routeAnnotations removeObject:selectedAnnotation];
    OBRalgPoint* ap = [self getPointAtLat:selectedAnnotation.coordinate.latitude
                                      lon:selectedAnnotation.coordinate.longitude];
    [points removeObject:ap];
    selectedAnnotation = nil;
    [self GenerateLines];
}

- (IBAction)SetStop:(id)sender {
    selectedAnnotation.type = @"growthStop";
    [self redrawAnnotations];
}

- (IBAction)AddPoint:(id)sender {
    //[self addNode:lastTapPoint];
    //[self addNode:lastTapPoint];
    [self addAnnotation:@"added" lat:lastTapPoint.latitude lon:lastTapPoint.longitude type:@"node" dict:@{}];
}

-(void)addNode:(CLLocationCoordinate2D)p {
    NSMutableDictionary* temp = [[NSMutableDictionary alloc] init];
    temp[@"lat"] = [NSString stringWithFormat:@"%f",p.latitude];
    temp[@"lon"] = [NSString stringWithFormat:@"%f",p.longitude];
    
    //get the largest node id
    long largestID = 0;
    for (NSString* nodeIDStr in [_OSMnodes allKeys]) {
        long nodeID = [nodeIDStr floatValue];
        if (nodeID>largestID) largestID = nodeID;
    }

    //add a new node at the next availbel ID
    largestID++;
    [_OSMnodes setValue:temp forKey:[NSString stringWithFormat:@"%ld",largestID]];
    
}

-(UIImage*)getAnnotationImage:(OBRMapViewAnnotation*) a {
    SWITCH (a.type) {
        CASE (@"node") {
            return [IOSI imageWithFilename:@"Circle.png" Color:ROYAL_BLUE Size:5];
        }
        CASE (@"stop") {
            return  [IOSI imageWithFilename:@"Circle.png" Color:YELLOW Size:6];
        }
        CASE (@"start") {
            return  [IOSI imageWithFilename:@"Circle.png" Color:GREEN Size:10];
        }
        CASE (@"route") {
            return  [IOSI imageWithFilename:@"Circle.png" Color:GREEN Size:6];
        }
        CASE (@"growthStop") {
            return  [IOSI imageWithFilename:@"Circle.png" Color:BLACK Size:6];
        } DEFAULT {
            return nil;
        }
    }
}

-(void)addAnnotation:(NSString*)title lat:(float)lat lon:(float) lon type:(NSString*)t dict:(NSDictionary*)d {
    
    
    
    // Set some coordinates for our position
    CLLocationCoordinate2D location;
    location.latitude = (double) lat;
    location.longitude = (double) lon;
    
    // Add the annotation to our map view
    OBRMapViewAnnotation *newAnnotation = [[OBRMapViewAnnotation alloc] initWithTitle:title andCoordinate:location];
    
    newAnnotation.pinColor = MKPinAnnotationColorGreen;
    newAnnotation.type = t;
    newAnnotation.IDdict = [[NSMutableDictionary alloc] initWithDictionary:d];

    //check to see if this annotation already exists
    for (OBRMapViewAnnotation* mva in self.mapView.annotations) {
        if (mva.coordinate.latitude == lat) {
            if (mva.coordinate.longitude == lon) {
                if ([mva.type isEqualToString:t]) {
                    // already exists
                    return;
                }
            }
        }
    }
    
    
    [self.mapView addAnnotation:newAnnotation];
}

-(void)highlightTheWayForAnnotation:(OBRMapViewAnnotation*)a {
    NSDictionary* way = a.IDdict[@"way"];
    if (way) {
        NSArray* nd = way[@"nd"];
        for (NSNumber* n in nd) {
            NSDictionary* desirednode = [self getnode:n from:_OSMnodes];
            for (OBRMapViewAnnotation* mva in [self.mapView annotations]) {
                if (mva != a) {
                    NSDictionary* anode = mva.IDdict[@"node"];
                    if (anode == desirednode) {
                        MKAnnotationView* av = [[self mapView] viewForAnnotation:mva];
                        av.image = [IOSI imageWithFilename:@"Circle.png" Color:PURPLE Size:5];
                    }
                }
            }
        }
    }
}

-(void)unHighlightTheWayForAnnotation:(OBRMapViewAnnotation*)a {
    NSDictionary* way = a.IDdict[@"way"];
    if (way) {
        NSArray* nd = way[@"nd"];
        for (NSNumber* n in nd) {
            NSDictionary* desirednode = [self getnode:n from:_OSMnodes];
            for (OBRMapViewAnnotation* mva in [self.mapView annotations]) {
                if (mva != a) {
                    NSDictionary* anode = mva.IDdict[@"node"];
                    if (anode == desirednode) {
                        MKAnnotationView* av = [[self mapView] viewForAnnotation:mva];
                        av.image = [self getAnnotationImage:mva];
                    }
                }
            }
        }
    }
}

-(void)redrawAnnotations{
    //check that all the routeAnnotations are on the map
    for (OBRMapViewAnnotation* mva in routeAnnotations) {
        if (![[_mapView annotations] containsObject:mva]) {
            //add this annotation back onto the map
            [_mapView addAnnotation:mva];
        }
    }
    
    //make sure all the icons are correct
    for (OBRMapViewAnnotation* mva in _mapView.annotations) {
        MKAnnotationView* av = [_mapView viewForAnnotation:mva];
        av.image = [self getAnnotationImage:mva];
    }
    
}

 -(IBAction)addEndPoint:(id)sender {
    
    bool foundStop = false;
    int numAdded = 0;
    while (!foundStop && numAdded<10) {
        //find the last node of this segment
        OBRMapViewAnnotation* lastNode = nil;
        float nodeNum = -20000;
        for (OBRMapViewAnnotation* mva in routeAnnotations) {
            if (mva.IDi == selectedSegment) {
                if (mva.IDd > nodeNum) {
                    nodeNum = mva.IDd;
                    lastNode = mva;
                }
            }
        }
        
        //find the closet point to the last node
        float mindistance = 1e9;
        OBRMapViewAnnotation* closestAnn;
        for (OBRMapViewAnnotation* mva in _mapView.annotations) {
            if ([mva.type isEqualToString:@"node"]  ||
                [mva.type isEqualToString:@"growthStop"]) {
                float dlat = lastNode.coordinate.latitude - mva.coordinate.latitude;
                float dlon = lastNode.coordinate.longitude - mva.coordinate.longitude;
                float d = sqrtf(dlat*dlat+dlon*dlon);
                if (d<mindistance) {
                    NSLog(@"lastnode Num %lf",lastNode.IDd);
                    mindistance = d;
                    closestAnn = mva;
                }
            }
        }
        NSLog(@"closest d = %f",mindistance);
        
        //check to see if this is a stop
        if ([closestAnn.type isEqualToString:@"growthStop"]) {
            foundStop = true;
        }
        
        if (closestAnn != nil) {
            numAdded++;
            closestAnn.type = @"route";
            closestAnn.IDi = selectedSegment;
            closestAnn.IDd = ++nodeNum;
            closestAnn.title = [NSString stringWithFormat:@"%d %f",selectedSegment,nodeNum];
            [routeAnnotations addObject:closestAnn];
            
            OBRalgPoint* np = [[OBRalgPoint alloc] createAlgPoint:closestAnn.coordinate.latitude
                                                              lon:closestAnn.coordinate.longitude];
            np.findex = nodeNum;
            np.index = nodeNum;
            np.segment = selectedSegment;
            [points addObject:np];
            lastNode = closestAnn;
            
        }
        [self redrawAnnotations];
    }
    
    [self GenerateLines];
}

- (IBAction)addBeginPoint:(id)sender {
    
    bool foundStop = false;
    int numAdded = 0;
    OBRMapViewAnnotation* firstNode = nil;
    while (!foundStop && numAdded<10) {
        //find the last node of this segment
       
        float nodeNum = 20000;
        for (OBRMapViewAnnotation* mva in routeAnnotations) {
            if (mva.IDi == selectedSegment) {
                if (mva.IDd <= nodeNum) {
                    nodeNum = mva.IDd;
                    firstNode = mva;
                }
            }
        }
        
        //find the closet point to the last node
        float mindistance = 1e9;
        OBRMapViewAnnotation* closestAnn;
        for (OBRMapViewAnnotation* mva in _mapView.annotations) {
            if ([mva.type isEqualToString:@"node"]  ||
                [mva.type isEqualToString:@"growthStop"]) {
                float dlat = firstNode.coordinate.latitude - mva.coordinate.latitude;
                float dlon = firstNode.coordinate.longitude - mva.coordinate.longitude;
                float d = sqrtf(dlat*dlat+dlon*dlon);
                if (d<mindistance) {
                    NSLog(@"lastnode Num %lf",firstNode.IDd);
                    mindistance = d;
                    closestAnn = mva;
                }
            }
        }
        NSLog(@"closest d = %f",mindistance);
        
        //check to see if this is a stop
        if ([closestAnn.type isEqualToString:@"growthStop"]) {
            foundStop = true;
        }
        
        if (closestAnn != nil) {
            numAdded++;
            closestAnn.type = @"route";
            closestAnn.IDi = selectedSegment;
            closestAnn.IDd = --nodeNum;
            closestAnn.title = [NSString stringWithFormat:@"%d %f",selectedSegment,nodeNum];
            [routeAnnotations addObject:closestAnn];
            
            OBRalgPoint* np = [[OBRalgPoint alloc] createAlgPoint:closestAnn.coordinate.latitude
                                                              lon:closestAnn.coordinate.longitude];
            np.findex = nodeNum;
            np.index = nodeNum;
            np.segment = selectedSegment;
            [points insertObject:np atIndex:0];
            
            //update the first node
            firstNode.type = @"route";
            firstNode = closestAnn;
        }
    }
    firstNode.type = @"start";
    [self redrawAnnotations];
    [self GenerateLines];
    
}





//node and ways helper functions
-(NSDictionary*)getnode:(NSNumber*) nodeid from:(NSDictionary*)nodes {
    NSDictionary* node = [nodes objectForKey:nodeid];
    return node;
}

-(CLLocationCoordinate2D)getLocationOfNode:(NSNumber*)nodeid from:(NSDictionary*) nodes {
    NSDictionary* node = [nodes objectForKey:nodeid];
    float lat = [node[@"lat"] floatValue];
    float lon = [node[@"lon"] floatValue];
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lat, lon);
    return point;
}





//original functions

-(IBAction)foundTap:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self.mapView];
    
    lastTapPoint = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    
    
    //find the closet node
    float best = 1e9;
    NSNumber* bestkey;
    NSDictionary* bestNode;
    for (id nodekey in _OSMnodes) {
        
        NSDictionary* node = _OSMnodes[nodekey];
        float lat = [node[@"lat"] floatValue];
        float lon = [node[@"lon"] floatValue];
        float d = sqrt((lat-lastTapPoint.latitude)*(lat - lastTapPoint.latitude)+(lon - lastTapPoint.longitude)*(lon-lastTapPoint.longitude));
        if (d<best) {
            
            NSSet* foundWays = [self getWaysForNode:nodekey];
            if (foundWays.count >0) {
                
                best=d;
                bestNode = node;
                bestkey = nodekey;
                selectedWay = [foundWays anyObject];
            }
        }
    }
    NSLog(@"best Node = %@",bestNode);
    NSLog(@"best Way = %@",selectedWay);
    NSString* ref = selectedWay[@"ref"];
    NSString* name = selectedWay[@"name"];
    [_Streetfield setText:name];
    
    if (name == nil) {
        [_Streetfield setText:ref];
    }
}

-(NSMutableSet*)getWaysForNode:(id)node {
    NSMutableSet* ways = [[NSMutableSet alloc] init];
    //find the matching ways
    for (id waykey in _OSMways) {
        NSDictionary* way = _OSMways[waykey];
        NSString* highway = way[@"highway"];
        if (highway != nil && ![highway isEqualToString:@"service"]) {
            
            NSArray* nd = way[@"nd"];
            if (nd!=nil) {
                for (NSString* n in nd) {
                    if ([n isEqualToString:node]) {
                        //found a match
                        NSLog(@"way=%@",way);
                        [ways addObject:way];
                    }
                }
            }
        }
    }
    return ways;
}


- (IBAction)editingEnded:(id)sender {
    [sender resignFirstResponder];
}

- (IBAction)LoadRoute:(id)sender {
    
    
    if (!points) {
        points = [[NSMutableArray alloc] init];
    }
    
    FILE* fp = fopen("/Users/Paul/Desktop/Routes/432 temp.txt", "r");
    
    //record the last data point
    OBRalgPoint* ldp = [[OBRalgPoint alloc] init];
    
    float lat = 0.0;
    float lon = 0.0;
    float index = 0;
    while (fscanf(fp, "%d %f %f",&routeNum,&lat,&lon) != EOF) {;
        BOOL contained = false;
        for (OBRalgPoint* p in points) {
            if (p.lat == lat && p.lon==lon && p.segment==numSeg) {
                contained = true;
            }
        }
        if (!contained) {
            
            OBRalgPoint* ap = [[OBRalgPoint alloc] createAlgPoint:lat lon:lon];
            
            //check the distance between points in meters
            float d = 111000*[self distance:ldp p2:ap];
            if (d>1000) {
                //split into a new segment
                numSeg++;
                index = 0;
                NSLog(@"Distance is %f",d);
            }
       
            ap.segment = numSeg;
            ap.findex = index;
            [self addAnnotation:[NSString stringWithFormat:@"%d %f",ap.segment,index++ ]
                            lat:lat
                            lon:lon
                           type:@"undefined" dict:@{}];
            
            [points addObject:ap];
            
            ldp = ap;
        }
        //NSLog(@"seg:%d %f %f",numSeg,lat,lon);
    }
    fclose(fp);
    numSeg++;
    
    
  }

-(float)distance:(OBRalgPoint*)start p2:(OBRalgPoint*)end {
    float x = (start.lat - end.lat)*(start.lat - end.lat);
    float y = (start.lon - end.lon)*(start.lon - end.lon);
    return  sqrt(x+y);
}

- (IBAction)saveRoute:(id)sender {
    FILE* fp = fopen("/Users/Paul/Desktop/Routes/VC temp.txt", "w");
    for (OBRalgPoint* p in points) {
        fprintf(fp,"%d %s %d %f %f \n",_textField.text.intValue,[_routeStr.text UTF8String],p.segment,p.lat,p.lon);
        NSLog(@" print %f",p.lat);
    }
    fclose(fp);
}

- (IBAction)newPolyline:(id)sender {
    if (!points) points = [[NSMutableArray alloc] init];
    
    OBRalgPoint* p = [[OBRalgPoint alloc] createAlgPoint:selectedAnnotation.coordinate.latitude
                                                     lon:selectedAnnotation.coordinate.longitude];
    p.findex = 0;
    p.segment = numSeg++;
    [points addObject:p];
    [self addAnnotation:[NSString stringWithFormat:@"%d %f",p.segment,p.findex]
                    lat:p.lat
                    lon:p.lon
                   type:@"start" dict:@{}];
    selectedAnnotation.IDi = p.segment;
    selectedAnnotation.IDd = 1.0;
    selectedAnnotation.IDs = @"start";
    selectedAnnotation.type = @"start";
    selectedAnnotation.title =[NSString stringWithFormat:@"%d %f",p.segment,p.findex];
    [routeAnnotations addObject:selectedAnnotation];
    [self.mapView removeAnnotation:selectedAnnotation];
    selectedAnnotation = nil;
    
    selectedSegment = p.segment;
    [_segment setText:[NSString stringWithFormat:@"%d",p.segment]];
    
    [self redrawRoutes];
}


- (IBAction)addMidPoint:(id)sender {
    OBRalgPoint* pointBefore = [[OBRalgPoint alloc] init];
    OBRalgPoint* afterPoint = [[OBRalgPoint alloc] init];
    
    pointBefore = [points objectAtIndex:selectedPointIndex];
    NSLog(@"First index is %d seg=%d",selectedPointIndex,selectedSegment);
    
    //search for the point after
    for (OBRalgPoint* ap in points) {
        int cindx = (int)[points indexOfObject:ap];
        if (cindx >selectedPointIndex) {
            if (ap.segment == selectedSegment) {
                NSLog(@"Next Index is %d",cindx);
                afterPoint = ap;
                break;
            } else {
                NSLog(@"index %d is wrong segment %d",cindx,ap.segment);
            }
        }
    }
    
    float lat = (pointBefore.lat + afterPoint.lat)/2.0;
    float lon = (pointBefore.lon + afterPoint.lon)/2.0;
    float findex = (pointBefore.findex + afterPoint.findex)/2.0;
    OBRalgPoint* newPoint = [[OBRalgPoint alloc] createAlgPoint:lat lon:lon];
    newPoint.findex = findex;
    newPoint.segment = selectedSegment;
    [points insertObject:newPoint atIndex:(selectedPointIndex+1)];
    
    [self addAnnotation:[NSString stringWithFormat:@"%d %f",selectedSegment,findex]
                    lat:lat
                    lon:lon
                   type:@"undefined" dict:@{}];
}

- (IBAction)GenerateLines {

    [self.mapView removeOverlays:[self myOverlays]];
    
    for (int seg=0 ; seg<numSeg; seg++) {
        
        int num = [self countNumberOfPointsForSeg:seg];
        
        MKMapPoint* pointArr = malloc(sizeof(CLLocationCoordinate2D)*num);
        
        int Indx = 0;
        for  (OBRalgPoint* p in points) {
            //NSLog(p.description);
            if (p.segment == seg) {
                
                CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(p.lat, p.lon);
                MKMapPoint mp = MKMapPointForCoordinate(coor);
                
                //adjust the bounding box
                pointArr[Indx++] = mp;
            }
        }
        
        MKPolyline* routeLine = [MKPolyline polylineWithPoints:pointArr count:num];
        
        [self.mapView addOverlay:routeLine];
        [[self myOverlays] addObject:routeLine];
    }
}


-(void)redrawRoutes {
    for (OBRMapViewAnnotation* mva in routeAnnotations) {
        MKAnnotationView* av = [self.mapView viewForAnnotation:mva];
        //does the annotation already exist
        if ([self.mapView.annotations containsObject:mva]) {
            //exists
            av.image = [self getAnnotationImage:mva];
        } else {
            NSString* routePointStr = [NSString stringWithFormat:@"%ld %f",mva.IDi,mva.IDd];
            [self addAnnotation:routePointStr lat:mva.coordinate.latitude lon:mva.coordinate.longitude type:@"route" dict:@{}];
        }
    }
}



-(int) countNumberOfPointsForSeg:(int)seg {
    int num=0;
    for (OBRalgPoint* ap in points) {
        if (ap.segment == seg) {
            num++;
        }
    }
    return num;
}

-(OBRalgPoint*) getPointAtLat:(float)lat lon:(float)lon seg:(int)seg{
    for(OBRalgPoint* ap in points) {
        if (ap.segment==seg) {
            float d1 = fabs(ap.lat - lat);
            float d2 = fabs(ap.lon - lon);
            if (d1<.000000000001 && d2<.00000000001) {
                return ap;
            }
        }
    }
    NSLog(@"could not locate point!");
    return nil;
}

-(OBRalgPoint*) getPointAtLat:(float)lat lon:(float)lon {
    for(OBRalgPoint* ap in points) {
        float d1 = fabs(ap.lat - lat);
        float d2 = fabs(ap.lon - lon);
        if (d1<.000000000001 && d2<.00000000001) {
            return ap;
        }
    }
    NSLog(@"could not locate point!");
    return nil;
}

-(id<MKAnnotation>) getAnnotationAtLat:(float)lat lon:(float)lon {
    for(id<MKAnnotation> a in self.mapView.annotations) {
        CLLocationCoordinate2D c = a.coordinate;
        float d1 = fabs(c.latitude - lat);
        float d2 = fabs(c.longitude - lon);
        if (d1<.00000001 && d2<.0000000001) {
            return a;
        }
    }
    NSLog(@"could not locate annotation!");
    return nil;
}

@end
