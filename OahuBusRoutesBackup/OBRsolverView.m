//
//  OBRsolverView.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 3/21/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRsolverView.h"
#import "OBRStopNew.h"
#import "OBRMapViewAnnotation.h"
#import <MapKit/MapKit.h>
#import "OBRsolvedRouteRecord.h"

@interface OBRsolverView ()
{
    float progressBarValue;
    //OBRMapViewAnnotation* selectedAnnotation;
    OBRMapViewAnnotation* startFlagAnnotation;
    OBRMapViewAnnotation* destFlagAnnotation;
    OBRMapViewAnnotation* startFlagLabel;
    OBRMapViewAnnotation* destFlagLabel;
    OBRStopNew* selectedStop;
    CLLocationCoordinate2D startPoint;
    CLLocationCoordinate2D endPoint;
    choiceMethod startChoiceMethod;
    choiceMethod endChoiceMethod;
    BOOL startPointSet;
    BOOL endPointSet;
    OBRdataStore* db;
    NSMutableArray* POIannotations;
    OBRMapViewAnnotation* selectedPOI;
    OBRMapViewAnnotation* selectedPOIlabel;
    NSTimer* disableButtonTimer;
    float minStopDistanceToCrosshairs;
    CLLocationCoordinate2D crosshairLocation;
    IOSImage* IOSI;
    IOSTimeFunctions* TF;
}
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *StartButton;
@property (weak, nonatomic) IBOutlet UIButton *EndButton;
@property (weak, nonatomic) IBOutlet UISlider *maxWalkSlider;
@property (weak, nonatomic) IBOutlet UILabel *maxWalkLabel;
@property (nonatomic) NSArray* stops;
@property (nonatomic) NSMutableArray* course;
@property (nonatomic) NSMutableDictionary* cache;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchButton;
@property (weak, nonatomic) IBOutlet UIImageView *crosshairView;
@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;
- (IBAction)pressedMenu:(id)sender;


- (IBAction)maxWalkChanged:(id)sender;
- (IBAction)setStart:(id)sender;
- (IBAction)setEnd:(id)sender;
- (IBAction)solve:(id)sender;

@end

@implementation OBRsolverView

-(NSArray*)stops {
    if (_stops==nil) {
        _stops = [[OBRdataStore defaultStore] getStops];
    }
    return _stops;
}

-(NSMutableDictionary*)cache {
    if (_cache==nil) {
        _cache = [[NSMutableDictionary alloc] init];;
    }
    return _cache;
}

-(NSArray*)course {
    if (_course==nil) {
        _course = [[NSMutableArray alloc] init];
    }
    return _course;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(21.4, -158.0);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(center, 47000, 47000)];
    
    [self.mapView setCenterCoordinate:center animated:YES];
    [self.mapView setZoomEnabled:YES];
    [self.mapView setRegion:adjustedRegion animated:YES];
    [self.mapView setDelegate:self];
    
    //connect to the datastore
    db = [OBRdataStore defaultStore];
    
    //init any variables
    //_maxWaitMin = 60;
    db.solving = false;
    db.interupt = false;
    db.minWalkingDistanceEnd = 200;
    db.minWalkingDistanceStart  = 200;
    startChoiceMethod = NONE;
    endChoiceMethod = NONE;
    startFlagAnnotation = nil;
    destFlagAnnotation = nil;
    startPointSet = false;
    endPointSet = false;
    POIannotations = [[NSMutableArray alloc] init];
    minStopDistanceToCrosshairs = 0;
    IOSI = [[IOSImage alloc] init];
    TF = [[IOSTimeFunctions alloc] init];
    
    
    [_searchButton setEnabled:false];
    
    //initialize the endpoints
    startPoint = CLLocationCoordinate2DMake(0, 0);
    endPoint = CLLocationCoordinate2DMake(0, 0);
    

    //add tap gesture
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(foundTap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [self.mapView addGestureRecognizer:tapRecognizer];
    
    //configure the buttons
    _StartButton.backgroundColor = BLACK;
    [_StartButton setEnabled:false];
    [_EndButton setEnabled:false];
    _StartButton.alpha = 0;
    _EndButton.alpha = 0;
    
    //add two test annotation
    [self addAnnotation:@"test1" lat:21.50511 lon:-157.89 color:YELLOW type:@"test" subtitle:@""];
    [self addAnnotation:@"test2" lat:21.530511 lon:-157.98 color:YELLOW type:@"test" subtitle:@""];
    

    
}

-(void)viewWillAppear:(BOOL)animated {
    
    //interupt the detached solver thread if we are stepping back from an impossible problem
    db.interupt = true;
    
    
    //convert the value for logrithmic scale
    [self updateSliders];
    
    //update the icon with the number of solutions
    [db updateNumSolIcon:db.solvedRoutes.count Color:BLACK Alpha:1.0];
    

}

-(void)viewDidAppear:(BOOL)animated {
    db.forwardToList = true;
    db.forwardToSolving = true;
    db.routeListViewed = false;
}

-(void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView* av in views) {
        [[av superview] bringSubviewToFront:av];
    }
}

-(void)removeAnnotationTypes:(NSString*)s {
    
    for (id<MKAnnotation> a in _mapView.annotations) {
        //return if this is a user class
        if (![a isKindOfClass:[MKUserLocation class]]) {
            OBRMapViewAnnotation* oa = a;
            if ([oa.type isEqualToString:s]) {
                [self.mapView removeAnnotation:a];
            }
        }
    }
}



-(MKAnnotationView *) mapView:(MKMapView *)mapView
            viewForAnnotation:(id <MKAnnotation>) annotation {
    
    MKAnnotationView *annView=[[MKAnnotationView alloc]
                               initWithAnnotation:annotation reuseIdentifier:@"pin"];
    
    //return if this is a user class
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return annView;
    }
    
    //get the properties
    OBRMapViewAnnotation* a = annotation;
    UIColor* color = a.color;
    NSString* title = a.title;
    NSString* subtitle = a.subtitle;
    
    //NSLog(@"viewForAnnotation type = %@ sf=%@  sl=%@",a.type,startFlagAnnotation,startFlagLabel);
    
    
    
    if ([a.type isEqualToString:@"startFlag"]) {
        
        //remove the old start flag
        startFlagAnnotation = a;
        
        //get the image
        annView.image = [IOSI imageWithFilename:@"HollowFlag.png" Color:color Size:50];
        annView.centerOffset = CGPointMake(14,-21);
        annView.layer.zPosition = 1000;
        return annView;
    }
    
    if ([a.type isEqualToString:@"nearStart"]) {
        
        annView.image = [IOSI imageWithFilename:@"BusStopSign.png" Color:GREEN Size:20];
        annView.layer.zPosition = 102;
        return annView;
    }
    
    if ([a.type isEqualToString:@"nearCenter"]) {
        
        annView.image = [IOSI imageWithFilename:@"BusStopSign.png" Color:YELLOW Size:25];
        annView.layer.zPosition = 100;
        return annView;
    }
    
    
    if ([a.type isEqualToString:@"nearDest"]) {
        
        annView.image = [IOSI imageWithFilename:@"BusStopSign.png" Color:RED Size:20];
        annView.layer.zPosition = 101;
        return annView;
    }
    
    if ([a.type isEqualToString:@"destFlag"]) {
        
        //remove the old start flag
        destFlagAnnotation = a;
        
        //get the image
        annView.image = [IOSI imageWithFilename:@"HollowFlag.png" Color:color Size:50];
        annView.centerOffset = CGPointMake(14,-21);
        annView.layer.zPosition = 999;
        return annView;
    }
    
    if ([a.type isEqualToString:@"test"]) {
        
        //get the image
        annView.image = [IOSI imageWithFilename:@"HollowFlag.png" Color:LIGHT_GRAY Size:50];
        annView.centerOffset = CGPointMake(14,-21);
        
        //store the POI annotations
        [POIannotations addObject:a];
            
        return annView;
    }
    
    if ([a.type isEqualToString:@"callout"]) {
        
        IOSLabel* label = [[IOSLabel alloc] initWithText:@[@"Name",@"Address"] Color:YELLOW Sizex:-1 Sizey:40];
        annView.image = label.image.image;
        annView.alpha = 0.8;
        annView.centerOffset = CGPointMake(0,-60);
        selectedPOIlabel = a;
        return annView;
    }
    if ([a.type isEqualToString:@"startLabel"]) {

        startFlagLabel = a;
        IOSLabel* label = [[IOSLabel alloc] initWithText:@[title,subtitle] Color:color Sizex:-1 Sizey:40];
        annView.image = label.image.image;
        annView.alpha = 0.9;
        annView.centerOffset = CGPointMake(0,-60);
        annView.layer.zPosition = 200;
        return annView;
    }
    
    if ([a.type isEqualToString:@"destLabel"]) {
        
        destFlagLabel = a;
        IOSLabel* label = [[IOSLabel alloc] initWithText:@[title,subtitle] Color:color Sizex:-1 Sizey:40];
        annView.image = label.image.image;
        annView.alpha = 0.9;
        annView.centerOffset = CGPointMake(0,-60);
        annView.layer.zPosition = 199;
        return annView;
    }
    

    
    return nil;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    [_crosshairView setHidden:false];
    
    
    //highlight the selected icon
    MKAnnotationView *av=[self.mapView viewForAnnotation:selectedPOI];
    av.image = [IOSI imageWithFilename:@"HollowFlag.png" Color:LIGHT_GRAY Size:50];
    
    av.centerOffset = CGPointMake(14,-21);
    selectedPOI = nil;
    
    //erase the label when it starts to move
    [self.mapView removeAnnotation:selectedPOIlabel];
    selectedPOIlabel = nil;
    
    //hide the set buttons
    [self disableButtons];

}

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    //get the center coordinate of the crosshairs
    CGPoint center = self.crosshairView.center;
    
    crosshairLocation = [self.mapView convertPoint:center toCoordinateFromView:self.view];
    
    //see if any of the annotations are close to the crosshairs
    float maxd = 1000;
    float bestd = maxd;
    for (OBRMapViewAnnotation* a in POIannotations) {
        float d = [self metersBetweenLat1:crosshairLocation.latitude Lon1:crosshairLocation.longitude Lat2:a.coordinate.latitude Lon2:a.coordinate.longitude];
        if (d<maxd) {
            if (d<bestd) {
                bestd = d;
                selectedPOI = a;
            }
        }
    }
    
    //if the POI is close
    if (selectedPOI != nil) {
        [_crosshairView setHidden:true];
        
        //highlight the selected icon
        MKAnnotationView *av=[self.mapView viewForAnnotation:selectedPOI];
        av.image = [IOSI imageWithFilename:@"HollowFlag.png" Color:YELLOW Size:50];
        av.centerOffset = CGPointMake(14,-21);
        
        [self addAnnotation:@"test" lat:selectedPOI.coordinate.latitude
                        lon:selectedPOI.coordinate.longitude
                      color:BLUISH_GREEN type:@"callout" subtitle:@""];

    }
    
    //show the closest stops
    //determine the required distance from the points to the stops
    minStopDistanceToCrosshairs = 50 + [self findDistanceToStopsFromLat:crosshairLocation.latitude
                                                                    Lon:crosshairLocation.longitude];
    if (minStopDistanceToCrosshairs<500) minStopDistanceToCrosshairs = 500;
    [self addStopsWithinRangeOfFlags];
    
    [self startDisablingButtons];
    
}


