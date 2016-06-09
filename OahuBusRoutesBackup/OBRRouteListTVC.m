//
//  OBRRouteListTVC.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 4/12/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRRouteListTVC.h"

@interface OBRRouteListTVC () {
    UITableView* tvp;
    UIColor* red;
    UIColor* green;
    UIColor* black;
    UIColor* darkGreen;
    UIColor* yellow;
    UIColor* forestGreen;
    UIColor* lemonChiffon;
    UIColor* lightYellow;
    NSTimer* refreshTable;
    NSTimer* refreshRTDataTimer;
    OBRsolvedRouteRecord* selectedRoute;
    long currentWeekday;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *guidanceButton;


@end

@implementation OBRRouteListTVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    tvp = nil;
    
    //set local variables
    selectedRoute = [[OBRdataStore defaultStore] chosenRoute];
    
    //set the default sort to departure
    [[OBRdataStore defaultStore] sortSolvedRoutesByDeparture];
    
    //init local variables
    black = [UIColor blackColor];
    red = [UIColor redColor];
    green = [UIColor greenColor];
    yellow = [UIColor yellowColor];
    darkGreen = [UIColor colorWithRed:0 green:100.0/255.0 blue:0 alpha:1];
    forestGreen = [UIColor colorWithRed:34.0/255.0 green:139.0/255.0 blue:34.0/255.0 alpha:1];
    lemonChiffon = [UIColor colorWithRed:255.0/255.0 green:250.0/255.0 blue:205.0/255.0 alpha:1];
    lightYellow = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:224.0/255.0 alpha:1];
    

    //enable the buttons we we have a selected route
    if (selectedRoute == nil) {
        _infoButton.enabled = false;
        _guidanceButton.enabled = false;
    } else {
        _infoButton.enabled = true;
        _guidanceButton.enabled = true;
    }
    
    //determine the index path of the selected cell
    NSArray* solvedRoutes = [[OBRdataStore defaultStore] solvedRoutes];
    int row = -1;
    for (OBRsolvedRouteRecord* sr in solvedRoutes) {
        if (sr == selectedRoute) {
            row = (int) [solvedRoutes indexOfObject:sr];
            NSLog(@"row = %lu",(unsigned long)row);
            //second line
        }
    }
    if (row != -1) {
        NSUInteger x[] = {0 , row};
        NSIndexPath *path = [[NSIndexPath alloc] initWithIndexes: x length: 2];
        [self.tableView reloadData];
        [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionMiddle animated:false];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    
    //get the current weekday
    //get the current weekday
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate:[NSDate date]];
    currentWeekday = [comps weekday];

    
    //start a timer to check for new solved routes
    refreshTable = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                    target:self
                                                  selector:@selector(refreshTableData)
                                                  userInfo:nil
                                                   repeats:YES];
    
    //start a timer to reload Real Time Data
    refreshRTDataTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                    target:self
                                                  selector:@selector(refreshRTData)
                                                  userInfo:nil
                                                   repeats:YES];
    
}


-(void)viewWillDisappear:(BOOL)animated {
    [refreshTable invalidate];
    refreshTable = nil;
    
    [refreshRTDataTimer invalidate];
    refreshRTDataTimer = nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)refreshTableData {
    bool newdata = [[OBRdataStore defaultStore] solvedRoutesModified];
    if (newdata) {
        NSLog(@"solved route list has changed... updating");
        [self.tableView reloadData];
        [OBRdataStore defaultStore].solvedRoutesModified = false;
    }
}

-(void)refreshRTData {
    NSLog(@"Updating the routeList RT Data");
    [self.tableView reloadData];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    tvp = tableView;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    tvp = tableView;
    
    // Return the number of rows in the section.
    NSArray* solvedRoutes = [[OBRdataStore defaultStore] solvedRoutes];
    
    return solvedRoutes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    tvp = tableView;

    static NSString *CellIdentifier = @"myCell";
    MyCustomCellTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [tableView registerNib:[UINib nibWithNibName:@"MyCustomCell" bundle:nil] forCellReuseIdentifier:@"myCell"];
     
        cell = [tableView dequeueReusableCellWithIdentifier:@"myCell"];
    }

    return cell;
}



