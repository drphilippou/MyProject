//
//  OBRdataStore.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 2/5/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRdataStore.h"

@interface OBRdataStore() {
    NSPersistentStoreCoordinator *psc;
    NSMutableData* versionData;
    NSURLConnection* versionConnection;
    //IOSImage* IOSI;
    
    NSMutableData* vehicleData;
    NSURLConnection* vehicleConnection;
    NSTimer* vehicleUpdateTimer;

    
}

@property (nonatomic,strong) NSManagedObjectContext *context;
@property (nonatomic,strong) NSManagedObjectContext *threadContext;
@property (nonatomic,strong) NSManagedObjectModel *model;
@property (nonatomic) UIImageView* dataRxButton;
@property (nonatomic) NSMutableArray* isStopOnRouteArray;
@property (nonatomic) UIActivityIndicatorView* activityIndicator;
@property (nonatomic) UIImageView* numSolsIcon;



@end



@implementation OBRdataStore
@synthesize context;
@synthesize threadContext;
@synthesize model;
@synthesize minWalkingDistanceEnd;
@synthesize minWalkingDistanceStart;
@synthesize busy;
@synthesize data;
@synthesize searchSelection;
@synthesize updateVehicles;
@synthesize fullUpdate;
@synthesize guiding;
@synthesize lastVehicleEtag;
@synthesize vehiclesModified;
@synthesize downloadingUpdate;
@synthesize updateVehicleTime;

#pragma mark init

+ (OBRdataStore *)defaultStore {
    static OBRdataStore *defaultStore = nil;
    if(!defaultStore)
        defaultStore = [[super allocWithZone:nil] init];

    return defaultStore;
}

-(IOSImage*)IOSI {
    if (_IOSI == nil) {
        _IOSI = [[IOSImage alloc] init];
    }
    return _IOSI;
}

-(NSMutableDictionary*)cache {
    if (_cache == nil) {
        _cache = [[NSMutableDictionary alloc] init];
    }
    return _cache;
}

-(void)clearCache {
    NSLog(@"Erasing Cache");
    [_cache removeAllObjects];
    _cache = nil;
    
}

-(NSMutableArray*) trips {
    if (!_trips) {
        
        NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRTrip"];
        NSFetchRequest *rq = [[NSFetchRequest alloc] init];
        [rq setEntity:e];
        NSArray* res;
        @synchronized (self) {
            res = [context executeFetchRequest:rq error:nil];
        }
        
        if (res.count>0) {
            _trips = [[NSMutableArray alloc] initWithArray:res];
        }
    }
    return _trips;
}

-(NSMutableArray*) routes {
    if (!_routes) {
        NSMutableSet* routeset = [[NSMutableSet alloc] init];
        for (OBRTrip* t in [self trips]) {
            [routeset addObject:t.route];
        }
        _routes = [[routeset allObjects] mutableCopy];
    }
    return _routes;
}

-(NSMutableArray*) pois {
    if (!_pois) {
        
        NSEntityDescription *e = [[model entitiesByName] objectForKey:@"POI"];
        NSFetchRequest *rq = [[NSFetchRequest alloc] init];
        [rq setEntity:e];
        NSArray* res;
        @synchronized (self) {
            res = [context executeFetchRequest:rq error:nil];
        }
        
        if (res.count>0) {
            _pois = [[NSMutableArray alloc] initWithArray:res];
        }
    }
    return _pois;
}


#pragma mark - time functions
-(NSTimeInterval)currentTimeSec {
    return [[NSDate date] timeIntervalSinceReferenceDate];
}

-(long)currentMinOfDay {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:[NSDate date]];
    long hour = [comps hour];
    long minute = [comps minute];
    
    return hour*60+minute;
}




#pragma mark - solver
-(NSMutableDictionary*)routeStopDict {
    if (_routeStopDict == nil) {
        _routeStopDict = [[NSMutableDictionary alloc] init];
        NSDictionary* dict = [self stopRouteDict];
        for (NSString* stop in [self stopRouteDict]) {
            NSArray* routes = [dict objectForKey:stop];
            for (NSString* route in routes) {
                
                NSMutableSet* rs = [_routeStopDict objectForKey:route];
                if (rs == nil) {
                    rs = [[NSMutableSet alloc] initWithObjects:stop, nil];
                    _routeStopDict[route] = rs;
                } else {
                    [rs addObject:stop];
                }
            }
        }
    }
    return _routeStopDict;
}

-(NSMutableDictionary*)jointStops {
    if (_jointStops == nil) {
        NSLog(@"loading JointStops json file...");
        NSError *err = nil;
        NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"jointStops" ofType:@"txt"];
        _jointStops = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath] options:kNilOptions error:&err];
        NSLog(@"done");
    }
    return _jointStops;
}

-(NSMutableDictionary*)routeWalkRoute {
    if (_routeWalkRoute == nil) {
        NSLog(@"loading RouteWalkRoute json file...");
        NSError *err = nil;
        NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"routeWalkRoute" ofType:@"txt"];
        _routeWalkRoute = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath] options:kNilOptions error:&err];
        NSLog(@"done");
    }
    return _routeWalkRoute;
}

-(NSMutableDictionary*)routeRouteRoute {
    if (_routeRouteRoute == nil) {
        NSLog(@"loading RouteRouteRoute json file...");
        NSError *err = nil;
        NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"routeRouteRoute" ofType:@"txt"];
        _routeRouteRoute = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath] options:kNilOptions error:&err];
        NSLog(@"done");
    }
    return _routeRouteRoute;
}



#pragma mark - load database
- (id)init {
    NSLog(@"OBRDS dataStore Init Start");
    self = [super init];
    if(self) {
        //init local variables
        _departureMin = 0;
        _arrivalMin = 24*60;
        _maxWalkingDistance = 500;
        _maxWaitMin = 240;
        _arrivalDay = 1;
        versionData = [[NSMutableData alloc] init];
        [self IOSI];
        updateVehicles = false;
        fullUpdate = true;
        guiding = false;
        
        
        //start the busy icon
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkForIconState) userInfo:nil repeats:true];

        //check that any given database is moved to the documents directory from the bundle
        [self testExtractAndMoveFiles];
        
        //for now just use the database given in the bundle
        [self loadDatabase];
    }
    
    NSLog(@"OBRDS dataStore Init Done");
    return self;
}

-(BOOL)loadDatabase {
    NSLog(@"OBRDS loadDatabase Start");
    
    //start the animation
    busy++;
    
    //create the model and the coordinator
    @synchronized (self) {
        model = [NSManagedObjectModel mergedModelFromBundles:nil];
        psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    }
    
    //create the address for the database in the documents directory
    NSArray* docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docDir = [docDirs objectAtIndex:0];
    NSString* DBPath = [docDir stringByAppendingPathComponent:@"store.data"];
    NSURL* storeURL = [NSURL fileURLWithPath:DBPath];
    
    //add the persistent Store
    NSError *error=nil;
    [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];

    //report any errors
    if (error) {
        //[NSException raise:@"Open failed" format:@"Reason: %@",[error localizedDescription]];
        //add an alert to handle this
        if (error.code == 134100) {
            //database is inconsistant with the model
            //show an alert that this version of software must be updated
        }
    }
    
    @synchronized (self) {
        //create the managed object context
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator:psc];
        
        //create a separate thread for the solver thread
        threadContext = [[NSManagedObjectContext alloc] init];
        [threadContext setPersistentStoreCoordinator:psc];
        
        //The managed object context can manage undo, but we dont need it
        [context setUndoManager:nil];
        [threadContext setUndoManager:nil];
        
        //reset the db debug
        if (!psc) {
            psc = nil;
            model = nil;
            context = nil;
            threadContext = nil;
        }
    }
    
    //load the stop/Route dictionary into memory
    [self stopRouteDict];
    
    //build an array of strings to optimize isStopOnRouteStr
    _isStopOnRouteArray = [[NSMutableArray alloc] initWithCapacity:5001];
    for (int s=0 ; s<5000 ; s++) {
        NSString* ss = [NSString stringWithFormat:@"%d",s];
        [_isStopOnRouteArray addObject:ss];
    }
        
    //read the combined route file
    [self loadCombinedRouteFile];
    
    //stop the activity animation
    busy--;
    