-(void)startDisablingButtons {
    //reset any other annimations on the buttons
    [_StartButton.layer removeAllAnimations];
    [_EndButton.layer removeAllAnimations];
    [disableButtonTimer invalidate];
    disableButtonTimer = nil;

    
    //show the set buttons
    [_StartButton setEnabled:true];
    [_EndButton setEnabled:true];
    _StartButton.alpha = 1;
    _EndButton.alpha = 1;
    
    CABasicAnimation *theAnimation;
    theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    theAnimation.duration=3;
    theAnimation.repeatCount=1;
    theAnimation.autoreverses=NO;
    theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
    theAnimation.toValue=[NSNumber numberWithFloat:0.0];
    [_StartButton.layer   addAnimation:theAnimation forKey:@"animateOpacity"];
    [_EndButton.layer   addAnimation:theAnimation forKey:@"animateOpacity"];
    
    //disable the buttons at the end of the timer
    disableButtonTimer = [NSTimer scheduledTimerWithTimeInterval:2.95
                                                                   target:self
                                                                 selector:@selector(disableButtons)
                                                                 userInfo:nil
                                                                  repeats:false];
    
}

-(void)disableButtons {
    [_StartButton setEnabled:false];
    [_EndButton setEnabled:false];
    _StartButton.alpha = 0;
    _EndButton.alpha = 0;
}




-(IBAction)foundTap:(UITapGestureRecognizer *)recognizer {
    
    [self startDisablingButtons];
}




-(double)distanceBetweenLat1:(double)lat1 Lon1:(double)lon1
                        Lat2:(double)lat2 Lon2:(double)lon2 {
    double x = lat1-lat2;
    double y = lon1-lon2;
    return sqrt(x*x+y*y);
}

-(double)metersBetweenLat1:(double)lat1 Lon1:(double)lon1
                        Lat2:(double)lat2 Lon2:(double)lon2 {
    double x = 111122.0*(lat1-lat2);
    double y = 102288.0*(lon1-lon2);
    return sqrt(x*x+y*y);
}

-(int)numberOfNearbyStops:(CLLocationCoordinate2D)point {
    long maxWalkingDistance = [[OBRdataStore defaultStore] maxWalkingDistance];
    int num = 0;
    NSArray* sa = [[OBRdataStore defaultStore] getStops];
    for (OBRStopNew* stop in sa) {
        float m = [self metersBetweenLat1:stop.lat Lon1:stop.lon Lat2:point.latitude Lon2:point.longitude];
        if (m<maxWalkingDistance) {
            num++;
        }
    }
    
    return num;
}



-(void)addAnnotation:(NSString*)title
                 lat:(float)lat
                 lon:(float)lon
               color:(UIColor*)color
                type:(NSString*)type
            subtitle:(NSString*)st
{
    // Set some coordinates for our position
	CLLocationCoordinate2D location;
	location.latitude = (double) lat;
	location.longitude = (double) lon;
    
	// Add the annotation to our map view
	OBRMapViewAnnotation *newAnnotation = [[OBRMapViewAnnotation alloc] initWithTitle:title
                                                                        andCoordinate:location
                                                                          andSubtitle:st];
    //store the attributes
    newAnnotation.type = type;
    newAnnotation.color = color;
    
    [self.mapView addAnnotation:newAnnotation];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[OBRdataStore defaultStore] clearCache];
}


// In a storyboard-based application, you will often want to do a little preparation before navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//    if ([[segue identifier] isEqualToString:@"SolverToRouteListView"])
//    {
//        //YourViewController *yourVC = [segue destinationViewController];
//    }
}


- (IBAction)pressedMenu:(id)sender {
        UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Menu:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                            @"Current Location as Start",
                            @"Current Destination as End",
                            @"Add POIs",
                            @"Add Past Locations",
                            @"Search Web",
                            nil];
    popup.tag = 1;
    [popup showInView:[UIApplication sharedApplication].keyWindow];
    
}

- (IBAction)maxWalkChanged:(id)sender {
    int mw = powf(10,(float) _maxWalkSlider.value/1000.0);
    _maxWalkLabel.text = [NSString stringWithFormat:@"%dm",mw];
    [OBRdataStore defaultStore].maxWalkingDistance = mw;
    
    [self addStopsWithinRangeOfFlags];

}

-(float)findDistanceToStopsFromLat:(float)lat Lon:(float)lon {
    float distance1 = 1e9;
    float distance2 = 1e9;
    for (OBRStopNew* stop in db.stops) {
        float d = [self metersBetweenLat1:lat Lon1:lon Lat2:stop.lat Lon2:stop.lon];
        float e1 = fabsf(distance1-d);
        float e2 = fabsf(distance2-d);
        if (e1>=e2 && d<distance1) distance1 = d;
        else if (e2>e1 && d<distance2) distance2 = d;
    }
    return MAX(distance1, distance2);
}


- (IBAction)setStart:(id)sender {
    
    //update the icon with the number of solutions
    [db updateNumSolIcon:0 Color:BLACK Alpha:1.0];
    

    if (selectedPOI == nil) {
        //use map coordinates
        CGPoint center = self.crosshairView.center;
        CLLocationCoordinate2D location = [self.mapView convertPoint:center toCoordinateFromView:self.view];
        
        //use POI coordinates
        startPointSet = true;
        startPoint = location;

        [self removeAnnotationTypes:@"startFlag"];
        [self removeAnnotationTypes:@"startLabel"];
        
        //add a starting flag
        [self addAnnotation:@"Starting Point" lat:startPoint.latitude lon:startPoint.longitude color:GREEN type:@"startFlag" subtitle:@""];
        NSString* title =  [NSString stringWithFormat:@"Coordinates (%5.5f, %5.5f)",startPoint.latitude,startPoint.longitude];

        //create a start label
        [self addAnnotation:@"Start Name" lat:startPoint.latitude lon:startPoint.longitude color:GREEN type:@"startLabel" subtitle:title];
        
        //remove the POI labels
        [_mapView removeAnnotation:selectedPOIlabel];
        selectedPOIlabel = nil;

    } else {
        //use POI coordinates
        startPointSet = true;
        startPoint = selectedPOI.coordinate;

        [self removeAnnotationTypes:@"startFlag"];
        [self removeAnnotationTypes:@"startLabel"];
        
        //add a starting flag
        [self addAnnotation:@"Starting Point" lat:startPoint.latitude lon:startPoint.longitude color:GREEN type:@"startFlag" subtitle:@""];
        NSString* title =  [NSString stringWithFormat:@"Coordinates (%5.5f, %5.5f)",startPoint.latitude,startPoint.longitude];

        //create a start label
        [self addAnnotation:@"Start Name" lat:startPoint.latitude lon:startPoint.longitude color:GREEN type:@"startLabel" subtitle:title];
        
        //remove the POI labels
        [_mapView removeAnnotation:selectedPOIlabel];
        selectedPOIlabel = nil;
        
    }
    
    if (startPointSet && endPointSet) {
        [_searchButton setEnabled:true];
    }
    
    //determine the required distance from the points to the stops
    db.minWalkingDistanceStart = 50 + [self findDistanceToStopsFromLat:startPoint.latitude
                                           Lon:startPoint.longitude];
    [self updateSliders];
    [self addStopsWithinRangeOfFlags];
    
    
}