-(long)currentMinOfDay {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:[NSDate date]];
    long hour = [comps hour];
    long minute = [comps minute];
    return hour*60+minute;
}



//updates the lats and lons of stops and routes
//while the stops are static, the vehicles should move
-(void)updateRouteInfoForRouteArray:(NSArray*)ra {
    OBRdataStore* db = [OBRdataStore defaultStore];
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
            ri.completeMin = ri.minOfDayDepart - ad;
        }
    } else if (r.summaryRouteType == RSR) {
        NSArray* RSRadArr = [[NSArray alloc] initWithObjects:@"2",@"2",@"2",@"4",@"4",@"4",@"4", nil];
        for (int i=0 ; i<ra.count; i++) {
            OBRsolvedRouteRecord* r = ra[i];
            NSNumber* p = RSRadArr[i];
            int ad = ((OBRsolvedRouteRecord*)ra[[p intValue]]).adherence;
            r.completeMin = r.minOfDayDepart - ad;
        }
    } else if (r.summaryRouteType == RWR) {
        NSArray* RWRadArr = [[NSArray alloc] initWithObjects:@"2",@"2",@"2",@"2",@"2",@"6",@"6",@"6",@"6", nil];
        for (int i=0 ; i<ra.count; i++) {
            OBRsolvedRouteRecord* r = ra[i];
            NSNumber* p = RWRadArr[i];
            int ad = ((OBRsolvedRouteRecord*)ra[[p intValue]]).adherence;
            r.completeMin = r.minOfDayDepart - ad;
        }
    } else if (r.summaryRouteType == RRR) {
        NSArray* RRRadArr = [[NSArray alloc] initWithObjects:@"2",@"2",@"2",@"4",@"4",@"6",@"6",@"6",@"6", nil];
        for (int i=0 ; i<ra.count; i++) {
            OBRsolvedRouteRecord* r = ra[i];
            NSNumber* p = RRRadArr[i];
            int ad = ((OBRsolvedRouteRecord*)ra[[p intValue]]).adherence;
            r.completeMin = r.minOfDayDepart - ad;
        }
    }
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(MyCustomCellTableViewCell*)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    tvp = tableView;
    
    //reset the cell views components
    cell.departureLabel.textColor = black;
    
    
    NSArray* solvedRoutes = [[OBRdataStore defaultStore] solvedRoutes];
    OBRsolvedRouteRecord* r = [solvedRoutes objectAtIndex:indexPath.row];
    NSArray* ra = [r convertToArray:r];
    [self updateRouteInfoForRouteArray:ra];
    

    //refresh the course summary information
    [r refreshSummary:r];
    
    //show/hide selection checkmark
    if (r == selectedRoute) {
        cell.contentView.backgroundColor = lightYellow;
    } else {
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }
    
    
    
    //hide the update label by default
    BOOL RTDA = false;  //RT Data Available
    BOOL RTDAfirstBus = false;
    BOOL RTDAlastBus = false;
    BOOL firstBusFound = false;
    cell.statusLabel.hidden = true;
    OBRdataStore* db = [OBRdataStore defaultStore];
    int firstAd = 0;
    int lastAd = 0;
    int numberOfRoutes = 0;
    if ([db checkRouteForRealTimeInfo:r]) {
        RTDA = true;
        for (OBRsolvedRouteRecord* rr in ra) {
            if (rr.isRoute) {
                numberOfRoutes++;
                if (!firstBusFound) {
                    if (rr.busNum>0) {
                        firstAd = rr.adherence;
                        RTDAfirstBus = true;
                    }
                    firstBusFound = true;
                } else {
                    if (rr.busNum >0) {
                        RTDAlastBus = true;
                    }
                }
                lastAd = rr.adherence;
            }
        }
        
        
        //adjust the departure Label
        r.summaryEarliestDepart -= firstAd;
        r.summaryEarliestTimestamp -= firstAd;
        
        //adjust the arrival Label
        r.summaryLatestArrive -= lastAd;
        r.summaryLatestTimestamp -= lastAd;
        
    }
    
    //set the adherences the same if only a single bus
    if (numberOfRoutes==1) {
        RTDAlastBus = RTDAfirstBus;
        lastAd = firstAd;
    }
    
    //fill in the timeline
    NSMutableArray* timelineArray = [[NSMutableArray alloc] initWithObjects:cell.timeline1,
                                     cell.timeline2,
                                     cell.timeline3,
                                     cell.timeline4,
                                     cell.timeline5,
                                     cell.timeline6,
                                     cell.timeline7,
                                     cell.timeline8,
                                     cell.timeline9, nil];
    NSMutableArray* timelineLabelArray = [[NSMutableArray alloc] initWithObjects:cell.tl1,
                                         cell.tl2,
                                         cell.tl3,
                                         cell.tl4,
                                         cell.tl5,
                                         cell.tl6,
                                         cell.tl7,
                                         cell.tl8,
                                         cell.tl9, nil];

    int timeLinePtr = 0;
    for (UIImageView* iv in timelineArray) iv.hidden= true;
    for (UILabel* l in timelineLabelArray) l.text = @"";
    OBRsolvedRouteRecord* lastRecord = nil;
    for (OBRsolvedRouteRecord* rec in ra) {
        int delay = abs(rec.minOfDayDepart-rec.minOfDayArrive);
        
        //dim the past timeline events
        bool stepCompleted = false;
        long cMOD = [[OBRdataStore defaultStore] currentMinOfDay];
        if (cMOD> rec.completeMin) {
            stepCompleted = true;
        }
        
        
       
        CGPoint spacing = CGPointMake(36, 18);  //single character
        if (rec.route.length == 2) spacing = CGPointMake(24, 18);  //two characte
        if (rec.route.length == 3) spacing = CGPointMake(15, 18);  //three character
        
        if (rec.isRoute) {
            if (timeLinePtr+1 < ra.count) {
                UIImageView* iv = [timelineArray objectAtIndex:(timeLinePtr++)];
                iv.hidden = false;
                UIImage* bwimage = [UIImage imageNamed:@"DataHollow.png"];
                if (rec.busNum>0) {
                    
                    UIColor* busColor = black;
                    if (rec.adherence>=0) busColor = green;
                    else if (rec.adherence > -6) busColor = yellow;
                    else busColor = red;
                    
                    UIImage* timage = [self drawText:rec.route inImage:bwimage atPoint:spacing];
                    iv.image = [self colorImage:timage color:busColor];
                    
                } else {
                    iv.image = [self drawText:rec.route inImage:bwimage atPoint:spacing];
                }
                //dim the icon if the step has passed
                if (stepCompleted) iv.alpha = 0.5;
                else iv.alpha = 1;
                
                UILabel* l =[timelineLabelArray objectAtIndex:(timeLinePtr-1)];
                l.text = [NSString stringWithFormat:@"%d",delay];
            }
        }
        if (rec.isStop) {
            if (timeLinePtr+1 < ra.count) {
                int waitTime = [self calculateWaitTimeForRoute:rec inArray:ra];
                if (!lastRecord.isWalk || waitTime>5 || waitTime<=1) {
                    if (!rec.transition) { //stops with no wait like getting off the bus
                        
                        UIImageView* iv = [timelineArray objectAtIndex:(timeLinePtr++)];
                        iv.hidden = false;
                        iv.image = [UIImage imageNamed:@"waitIcon.png"];
                        
                        //dim the icon if historic
                        if (stepCompleted) iv.alpha = 0.5;
                        else iv.alpha = 1.0;
                        
                        
                        UILabel* l =[timelineLabelArray objectAtIndex:(timeLinePtr-1)];
                        l.text = [NSString stringWithFormat:@"%d",waitTime];
                        
                        //pulse the icon if the waitTime is problematic
                        //[self pulseIcon:iv];
                        
                        if (waitTime<=1 && !stepCompleted) {
                            CABasicAnimation *theAnimation;
                            theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
                            theAnimation.duration=0.5;
                            theAnimation.repeatCount=10;
                            theAnimation.autoreverses=YES;
                            theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
                            theAnimation.toValue=[NSNumber numberWithFloat:0.0];
                            [iv.layer   addAnimation:theAnimation forKey:@"animateOpacity"];
                        }
                    }
                }
            }
        }
        
        if (rec.isWalk) {
            if (timeLinePtr+1 < ra.count) {
                if (delay>0) {
                    UIImageView* iv = [timelineArray objectAtIndex:(timeLinePtr++)];
                    iv.hidden = false;
                    iv.image = [UIImage imageNamed:@"walkIcon2.png"];
                    
                    //dim the icon if historic
                    if (stepCompleted) iv.alpha = 0.5;
                    else iv.alpha = 1;
                    
                    UILabel* l =[timelineLabelArray objectAtIndex:(timeLinePtr-1)];
                    l.text = [NSString stringWithFormat:@"%d",delay];
                }
            }
        }
        lastRecord = rec;
        
      }
    
    //stamp the cells arrived or departed
    if (currentWeekday == r.day) {
        long mod = [self currentMinOfDay];
        if (r.summaryLatestTimestamp < mod) {
            cell.statusLabel.text = @"ARRIVED";
            cell.statusLabel.hidden = false;
        } else if (r.summaryEarliestTimestamp <mod) {
            cell.statusLabel.text = @"IN ROUTE";
            cell.statusLabel.hidden = false;
        }
    }
    
    //get cell data
    int ed = r.summaryEarliestTimestamp;
    int edhour = ed/60;
    int edmin = (ed-60*edhour);
    int la = r.summaryLatestTimestamp;
    int lahour = la/60;
    int lamin = (la-60*lahour);
    
     //set the trip duration
    int duration = la-ed;
    cell.durationLabel.text = [NSString stringWithFormat:@" %d min",duration];
    
    
    
    cell.row = indexPath.row;
    cell.durationLabel.text = [NSString stringWithFormat:@"%d min",duration];
    cell.route = r;
    
    
    NSString* arriveStr,*departStr;
    if (edhour<13) {
        arriveStr = [NSString stringWithFormat:@"%d:%02d",edhour,edmin];
    } else {
        arriveStr = [NSString stringWithFormat:@"%d:%02d",edhour-12,edmin];
    }
    if (lahour<13) {
        departStr = [NSString stringWithFormat:@"- %d:%02d",lahour,lamin];
    } else {
        departStr = [NSString stringWithFormat:@"- %d:%02d",lahour-12,lamin];
    }
    
    
    // If attributed text is supported (iOS6+)
    if ([cell.departureLabel respondsToSelector:@selector(setAttributedText:)]) {
        
        // Define general attributes for the entire text
        NSDictionary *attribs = @{
                                  NSForegroundColorAttributeName:black,
                                  NSFontAttributeName:[UIFont boldSystemFontOfSize:20]
                                  };
        NSMutableAttributedString* attributedText = [[NSMutableAttributedString alloc] initWithString:arriveStr
                                                                                           attributes:attribs];
        
        //add the AM of PM LAbel
        NSMutableAttributedString* AMorPM;
        if (edhour>=12) {
            AMorPM = [[NSMutableAttributedString alloc] initWithString:@"PM " attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:10]}];
        } else {
            AMorPM = [[NSMutableAttributedString alloc] initWithString:@"AM " attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:10]}];
        }
        [attributedText appendAttributedString:AMorPM];
        
        
        //add real time data for first bus if available
        NSRange arrivalStrRange = [arriveStr rangeOfString:arriveStr];
        if (RTDAfirstBus) {
            if (firstAd>=0) {
                [attributedText setAttributes:@{NSForegroundColorAttributeName:forestGreen,
                                                NSFontAttributeName:[UIFont boldSystemFontOfSize:20]} range:arrivalStrRange];
            } else {
                [attributedText setAttributes:@{NSForegroundColorAttributeName:red,
                                                NSFontAttributeName:[UIFont boldSystemFontOfSize:20]} range:arrivalStrRange];
            }
            NSMutableAttributedString* firstAdStr = [self adherenceStr:firstAd label:cell.departureLabel];
            [attributedText appendAttributedString:firstAdStr];
          }
        
        //create the arrival time string
        NSMutableAttributedString* dat = [[NSMutableAttributedString alloc] initWithString:departStr attributes:attribs];
        [dat setAttributes:@{NSForegroundColorAttributeName:black,
                             NSFontAttributeName:[UIFont boldSystemFontOfSize:20]} range:(NSMakeRange(0, dat.length))];
        
        //change the color of the arrival string if RT data available
        if (RTDAlastBus) {
            if (lastAd>=0) {
                [dat setAttributes:@{NSForegroundColorAttributeName:forestGreen,
                                     NSFontAttributeName:[UIFont boldSystemFontOfSize:20]} range:(NSMakeRange(0, dat.length))];
            } else {
                [dat setAttributes:@{NSForegroundColorAttributeName:red,
                                     NSFontAttributeName:[UIFont boldSystemFontOfSize:20]} range:(NSMakeRange(0, dat.length))];
            }
        }
        [attributedText appendAttributedString:dat];
        
        //add the AM or PM label
        if (lahour>=12) {
            AMorPM = [[NSMutableAttributedString alloc] initWithString:@"PM " attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:10]}];
        } else {
            AMorPM = [[NSMutableAttributedString alloc] initWithString:@"AM " attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:10]}];
        }
        [attributedText appendAttributedString:AMorPM];
        
        
        //add the real time arrival data to the string
        if (RTDAlastBus) {
            NSMutableAttributedString* lastAdStr = [self adherenceStr:lastAd label:cell.departureLabel];
            [attributedText appendAttributedString:lastAdStr];
        }
       
     
        
        cell.departureLabel.attributedText = attributedText;
    }
    // If attributed text is NOT supported (iOS5-)
    else {
        cell.departureLabel.text = arriveStr;
    }
    
}