//    //test
//    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRScheduleNew"];
//    NSString* trip =@"6238838.2505";
//    //NSPredicate *p = [NSPredicate predicateWithFormat:@"(trip.tripStr=%@)",trip];
//    NSPredicate *p = [NSPredicate predicateWithFormat:@"(stop.number=186)"];
//    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
//    [rq setEntity:e];
//    [rq setPredicate:p];
//    NSArray* res = [context executeFetchRequest:rq error:nil];
//    OBRScheduleNew* new = [res firstObject];
//    NSLog(@"new=%@",new.description);
//    
//    
//    //test the getting stops
//    for (int s = 12 ; s<2000 ; s++) {
//        OBRStopNew* stop = [self getNewStop:s];
//        NSLog(@"%@",stop);
//        NSSet* trips = stop.trips;
//        OBRTrip* trip = [trips anyObject];
//        NSSet* stops = [trip stops];
//        OBRStopNew* anyStop = [stops anyObject];
//    }
//
//    

    NSLog(@"OBRDS loadDatabase Done");
    return true;
   
}

-(OBRStopNew*)getNewStop:(int)number {
    
    
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRStopNew"];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(number=%d)",number];
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    [rq setPredicate:p];
    NSArray* res;
    @synchronized (self) {
        res = [context executeFetchRequest:rq error:nil];
    }
    OBRStopNew* s = [res firstObject];
    return s;
}

//-(bool)updatesAvailable{
//    
//    NSLog(@"OBRDS Checking for Updates");
//    
//    //start flashing the data icon
//    data++;
//    
//    //get the version files form the website
//    NSString* page = @"http://OBRuser:OBRUserPassword@ios-hawaii.com/OBRroot/version.json";
//    NSURL *url = [NSURL URLWithString:page];
//    NSError *error = nil;
//    NSString *jsonString = [[NSString alloc] initWithContentsOfURL:url usedEncoding:0 error:&error];
//    
//    //parse the json file
//    if (error == nil) {
//        
//        //convert the string object to a dict
//        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//        NSDictionary *versionJSON = [NSJSONSerialization JSONObjectWithData:jsonData
//                                                                    options:0
//                                                                      error:&error];
//        
//        //check each library file timestamp with the server timestamp
//        if (error == nil) {
//            for (NSString* key in versionJSON.keyEnumerator)
//            {
//                // get the timestamp of the library value
//                NSString* filename = [key lastPathComponent];
//                NSString* tsstr = [[NSUserDefaults standardUserDefaults] objectForKey:filename];
//                int currentTS = [tsstr intValue];
//                
//                if (currentTS==0) NSLog(@"no Database loaded");
//                
//                //get the timestamp from the version file
//                int incomingTS = [[versionJSON objectForKey:key] intValue];
//            
//                //check if any files need to be downloaded
//                if (incomingTS > currentTS) {
//                    NSLog(@"OBRDS Updates available");
//                    data--;
//                    return true;
//                }
//            }
//        }
//    }
//    
//    NSLog(@"OBRDS No Updates Available");
//    data--;
//    return false;
//}

//-(void)downloadUpdate{
//    
//    NSLog(@"initial check for updates is starting");
//    
//    //start flashing the data icon
//    data++;
//    
//    //mark the update as downloading
//    downloadingUpdate = true;
//    
//    //get the version files form the website
//    NSString* page = @"http://OBRuser:OBRUserPassword@ios-hawaii.com/OBRroot/version.json";
//    NSURL *url = [NSURL URLWithString:page];
//    NSStringEncoding encoding = 0;
//    NSError *error = nil;
//    NSString *jsonString = [[NSString alloc] initWithContentsOfURL:url usedEncoding:&encoding error:&error];
//    
//    //parse the json file
//    if (error == nil) {
//        
//        //convert the string object to a dict
//        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//        NSDictionary *versionJSON = [NSJSONSerialization JSONObjectWithData:jsonData
//                                                                    options:0
//                                                                      error:&error];
//        
//        //check each library file timestamp with the server timestamp
//        if (error == nil) {
//            for (NSString* key in versionJSON.keyEnumerator) {
//                // get the timestamp of the library value
//                NSString* filename = [key lastPathComponent];
//                
//                
//                NSString* tsstr = [[NSUserDefaults standardUserDefaults] objectForKey:filename];
//                int currentTS = [tsstr intValue];
//                
//                //get the timestamp from the version file
//                int incomingTS = [[versionJSON objectForKey:key] intValue];
//                
//                if (incomingTS > currentTS) {
//                    NSLog(@"Server file(%d) is newer (%d) %@",incomingTS,currentTS,filename);
//                    [self copyFile:filename timeStamp:incomingTS];
//                    
//                } else {
//                    NSLog(@" Server file(%d) is older or the same(%d) %@",incomingTS,currentTS,filename);
//                }
//            }
//        }
//    }
//    
//    //release the raw data
//    versionData = nil;
//    
//    NSLog(@"Update Download Completed");
//    
//    //load the new database
//    [self loadDatabase];
//    
//    //alert the user and ask for guidance
//    UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Download Complete" message:@"Updated schedules are now available for use." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
//    [av show];
//    
//    data--;
//    
//    //flag the download as complete
//    downloadingUpdate = false;
//}


//-(bool)periodicUpdateCheck{
//    
//    //do not allow update checks if we are performing guidance
//    if (self.guiding) {
//        NSLog(@"OBRDS skipping Update Check becuase of guidance flag");
//        return false;
//    }
//    
//    //do not allow an update check if we are currently downloading the new database
//    if (downloadingUpdate) {
//        NSLog(@"ORBDS skipping update check... download in progress");
//        return false;
//    }
//    
//    NSLog(@"OBRDS Periodic Update Check");
//    
//    //start flashing the data icon
//    data++;
//    
//    //get the version files form the website
//    NSString* page = @"http://OBRuser:OBRUserPassword@ios-hawaii.com/OBRroot/version.json";
//    NSURL *url = [NSURL URLWithString:page];
//    NSError *error = nil;
//    NSString *jsonString = [[NSString alloc] initWithContentsOfURL:url usedEncoding:0 error:&error];
//    
//    //parse the json file
//    if (error == nil) {
//        
//        //convert the string object to a dict
//        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//        NSDictionary *versionJSON = [NSJSONSerialization JSONObjectWithData:jsonData
//                                                                    options:0
//                                                                      error:&error];
//        
//        //check each library file timestamp with the server timestamp
//        if (error == nil) {
//            for (NSString* key in versionJSON.keyEnumerator)
//            {
//                // get the timestamp of the library value
//                NSString* filename = [key lastPathComponent];
//                NSString* tsstr = [[NSUserDefaults standardUserDefaults] objectForKey:filename];
//                int currentTS = [tsstr intValue];
//                
//                //get the timestamp from the version file
//                int incomingTS = [[versionJSON objectForKey:key] intValue];
//                
//                //check if any files need to be downloaded
//                if (incomingTS > currentTS) {
//                    NSLog(@"OBRDS Updates available");
//                    //alert the user and ask for guidance
//                    UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Periodic Update" message:@"Updated schedules are available. Close the application completely (including the background operation) and restart to perform update." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
//                    [av show];
//                    data--;
//                    return true;
//                }
//            }
//        }
//    }
//    
//    NSLog(@"OBRDS No Updates Available");
//    data--;
//    return false;
//}



-(void)copyFile:(NSString*)filename timeStamp:(int) incomingTS{
    // copy the file over
    

    NSString* page2 = [NSString stringWithFormat:@"http://OBRuser:OBRUserPassword@ios-hawaii.com/OBRroot/routeSchedules/%@",filename];
    NSURL* url = [NSURL URLWithString:page2];
    NSError *error = nil;
    NSData* incomingData = [[NSData alloc] initWithContentsOfURL:url options:0 error:&error];
    
    if (error == nil) {
        NSString *strPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        strPath = [strPath stringByAppendingPathComponent:filename];
        BOOL success = [incomingData writeToFile:strPath options:NSDataWritingAtomic error:&error];

        //if sucessfull update the version defaults
        if (success) {
            NSString* newTSstr = [NSString stringWithFormat:@"%d",incomingTS];
            [[NSUserDefaults standardUserDefaults] setObject:newTSstr forKey:filename];
        }
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    //return if this is just an acknowledgement
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"]) {
        return;
    }
    
    //otherwise handle the download
    if (buttonIndex ==0) {
        //download the data
        if (model == nil && context==nil && psc == nil) {
            [NSThread detachNewThreadSelector:@selector(downloadUpdate)
                                     toTarget:self withObject:nil];
        }
    } else if (buttonIndex == 1) {
        //just load the current database        
        if (model==nil && context == nil && psc == nil) {
            [self loadDatabase];
        }
    }
 }