-(void)addStopsWithinRangeOfFlags{
    
    
    //find the new stops in range
    NSMutableSet* nearStart = [[NSMutableSet alloc] init];
    NSMutableSet* nearDest = [[NSMutableSet alloc] init];
    NSMutableSet* nearCenter = [[NSMutableSet alloc] init];
    for (OBRStopNew* stop in [db stops]) {
        
        //add start stops
        float d = [self metersBetweenLat1:startPoint.latitude Lon1:startPoint.longitude Lat2:stop.lat Lon2:stop.lon];
        if (d<db.maxWalkingDistance) {
            [nearStart addObject:stop];
            
        }
    
        //add Destination stops
        d = [self metersBetweenLat1:endPoint.latitude Lon1:endPoint.longitude Lat2:stop.lat Lon2:stop.lon];
        if (d<db.maxWalkingDistance) {
            [nearDest addObject:stop];
        }
        
        //add stops near crosshairs
        d = [self metersBetweenLat1:crosshairLocation.latitude Lon1:crosshairLocation.longitude Lat2:stop.lat Lon2:stop.lon];
        if (d<minStopDistanceToCrosshairs) {
            [nearCenter addObject:stop];
        }
        
        
    }
    
    //remove any stops that arnt in one or the other sets
    for (OBRMapViewAnnotation* mva in self.mapView.annotations) {
        if ([mva.type isEqualToString:@"nearStart"] ||
            [mva.type isEqualToString:@"nearDest"] ||
            [mva.type isEqualToString:@"nearCenter"]) {
            bool found = false;
            for (OBRStopNew* stop in nearStart) {
                if (stop.lat == mva.coordinate.latitude &&
                    stop.lon == mva.coordinate.longitude) {
                    found = true;
                    break;
                }
            }
            for (OBRStopNew* stop in nearDest) {
                if (stop.lat == mva.coordinate.latitude &&
                    stop.lon == mva.coordinate.longitude) {
                    found = true;
                    break;
                }
            }
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
    
    //add any stops that aren't already present
    for (OBRStopNew* stop in nearStart) {
        bool found = false;
        for (OBRMapViewAnnotation* mva in self.mapView.annotations) {
            if (stop.lat == mva.coordinate.latitude &&
                stop.lon == mva.coordinate.longitude) {
                found = true;
                break;
            }
        }
        [self addAnnotation:@"stop" lat:stop.lat lon:stop.lon color:RED type:@"nearStart" subtitle:@""];
    }
    
    //add any stops that aren't already present
    for (OBRStopNew* stop in nearDest) {
        bool found = false;
        for (OBRMapViewAnnotation* mva in self.mapView.annotations) {
            if (stop.lat == mva.coordinate.latitude &&
                stop.lon == mva.coordinate.longitude) {
                found = true;
                break;
            }
        }
        [self addAnnotation:@"stop" lat:stop.lat lon:stop.lon color:RED type:@"nearDest" subtitle:@""];

    }
    
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
        [self addAnnotation:@"stop" lat:stop.lat lon:stop.lon color:YELLOW type:@"nearCenter" subtitle:@""];

    }
    
}

-(void)updateSliders {
    
    float requiredWalk = MAX(db.minWalkingDistanceStart, db.minWalkingDistanceEnd);
    float vv =1000*log10(requiredWalk);
    _maxWalkSlider.minimumValue = vv;
    //NSLog(@"startmin = %f  endmin=%f  min=%f  slidermin=%f",db.minWalkingDistanceStart,
    //      db.minWalkingDistanceEnd,
    //requiredWalk,
    //      vv);
    
    //set the amount of walking to a minimum
    db.maxWalkingDistance = requiredWalk;
    
//    //convert the value for logrithmic scale
//    if (db.maxWalkingDistance < requiredWalk) {
//        db.maxWalkingDistance = requiredWalk;
//        //NSLog(@"setting maxwalk to required walk %f",requiredWalk);
//    } else {
//        db.maxWalkingDistance = 500;
//        //NSLog(@"setting maxwalk to 500");
//    }
    float v = 1000*log10(db.maxWalkingDistance);
    _maxWalkSlider.value = v;
    _maxWalkLabel.text = [NSString stringWithFormat:@"%d",db.maxWalkingDistance];
    
}

- (IBAction)setEnd:(id)sender {
    endPoint = CLLocationCoordinate2DMake(selectedStop.lat, selectedStop.lon);
    
    
    //update the icon with the number of solutions
    [db updateNumSolIcon:0 Color:BLACK Alpha:1.0];
    
    if (selectedPOI == nil) {
        //use map coordinates
        CGPoint center = self.crosshairView.center;
        CLLocationCoordinate2D location = [self.mapView convertPoint:center toCoordinateFromView:self.view];
        
        //use POI coordinates
        endPointSet = true;
        endPoint = location;
        
        [self removeAnnotationTypes:@"destFlag"];
        [self removeAnnotationTypes:@"destLabel"];
        
        //add a flag
        [self addAnnotation:@"Destination Point" lat:endPoint.latitude lon:endPoint.longitude color:RED type:@"destFlag" subtitle:@""];
        NSString* title =  [NSString stringWithFormat:@"Coordinates (%5.5f, %5.5f)",endPoint.latitude,endPoint.longitude];
        
        //create a label
        [self addAnnotation:@"Destimation Name" lat:endPoint.latitude lon:endPoint.longitude color:RED type:@"destLabel" subtitle:title];
        
        //remove the POI labels
        [_mapView removeAnnotation:selectedPOIlabel];
        selectedPOIlabel = nil;
        
    } else {
        //use POI coordinates
        endPointSet = true;
        endPoint = selectedPOI.coordinate;
        
        [self removeAnnotationTypes:@"destFlag"];
        [self removeAnnotationTypes:@"destLabel"];
        
        //add a starting flag
        [self addAnnotation:@"Destination Point" lat:endPoint.latitude lon:endPoint.longitude color:RED type:@"destFlag" subtitle:@""];
        NSString* title =  [NSString stringWithFormat:@"Coordinates (%5.5f, %5.5f)",endPoint.latitude,endPoint.longitude];
        
        //create a start label
        [self addAnnotation:@"Destination Name" lat:endPoint.latitude lon:endPoint.longitude color:RED type:@"destLabel" subtitle:title];
        
        //remove the POI labels
        [_mapView removeAnnotation:selectedPOIlabel];
        selectedPOIlabel = nil;
        
    }
    
    
    if (startPointSet && endPointSet) {
        [_searchButton setEnabled:true];
    }
    
    
    //determine the required distance from the points to the stops
    db.minWalkingDistanceEnd = 50 + [self findDistanceToStopsFromLat:endPoint.latitude
                                                Lon:endPoint.longitude];
  
    [self updateSliders];
    [self addStopsWithinRangeOfFlags];
}


- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (popup.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0:
                    NSLog(@"Current Location not implemented yet");
                    break;
                case 1:
                    NSLog(@"Popular locations not implemented yet");
                    break;
                case 2:
                    NSLog(@"map locations not implemented yet");
                    break;
                case 3:
                    NSLog(@"Past locations not implemented yet");
                    break;
                case 4:
                    NSLog(@"Search Web not implemented yet");
                    break;
                default:
                    break;
            }
            break;
        }
        
    }
    
}



-(void) setStartToCurrentLocation {
    
}






-(void)appendToLinkedListInitial:(OBRsolvedRouteRecord*)first
                       newRecord:(OBRsolvedRouteRecord*)r {
    OBRsolvedRouteRecord* p = first;
    while (p.nextRec != nil) {
        p = p.nextRec;
    }
    p.nextRec = r;
}


-(void) printLinkedList:(OBRsolvedRouteRecord*)start {
    NSLog(@"printing linked list");
    OBRsolvedRouteRecord* p=start;
    while (p.nextRec!=nil) {
        NSLog(@"middle %@",p.description);
        p = p.nextRec;
    }
    NSLog(@"%@",p.description);
}






- (IBAction)solve:(id)sender {
    
    //erase the previously solved routes
    [db eraseSolvedRoutes];
    db.chosenRoute = nil;
    db.solvingNumRoutesConsidered =0;
    db.solvingNumRoutesFound = 0;
    
    //update the icon with the number of solutions
    [db updateNumSolIcon:0 Color:BLACK Alpha:1.0];
    
    //start the processing thread
    [NSThread detachNewThreadSelector:@selector(newProcessSolver) toTarget:self withObject:nil];
    
    //jump to the solving view controller
    if (db.forwardToSolving) {
        db.forwardToSolving = false;
        [self performSegueWithIdentifier:@"solvingVC" sender:self];
    }
}