-(int)calculateWaitTimeForRoute:(OBRsolvedRouteRecord*)rec inArray:(NSArray*)ra {
    int row = (int) [ra indexOfObject:rec];
    //bus stop bus
    if (row-1>=0 && row+1<ra.count) {
        OBRsolvedRouteRecord* prec = [ra objectAtIndex:row-1];
        OBRsolvedRouteRecord* nrec = [ra objectAtIndex:row+1];
        if (prec.isRoute && nrec.isRoute) {
            int waitMin = nrec.minOfDayArrive - nrec.adherence;
            waitMin -= prec.minOfDayDepart - prec.adherence;
            return waitMin;
        }
    }
    
    //bus/stop/walk/stop/bus
    if (row-3>=0 && row+1<ra.count) {
        OBRsolvedRouteRecord* bus1 = [ra objectAtIndex:row-3];
        OBRsolvedRouteRecord* walk = [ra objectAtIndex:row-1];
        OBRsolvedRouteRecord* bus2 = [ra objectAtIndex:row+1];
        if (bus1.isRoute && walk.isWalk && bus2.isRoute) {
            //NSLog(@"The First Bus %d %d %d",bus1.minOfDayArrive,bus1.minOfDayDepart,bus1.adherence);
            //NSLog(@"The walk %d %d %d",walk.minOfDayArrive,walk.minOfDayDepart,walk.waitMin);
            //NSLog(@"The second Bus %d %d %d",bus2.minOfDayArrive,bus2.minOfDayDepart,bus2.adherence);

            int waitMin = bus2.minOfDayArrive - bus2.adherence;
            waitMin -= bus1.minOfDayDepart - bus1.adherence;
            waitMin -= walk.waitMin;
            //NSLog(@" wait min %d",waitMin);
            return waitMin;
        }
    }
    
    return rec.waitMin;
}