-(void)testExtractAndMoveFiles {
    //check to see if this file is in the document directory
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    NSString* docFilename = [NSString stringWithFormat:@"%@/store.data",documentDirectory];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:docFilename];
    
    //move the database if necessary
    if (!fileExists) {
        
        //create the bundle path
        NSBundle* bundle = [NSBundle mainBundle];
        NSString* bundlefile = [[NSBundle mainBundle] pathForResource:@"store" ofType:@"data"];
    
        //copy the file from the bundle
        NSError* err;
        NSLog(@"copying DB from bundle to document directory");
        [[NSFileManager defaultManager] copyItemAtPath:bundlefile toPath:docFilename error:&err];
        if (!err) {
            NSLog(@"copy complete with no errors");
        } else {
            NSLog(@"copy had an error %@",err);
        }
    }
}





#pragma mark - Check for Updates

//-(NSString*)extractFileTime:(NSString*)path {
//    
//    NSString* content = [NSString stringWithContentsOfFile:path
//                                                  encoding:NSUTF8StringEncoding
//                                                     error:NULL];
//    
//    //parse the file
//    NSArray *lines = [content componentsSeparatedByString:@"\r\n"];
//    for (NSString* s in lines) {
//        NSArray* a = [s componentsSeparatedByString:@","];
//        if (a.count <3) {
//            return [a firstObject];
//        }
//    }
//    return nil;
//}
//




#pragma mark - solver funcs
-(NSArray*)solvedRoutes {
    if (_solvedRoutes == nil) {
        _solvedRoutes = [[NSMutableArray alloc] init];
    }
    return _solvedRoutes;
}