-(void)searchingSingleRouteSol:(NSSet*)initialRouteSet
                 finalRouteSet:(NSSet*) finalRouteSet
                  initialStops:(NSArray*) initialStops
                    finalStops:(NSArray*) finalStops
                     dayOfWeek:(long) dayofWeek
                      earlyMin:(long)earlyMin
                       lateMin:(long)lateMin
                   courseStart:(OBRsolvedRouteRecord*)courseStart  {
    //get the threaded database
    //OBRdataStore* databaseT = [OBRdataStore defaultStore];
    
    
    db.solvingLabelText = @"Searching Single Route Sol";
    if ([initialRouteSet intersectsSet:finalRouteSet]) {
        NSMutableSet* commonRoute = [[NSMutableSet alloc] initWithSet:initialRouteSet];
        [commonRoute intersectSet:finalRouteSet];
        
        for (NSString* r in commonRoute) {
            for (int i=0 ; i<initialStops.count ; i++) {
                @autoreleasepool {
                    
                    
                    if (db.interupt) return;
                    double v = [initialStops[i] doubleValue];
                    int isn = round(((v - floor(v))*10000));
                    if  ([db isStop:isn onRouteStr:r]) {
                        
                        
                        for (int j=0 ; j<finalStops.count ; j++) {
                            
                            
                            
                            if (db.interupt) return;
                            double vj = [finalStops[j] doubleValue];
                            int fsn = round(((vj - floor(vj))*10000));
                            if ([db isStop:fsn onRouteStr:r]) {

                                @autoreleasepool {
                                            
                                
                                db.solvingLabelText = [NSString stringWithFormat:@" Searching S%d R%@ S%d",isn,r, fsn];
                                
                                //not sure if this is the right place
                                db.solvingNumRoutesConsidered++;
                                
                                //find two stops on the same route
                                NSArray* esch = [db getNewSchForRoutestr:r Stop:isn Day:dayofWeek eMin:earlyMin lMin:lateMin Thread:TRUE];
                                NSArray* lsch = [db getNewSchForRoutestr:r Stop:fsn Day:dayofWeek eMin:earlyMin lMin:lateMin Thread:TRUE];
                                
                                //compare the bus trips and the times to find a valid combination
                                for (OBRScheduleNew* es in esch) {
                            
                                    
                                        for (OBRScheduleNew* ef in lsch) {
                                            
                                            if (db.interupt) return;
                                            if ([es.trip.tripStr isEqualToString:ef.trip.tripStr]) {
                                                if (es.minOfDay < ef.minOfDay) {
                                                    //this should be a viable route
                                                    //same bus trip, suitable times
                                                    //NSLog(@"found a valid combination \n %@ \n %@",es.description,ef.description);
                                                    
                                                    //compute the walking distance to the first stop.
                                                    //assume an average person can walk 5000m/hr
                                                    OBRStopNew* initialStop = [db getStop:es.stop.number];
                                                    float distancetoStart = [self metersBetweenLat1:initialStop.lat
                                                                                               Lon1:initialStop.lon
                                                                                               Lat2:startPoint.latitude
                                                                                               Lon2:startPoint.longitude];
                                                    OBRsolvedRouteRecord* r = [[OBRsolvedRouteRecord alloc] initWalk:floor(distancetoStart)];
                                                    r.minOfDayArrive = es.minOfDay-5 - floor(distancetoStart/5000.0*60.0);
                                                    r.minOfDayDepart = es.minOfDay-5;
                                                    r.day = es.day;
                                                    r.distanceMeters = floor(distancetoStart);
                                                    r.lat = startPoint.latitude;
                                                    r.lon = startPoint.longitude;
                                                    courseStart = r;
                                                    
                                                    //add the initial stop.  Add in a min five minute wait
                                                    //TODO make the minimum wait a preference.
                                                    r = [[OBRsolvedRouteRecord alloc] initStop:es.stop.number];
                                                    r.minOfDayArrive = es.minOfDay-5;
                                                    r.minOfDayDepart = es.minOfDay;
                                                    r.waitMin = 5;
                                                    r.day = es.day;
                                                    [self appendToLinkedListInitial:courseStart newRecord:r];
                                                    
                                                    //add the bus route
                                                    r = [[OBRsolvedRouteRecord alloc] initRoute:es.trip.route];
                                                    r.direction = es.trip.direction;
                                                    r.headsign = es.trip.headsign;
                                                    r.trip = es.trip.tripStr;
                                                    r.day = es.day;
                                                    r.waitMin = ef.minOfDay - es.minOfDay;
                                                    r.minOfDayArrive = es.minOfDay;
                                                    r.minOfDayDepart = ef.minOfDay;
                                                    [self appendToLinkedListInitial:courseStart newRecord:r];
                                                    
                                                    //add the final stop
                                                    r = [[OBRsolvedRouteRecord alloc] initStop:ef.stop.number];
                                                    r.minOfDayArrive = ef.minOfDay;
                                                    r.minOfDayDepart = ef.minOfDay;
                                                    r.waitMin = 0;
                                                    r.day = ef.day;
                                                    r.transition = true;
                                                    [self appendToLinkedListInitial:courseStart newRecord:r];
                                                    
                                                    //add the walking distance to the destination
                                                    OBRStopNew* finalStop = [db getStop:ef.stop.number];
                                                    float distanceToDest = [self metersBetweenLat1:finalStop.lat
                                                                                              Lon1:finalStop.lon
                                                                                              Lat2:endPoint.latitude
                                                                                              Lon2:endPoint.longitude];
                                                    r = [[OBRsolvedRouteRecord alloc] initWalk:floor(distanceToDest)];
                                                    r.minOfDayArrive = ef.minOfDay;
                                                    r.minOfDayDepart = ef.minOfDay + floor(distanceToDest/5000.0*60.0);
                                                    r.distanceMeters = floor(distanceToDest);
                                                    r.day = ef.day;
                                                    r.lat = endPoint.latitude;
                                                    r.lon = endPoint.longitude;
                                                    [self appendToLinkedListInitial:courseStart newRecord:r];
                                                    
                                                    //the summary description is used by addsolvedroutes to avoid
                                                    //regenerating the desctiption
                                                    courseStart.summaryDes = courseStart.description;
                                                    courseStart.summaryRouteType = SRS;
                                                    
                                                    //this function checks for duplicate and
                                                    //better routes and does not blinds add the route
                                                    [db addSolvedRoutes:courseStart];
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    //clean the cache
    //[databaseT clearCache];
}


-(void)searchingStopRouteStop:(NSSet*)initialRouteSet
                finalRouteSet:(NSSet*) finalRouteSet
                 initialStops:(NSArray*) initialStops
                   finalStops:(NSArray*) finalStops
                    dayOfWeek:(long) dayofWeek
                     earlyMin:(long)earlyMin
                      lateMin:(long)lateMin
                  courseStart:(OBRsolvedRouteRecord*)courseStart  {
    
    //get the threaded database
    OBRdataStore* databaseT = [OBRdataStore defaultStore];
    
    NSLog(@"solving RSR...");
    bool debugRSR = false;
    databaseT.solvingLabelText = @"Searching Dual Routes";
    for (NSString* initRoute in initialRouteSet) {
        
        @autoreleasepool {
        for (NSString* finalRoute in finalRouteSet) {
            
            @autoreleasepool {
                
                databaseT.solvingNumRoutesConsidered++;
                
                if (db.interupt) return;
                NSArray* stops = [databaseT getJointStopsOnRoute1:initRoute Route2:finalRoute];
                for (NSNumber* stop in stops) {
                    int msn = [stop intValue];    //middle stop number
                    databaseT.solvingLabelText = [NSString stringWithFormat:@"RSR R%@ S%d R%@",initRoute,msn,finalRoute];
                    
                    databaseT.solvingNumRoutesConsidered++;
                    
                    //NSTimeInterval t1 = [TF currentTimeSec];
                    NSArray* msch = [databaseT getNewSchForRoutestr:initRoute
                                                                    Stop:msn
                                                                     Day:dayofWeek
                                                                    eMin:earlyMin
                                                                    lMin:lateMin
                                                                  Thread:TRUE];
                    //NSTimeInterval t2 = [TF currentTimeSec];
                    //NSLog(@"file= %f",t2-t1);
                    
//                    NSTimeInterval t3 = [TF currentTimeSec];
//                    NSArray* junk = [databaseT getNewSchForRoutestr:initRoute
//                                                                    Stop:msn
//                                                                     Day:dayofWeek
//                                                                    eMin:earlyMin
//                                                                    lMin:lateMin
//                                                                  Thread:TRUE];
//                    NSTimeInterval t4 = [TF currentTimeSec];
//                    NSLog(@"db= %f",t4-t3);
//                    

                    
                    
                    NSArray* msch2 = [databaseT getNewSchForRoutestr:finalRoute
                                                                     Stop:msn
                                                                      Day:dayofWeek
                                                                     eMin:earlyMin
                                                                     lMin:lateMin
                                                                   Thread:TRUE];
                    if (debugRSR) NSLog(@"get msch/msch2 for msn %d [%ld %ld] eMin %ld", msn,(unsigned long)msch.count,msch2.count,earlyMin);
                    
                    
                    for (int i=0 ; i<initialStops.count ; i++) {
                        if (db.interupt) return;
                        databaseT.solvingNumRoutesConsidered++;
                        double v = [initialStops[i] doubleValue];
                        int isn = round(((v - floor(v))*10000));  //initial stop number
                        if  ([databaseT isStop:isn onRouteStr:initRoute]) {
                            
                            NSArray* esch = [databaseT getNewSchForRoutestr:initRoute
                                                                            Stop:isn
                                                                             Day:dayofWeek
                                                                            eMin:earlyMin
                                                                            lMin:lateMin
                                                                          Thread:TRUE];
                            
                            if (msch.count==0 || esch.count==0) {
                                NSLog(@"found a zero schedule return");
                            }
                            
                            //compare the bus trips and the times to find a valid combination
                            for (OBRScheduleNew* es in esch) {
                                
        
                                @autoreleasepool {
                                    
                                    for (OBRScheduleNew* em in msch) {
                                        if (databaseT.interupt) return;
                                        databaseT.solvingNumRoutesConsidered++;
                                        if ([es.trip.tripStr isEqualToString:em.trip.tripStr]) {
                                            if (es.minOfDay < em.minOfDay) {
                                                //this should be a viable route
                                                if (debugRSR) NSLog(@"RSR init SI %d(%d) R %@ SM %d(%d) [%ld,%ld] ",isn,es.minOfDay,initRoute,msn,em.minOfDay,(unsigned long)esch.count,(unsigned long)msch.count);
                                                
                                                
                                                
                                                
                                                for (int jj=0 ; jj<finalStops.count ; jj++) {
                                                    //if (![OBRdataStore defaultStore].solving) break;
                                                    databaseT.solvingNumRoutesConsidered++;
                                                    double vvv = [finalStops[jj] doubleValue];
                                                    int fsn = round(((vvv - floor(vvv))*10000));
                                                    if  ([databaseT isStop:fsn onRouteStr:finalRoute]) {
                                                        
                                                        NSArray* fsch = [databaseT getNewSchForRoutestr:finalRoute
                                                                                                        Stop:fsn
                                                                                                         Day:dayofWeek
                                                                                                        eMin:earlyMin
                                                                                                        lMin:lateMin
                                                                                                      Thread:TRUE];
                                                        if (debugRSR) NSLog(@"    RSR final SM%d R%@ SF%d [%ld %ld] emin %d",msn,finalRoute,fsn,(unsigned long)msch2.count,fsch.count,em.minOfDay);
                                                        
                                                        
                                                        if (fsch.count == 0) {
                                                            //test condition
                                                            [databaseT isStop:fsn onRouteStr:finalRoute];
                                                        }
                                                        //compare the bus trips and the times to find a valid combination
                                                        for (OBRScheduleNew* em2 in msch2) {
                                                            for (OBRScheduleNew* ef in fsch) {
                                                                //if (!_processing) break;
                                                                databaseT.solvingNumRoutesConsidered++;
                                                                //NSLog(@"            comparing %@ to %@  %@ %@",em2.trip.tripStr,ef.trip.tripStr,em2.trip.direction,ef.trip.direction);
                                                                
                                                                if (em.minOfDay < em2.minOfDay) {
                                                                    //NSLog(@"            comparing %d to %d trip:%@ %@",em2.minOfDay,ef.minOfDay,ef.trip.tripStr,ef.trip.direction);
                                                                    if (em2.minOfDay < ef.minOfDay) {
                                                                        
                                                                        if ([em2.trip.tripStr isEqualToString:ef.trip.tripStr]) {
                                                                            
                                                                            
                                                                            
                                                                            //this should be a viable route
                                                                            if (debugRSR) {
                                                                                NSLog(@"found a viable route last leg");
                                                                                NSLog(@"%@",es.description);
                                                                                NSLog(@"%@",em.description);
                                                                                NSLog(@"%@",em2.description);
                                                                                NSLog(@"%@",ef.description);
                                                                            }
                                                                            
                                                                            //compute the walking distance to the first stop.
                                                                            //assume an average person can walk 5000m/hr
                                                                            OBRStopNew* initialStop = [databaseT getStop:es.stop.number];
                                                                            float distancetoStart = [self metersBetweenLat1:initialStop.lat Lon1:initialStop.lon Lat2:startPoint.latitude Lon2:startPoint.longitude];
                                                                            OBRsolvedRouteRecord* r = [[OBRsolvedRouteRecord alloc] initWalk:floor(distancetoStart)];
                                                                            r.minOfDayArrive = es.minOfDay-5 - floor(distancetoStart/5000.0*60.0);
                                                                            r.minOfDayDepart = es.minOfDay-5;
                                                                            r.day = es.day;
                                                                            r.distanceMeters = floor(distancetoStart);
                                                                            r.lat = startPoint.latitude;
                                                                            r.lon = startPoint.longitude;
                                                                            courseStart = r;
                                                                            
                                                                            //add the initial stop.  Add in a min five minute wait
                                                                            //TODO make the minimum wait a preference.
                                                                            r = [[OBRsolvedRouteRecord alloc] initStop:es.stop.number];
                                                                            r.minOfDayArrive = es.minOfDay-5;
                                                                            r.minOfDayDepart = es.minOfDay;
                                                                            r.day = es.day;
                                                                            r.waitMin = 5;
                                                                            r.day = es.day;
                                                                            [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                            
                                                                            //add the bus route
                                                                            r = [[OBRsolvedRouteRecord alloc] initRoute:es.trip.route];
                                                                            r.direction = es.trip.direction;
                                                                            r.headsign = es.trip.headsign;
                                                                            r.trip = es.trip.tripStr;
                                                                            r.day = es.day;
                                                                            r.minOfDayArrive = es.minOfDay;
                                                                            r.minOfDayDepart = em.minOfDay;
                                                                            r.waitMin = r.minOfDayDepart - r.minOfDayArrive;
                                                                            [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                            
                                                                            //add the middle stop
                                                                            r = [[OBRsolvedRouteRecord alloc] initStop:em.stop.number];
                                                                            r.minOfDayArrive = em.minOfDay;
                                                                            r.minOfDayDepart = em2.minOfDay;
                                                                            r.waitMin = r.minOfDayDepart - r.minOfDayArrive;
                                                                            r.day = em.day;
                                                                            r.transition = false;
                                                                            [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                            
                                                                            //add the second route
                                                                            r = [[OBRsolvedRouteRecord alloc] initRoute:ef.trip.route];
                                                                            r.direction = ef.trip.direction;
                                                                            r.headsign = ef.trip.headsign;
                                                                            r.trip = ef.trip.tripStr;
                                                                            r.day = ef.day;
                                                                            r.waitMin = ef.minOfDay - em2.minOfDay;
                                                                            r.minOfDayArrive = em2.minOfDay;
                                                                            r.minOfDayDepart = ef.minOfDay;
                                                                            [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                            
                                                                            
                                                                            //add the final stop
                                                                            r = [[OBRsolvedRouteRecord alloc] initStop:ef.stop.number];
                                                                            r.minOfDayArrive = ef.minOfDay;
                                                                            r.minOfDayDepart = ef.minOfDay;
                                                                            r.waitMin = 0;
                                                                            r.day = ef.day;
                                                                            r.transition = true;
                                                                            [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                            
                                                                            //add the walking distance to the destination
                                                                            OBRStopNew* finalStop = [databaseT getStop:ef.stop.number];
                                                                            float distanceToDest = [self metersBetweenLat1:finalStop.lat Lon1:finalStop.lon Lat2:endPoint.latitude Lon2:                    endPoint.longitude];
                                                                            r = [[OBRsolvedRouteRecord alloc] initWalk:floor(distanceToDest)];
                                                                            r.minOfDayArrive = ef.minOfDay;
                                                                            r.minOfDayDepart = ef.minOfDay + floor(distanceToDest/5000.0*60.0);
                                                                            r.distanceMeters = floor(distanceToDest);
                                                                            r.day = ef.day;
                                                                            r.lat = endPoint.latitude;
                                                                            r.lon = endPoint.longitude;
                                                                            [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                            
                                                                            //set the route type
                                                                            courseStart.summaryRouteType = RSR;
                                                                            
                                                                            //update the earliest arrival time
//                                                                            if (ef.minOfDay < earliestArrival || earliestArrival == -1) {
//                                                                                earliestArrival = ef.minOfDay;
//                                                                            }
                                                                            
                                                                            //update the shortest Travel Time
//                                                                            int firstDepartMin = [courseStart getEarliestDepart];
//                                                                            int lastArriveMin = [courseStart getLatestArrive];
//                                                                            int tripDuration = lastArriveMin - firstDepartMin;
//                                                                            if (tripDuration < shortestTravelTime || shortestTravelTime == -1) {
//                                                                                shortestTravelTime = tripDuration;
//                                                                            }
                                                                            
                                                                            //this function checks for duplicate and
                                                                            //better routes and does not blinds add the route
                                                                            [databaseT addSolvedRoutes:courseStart];
                                                                            
                                                                            
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    }
                }
            }
        }
    }
    
    //clean the cache
    //[databaseT clearCache];
}



-(void)searchingRouteWalkRouteSol:(NSSet*)initialRouteSet
                 finalRouteSet:(NSSet*) finalRouteSet
                  initialStops:(NSArray*) initialStops
                    finalStops:(NSArray*) finalStops
                     dayOfWeek:(long) dayofWeek
                      earlyMin:(long)earlyMin
                       lateMin:(long)lateMin
                   courseStart:(OBRsolvedRouteRecord*)courseStart  {
    
    //get the threaded database
    OBRdataStore* databaseT = [OBRdataStore defaultStore];

    
    databaseT.solvingLabelText = @"Searching RWR Routes";
    if (1) {
        for (NSString* initRoute in initialRouteSet) {
            
            //clear cache
            //databaseT clearCache];
            
            for (NSString* finalRoute in finalRouteSet) {
                databaseT.solvingLabelText = [NSString stringWithFormat:@"RWR %@ %@",initRoute,finalRoute];
                
               databaseT.solvingNumRoutesConsidered++;
                
                @autoreleasepool {
                    
                    if (db.interupt) return;
                    NSArray* midStops = [databaseT getRouteWalkRoute1:initRoute Route2:finalRoute];
                    for (NSArray* arr in midStops) {
                        
                        databaseT.solvingNumRoutesConsidered++;
                        long msn1 = [arr[0] integerValue];  //mid stop number 1
                        long msn2 = [arr[1][0] integerValue];  //mid stop number 2
                        float midDistance = [arr[1][1] floatValue];
                        //NSLog(@"midStop1 %ld midStop2 %ld = %f",msn1,msn2,midDistance);
                        
                        for (int i=0 ; i<initialStops.count ; i++) {
                            if (db.interupt) return;
                            databaseT.solvingNumRoutesConsidered++;
                            double v = [initialStops[i] doubleValue];
                            int isn = round(((v - floor(v))*10000));  //initial stop number
                            if  ([databaseT isStop:isn onRouteStr:initRoute]) {
                                if ([databaseT isStop:msn1 onRouteStr:initRoute]) {
                                    
                                    NSArray* esch = [databaseT getNewSchForRoutestr:initRoute
                                                                                    Stop:isn
                                                                                     Day:dayofWeek
                                                                                    eMin:earlyMin
                                                                                    lMin:lateMin
                                                                                  Thread:TRUE];
                                    //NSLog(@"get esch for %d at %d",isn,earlyMin);
                                    NSArray* msch = [databaseT getNewSchForRoutestr:initRoute
                                                                                    Stop:msn1
                                                                                     Day:dayofWeek
                                                                                    eMin:earlyMin
                                                                                    lMin:lateMin
                                                                                  Thread:TRUE];
                                    //NSLog(@"get msch for %ld at %d",msn1,earlyMin);
                                    //NSLog(@"RWR init S:%d R:%@ S:%ld [%ld,%ld]",isn,initRoute,msn1,esch.count,msch.count);
                                    
                                    
                                    //compare the bus trips and the times to find a valid combination
                                    for (OBRScheduleNew* es in esch) {
                                        
                                        @autoreleasepool {
                                            for (OBRScheduleNew* em in msch) {
                                                if (databaseT.interupt) return;
                                                databaseT.solvingNumRoutesConsidered++;
                                                if ([es.trip.tripStr isEqualToString:em.trip.tripStr]) {
                                                    if (es.minOfDay < em.minOfDay) {
                                                        //this should be a viable route
                                                        //NSLog(@"found a viable route first leg");
                                                        
                                                        
                                                        //compute the earliest possible second leg
                                                        int midWalkMin = floor(midDistance/5000.0*60.0);
                                                        int earliestPossibleSecondLeg = em.minOfDay + midWalkMin;
                                                        
                                                        
                                                        for (int ii=0 ; ii<finalStops.count ; ii++) {
                                                            if (databaseT.interupt) return;
                                                            databaseT.solvingNumRoutesConsidered++;
                                                            double vv = [finalStops[ii] doubleValue];
                                                            int fsn = round(((vv - floor(vv))*10000));
                                                            if  ([databaseT isStop:fsn onRouteStr:finalRoute]) {
                                                                if ([databaseT isStop:msn2 onRouteStr:finalRoute]) {
                                                                    
                                                                    
                                                                    NSArray* msch2 = [databaseT getNewSchForRoutestr:finalRoute
                                                                                                                     Stop:msn2
                                                                                                                      Day:dayofWeek
                                                                                                                     eMin:earliestPossibleSecondLeg
                                                                                                                     lMin:lateMin
                                                                                                                   Thread:TRUE];
                                                                    NSArray* fsch = [databaseT getNewSchForRoutestr:finalRoute
                                                                                                                    Stop:fsn
                                                                                                                     Day:dayofWeek
                                                                                                                    eMin:earliestPossibleSecondLeg
                                                                                                                    lMin:lateMin
                                                                                                                  Thread:TRUE];
                                                                    //NSLog(@"RWR init S:%d(%d) R:%@ S:%ld(%d) [%ld,%ld]      S:%ld R:%@ S:%d [%ld,%ld]",isn,es.minOfDay,initRoute,msn1,em.minOfDay,esch.count,msch.count,msn2,finalRoute,fsn,msch2.count,fsch.count);
                                                                    
                                                                    
                                                                    //compare the bus trips and the times to find a valid combination
                                                                    for (OBRScheduleNew* em2 in msch2) {
                                                                        for (OBRScheduleNew* ef in fsch) {
                                                                            //NSLog(@"RWR init S:%d(%d) R:%@ S:%ld(%d) [%ld,%ld]      S:%ld(%d) R:%@ S:%d(%d) [%ld,%ld]",isn,es.minOfDay,initRoute,msn1,em.minOfDay,esch.count,msch.count,msn2,em2.minOfDay,finalRoute,fsn,ef.minOfDay,msch2.count,fsch.count);
                                                                            if (db.interupt) break;
                                                                            databaseT.solvingNumRoutesConsidered++;
                                                                            if ([em2.trip.tripStr isEqualToString:ef.trip.tripStr]) {
                                                                                if (em.minOfDay < em2.minOfDay) {
                                                                                    if (em2.minOfDay < ef.minOfDay) {
                                                                                        
                                                                                        
                                                                                        //this should be a viable route
                                                                                        //NSLog(@"found a viable route last leg");
                                                                                        //NSLog(@"%@",es.description);
                                                                                        //NSLog(@"%@",em.description);
                                                                                        //NSLog(@"%@",em2.description);
                                                                                        //NSLog(@"%@",ef.description);
                                                                                        
                                                                                        //compute the walking distance to the first stop.
                                                                                        //assume an average person can walk 5000m/hr
                                                                                        OBRStopNew* initialStop = [databaseT getStop:es.stop.number];
                                                                                        float distancetoStart = [self metersBetweenLat1:initialStop.lat Lon1:initialStop.lon Lat2:startPoint.latitude Lon2:startPoint.longitude];
                                                                                        OBRsolvedRouteRecord* r = [[OBRsolvedRouteRecord alloc] initWalk:floor(distancetoStart)];
                                                                                        r.minOfDayArrive = es.minOfDay-5 - floor(distancetoStart/5000.0*60.0);
                                                                                        r.minOfDayDepart = es.minOfDay-5;
                                                                                        r.waitMin = 0;
                                                                                        r.day = es.day;
                                                                                        r.distanceMeters = floor(distancetoStart);
                                                                                        r.lat = startPoint.latitude;
                                                                                        r.lon = startPoint.longitude;
                                                                                        courseStart = r;
                                                                                        
                                                                                        //add the initial stop.  Add in a min five minute wait
                                                                                        //TODO make the minimum wait a preference.
                                                                                        r = [[OBRsolvedRouteRecord alloc] initStop:es.stop.number];
                                                                                        r.minOfDayArrive = es.minOfDay-5;
                                                                                        r.minOfDayDepart = es.minOfDay;
                                                                                        r.waitMin = 5;
                                                                                        r.day = es.day;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the bus route
                                                                                        r = [[OBRsolvedRouteRecord alloc] initRoute:es.trip.route];
                                                                                        r.direction = es.trip.direction;
                                                                                        r.headsign = es.trip.headsign;
                                                                                        r.trip = es.trip.tripStr;
                                                                                        r.day = es.day;
                                                                                        r.minOfDayArrive = es.minOfDay;
                                                                                        r.minOfDayDepart = em.minOfDay;
                                                                                        r.waitMin = r.minOfDayDepart - r.minOfDayArrive;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the middle stop
                                                                                        r = [[OBRsolvedRouteRecord alloc] initStop:em.stop.number];
                                                                                        r.minOfDayArrive = em.minOfDay;
                                                                                        r.minOfDayDepart = em.minOfDay;
                                                                                        r.waitMin = r.minOfDayDepart - r.minOfDayArrive;
                                                                                        r.day = em.day;
                                                                                        r.transition = true;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the walk between stops msn1 and msn2
                                                                                        int midWalkMin = floor(midDistance/5000.0*60.0);
                                                                                        r = [[OBRsolvedRouteRecord alloc] initWalk:floor(midDistance)];
                                                                                        r.minOfDayArrive = em.minOfDay;
                                                                                        r.minOfDayDepart = em.minOfDay + midWalkMin;
                                                                                        r.day = em.day;
                                                                                        r.waitMin = 0;
                                                                                        r.distanceMeters = floor((midDistance));
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the second middle stop
                                                                                        r = [[OBRsolvedRouteRecord alloc] initStop:em2.stop.number];
                                                                                        r.minOfDayArrive = em.minOfDay + midWalkMin;
                                                                                        r.minOfDayDepart = em2.minOfDay;
                                                                                        r.waitMin = r.minOfDayDepart - r.minOfDayArrive;
                                                                                        r.day = em.day;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the second route
                                                                                        r = [[OBRsolvedRouteRecord alloc] initRoute:ef.trip.route];
                                                                                        r.direction = ef.trip.direction;
                                                                                        r.headsign = ef.trip.headsign;
                                                                                        r.trip = ef.trip.tripStr;
                                                                                        r.minOfDayArrive = em2.minOfDay;
                                                                                        r.minOfDayDepart = ef.minOfDay;
                                                                                        r.waitMin = r.minOfDayDepart - r.minOfDayArrive;
                                                                                        r.day = em.day;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        
                                                                                        //add the final stop
                                                                                        r = [[OBRsolvedRouteRecord alloc] initStop:ef.stop.number];
                                                                                        r.minOfDayArrive = ef.minOfDay;
                                                                                        r.minOfDayDepart = ef.minOfDay;
                                                                                        r.waitMin = 0;
                                                                                        r.day = ef.day;
                                                                                        r.transition = true;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the walking distance to the destination
                                                                                        OBRStopNew* finalStop = [databaseT getStop:ef.stop.number];
                                                                                        float distanceToDest = [self metersBetweenLat1:finalStop.lat Lon1:finalStop.lon Lat2:endPoint.latitude Lon2:                    endPoint.longitude];
                                                                                        r = [[OBRsolvedRouteRecord alloc] initWalk:floor(distanceToDest)];
                                                                                        r.minOfDayArrive = ef.minOfDay;
                                                                                        r.minOfDayDepart = ef.minOfDay + floor(distanceToDest/5000.0*60.0);
                                                                                        r.distanceMeters = floor(distanceToDest);
                                                                                        r.lat = endPoint.latitude;
                                                                                        r.lon = endPoint.longitude;
                                                                                        r.day = ef.day;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        
                                                                                        //update the earliest arrival time
//                                                                                        if (ef.minOfDay < earliestArrival || earliestArrival == -1) {
//                                                                                            earliestArrival = ef.minOfDay;
//                                                                                        }
                                                                                        
                                                                                        //update the shortest Travel Time
//                                                                                        int firstDepartMin = [courseStart getEarliestDepart];
//                                                                                        int lastArriveMin = [courseStart getLatestArrive];
//                                                                                        int tripDuration = lastArriveMin - firstDepartMin;
//                                                                                        if (tripDuration < shortestTravelTime || shortestTravelTime == -1) {
//                                                                                            shortestTravelTime = tripDuration;
//                                                                                        }
                                                                                        
                                                                                        //set the route type
                                                                                        courseStart.summaryRouteType = RWR;
                                                                                        
                                                                                        //this function checks for duplicate and
                                                                                        //better routes and does not blinds add the route
                                                                                        [databaseT addSolvedRoutes:courseStart];
                                                                                        
                                                                                        
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}



-(void)searchingRouteRouteRouteSol:(NSSet*)initialRouteSet
                    finalRouteSet:(NSSet*) finalRouteSet
                     initialStops:(NSArray*) initialStops
                       finalStops:(NSArray*) finalStops
                        dayOfWeek:(long) dayofWeek
                         earlyMin:(long)earlyMin
                          lateMin:(long)lateMin
                      courseStart:(OBRsolvedRouteRecord*)courseStart  {
    
    //get the threaded database
    OBRdataStore* databaseT = [OBRdataStore defaultStore];
    
    databaseT.solvingLabelText = @"Searching RRR Routes";
    if (1) {
        for (NSString* initRoute in initialRouteSet) {
            
            @autoreleasepool {
            
            for (NSString* finalRoute in finalRouteSet) {
                
                if (databaseT.interupt) return;
                NSArray* RRRarray = [databaseT getRouteRouteRoute1:initRoute Route2:finalRoute];
                for (NSString* midRoute in RRRarray) {
                    
                    databaseT.solvingLabelText = [NSString stringWithFormat:@"RRR %@ %@ %@",initRoute,midRoute,finalRoute];
                    //NSLog(@"RRR %@ %@ %@",initRoute,midRoute,finalRoute);
                    databaseT.solvingNumRoutesConsidered++;
                    
                    NSArray* stopsIM = [databaseT getJointStopsOnRoute1:initRoute Route2:midRoute];
                    for (NSNumber* stopIM in stopsIM) {
                        int stop2 = [stopIM intValue];    //middle stop number
                        databaseT.solvingLabelText = [NSString stringWithFormat:@"RRR R%@ S%d R%@ S?? R%@",initRoute,stop2,midRoute,finalRoute];
                        
                        databaseT.solvingNumRoutesConsidered++;
                        
                        for (int i=0 ; i<initialStops.count ; i++) {
                            if (databaseT.interupt) return;
                            databaseT.solvingNumRoutesConsidered++;
                            double v = [initialStops[i] doubleValue];
                            int isn = round(((v - floor(v))*10000));  //initial stop number
                            if  ([databaseT isStop:isn onRouteStr:initRoute]) {
                                
                                NSArray* esch = [databaseT getNewSchForRoutestr:initRoute
                                                                        Stop:isn
                                                                         Day:dayofWeek
                                                                        eMin:earlyMin
                                                                        lMin:lateMin
                                                                      Thread:TRUE];
                                NSArray* sch2Alist = [databaseT getNewSchForRoutestr:initRoute
                                                                             Stop:stop2
                                                                              Day:dayofWeek
                                                                             eMin:earlyMin
                                                                             lMin:lateMin
                                                                           Thread:TRUE];
                                
                                //NSLog(@"RRR first leg SI:%d R:%@ SM:%d schI:%ld  schM:%ld ",isn,initRoute,stop2,esch.count,sch2Alist.count);
                                
                                //compare the bus trips and the times to find a valid combination
                                for (OBRScheduleNew* sch1 in esch) {
                                    @autoreleasepool {
                        
                                    for (OBRScheduleNew* sch2A in sch2Alist) {
                                        if (db.interupt) return;
                                        databaseT.solvingNumRoutesConsidered++;
                                        if ([sch1.trip.tripStr isEqualToString:sch2A.trip.tripStr]) {
                                            if (sch1.minOfDay < sch2A.minOfDay) {
                                                //this should be a viable route
                                                //NSLog(@"found a viable route IM first leg %d  %d",sch1.minOfDay,sch2A.minOfDay);
                                                
                                                //here I have a first stop, first route, mid stop, mid route
                                                //find the list of stops between the mid route and the final route
                                                NSArray* stopsBetweenMidAndFinalRoute = [databaseT getJointStopsOnRoute1:midRoute Route2:finalRoute];
                                                
                                                for (NSNumber* stopBetweenMidAndFinalRoute in stopsBetweenMidAndFinalRoute) {
                                                    int stop3 = [stopBetweenMidAndFinalRoute intValue];
                                                    databaseT.solvingLabelText = [NSString stringWithFormat:@"RRR R%@ S%d R%@ S%d R%@",initRoute,stop2,midRoute,stop3,finalRoute];
                                                    //get the schedules between the first middle stop and the second middle stop
                                                    
                                                    
                                                    NSArray* sch2Blist = [databaseT getNewSchForRoutestr:midRoute Stop:stop2 Day:dayofWeek eMin:sch2A.minOfDay lMin:lateMin Thread:true];
                                                    NSArray* sch3Alist = [databaseT getNewSchForRoutestr:midRoute Stop:stop3 Day:dayofWeek eMin:sch2A.minOfDay lMin:lateMin Thread:true];
                                                    //NSLog(@"    RRR second leg SI:%d R1:%@ SM:%d R2:%@ SM2:%d R3:%@ sch:(%ld %ld) schM:(%ld %ld)",isn,initRoute,stop2,midRoute,stop3,finalRoute,esch.count,sch2Alist.count,sch2Blist.count,sch3Alist.count);
                                                    
                                                    for (OBRScheduleNew* sch2B in sch2Blist) {
                                                        for (OBRScheduleNew* sch3A in sch3Alist) {
                                                            
                                                            
                                                            
                                                            if ([sch2B.trip.tripStr isEqualToString:sch3A.trip.tripStr]) {
                                                                if (sch2B.minOfDay < sch3A.minOfDay) {
                                                                    //this should be a viable route
                                                                    //NSLog(@"    found a viable route IM second leg %d %d, %d %d",sch1.minOfDay,sch2A.minOfDay,sch2B.minOfDay,sch3A.minOfDay);
                                                                    
                                                                    
                                                                    //now I have
                                                                    //Stop: isn (sch1)   on initRoute  Stop: stop2(sch2A)
                                                                    //Stop: stop2(sch2B) on midRoute   Stop: stop3(sch3A)
                                                                    //need to find
                                                                    //Stop: stop3(sch3B) on finalRoute  Stop: fsn(sch4)
                                                                    
                                                                    for (int j=0 ; j<finalStops.count ; j++) {
                                                                        if (db.interupt) return;
                                                                        databaseT.solvingNumRoutesConsidered++;
                                                                        double vv = [finalStops[j] doubleValue];
                                                                        int fsn = round(((vv - floor(vv))*10000));  //final stop number
                                                                        
                                                                        NSArray* sch3Blist = [databaseT getNewSchForRoutestr:finalRoute Stop:stop3 Day:dayofWeek eMin:sch3A.minOfDay lMin:lateMin Thread:true];
                                                                        NSArray* sch4list = [databaseT getNewSchForRoutestr:finalRoute Stop:fsn Day:dayofWeek eMin:sch3A.minOfDay lMin:lateMin Thread:true];
                                                                        
                                                                        for (OBRScheduleNew* sch3B in sch3Blist) {
                                                                            for (OBRScheduleNew* sch4 in sch4list) {
                                                                                
                                                                                if ([sch3B.trip.tripStr isEqualToString:sch4.trip.tripStr]) {
                                                                                    if (sch3B.minOfDay < sch4.minOfDay) {
                                                                                        //this should be a viable route
                                                                                        //NSLog(@"    found a viable route IM third leg %d %d, %d %d %d %d",sch1.minOfDay,sch2A.minOfDay,sch2B.minOfDay,sch3A.minOfDay,sch3B.minOfDay,sch4.minOfDay);
                                                                                        
                                                                                        //compute the walking distance to the first stop.
                                                                                        //assume an average person can walk 5000m/hr
                                                                                        OBRStopNew* initialStop = [databaseT getStop:sch1.stop.number];
                                                                                        float distancetoStart = [self metersBetweenLat1:initialStop.lat Lon1:initialStop.lon Lat2:startPoint.latitude Lon2:startPoint.longitude];
                                                                                        OBRsolvedRouteRecord* r = [[OBRsolvedRouteRecord alloc] initWalk:floor(distancetoStart)];
                                                                                        r.minOfDayArrive = sch1.minOfDay-5 - floor(distancetoStart/5000.0*60.0);
                                                                                        r.minOfDayDepart = sch1.minOfDay-5;
                                                                                        r.waitMin = 0;
                                                                                        r.distanceMeters = floor(distancetoStart);
                                                                                        r.lat = startPoint.latitude;
                                                                                        r.lon = startPoint.longitude;
                                                                                        courseStart = r;
                                                                                        
                                                                                        //add the initial stop.  Add in a min five minute wait
                                                                                        //TODO make the minimum wait a preference.
                                                                                        r = [[OBRsolvedRouteRecord alloc] initStop:sch1.stop.number];
                                                                                        r.minOfDayArrive = sch1.minOfDay-5;
                                                                                        r.minOfDayDepart = sch1.minOfDay;
                                                                                        r.waitMin = r.minOfDayDepart - r.minOfDayArrive;
                                                                                        r.day = sch1.day;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the bus route 1
                                                                                        r = [[OBRsolvedRouteRecord alloc] initRoute:sch1.trip.route];
                                                                                        r.direction = sch1.trip.direction;
                                                                                        r.headsign = sch1.trip.headsign;
                                                                                        r.trip = sch1.trip.tripStr;
                                                                                        r.day = sch1.day;
                                                                                        r.minOfDayArrive = sch1.minOfDay;
                                                                                        r.minOfDayDepart = sch2A.minOfDay;
                                                                                        r.waitMin = r.minOfDayDepart - r.minOfDayArrive;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the first middle stop
                                                                                        r = [[OBRsolvedRouteRecord alloc] initStop:sch2A.stop.number];
                                                                                        r.minOfDayArrive = sch2A.minOfDay;
                                                                                        r.minOfDayDepart = sch2B.minOfDay;
                                                                                        r.waitMin = r.minOfDayDepart - r.minOfDayArrive;
                                                                                        r.day = sch2A.day;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the bus route 2
                                                                                        r = [[OBRsolvedRouteRecord alloc] initRoute:sch2B.trip.route];
                                                                                        r.direction = sch2B.trip.direction;
                                                                                        r.headsign = sch2B.trip.headsign;
                                                                                        r.trip = sch2B.trip.tripStr;
                                                                                        r.day = sch2B.day;
                                                                                        r.minOfDayArrive = sch2B.minOfDay;
                                                                                        r.minOfDayDepart = sch3A.minOfDay;
                                                                                        r.waitMin = r.minOfDayDepart - r.minOfDayArrive;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the second middle stop
                                                                                        r = [[OBRsolvedRouteRecord alloc] initStop:sch3A.stop.number];
                                                                                        r.minOfDayArrive = sch3A.minOfDay;
                                                                                        r.minOfDayDepart = sch3B.minOfDay;
                                                                                        r.waitMin = r.minOfDayDepart - r.minOfDayArrive;
                                                                                        r.day = sch3A.day;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the bus route 3
                                                                                        r = [[OBRsolvedRouteRecord alloc] initRoute:sch3B.trip.route];
                                                                                        r.direction = sch3B.trip.direction;
                                                                                        r.headsign = sch3B.trip.headsign;
                                                                                        r.trip = sch3B.trip.tripStr;
                                                                                        r.day = sch3B.day;
                                                                                        r.minOfDayArrive = sch3B.minOfDay;
                                                                                        r.minOfDayDepart = sch4.minOfDay;
                                                                                        r.waitMin = r.minOfDayDepart - r.minOfDayArrive;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the final stop
                                                                                        r = [[OBRsolvedRouteRecord alloc] initStop:sch4.stop.number];
                                                                                        r.minOfDayArrive = sch4.minOfDay;
                                                                                        r.minOfDayDepart = sch4.minOfDay;
                                                                                        r.waitMin = 0;
                                                                                        r.day = sch4.day;
                                                                                        r.transition = true;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        //add the walking distance to the destination
                                                                                        OBRStopNew* finalStop = [databaseT getStop:sch4.stop.number];
                                                                                        float distanceToDest = [self metersBetweenLat1:finalStop.lat
                                                                                                                                  Lon1:finalStop.lon
                                                                                                                                  Lat2:endPoint.latitude
                                                                                                                                  Lon2:endPoint.longitude];
                                                                                        r = [[OBRsolvedRouteRecord alloc] initWalk:floor(distanceToDest)];
                                                                                        r.minOfDayArrive = sch4.minOfDay;
                                                                                        r.minOfDayDepart = sch4.minOfDay + floor(distanceToDest/5000.0*60.0);
                                                                                        r.distanceMeters = floor(distanceToDest);
                                                                                        r.lat = endPoint.latitude;
                                                                                        r.lon = endPoint.longitude;
                                                                                        [self appendToLinkedListInitial:courseStart newRecord:r];
                                                                                        
                                                                                        
                                                                                        //update the earliest arrival time
//                                                                                        if (sch4.minOfDay < earliestArrival || earliestArrival == -1) {
//                                                                                            earliestArrival = sch4.minOfDay;
//                                                                                        }
                                                                                        
                                                                                        //update the shortest Travel Time
//                                                                                        int firstDepartMin = [courseStart getEarliestDepart];
//                                                                                        int lastArriveMin = [courseStart getLatestArrive];
//                                                                                        int tripDuration = lastArriveMin - firstDepartMin;
//                                                                                        if (tripDuration < shortestTravelTime || shortestTravelTime == -1) {
//                                                                                            shortestTravelTime = tripDuration;
//                                                                                        }
                                                                                        
                                                                                        //set the route type
                                                                                        courseStart.summaryRouteType = RRR;
                                                                                        
                                                                                        
                                                                                        //this function checks for duplicate and
                                                                                        //better routes and does not blinds add the route
                                                                                        [databaseT addSolvedRoutes:courseStart];
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
}

-(void)newProcessSolver {
    
    
    //get the threaded database
    OBRdataStore* databaseT = [OBRdataStore defaultStore];

    //start the solving
    NSLog(@"starting solver");
    databaseT.solving = TRUE;
    databaseT.interupt = false;
    
    //start the indicator
    db.busy++;
    
    //determine when the prefs were last changed
    NSTimeInterval nowSec = [databaseT currentTimeSec];
    NSTimeInterval timeSetSec = databaseT.solverTimeSetSec;
    float eSec = nowSec - timeSetSec;
    
    //reset the time preferences if more then four hours have elapsed
    if (eSec > 60) {
        
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate:[NSDate date]];
        long weekday = [comps weekday];

        comps = [gregorian components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:[NSDate date]];
        long hour = [comps hour];
        long minute = [comps minute];
        
         //erase the settings
        databaseT.arrivalDay = weekday;
        databaseT.departureMin = (hour*60+minute)-120;
        databaseT.arrivalMin = (hour*60+minute)+240;
        
    }
    
    //get the preference settings
    long maxWalkingDistance = [databaseT maxWalkingDistance];
    long earlyMin = [databaseT departureMin];
    long lateMin = [databaseT arrivalMin];
    long dayofWeek = [databaseT arrivalDay]; //1=sunday 7=sat
    
    //find the starts and end stops within maxWalkingDistance
    NSMutableArray* initialStops = [[NSMutableArray alloc] init ];
    NSMutableArray* finalStops = [[NSMutableArray alloc] init];
    
    //initialize the closests starts
    NSLog(@"Finding end Points");
    for (OBRStopNew* s in [self stops]) {
        double stopDistance = round(1e3*[self metersBetweenLat1:s.lat
                                                             Lon1:s.lon
                                                             Lat2:startPoint.latitude
                                                             Lon2:startPoint.longitude]);
        if (stopDistance< maxWalkingDistance*1e3) {
            int i = 0;
            for (i=0 ; i<initialStops.count ; i++) {
                double entryDistance = [[initialStops objectAtIndex:i] floatValue];
                if (entryDistance > stopDistance ) break;
            }
            double value = ((float)(s.number))/10000.0;
            value += stopDistance;
            NSString* vs = [NSString stringWithFormat:@"%0.4lf",value];
            [initialStops insertObject:vs atIndex:i];
        }
    }

    for (OBRStopNew* s in [self stops]) {
        double stopDistance = round(1e3*[self metersBetweenLat1:s.lat
                                                           Lon1:s.lon
                                                           Lat2:endPoint.latitude
                                                           Lon2:endPoint.longitude]);
        if (stopDistance< maxWalkingDistance*1e3) {
            int i = 0;
            for (i=0 ; i<finalStops.count ; i++) {
                double entryDistance = [[finalStops objectAtIndex:i] floatValue];
                if (entryDistance > stopDistance ) break;
            }
            double value = ((float)(s.number))/10000.0;
            value += stopDistance;
            long idist = floor(stopDistance);
            NSString* vs = [NSString stringWithFormat:@"%ld.%04d",idist,s.number];
            [finalStops insertObject:vs atIndex:i];
        }
    }

    NSLog(@"Found %ld stops within %ld meters of Start",(unsigned long)initialStops.count,maxWalkingDistance);
    NSLog(@"Found %ld stops within %ld meters of End",(unsigned long)finalStops.count,maxWalkingDistance);

    //loop through the closest stops and find the routes associated
    //with the origin and the destination
    NSMutableSet* initialRouteSet = [self getRouteSetFromStopArray:initialStops];
    NSMutableSet* finalRouteSet = [self getRouteSetFromStopArray:finalStops];

    //search for a common route
    OBRsolvedRouteRecord* courseStart;
    [self searchingSingleRouteSol:initialRouteSet
                    finalRouteSet:finalRouteSet
                     initialStops:initialStops
                       finalStops:finalStops
                        dayOfWeek:(long) dayofWeek
                         earlyMin:(long)earlyMin
                          lateMin:(long)lateMin
                      courseStart:(OBRsolvedRouteRecord*)courseStart];
    
    //get any single route solutions and remove them from the search path
    //why take multiple buses if one will get you there
    NSMutableSet* routesThatConnect = [self getRoutesInSolution];
    [initialRouteSet minusSet:routesThatConnect];
    [finalRouteSet minusSet:routesThatConnect];
    
    
    //if no results then search for a route/stop/route solution
    [ self searchingStopRouteStop:(NSSet*)initialRouteSet
                    finalRouteSet:finalRouteSet
                     initialStops:initialStops
                       finalStops:finalStops
                        dayOfWeek:dayofWeek
                         earlyMin:earlyMin
                          lateMin:lateMin
                      courseStart:courseStart];
    
    routesThatConnect = [self getRoutesInSolution];
    [initialRouteSet minusSet:routesThatConnect];
    [finalRouteSet minusSet:routesThatConnect];
    
    
    
    //search for route/walk/route
    [self searchingRouteWalkRouteSol:(NSSet*)initialRouteSet
                       finalRouteSet:(NSSet*) finalRouteSet
                        initialStops:(NSArray*) initialStops
                          finalStops:(NSArray*) finalStops
                           dayOfWeek:(long) dayofWeek
                            earlyMin:(long)earlyMin
                             lateMin:(long)lateMin
                         courseStart:(OBRsolvedRouteRecord*)courseStart];

    
    routesThatConnect = [self getRoutesInSolution];
    [initialRouteSet minusSet:routesThatConnect];
    [finalRouteSet minusSet:routesThatConnect];
    
    
    //search for route/route/route
    [self searchingRouteRouteRouteSol:(NSSet*)initialRouteSet
                       finalRouteSet:(NSSet*) finalRouteSet
                        initialStops:(NSArray*) initialStops
                          finalStops:(NSArray*) finalStops
                           dayOfWeek:(long) dayofWeek
                            earlyMin:(long)earlyMin
                             lateMin:(long)lateMin
                         courseStart:(OBRsolvedRouteRecord*)courseStart];

    
    //clean the cache
    [databaseT clearCache];
    
    databaseT.solvingLabelText = @"Finished Searching";
    NSLog(@"Finished Processing");
    
    //pop up an alert if there was no solution
    if (databaseT.solvedRoutes.count == 0 && databaseT.interupt==false) {
        
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"No Routes Found"
                                                     message:@"Try increasing the walking distance or changing the start or destination locations"
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
        
        [av show];
        
    }
    
    
    databaseT.solving = FALSE;
    databaseT.interupt = false;
    
    //stop the indicator
    db.busy--;

}


-(NSMutableSet*)getRoutesInSolution {
    NSMutableSet* routesThatConnect = [[NSMutableSet alloc]init];
    for (OBRsolvedRouteRecord* sr in db.solvedRoutes) {
        if (sr.summaryRouteType == SRS) {
            NSArray* routeArray = [sr convertToArray:sr];
            for (OBRsolvedRouteRecord* singleRecord in routeArray) {
                if ([singleRecord isRoute]) {
                    [routesThatConnect addObject:singleRecord.route];
                }
            }
        }
    }
    return routesThatConnect;
}



-(NSMutableSet*)getRouteSetFromStopArray: (NSArray*) stopArray
{
    //get the threaded database
    OBRdataStore* databaseT = [OBRdataStore defaultStore];

    NSMutableArray* arwd = [[NSMutableArray alloc] init];
    for (int i=0; i<stopArray.count ; i++) {
        double v = [stopArray[i] doubleValue];
        int isn = round(((v - floor(v))*10000));
        NSArray* irt = [databaseT getRoutesForStop:isn];
        
        //add the routes to the combined array (with repeats)
        for (NSString* r in irt) {
            [arwd addObject:r];
        }
    }
    NSMutableSet* rs = [[NSMutableSet alloc] initWithArray:arwd];
    return rs;
}



@end