-(UIImage*)colorImage:(UIImage*)input
                 color:(UIColor*)c {
    
       // begin a new image context, to draw our colored image onto
    UIGraphicsBeginImageContext(input.size);
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // set the fill color
    [c setFill];
    
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, input.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // set the blend mode to color burn, and the original image
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    CGRect rect = CGRectMake(0, 0, input.size.width, input.size.height);
    CGContextDrawImage(context, rect, input.CGImage);
    
    // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
    CGContextClipToMask(context, rect, input.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImg;
}


-(NSString*)localTime:(NSDate*)date{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    NSTimeZone* tz = [NSTimeZone timeZoneWithName:@"HST"];
    [df setDateFormat:@"hh:mm:ss a"];
    [df setTimeZone:tz];
    NSString* dateStr =[df stringFromDate:date];
    return dateStr;
}


-(NSString*)localTimeI:(NSTimeInterval)interval{
    NSDate* date = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:interval];
    return [self localTime:date];
}


-(UIImage*)drawText:(NSString*) text
             inImage:(UIImage*)  image
             atPoint:(CGPoint)   point {
    
    UIFont *font = [UIFont boldSystemFontOfSize:40];
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
    [[UIColor blackColor] set];
    [text drawInRect:CGRectIntegral(rect) withFont:font];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}