NSInteger durationSort(id r1, id r2, void *context) {
    OBRsolvedRouteRecord* rr1 = r1;
    OBRsolvedRouteRecord* rr2 = r2;
    int la1 = [rr1 getLatestArrive];
    int la2 = [rr2 getLatestArrive];
    int ed1 = [rr1 getEarliestDepart];
    int ed2 = [rr2 getEarliestDepart];
    int d1 = la1 - ed1;
    int d2 = la2 - ed2;
    
    if (d1 < d2)
        return NSOrderedAscending;
    else if (d1 > d2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

NSInteger arrivalSort(id r1, id r2, void *context) {
    OBRsolvedRouteRecord* rr1 = r1;
    OBRsolvedRouteRecord* rr2 = r2;
    int la1 = [rr1 getLatestArrive];
    int la2 = [rr2 getLatestArrive];

    if (la1 < la2)
        return NSOrderedAscending;
    else if (la1 > la2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

NSInteger departureSort(id r1, id r2, void *context) {
    OBRsolvedRouteRecord* rr1 = r1;
    OBRsolvedRouteRecord* rr2 = r2;
    int la1 = [rr1 getEarliestDepart];
    int la2 = [rr2 getEarliestDepart];
    
    if (la1 < la2)
        return NSOrderedAscending;
    else if (la1 > la2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

-(void)sortSolvedRoutesByDuration{
    NSArray* sortedArray = [_solvedRoutes sortedArrayUsingFunction:durationSort context:NULL];
    
    _solvedRoutes = [[NSMutableArray alloc] initWithArray:sortedArray];
    _solvedRoutesModified = true;
}

-(void)sortSolvedRoutesByArrival{
    NSArray* sortedArray = [_solvedRoutes sortedArrayUsingFunction:arrivalSort context:NULL];
    
    _solvedRoutes = [[NSMutableArray alloc] initWithArray:sortedArray];
    _solvedRoutesModified = true;
}

-(void)sortSolvedRoutesByDeparture{
    NSArray* sortedArray = [_solvedRoutes sortedArrayUsingFunction:departureSort context:NULL];
    
    _solvedRoutes = [[NSMutableArray alloc] initWithArray:sortedArray];
    _solvedRoutesModified = true;
}

-(long)addSolvedRoutes:(OBRsolvedRouteRecord*)r {
    
    [r refreshSummary:r];
    
    //check that the latest timestamp is within the time window
    //this could be off because of the time to walk
    if (r.summaryLatestTimestamp > _arrivalMin) {
        //NSLog(@"This route exceeds the maximum time");
        return [[self solvedRoutes] count];
    }
    
    //check for an unreasonable wait time
    OBRsolvedRouteRecord* p = r;
    while (p != nil) {
        if (p.waitMin >240) {
            return [[self solvedRoutes] count];
        }
        p = p.nextRec;
    }
    
    //loop through the different solutions and check that the solution
    //already has been found
    for (OBRsolvedRouteRecord* p in [self solvedRoutes]) {
        if (r.summaryEarliestTimestamp == p.summaryEarliestTimestamp &&
            r.summaryLatestTimestamp == p.summaryLatestTimestamp) {
            
            //check that summary description has been filled
            if (r.summaryDes == nil) {
                r.summaryDes = r.description;
            }
            
            if ([p.summaryDes isEqualToString:r.summaryDes] ) {
                //NSLog(@"An identical route was found... ");
                return [[self solvedRoutes] count];
            }
        }
    }
    
    //check that we haven't found trip that only differ by the stops used
    for (OBRsolvedRouteRecord* p in [self solvedRoutes]) {
        if ([r.summaryFirstTrip isEqualToString:p.summaryFirstTrip]) {
            if ([r.summaryLastTrip isEqualToString:p.summaryLastTrip]) {
                
                //choose the trip with the least amount of walking involved
                if (p.summaryWalkedDistance > r.summaryWalkedDistance) {
                    [[self solvedRoutes] removeObject:p];
                    [[self solvedRoutes] addObject:r];
                    [self sortSolvedRoutesByDeparture];
                    return [self solvedRoutes].count;
                } else if (p.summaryWalkedDistance < r.summaryWalkedDistance){
                    return [self solvedRoutes].count;
                } else {
                    //the two paths have the same amount of walking
                    if (p.summaryWaitMin < r.summaryWaitMin) {
                        [[self solvedRoutes] removeObject:p];
                        [[self solvedRoutes] addObject:r];
                        [self sortSolvedRoutesByDeparture];
                        return [self solvedRoutes].count;
                    } else {
                        return [self solvedRoutes].count;
                    }
                }
            }
        }
    }
    
    //loop through the different soutions and check that a better solution
    //doesn't exist.  Define a better solution as one that departs the first
    //stop at the same time and arrives at the final stop earlier
    OBRsolvedRouteRecord* recordToDelete = nil;
    BOOL addIncomingRoute = false;
    BOOL foundStoredRoute = false;
    int cFS = r.summaryFirstStop;
    int cLS = r.summaryLastStop;
    int cFSD = r.summaryFirstStopDepart;
    int cLSA = r.summaryLastStopArrive;
    for (OBRsolvedRouteRecord* p in [self solvedRoutes]) {
        int pFS = p.summaryFirstStop;
        int pFSD = p.summaryFirstStopDepart;
        int pLS = p.summaryLastStop;
        if (pFS == cFS && pFSD == cFSD && cLS == pLS) {
            foundStoredRoute = true;
            int pLSA = p.summaryLastStopArrive;
            
            int cD = cLSA - cFSD;
            int pD = pLSA - pFSD;
            
            if (pD > cD) {
                //the stored route has a longer duration and
                //is thus worse then the incoming route
                //record the index of the routeToDelete and
                //mark the incoming route for inclusion
                recordToDelete = p;
                addIncomingRoute = true;
                //NSLog(@"incoming Route is better then stored route...");
            }
        }
    }
    
    //search for a subset route... one that departs later and arrives earlier then
    //another
    int cFT = r.summaryEarliestTimestamp;
    int cLT = r.summaryLatestTimestamp;
    int cWD = r.summaryWalkedDistance;
    for (OBRsolvedRouteRecord* p in [self solvedRoutes]) {
        int pFT = p.summaryEarliestTimestamp;
        int pLT = p.summaryLatestTimestamp;
                
        
        if ((cFT==pFT) && (cLT==pLT)) {
            //maybe I should check that the routes are the same???
            foundStoredRoute = true;
            //NSLog(@"incoming Route has identical time bounds of current Route");
            int pWD = p.summaryWalkedDistance;
            if (cWD < pWD) {
                //this route has same time but shorter walking distance
                addIncomingRoute = true;
                recordToDelete = p;
                //NSLog(@"same time shorter walking distance...");
            }
        } else if ((cFT >= pFT) && (cLT <= pLT)) {
            //discard the stored route and add the incoming route
            foundStoredRoute = true;
            addIncomingRoute = true;
            recordToDelete = p;
            //NSLog(@"Nested: Keep Icoming, Erase Stored... ");
        } else if ((pFT >= cFT) && (pLT <= cLT)) {
            //keep the stored route and discard the incoming
            foundStoredRoute = true;
            addIncomingRoute = false;
            //NSLog(@"Nested Keep Stored...");
        }
    }
    
    //do a check for wait times exceeding a maximum
    
    //delete old route if needed
    if (recordToDelete != nil) {
        [[self solvedRoutes] removeObjectIdenticalTo:recordToDelete];
        _solvedRoutesModified = true;
    }
    
    
    //add the incoming route if it is new or better
    if (addIncomingRoute || foundStoredRoute==false) {
    
        //check that summary description has been filled
        if (r.summaryDes == nil) {
            r.summaryDes = r.description;
        }

        //make a copy of the record
        OBRsolvedRouteRecord* c = [r deepCopy:r];
        
        //NSLog(@"Adding Course");
        
        [[self solvedRoutes] addObject:c];
        [self sortSolvedRoutesByDeparture];
        _solvedRoutesModified = true;
        
        //update the icon with the number of solutions
        [_IOSI imageWithFilename:@"AtoBWide.png"];
        NSString* dirStr = [NSString stringWithFormat:@"%ld",[[self solvedRoutes]count]];
        [_IOSI drawText:dirStr atPoint:CGPointMake(280, 20) FontSize:120];
        _numSolsIcon.alpha = 1;
        _numSolsIcon.image = [_IOSI getImage];
        
        
        //check the earliest time
        if (_solvingEarliestArrival ==0 || r.summaryLatestTimestamp < _solvingEarliestArrival) {
            _solvingEarliestArrival = r.summaryLatestTimestamp;
        }
        
        //update the shortest Travel Time
        int firstDepartMin = r.summaryEarliestTimestamp;
        int lastArriveMin = r.summaryLatestTimestamp;
        int tripDuration = lastArriveMin - firstDepartMin;
        if (tripDuration < _solvingShortestTripDuration || _solvingShortestTripDuration == 0) {
            _solvingShortestTripDuration = tripDuration;
        }
    }
    
    _solvingNumRoutesFound = [[self solvedRoutes] count];
    

    
    return [[self solvedRoutes] count];
}

-(void)eraseSolvedRoutes{
    [[self solvedRoutes] removeAllObjects];
    _solvedRoutesModified = true;
}







-(BOOL)isStop:(long)s onRouteStr:(NSString*)r
{
    NSDictionary* dict = [self stopRouteDict];
    NSString* key = _isStopOnRouteArray[s]; //[NSString stringWithFormat:@"%ld",s];
    NSArray* entry = [dict objectForKey:key];
    if ([entry containsObject:r]) {
        return true;
    } else {
        return false;
    }
}

-(void)setNumSolsIcon:(UIImageView *)numSolsIcon{
    _numSolsIcon = numSolsIcon;
}

-(UIImageView*)getNumSolsIcon {
    return _numSolsIcon;
}

-(void)updateNumSolIcon:(long)num Color:(UIColor *)c Alpha:(float)a {
    //update the icon with the number of solutions
    [_IOSI imageWithFilename:@"AtoBWide.png"];
    NSString* dirStr = [NSString stringWithFormat:@"%ld",num];
    //set the color of the text
    if (num==0 && a==1.0) {
        [_IOSI drawText:dirStr atPoint:CGPointMake(220, 20) FontSize:120 TextColor:RED];
    } else if (num==0) {
        [_IOSI drawText:dirStr atPoint:CGPointMake(220, 20) FontSize:120 TextColor:BLACK];
    } else {
        [_IOSI drawText:dirStr atPoint:CGPointMake(220, 20) FontSize:120 TextColor:FOREST_GREEN];
    }
    
    _numSolsIcon.alpha = a;
    _numSolsIcon.image = [_IOSI getImage];
}

#pragma mark - Stop functions

-(NSDictionary*)stopsDict {
    if (_stopsDict == nil) {
        _stopsDict = [[NSMutableDictionary alloc] init];
        for (OBRStopNew* s in [self stops]) {
            NSString* key = [NSString stringWithFormat:@"%d",s.number];
            [_stopsDict setObject:s forKey:key];
        }
    }
    return _stopsDict;
}

-(NSArray*)stops{
    if (!_stops) {
        [self getStopsUsingContext:context];
    }
    return _stops;
}

-(BOOL)getStopsUsingContext:(NSManagedObjectContext*)mc {
    //create fetch request
    NSFetchRequest *r = [[NSFetchRequest alloc] init];
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRStopNew"];
    if (e==nil) return false;
    [r setEntity:e];
    
    
    NSSortDescriptor *sd = [NSSortDescriptor
                            sortDescriptorWithKey:@"number"
                            ascending:YES];
    [r setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    //execute fetch
    NSError *err;
    NSArray* res = [mc executeFetchRequest:r error:&err];
    _stops = [[NSMutableArray alloc] initWithArray:res];
    
    //process exceptions
    if (!_stops) {
        [NSException raise:@"DS Stops Fetch failed"
                    format:@"Reason: %@", [err localizedDescription]];
        return false;
    }
    
    //handle empty database
    if (_stops.count == 0) {
        NSLog(@"OBRDS No Stops found in database");
    } else {
        NSLog(@"OBRDS Verified Stops in Database");
    }
    return true;
}

//this function search the resident memory copy of stop route dictionary.
//the dictionary is loaded into memory at init so it should be thread safe
-(NSArray*)getRoutesForStop:(int)stop {
    
    NSDictionary* dict = [self stopRouteDict];
    NSArray* result = nil;
    NSString* key = [NSString stringWithFormat:@"%d",stop];
    result = [dict objectForKey:key];
    return result;
}

-(NSArray*)getStops {
    return [self stops];
}

//this is called at init so it should be resident in memory at all times
-(NSArray*)stopRouteDict{
    
    if (_stopRouteDict == nil) {
        
        NSLog(@"loading StopRouteDict json file...");
        NSError *err = nil;
        NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"stopRouteDict" ofType:@"json"];
        if (dataPath==nil) return nil;
        _stopRouteDict= [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath] options:kNilOptions error:&err];
        NSLog(@"done");
        
    }
    return _stopRouteDict;
}


//gets its results either from the thread or main version of getschforroutestr
-(NSArray*)getStopsForRoutestr:(NSString *)rs {
    
    //search the cache
    NSString* key = [NSString stringWithFormat:@"getStopsForRoutestr%@",rs];
    NSArray* result = [_cache objectForKey:key];
    if (result != nil) return result;
    
    //get the route set
    NSSet* stopSet = [[self routeStopDict] objectForKey:rs];
    
    //create an array to hold
    NSMutableArray* array = [[NSMutableArray alloc] init];
    
    for (NSString* sstr in stopSet) {
        int stopNum = [sstr intValue];
        OBRStopNew* stop = [self getStop:stopNum];
        [array addObject:stop];
    }
    
    //store the results
    [[self cache] setObject:array forKey:key];
    
    //return result
    return array;
}


-(OBRStopNew*)getStop:(int)stop {
    NSString* key = [NSString stringWithFormat:@"%d",stop];
    return [[self stopsDict] objectForKey:key];
}

#pragma mark - Update vehicles

//update the vehicles from the website
-(void)updateVehiclesStart{
    
    if (model == nil) {
        NSLog(@"OBRDS Update Vehicle Start... DB not ready");
        return;
    }
    
    if (!updateVehicles) {
        NSLog(@"ORBDS Update vehicle is off");
        return;
    }
    
    if (vehicleConnection != nil) {
        NSTimeInterval now = [self currentTimeSec];
        NSTimeInterval elapsed = now - updateVehicleTime;
        NSLog(@"OBRDS Update Vehicle Start... UPdate in progress %f",elapsed);
        
        if (elapsed>30) {
            NSLog(@"Update Vehicle timed out restarting");
            vehicleConnection = nil;
            vehicleData = nil;
        }
        return;
    }
    NSLog(@"OBRDS Update Vehicle Start");
    
    //    //check the timestamp on the server file
    NSURL *url;
    if (self.fullUpdate) {
        url = [NSURL URLWithString:@"http://OBRuser:OBRUserPassword@ios-hawaii.com/OBRroot/allvehicles.json"];
    } else {
        url = [NSURL URLWithString:@"http://OBRuser:OBRUserPassword@ios-hawaii.com/OBRroot/changed.json"];
    }
    
    //set the start time
    updateVehicleTime = [self currentTimeSec];
    
    //start the asynchronous transfer
    vehicleData = [[NSMutableData alloc] init];
    NSURLRequest *req = [NSURLRequest requestWithURL:url
                                         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                     timeoutInterval:120];
    vehicleConnection = [[NSURLConnection alloc] initWithRequest:req
                                                        delegate:self
                                                startImmediately:YES];
    
    
}


-(void)updateVehiclesEnd:(NSMutableData*)rdata{
    
    NSLog(@"OBRDS Update Vehicle End");
    
    //get a reference to the datastore singleton
    
    //NSTimeInterval elapsed = [self currentTimeSec] - debug1_vehicleupdatetime;
    
    //start the icon
    self.data--;
    
    //check the input
    if (rdata==nil) {
        self.data--;
        NSLog(@"vehicle end data nil");
        return;
    }
    
    
    //parse the json file
    NSDictionary *vehiclesJSON = [NSJSONSerialization JSONObjectWithData:rdata
                                                                 options:0
                                                                   error:nil];
    
    //update the database
    for (id busNum in vehiclesJSON) {
        NSArray* v = [vehiclesJSON objectForKey:busNum];
        
        if ([v count] >= 9) {
            OBRVehicle* vdb = [self getVehicle:busNum];
            
            if (vdb) {
                
                //interpret the time as an HST time
                NSMutableString* timeStr = [[NSMutableString alloc] initWithString:[v objectAtIndex:4]];
                [timeStr appendString:@" HST"];
                NSDateFormatter* df = [[NSDateFormatter alloc] init];
                [df setDateFormat:@"MM/dd/yyyy hh:mm:ss a z"];
                NSDate* date = [df dateFromString:timeStr];
                NSTimeInterval incomingLastMessageDate = [date timeIntervalSinceReferenceDate];
                
                //check that this is not a repeat
                if (vdb.lastMessageDate != incomingLastMessageDate) {
                    vdb.number = [busNum intValue];
                    vdb.lat = [[v objectAtIndex:0] floatValue];
                    vdb.lon = [[v objectAtIndex:1] floatValue];
                    vdb.adherence = [[v objectAtIndex:2] intValue];
                    vdb.trip = [v objectAtIndex:3];
                    vdb.orientation = [[v objectAtIndex:5] floatValue];
                    vdb.route = [v objectAtIndex:6];
                    vdb.direction = [v objectAtIndex:7];
                    vdb.speed = [[v objectAtIndex:8] floatValue];
                    vdb.lastMessageDate = [date timeIntervalSinceReferenceDate];
                    
                    //add the vehicle to the vehicles in motion database array
                    [self.vehiclesInMotion addObject:vdb];
                    
                    //label the data as changed
                    vehiclesModified = true;
                    
                }
            }
        }
    }
    
    //save the database
    [self saveDatabase];
    
    //find the most recent timestamp
    double secs = 0;
    for (OBRVehicle* v in [self vehicles]) {
        if (v.lastMessageDate > secs) secs = v.lastMessageDate;
    }
    
    NSLog(@"OBRDS Update Vehicle Done %lu vehicles updated TS=%lf", vehiclesJSON.count,secs);
    
    //if we performed a full fetch go back to incremental now
    self.fullUpdate = false;
    
    //slow the timer to the normal update rate
    [vehicleUpdateTimer invalidate];
    [self setVehicleTimer:31.0];
}

-(void)setVehicleTimer:(float)interval {
    NSLog(@"Setting the vehicle timer to %f",interval);
    [vehicleUpdateTimer invalidate];
    vehicleUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(updateVehiclesStart)
                                                        userInfo:nil
                                                        repeats:YES];
}


#pragma mark - Access Data Connection
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    //get the etag
    NSString* eTag = nil;
    NSDictionary* d;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if ([response respondsToSelector:@selector(allHeaderFields)]) {
        d = [httpResponse allHeaderFields];
        eTag = d[@"Etag"];
    }
    
    if (eTag != nil && [eTag isEqualToString:lastVehicleEtag]) {
        [connection cancel];
        vehicleConnection = nil;
        vehicleData = nil;
        NSLog(@"OBRDS Server sending stale file... aborting connection");
    } else {
        lastVehicleEtag = [eTag copy];
    }
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)d {
    
    if (conn == vehicleConnection) {
        //NSString* debug = [NSString stringWithFormat:@"rx %d bytes",[data length]];
        //[self addtotextbox:debug];
        if (vehicleData.length == 0) {
            //debug1_vehicleupdatetime = [TF currentTimeSec];
            self.data++;
        }
        [vehicleData appendData:d];
    }
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
    if (conn == vehicleConnection) {
        //[self addtotextbox:@"vehicle connection failed"];
        vehicleConnection = nil;
        vehicleData = nil;
        self.data--;
        NSLog(@"vehicle fail");
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
     if (conn == vehicleConnection) {
        //[self addtotextbox:@"connection did finish loading"];
        vehicleConnection = nil;
        [self updateVehiclesEnd:vehicleData];
         vehicleData = nil;
    }
}





#pragma mark - save Database
-(BOOL)saveDatabaseWithinContext:(NSManagedObjectContext*)mycontext {
    if (context != nil) {
        //NSLog(@"OBRDS Saving Database for context");
        NSError *err=nil;
        BOOL successful = false;
        @synchronized (self) {
           successful = [mycontext save:&err];
        }
        if (!successful) {
            NSLog(@"Error Saving:%@",[err localizedDescription]);
        }
        return successful;
    }
    return false;
}


-(BOOL)saveDatabase {
    //NSLog(@"OBRDS Saving Database");
    NSError *err=nil;
    BOOL successful = false;
    @synchronized (self) {
        successful = [context save:&err];
    }
    
    if (!successful) {
        NSLog(@"Error Saving:%@",[err localizedDescription]);
    }
    return successful;
}



-(NSArray*) getArrivals:(int)vehicle {
    NSLog(@"OBRDS Loading Arrivals from Database");
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRArrival"];
    if (e==nil) return nil;
    
    NSSortDescriptor *sd = [NSSortDescriptor
                           sortDescriptorWithKey:@"stoptime"
                           ascending:YES];
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(vehicle = %d)", vehicle];
    
    //create fetch request
    NSFetchRequest *r = [[NSFetchRequest alloc] init];
    [r setEntity:e];
    [r setPredicate:p];
    [r setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [context executeFetchRequest:r error:&err];
    }
    if (!res) {
        [NSException raise:@"DS Arrivals matching vehicles Fetch failed"
                    format:@"Reason: %@", [err localizedDescription]];
        return nil;
    }
    return res;
 }

-(OBRTrip*) getTrip:(NSString *)tripStr {
    
    //if this has the full length tripstr then shorten it
    NSArray* sa = [tripStr componentsSeparatedByString:@"."];
    if (sa.count == 3) {
        tripStr = [NSString stringWithFormat:@"%@.%@",sa[0],sa[1]];
    }
    
    
    for (OBRTrip* trip in [self trips]) {
        //if ([trip.route isEqualToString:@"40"]) {
        //    NSLog(@"trip=%@ tripstr=%@",trip.tripStr,tripStr);
        //}
        if ([trip.tripStr isEqualToString:tripStr]) {
            return trip;
        }
    }
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRTrip"];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(tripStr=%@)", tripStr];
    
    //create fetch request
    NSFetchRequest *r = [[NSFetchRequest alloc] init];
    [r setEntity:e];
    [r setPredicate:p];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [context executeFetchRequest:r error:&err];
    }
    if (!res) {
        [NSException raise:@"DS no trip found"
                    format:@"Reason: %@", [err localizedDescription]];
        return nil;
    }
    return [res firstObject];

}

-(NSArray*)getTripsForRoute:(NSString *)routeStr {
    NSLog(@"I should cache the trips for route");
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRTrip"];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(route = %@)", routeStr];
    
    //create fetch request
    NSFetchRequest *r = [[NSFetchRequest alloc] init];
    [r setEntity:e];
    [r setPredicate:p];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [context executeFetchRequest:r error:&err];
    }
    if (!res) {
        [NSException raise:@"DS no trips found for RouteStr"
                    format:@"Reason: %@", [err localizedDescription]];
        return nil;
    }
    return res;

}


-(NSArray*) getArrivals:(int)vehicle atTime:(NSTimeInterval)time withSpan:(float)span {
    //NSLog(@"DS loading arrivals from database");
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRArrival"];
    if (e==nil) return nil;
    
    NSSortDescriptor *sd = [NSSortDescriptor
                            sortDescriptorWithKey:@"stoptime"
                            ascending:YES];
    
    NSDate* mintime = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:time-span];
    NSDate* maxtime = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:time+span];
    NSPredicate *p1 = [NSPredicate predicateWithFormat:@"(vehicle = %d)", vehicle];
    NSPredicate *p2 = [NSPredicate predicateWithFormat:@"(stoptime >%@)", mintime];
    NSPredicate *p3 = [NSPredicate predicateWithFormat:@"(stoptime <%@)", maxtime];
    
    NSMutableArray *parr = [NSMutableArray array];
    [parr addObject:p1];
    [parr addObject:p2];
    [parr addObject:p3];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:parr];
    
    //create fetch request
    NSFetchRequest *r = [[NSFetchRequest alloc] init];
    [r setEntity:e];
    [r setPredicate:predicate];
    [r setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [context executeFetchRequest:r error:&err];
    }
    if (!res) {
        [NSException raise:@"DS Arrivals matching vehicles Fetch failed"
                    format:@"Reason: %@", [err localizedDescription]];
        return nil;
    }
    return res;
}