-(NSMutableAttributedString*)adherenceStr:(long)a label:(UILabel*)l{

    if (a==0) {
    
        NSMutableAttributedString *at = [[NSMutableAttributedString alloc] initWithString:@"(On Time)"
                                                                               attributes:@{NSForegroundColorAttributeName:forestGreen,
                                                                                            NSFontAttributeName:[UIFont systemFontOfSize:12],
                                                                                            NSBaselineOffsetAttributeName:@"7.0" }];
        return at;
        
    } else if (a<0) {
        NSString* s = [NSString stringWithFormat:@"(%ldmin Late)",-a];
        NSMutableAttributedString *at = [[NSMutableAttributedString alloc] initWithString:s
                                                                               attributes:@{NSForegroundColorAttributeName: red,
                                                                                            NSFontAttributeName:[UIFont systemFontOfSize:12],
                                                                                            NSBaselineOffsetAttributeName:@"7.0"}];
        return at;
        
    } else {
        NSString* s = [NSString stringWithFormat:@"(%ldmin Early)",a];
        NSMutableAttributedString *at = [[NSMutableAttributedString alloc] initWithString:s
                                                                               attributes:@{NSForegroundColorAttributeName:forestGreen,
                                                                                            NSFontAttributeName:[UIFont systemFontOfSize:12],
                                                                                            NSBaselineOffsetAttributeName:@"7.0"}];
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray* solvedRoutes = [[OBRdataStore defaultStore] solvedRoutes];
    selectedRoute = [solvedRoutes objectAtIndex:indexPath.row];
    [OBRdataStore defaultStore].chosenRoute = selectedRoute;
    
    //refresh the course summary information
    [selectedRoute refreshSummary:selectedRoute];
    
    _infoButton.enabled = true;
    _guidanceButton.enabled = true;
    
    //redraw the cells
    [self.tableView reloadData];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)pressedQuit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)durationPressed:(id)sender {
    [[OBRdataStore defaultStore] sortSolvedRoutesByDuration];
    [self.tableView beginUpdates];
    [self.tableView reloadData];
    [self.tableView endUpdates];

}

- (IBAction)arrivalPressed:(id)sender {
    [[OBRdataStore defaultStore] sortSolvedRoutesByArrival];
    [self.tableView beginUpdates];
    [self.tableView reloadData];
    [self.tableView endUpdates];
}

- (IBAction)departurePressed:(id)sender {
    [[OBRdataStore defaultStore] sortSolvedRoutesByDeparture];
    [self.tableView beginUpdates];
    [self.tableView reloadData];
    [self.tableView endUpdates];

}

- (IBAction)routeInfoPressed:(id)sender {
    OBRdataStore* db = [OBRdataStore defaultStore];
    db.chosenRoute = selectedRoute;
    [self performSegueWithIdentifier:@"OBRRouteDetailTCV" sender:self];

}

- (IBAction)guidancePressed:(id)sender {
    OBRdataStore* db = [OBRdataStore defaultStore];
    db.chosenRoute = selectedRoute;
    [self performSegueWithIdentifier:@"guidanceVC" sender:self];
}

@end