-(OBRVehicle*)findVehicle:(int) num{    
    for (OBRVehicle* i in [self vehicles]) {
        if (i.number == num) {
            return i;
        }
    }
    return nil;
}

-(OBRVehicle*)getVehicle:(NSString*) numStr{
    numStr = [numStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    
    for (OBRVehicle* i in [self vehicles]) {
        //look for match
        if ([i.numString isEqualToString:numStr]) {
            //return match
            return i;
        }
    }

    //no match found create new entry
    OBRVehicle* v = [self createVehicle:numStr];

    //return new entry
    return v;
}

-(OBRVehicle*)getVehicleForTrip:(NSString*) tripstr {
    //get the current time
    NSTimeInterval nowSec = [self currentTimeSec];
    
    
    OBRVehicle* v = nil;
    unsigned long length = [tripstr length];
    
    int f=0;
    for (OBRVehicle* va in self.vehicles) {
        if (va.trip.length >= length) {
          NSString* substr = [va.trip substringToIndex:length];
            if ([substr isEqualToString:tripstr]) {
                
                float elapsed = nowSec - va.lastMessageDate;
                if (elapsed < 1800) {
                    f++;
                    v = va;
                }
            }
        }
    }
    if (f>1) {
        NSLog(@"Multiple vehicles found for trip!!!!!!!!!!");
    }
    
    return v;
}



-(int)checkRouteForRealTimeInfo:(OBRsolvedRouteRecord *)r {
    
    NSArray* ra = [r convertToArray:r];
    for (OBRsolvedRouteRecord* srr in ra) {
        if (srr.type == ROUTE) {
            if ([self getVehicleForTrip:srr.trip] != nil) {
                r.GPS = true;
                return 1;
            }
        }
    }
    r.GPS = false;
    return 0;
}


-(OBRArrival*)createArrival {
    OBRArrival* a;
    @synchronized (self) {
        //insert a new entry into the database
        a = [NSEntityDescription insertNewObjectForEntityForName:@"OBRArrival" inManagedObjectContext:context];
    }
    return a;
}


-(NSArray*)getRouteWalkRoute1:(NSString *)r1 Route2:(NSString *)r2 {
    NSDictionary* rwr = [self routeWalkRoute];
    NSString* keyword = [[NSString alloc] initWithFormat:@"%@/%@",r1,r2];
    NSArray* result = [rwr objectForKey:keyword];
    
    if (result != nil) {
        //NSLog(@"ROute %@ and Route %@ has walking stops %@",r1,r2,result);
        return result;
        
    } else {
    
        NSString* keyword2 = [[NSString alloc] initWithFormat:@"%@/%@",r2,r1];
        result = [rwr objectForKey:keyword2];
        //NSLog(@"ROute %@ and Route %@ has walking stops %@",r1,r2,result);
        return result;
    }
}

-(NSArray*)getRouteRouteRoute1:(NSString*)r1 Route2:(NSString*)r2 {
    NSDictionary* rrr = [self routeRouteRoute];
    NSString* keyword = [[NSString alloc] initWithFormat:@"%@/%@",r1,r2];
    NSArray* result = [rrr objectForKey:keyword];
    
    if (result != nil) {
        //NSLog(@"ROute %@ and Route %@ has RRR info %@",r1,r2,result);
        return result;
        
    } else {
    
        NSString* keyword2 = [[NSString alloc] initWithFormat:@"%@/%@",r2,r1];
        result = [rrr objectForKey:keyword2];
        //NSLog(@"ROute %@ and Route %@ has RRR info %@",r1,r2,result);
        return result;
    }
    
}


-(NSArray*)getJointStopsOnRoute1:(NSString *)r1 Route2:(NSString *)r2 {
    NSDictionary* jsd = [self jointStops];
    NSString* keyword = [[NSString alloc] initWithFormat:@"%@/%@",r1,r2];
    NSArray* result = [jsd objectForKey:keyword];
    
    if (result != nil) {
        //NSLog(@"ROute %@ and Route %@ has joint stops %@",r1,r2,result);
        return result;
        
    } else {
    
        NSString* keyword2 = [[NSString alloc] initWithFormat:@"%@/%@",r2,r1];
        result = [jsd objectForKey:keyword2];
        //NSLog(@"ROute %@ and Route %@ has joint stops %@",r1,r2,result);
        return result;
    }
}


#pragma mark - schedule functions
//depending on the thread paramter different contexts are used
-(NSArray*)getSchForRoutestr:(NSString*)r Stop:(long)s Day:(long)d Min:(long)m Thread:(BOOL)t {
    
    //check cache
    NSString* searchStr = [NSString stringWithFormat:@"getschforroutestr%@%ld%ld%ld",r,s,d,m];
    NSArray* result = [[self cache] objectForKey:searchStr];
    if (result != nil) return result;
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRScheduleNew"];
    if (e==nil) NSLog(@"fail");
    if (e==nil) return FALSE;
    
    NSPredicate *p;
    if (s==-1 && d==-1 && m==-1) {
        p= [NSPredicate predicateWithFormat:@"(trip.route=%@)",r];
    } else if (s>0 && d==-1 && m==-1) {
        p= [NSPredicate predicateWithFormat:@"(trip.route=%@ && stop.number=%d)",r,s];
    } else if (s==-1 && d>0 && m>=0) {
        p= [NSPredicate predicateWithFormat:@"(trip.route=%@ && minOfDay=%d && day==%d)",r,m,d];
    } else if (s==-1 && d>0 && m ==-1) {
        p= [NSPredicate predicateWithFormat:@"(trip.route=%@ && day==%d)",r,d];
    }  else if (s>0 && d>0 && m ==-1) {
        p= [NSPredicate predicateWithFormat:@"(trip.route=%@ && day==%d) && stop.number=%d",r,d,s];
    } else {
        p= [NSPredicate predicateWithFormat:@"(trip.route=%@ && stop.number=%d && minOfDay=%d && day==%d)",r,s,m,d];
    }
    
    //set the sort
    //NSSortDescriptor* sd = [ NSSortDescriptor sortDescriptorWithKey:@"stopMin" ascending:YES];
    
    //create fetch request
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    [rq setPredicate:p];
    //[rq setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        
        if (t) {
            res = [threadContext executeFetchRequest:rq error:&err];
        } else {
            res = [context executeFetchRequest:rq error:&err];
        }
        if (!res) {
            [NSException raise:@"DS Fetch failed" format:@"Reason: %@", [err localizedDescription]];
        }
    }
    
    
    //store data in cache
    result = [[NSMutableArray alloc] initWithArray:res];
    [[self cache] setObject:result forKey:searchStr];
    
    return result;
}








//depending on the thread paramter different contexts are used
-(NSArray*)getNewSchForRoutestr:(NSString*)r
                                Stop:(long)s
                                 Day:(long)d
                                eMin:(long)em
                                lMin:(long)lm
                              Thread:(BOOL)t {
    
    //retrieve the data
    NSArray* initresult = [self getNewSchForRoutestr:r Stop:s Thread:t];
    
    //filter
    NSMutableArray* mres = [[NSMutableArray alloc] init];
    for (OBRScheduleNew* e in initresult) {
        if (e.day == d) {
            if (e.minOfDay >= em ) {
                if (e.minOfDay <= lm) {
                    [mres addObject:e];
                }
            }
        }
    }
    
    return mres;
}

//depending on the thread paramter different contexts are used
-(NSArray*)getNewSchForRoutestr:(NSString*)r
                                Stop:(long)s
                              Thread:(BOOL)t {
    
    //check cache
    char cString[255];
    sprintf(cString, "getschfromfileforroutestrStop%s %ld",[r cStringUsingEncoding:NSUTF8StringEncoding],s);
    NSString* searchStr = [[NSString alloc] initWithUTF8String:cString];
    NSArray* result = [_cache objectForKey:searchStr];
    if (result != nil) return result;

    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRScheduleNew"];
    //NSPredicate *p = [NSPredicate predicateWithFormat:@"(trip.tripStr=%@)",trip];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(stop.number=%ld && trip.route =%@)",s,r];
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    [rq setPredicate:p];
    NSArray* res;
    @synchronized (self) {
        res = [context executeFetchRequest:rq error:nil];
    }
    

    //store data in cache
    [[self cache] setObject:res forKey:searchStr];
    
    return res;
}







////depending on the thread paramter different contexts are used
//-(NSArray*)getSchFromFileForRoutestr:(NSString*)r
//                        Stop:(long)s
//                      Thread:(BOOL)t {
//    
//    //check cache
//    char cString[255];
//    sprintf(cString, "getschfromfileforroutestrStop%s %ld",[r cStringUsingEncoding:NSUTF8StringEncoding],s);
//    NSString* searchStr = [[NSString alloc] initWithUTF8String:cString];
//    NSArray* result = [_cache objectForKey:searchStr];
//    if (result != nil) return result;
//    
//    //retrieve and filter the data
//    NSArray* schRouteStopDay = [self getSchFromFileForRoutestr:r Thread:t];
//    //NSLog(@" %d returned from route %@",schRouteStopDay.count,r);
//    
//    NSMutableArray* mresult = [[NSMutableArray alloc] init];
//    for (OBRscheduleFile* e in schRouteStopDay) {
//        if (e.stop == s) {
//            [mresult addObject:e];
//        }
//    }
//    
//    //store data in cache
//    [[self cache] setObject:mresult forKey:searchStr];
//    
//    return mresult;
//}
//



-(NSArray*)getSchForTrip:(NSString*)t {
    
    //if this has the full length tripstr then shorten it
    NSArray* sa = [t componentsSeparatedByString:@"."];
    if (sa.count == 3) {
        t = [NSString stringWithFormat:@"%@.%@",sa[0],sa[1]];
    }
    
    //check cache
    NSString* searchStr = [NSString stringWithFormat:@"getschfortrip%@",t];
    NSArray* result = [[self cache] objectForKey:searchStr];
    if (result != nil) return result;
   
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRScheduleNew"];
    if (e==nil) return FALSE;
    
    NSPredicate *p;
    p= [NSPredicate predicateWithFormat:@"(trip.tripStr=%@)",t];
    
    //set the sort
    NSSortDescriptor* sd = [ NSSortDescriptor sortDescriptorWithKey:@"minOfDay" ascending:YES];
    
    //create fetch request
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    [rq setPredicate:p];
    [rq setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [context executeFetchRequest:rq error:&err];
    }
    if (!res && res.count>0) {
        [NSException raise:@"DS Fetch failed" format:@"Reason: %@", [err localizedDescription]];
    }
    
    //store data in cache
    result = [[NSMutableArray alloc] initWithArray:res];
    [[self cache] setObject:result forKey:searchStr];
    
    return result;
}



-(NSArray*)getSchForTrip:(NSString*)t OnDay:(int)day {
    
    //if this has the full length tripstr then shorten it
    NSArray* sa = [t componentsSeparatedByString:@"."];
    if (sa.count == 3) {
        t = [NSString stringWithFormat:@"%@.%@",sa[0],sa[1]];
    }
    
    //check cache
    NSString* searchStr = [NSString stringWithFormat:@"getschfortrip%@ day%d",t,day];
    NSArray* result = [[self cache] objectForKey:searchStr];
    if (result != nil) return result;
   
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRScheduleNew"];
    if (e==nil) return FALSE;
    
    NSPredicate *p;
    p= [NSPredicate predicateWithFormat:@"(trip.tripStr=%@ && day==%d)",t,day];
    
    //set the sort
    NSSortDescriptor* sd = [ NSSortDescriptor sortDescriptorWithKey:@"minOfDay" ascending:YES];
    
    //create fetch request
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    [rq setPredicate:p];
    [rq setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [context executeFetchRequest:rq error:&err];
    }
    if (!res) {
        [NSException raise:@"DS Fetch failed" format:@"Reason: %@", [err localizedDescription]];
    }
    
    //store data in cache
    result = [[NSMutableArray alloc] initWithArray:res];
    [[self cache] setObject:result forKey:searchStr];
    
    return result;
}


-(NSArray*)getSchForStop:(int)stop {
    
    //check cache
    NSString* searchStr = [NSString stringWithFormat:@"getschforstop%d",stop];
    NSArray* result = [[self cache] objectForKey:searchStr];
    if (result != nil) return result;
    
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRScheduleNew"];
    if (e==nil) return FALSE;
    
    NSPredicate *p;
    p= [NSPredicate predicateWithFormat:@"(stop.number=%d)",stop];
    
    //set the sort
    NSSortDescriptor* sd1 = [ NSSortDescriptor sortDescriptorWithKey:@"minOfDay" ascending:YES];
    NSSortDescriptor* sd2 = [NSSortDescriptor sortDescriptorWithKey:@"day" ascending:YES];
    NSArray* sda = [[NSArray alloc] initWithObjects:sd2,sd1, nil];
    
    
    //create fetch request
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    [rq setPredicate:p];
    [rq setSortDescriptors:sda];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [context executeFetchRequest:rq error:&err];
    }
    if (!res) {
        [NSException raise:@"DS Fetch failed" format:@"Reason: %@", [err localizedDescription]];
    }
    
    //store data in cache
    result = [[NSMutableArray alloc] initWithArray:res];
    [[self cache] setObject:result forKey:searchStr];
    
    return result;

}


-(NSArray*)getCompleteSch{
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRScheduleNew"];
    if (e==nil) return FALSE;
    
    //create fetch request
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [context executeFetchRequest:rq error:&err];
    }
    if (!res) {
        [NSException raise:@"DS Fetch failed" format:@"Reason: %@", [err localizedDescription]];
    }
    
    return [[NSMutableArray alloc] initWithArray:res];
}



-(void)deleteObject:(NSManagedObject*) ob {
    @synchronized (self) {
        [context deleteObject:ob];
    }
}



//-(void)cleanArrivalTable{
//    NSLog(@"OBRDS cleanArrivalTable");
//    
//    //get the current time
//    NSDate* now = [[NSDate alloc] init];
//    NSTimeInterval secs = [now timeIntervalSinceReferenceDate];
//    NSTimeInterval yesterday = secs - (60.0*30.0);
//    
//    //define fetch parameters
//    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRArrival"];
//    if (e==nil) return;
//    
//    NSDate* mintime = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:yesterday];
//    NSPredicate *p = [NSPredicate predicateWithFormat:@"(stoptime <%@)", mintime];
//    
//    //create fetch request
//    NSFetchRequest *r = [[NSFetchRequest alloc] init];
//    [r setEntity:e];
//    [r setPredicate:p];
//    
//    //execute fetch
//    NSError *err;
//    NSArray *res = [context executeFetchRequest:r error:&err];
//
//    //delete the old arrivals
//    NSLog(@"Deleting %lu old arrivals", (unsigned long)res.count);
//    for (OBRArrival* a in res) {
//        //NSLog(@"Deleting Arrival %@",a.description);
//        [context deleteObject:a];
//    }
//    NSLog(@"done");
//}

-(NSArray*)getPointsForRegion:(MKCoordinateRegion)r {
    float Nlat = r.center.latitude + r.span.latitudeDelta/2.0;
    float Slat = r.center.latitude - r.span.latitudeDelta/2.0;
    float Elon = r.center.longitude + r.span.longitudeDelta/2.0;
    float Wlon = r.center.longitude - r.span.longitudeDelta/2.0;
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRRoutePoints"];
    if (e==nil) return FALSE;
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(lat<%f && lat>%f && lon<%f && lon>%f)",Nlat,Slat,Elon,Wlon];
    NSSortDescriptor* sd = [ NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    
    //create fetch request
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:e];
    [req setPredicate:p];
    [req setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [context executeFetchRequest:req error:&err];
    }
    if (!res) {
        [NSException raise:@"DS Fetch failed" format:@"Reason: %@", [err localizedDescription]];
    }
    
    return [[NSMutableArray alloc] initWithArray:res];
}

-(NSArray*)getPointsForRoute:(int)route {
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRRoutePoints"];
    if (e==nil) return FALSE;
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(route = %d)", route];
    NSSortDescriptor* sd = [ NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    
    //create fetch request
    NSFetchRequest *r = [[NSFetchRequest alloc] init];
    [r setEntity:e];
    [r setPredicate:p];
    [r setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [context executeFetchRequest:r error:&err];
    }
    if (!res) {
        [NSException raise:@"DS Fetch failed" format:@"Reason: %@", [err localizedDescription]];
    }
    
    return [[NSMutableArray alloc] initWithArray:res];
}

-(NSArray*)getPointsForRouteStr:(NSString *)route {
    
    
    //check cache
    NSString* searchStr = [NSString stringWithFormat:@"getPointsforroutestr%@",route];
    NSArray* result = [[self cache] objectForKey:searchStr];
    if (result != nil) return result;

    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRRoutePoints"];
    if (e==nil) return FALSE;
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(routestr = %@)", route];
    NSSortDescriptor* sd = [ NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    
    //create fetch request
    NSFetchRequest *r = [[NSFetchRequest alloc] init];
    [r setEntity:e];
    [r setPredicate:p];
    [r setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [context executeFetchRequest:r error:&err];
    }
    if (!res) {
        [NSException raise:@"DS Fetch failed" format:@"Reason: %@", [err localizedDescription]];
    }
    
    //store result in cache
    [[self cache] setObject:res forKey:searchStr];
    
    return [[NSMutableArray alloc] initWithArray:res];
}





-(void)loadCombinedRouteFile {
    //check if there are any routes loaded
    NSArray* test = [self getPointsForRoute:1];
    
    if (test.count ==0) {
        
        //load the stops from file
        NSLog(@"OBRDS loading Routes info into database");
        NSString* path = [[NSBundle mainBundle] pathForResource:@"CombinedRoutes"
                                                         ofType:@"txt"];
        
        NSString* content = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
        
        //parse the file
        NSArray *lines = [content componentsSeparatedByString:@"\n"];
        int order =0;
        for (NSString* s in lines) {
            NSArray* a = [s componentsSeparatedByString:@" "];
            if (a.count >=6) {
                
                if (context != nil) {
                    @synchronized (self) {
                        
                        OBRRoutePoints* rp = [NSEntityDescription insertNewObjectForEntityForName:@"OBRRoutePoints"
                                                                           inManagedObjectContext:context];
                        rp.route = [a[0] intValue];
                        rp.order = order++;
                        rp.routestr = a[1];
                        rp.segment = [a[2] intValue];
                        rp.lat = [a[3] floatValue];
                        rp.lon = [a[4] floatValue];
                        rp.distance = [a[5] intValue];
                        //NSLog(@"adding point %@",rp.description);
                    }
                }
            }
        }
        [self saveDatabase];
        
      } else {
        NSLog(@"OBRDS Verified Routes Info");
    }
}



-(OBRVehicle *)createVehicle:(NSString *)numStr {
    if (context) {
        //insert a new entry into the database
        OBRVehicle * v;
        
        @synchronized (self) {
            v= [NSEntityDescription insertNewObjectForEntityForName:@"OBRVehicle"
                                                       inManagedObjectContext:context];
        }
        
        //set the input values
        v.numString = numStr;
        
        //add to the vehicles array to match the database
        [self.vehicles addObject:v];
        
        return v;
    }
    return nil;
}



-(NSArray*)getArrivals{
    
    NSLog(@"DS loading arrivals database");
    
    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRArrival"];
    if (e==nil) return nil;
    
    
    NSSortDescriptor *sd = [NSSortDescriptor
                            sortDescriptorWithKey:@"stop"
                            ascending:YES];
    
    //create fetch request
    NSFetchRequest *r = [[NSFetchRequest alloc] init];
    [r setEntity:e];
    [r setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [context executeFetchRequest:r error:&err];
    }
    if (!res) {
        [NSException raise:@"DS Arrival Fetch failed"
                    format:@"Reason: %@", [err localizedDescription]];
    }
    
    NSArray* arrivals = [[NSMutableArray alloc] initWithArray:res];
    NSLog(@"DS %lu Arrival Entries loaded",(unsigned long) res.count);
    
    
    return arrivals;
}


-(NSMutableArray*)vehicles{
    if (_vehicles == nil) {
        _vehicles = [self fetchVehiclesUsingContext:context];
    }
    return _vehicles;
 }


-(NSMutableArray*)fetchVehiclesUsingContext:(NSManagedObjectContext*)mc {
    
     NSSortDescriptor *sd = [NSSortDescriptor
                            sortDescriptorWithKey:@"number"
                            ascending:YES];

    //define fetch parameters
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRVehicle"];
    if (e==nil) return FALSE;
    
    //create fetch request
    NSFetchRequest *r = [[NSFetchRequest alloc] init];
    [r setEntity:e];
    [r setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    //execute fetch
    NSError *err;
    NSArray *res;
    @synchronized (self) {
        res = [mc executeFetchRequest:r error:&err];
    }
    if (!res) {
        [NSException raise:@"DS Fetch failed" format:@"Reason: %@", [err localizedDescription]];
    }
    
    _vehicles = [[NSMutableArray alloc] initWithArray:res];
       
    if (res.count == 0) {
        NSLog(@"DS no vehicles in database");
    } else {
        NSLog(@"DS %lu vehicles loaded",(unsigned long) res.count);
    }
    
    
    return _vehicles;

}  


-(NSArray *)vehiclesInMotion{
    if (!_vehiclesInMotion) _vehiclesInMotion = [[NSMutableArray alloc] init];
    return _vehiclesInMotion;
}

-(void)setDataRxButton:(UIImageView *)in{
    _dataRxButton = in;
}

-(void)setActivityIndicator:(UIActivityIndicatorView *)in {
    _activityIndicator = in;
}

-(UIImageView*)getDataRxButton{
    return _dataRxButton;
}
-(UIActivityIndicatorView*)getActivityInd {
    return _activityIndicator;
}

-(void)checkForIconState {
    if (busy>0) {
        [_activityIndicator startAnimating];
        _activityIndicator.alpha = 1.0;
    } else {
        [_activityIndicator stopAnimating];
        _activityIndicator.alpha = 0.1;
    }
    
    if (data>0) {
        
        CABasicAnimation *theAnimation;
        theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
        theAnimation.duration=0.05;
        theAnimation.repeatCount=INFINITY;
        theAnimation.autoreverses=YES;
        theAnimation.fromValue=[NSNumber numberWithFloat:0.0];
        theAnimation.toValue=[NSNumber numberWithFloat:1.0];
        [_dataRxButton.layer   addAnimation:theAnimation forKey:@"masterData"];
        
    } else {
        [_dataRxButton.layer removeAnimationForKey:@"masterData"];
    }
    
    if (busy<0) busy=0;
    if (data<0) data=0;
}

@end
