//
//  OBRBuildDatabaseVC.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 11/8/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRBuildDatabaseVC.h"

@interface OBRBuildDatabaseVC () {
    IOSTimeFunctions* TF;
    NSMutableArray* addedNodes;
    NSMutableArray* addedPOIs;
    
}

@end


@implementation OBRBuildDatabaseVC

@synthesize textField;
@synthesize text;


-(NSMutableDictionary*)tripData {
    if (_tripData == nil) {
        _tripData = [[NSMutableDictionary alloc] init];
    }
    return _tripData;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //init local
    TF = [[IOSTimeFunctions alloc] init];
    addedNodes = [[NSMutableArray alloc] init];
    addedPOIs = [[NSMutableArray alloc] init];
    
    //reset the text field
    text = @"";
    textField.text = @"Ready";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - database search

-(OBRStopNew*)getStop:(int)number
   fromContext:(NSManagedObjectContext*)context
     withModel:(NSManagedObjectModel*)model {

    
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRStopNew"];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(number=%d)",number];
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    [rq setPredicate:p];
     NSArray* res = [context executeFetchRequest:rq error:nil];
    OBRStopNew* s = [res firstObject];
    return s;
}

-(OBRTrip*)getTrip:(NSString*) trip
   fromContext:(NSManagedObjectContext*)context
     withModel:(NSManagedObjectModel*)model {

    
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRTrip"];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(tripStr=%@)",trip];
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    [rq setPredicate:p];
     NSArray* res = [context executeFetchRequest:rq error:nil];
    OBRTrip* s = [res firstObject];
    return s;
}




#pragma mark - processing

-(void)process {
    
    
    //build the filename
    NSArray* docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [docDirs objectAtIndex:0];
    NSString *dbPath = [docDir stringByAppendingPathComponent:@"newstore.data"];
    NSLog(@"path = %@",dbPath);
    
    //delete the old file if it is still here
    [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
    
    //where does the SQLite file go?
    NSURL *storeURL = [NSURL fileURLWithPath:dbPath];
    NSError *error=nil;
    
    //create a persistantstorecoor
    NSManagedObjectModel* model = [NSManagedObjectModel mergedModelFromBundles:nil];
    NSPersistentStoreCoordinator* psc;
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    if(![psc addPersistentStoreWithType:NSSQLiteStoreType
                          configuration:nil
                                    URL:storeURL
                                options:nil
                                  error:&error]) {
        [NSException raise:@"Open failed" format:@"Reason: %@",[error localizedDescription]];
    }
    
    //create the managed object context
    NSManagedObjectContext* context;
    context = [[NSManagedObjectContext alloc] init];
    [context setPersistentStoreCoordinator:psc];
    
    
    
    //get the version files form the website
    NSString *poiPath = [[NSBundle mainBundle] pathForResource:@"OSMHawaiiData" ofType:@"json"];
    NSDictionary* a = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:poiPath] options:kNilOptions error:&error];
    NSMutableDictionary*  OSMnodes = [[NSMutableDictionary alloc] initWithDictionary:a[@"nodes"]];
    NSMutableDictionary*  OSMways = [[NSMutableDictionary alloc] initWithDictionary:a[@"ways"]];
    
    for (NSNumber* waykey in [OSMways keyEnumerator]) {
        
        NSDictionary* way = [OSMways objectForKey:waykey];
        
        
        if ([[way allKeys] containsObject:@"tourism"]) {
            if ([[way allKeys] containsObject:@"nd"]) {
                NSString* name = way[@"name"];
                NSString* tourism = way[@"tourism" ];
                if (tourism) {
                    if ([tourism isEqualToString:@"hotel"]) {
                        NSLog(@"HOTEL: %@ %@",name,way);
                        [self addPOIAndNodeForWay:way Type:@"hotel" UsingNodeDict:OSMnodes Context:context];
                        
                    } else if ([tourism isEqualToString:@"attraction"]) {
                        NSLog(@"ATTRACTION: %@",name);
                        [self addPOIAndNodeForWay:way Type:@"attraction" UsingNodeDict:OSMnodes Context:context];
                    } else if ([tourism isEqualToString:@"museum"]) {
                        NSLog(@"MUSEUM: %@",name);
                        [self addPOIAndNodeForWay:way Type:@"museum" UsingNodeDict:OSMnodes Context:context];
                    }else if ([tourism isEqualToString:@"zoo"]) {
                        NSLog(@"ZOO: %@",name);
                        [self addPOIAndNodeForWay:way Type:@"attraction" UsingNodeDict:OSMnodes Context:context];
                    }else if ([tourism isEqualToString:@"theme_park"]) {
                        NSLog(@"THEME PARK: %@",name);
                        [self addPOIAndNodeForWay:way Type:@"attraction" UsingNodeDict:OSMnodes Context:context];
                    }
                }
            }
        } else  if ([[way allKeys] containsObject:@"amenity"]) {
            if ([[way allKeys] containsObject:@"nd"]) {
                NSString* name = way[@"name"];
                NSString* amenity = way[@"amenity"];
                if (amenity) {
                    if ([amenity isEqualToString:@"school"]) {
                        NSLog(@"SCHOOL: %@",name);
                        [self addPOIAndNodeForWay:way Type:@"school" UsingNodeDict:OSMnodes Context:context];
                    } else if ([amenity isEqualToString:@"library"]) {
                        NSLog(@"LIBRARY: %@",name);
                        [self addPOIAndNodeForWay:way Type:@"library" UsingNodeDict:OSMnodes Context:context];
                        
                    } else if ([amenity isEqualToString:@"townhall"]) {
                        NSLog(@"%@: %@",amenity,name);
                        [self addPOIAndNodeForWay:way Type:@"government" UsingNodeDict:OSMnodes Context:context];
                        
                    } else if ([amenity isEqualToString:@"parking" ] ||
                               [amenity isEqualToString:@"fast_food"] ||
                               [amenity isEqualToString:@"shelter"] ||
                               [amenity isEqualToString:@"bar"] ||
                               [amenity isEqualToString:@"public_building"] ||
                               [amenity isEqualToString:@"pharmacy"] ||
                               [amenity isEqualToString:@"fuel"] ||
                               [amenity isEqualToString:@"toilets"] ||
                               [amenity isEqualToString:@"bank"] ||
                               [amenity isEqualToString:@"boat_storage"] ||
                               [amenity isEqualToString:@"prison"] ||
                               [amenity isEqualToString:@"swimming_pool"] ||
                               [amenity isEqualToString:@"marketplace"] ||
                               [amenity isEqualToString:@"cafe"] ||
                               [amenity isEqualToString:@"mall"] ||
                               [amenity isEqualToString:@"grave_yard"] ||
                               
                               [amenity isEqualToString:@"restaurant"]) {
                        //NSLog(@"%@: %@",amenity,name);
                    } else if ([amenity isEqualToString:@"theatre"]) {
                        [self addPOIAndNodeForWay:way Type:@"entertainment" UsingNodeDict:OSMnodes Context:context];
                        NSLog(@"%@: %@",amenity,name);
                    } else if ([amenity isEqualToString:@"church"]) {
                        [self addPOIAndNodeForWay:way Type:@"church" UsingNodeDict:OSMnodes Context:context];
                        
                        NSLog(@"%@: %@",amenity,name);
                    } else if ([amenity isEqualToString:@"police"]) {
                        [self addPOIAndNodeForWay:way Type:@"government" UsingNodeDict:OSMnodes Context:context];
                        
                        NSLog(@"%@: %@",amenity,name);
                    } else if ([amenity isEqualToString:@"post_office"]) {
                        [self addPOIAndNodeForWay:way Type:@"services" UsingNodeDict:OSMnodes Context:context];
                        
                        NSLog(@"%@: %@",amenity,name);
                    } else if ([amenity isEqualToString:@"hospital"]) {
                        [self addPOIAndNodeForWay:way Type:@"medical" UsingNodeDict:OSMnodes Context:context];
                        
                        NSLog(@"%@: %@",amenity,name);
                    } else if ([amenity isEqualToString:@"college"]) {
                        [self addPOIAndNodeForWay:way Type:@"school" UsingNodeDict:OSMnodes Context:context];
                        
                        NSLog(@"%@: %@",amenity,name);
                    } else if ([amenity isEqualToString:@"fire_station"]) {
                        [self addPOIAndNodeForWay:way Type:@"services" UsingNodeDict:OSMnodes Context:context];
                        
                        NSLog(@"%@: %@",amenity,name);
                    } else if ([amenity isEqualToString:@"place_of_worship"]) {
                        [self addPOIAndNodeForWay:way Type:@"church" UsingNodeDict:OSMnodes Context:context];
                        
                        NSLog(@"%@: %@",amenity,name);
                    } else if ([amenity isEqualToString:@"university"]) {
                        [self addPOIAndNodeForWay:way Type:@"school" UsingNodeDict:OSMnodes Context:context];
                        
                        NSLog(@"%@: %@",amenity,name);
                    }else if ([amenity isEqualToString:@"cinema"]) {
                        [self addPOIAndNodeForWay:way Type:@"entertainment" UsingNodeDict:OSMnodes Context:context];
                        
                        NSLog(@"%@: %@",amenity,name);
                    }
                }
            }
        }else  if ([[way allKeys] containsObject:@"highway"]) {
            //ignore
        } else  if ([[way allKeys] containsObject:@"leisure"]) {
            NSString* label = way[@"leisure"];
            NSString* name = way[@"name"];
            
            if ([label isEqualToString:@"park"]) {
                [self addPOIAndNodeForWay:way Type:@"park" UsingNodeDict:OSMnodes Context:context];
                
                NSLog(@"%@: %@",label,name);
            } else if ([label isEqualToString:@"sports_centre"]) {
                [self addPOIAndNodeForWay:way Type:@"sports" UsingNodeDict:OSMnodes Context:context];
                
                NSLog(@"%@: %@",label,name);
            } else if ([label isEqualToString:@"park"]) {
                NSLog(@"%@: %@",label,name);
            } else if ([label isEqualToString:@"swimming_pool" ] ||
                       [label isEqualToString:@"pitch"] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       [label isEqualToString:@""] ||
                       
                       [label isEqualToString:@""]) {
                //NSLog(@"%@: %@",label,name);
            } else if ([label isEqualToString:@"golf_course"]) {
                [self addPOIAndNodeForWay:way Type:@"sports" UsingNodeDict:OSMnodes Context:context];
                
                NSLog(@"%@: %@",label,name);
            } else if ([label isEqualToString:@"garden"]) {
                NSLog(@"%@: %@",label,name);
            } else if ([label isEqualToString:@""]) {
                NSLog(@"%@: %@",label,name);
            } else if ([label isEqualToString:@""]) {
                NSLog(@"%@: %@",label,name);
            } else if ([label isEqualToString:@""]) {
                NSLog(@"%@: %@",label,name);
            } else if ([label isEqualToString:@""]) {
                NSLog(@"%@: %@",label,name);
            } else if ([label isEqualToString:@""]) {
                NSLog(@"%@: %@",label,name);
            } else if ([label isEqualToString:@""]) {
                NSLog(@"%@: %@",label,name);
            } else if ([label isEqualToString:@""]) {
                NSLog(@"%@: %@",label,name);
            }else if ([label isEqualToString:@""]) {
                NSLog(@"%@: %@",label,name);
            }
        }else {
            //NSLog(@"way = %@ %@",waykey,way);
        }
    }

    

    
    
    //load the stops from file
    NSLog(@"Loading Stops from file");
    NSString* path = [[NSBundle mainBundle] pathForResource:@"Stops" ofType:@"txt"];
    NSString* content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    
    //parse the stop file
    NSMutableDictionary* stopDict = [[NSMutableDictionary alloc] init];
    NSArray *lines = [content componentsSeparatedByString:@"\r\n"];
    for (NSString* s in lines) {
        NSArray* a = [s componentsSeparatedByString:@","];
        if (a.count >3) {
            
            OBRStopNew* e = [NSEntityDescription insertNewObjectForEntityForName:@"OBRStopNew"
                                                        inManagedObjectContext:context];
            e.number = [a[0] intValue];
            e.lat = [a[1] floatValue];
            e.lon = [a[2] floatValue];
            e.streets = [a[3] substringWithRange:NSMakeRange(2,[a[3] length]-3)];
            //e.covered = -1;
            //e.seating = -1;
            [stopDict setObject:e forKey:a[0]];
        }
    }
    [context save:nil];

    
    
    //test the get stop function
    [self getStop:186 fromContext:context withModel:model];
    

    
    NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"Schedules" ofType:@"txt"];
    content = [NSString stringWithContentsOfFile:dataPath
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    
    //NSMutableArray* myThreads = [[NSMutableArray alloc] init];
    
    lines = [content componentsSeparatedByString:@"\r\n"];
    //NSMutableDictionary* tripData = [[NSMutableDictionary alloc] init];
    
    //NSMutableArray* strArray = [[NSMutableArray alloc] init];
    
    for (NSString* s in lines) {
        @autoreleasepool {
            
            NSArray* a = [s componentsSeparatedByString:@","];
            if (a.count >=7) {
                if([[[self tripData] allKeys] containsObject:a[4]] ) {
                    NSMutableDictionary* temp = [self tripData][a[4]];
                    int rTS = [a[3] intValue];
                    int eTS = [temp[@"earliestTS"] intValue];
                    int lTS = [temp[@"latestTS"] intValue];
                    if (rTS<eTS) {
                        temp[@"earliestTS"] = a[3];
                        
                    }
                    if (rTS>lTS) {
                        temp[@"latestTS"] = a[3];
                        
                    }
                    NSString* day = temp[@"day"];
                    NSString* cday = a[2];
                    if (![day containsString:cday]) {
                        //append
                        temp[@"day"] = [NSString stringWithFormat:@"%@%@",day,cday];
                    }
                    
                } else {
                    NSMutableDictionary* temp = [[NSMutableDictionary alloc] init];
                    [temp setObject:a[5] forKey:@"headsign"];
                    [temp setObject:a[6] forKey:@"direction"];
                    [temp setObject:a[3] forKey:@"earliestTS"];
                    [temp setObject:a[3] forKey:@"latestTS"];
                    [temp setObject:a[1] forKey:@"route"];
                    [temp setObject:a[2] forKey:@"day"];
                    [[self tripData] setObject:temp forKey:a[4]];
                    NSLog(@"adding %@ %ld",a[4],[self tripData].count);
                }
                
            }

        
        
            //if ([self tripData].count >3000) break;
        }
    }
    NSLog(@"num trip entries = %ld",[self tripData].count);
    
    //enter trip data into the database
    NSMutableDictionary* tripDict = [[NSMutableDictionary alloc] init];
    for (NSString* key in [[self tripData] allKeys]) {
        NSMutableDictionary* d = [[self tripData] objectForKey:key];
        OBRTrip* e = [NSEntityDescription insertNewObjectForEntityForName:@"OBRTrip"
                                                   inManagedObjectContext:context];
        e.headsign = d[@"headsign"];
        e.direction = d[@"direction"];
        e.tripStr = key;
        e.tripNum = 0;
        e.route = d[@"route"];
        e.earliestTS = [d[@"earliestTS"] intValue];
        e.latestTS = [d[@"latestTS"] intValue];
        e.day = d[@"day"];
        [tripDict setObject:e forKey:key];
    }
    [context save:nil];
    
    
    //enter the schedule data
    NSString* lastStop;
    for (NSString* s in lines) {
        @autoreleasepool {
            NSArray* a = [s componentsSeparatedByString:@","];
            if (a.count >=7) {
                if (![lastStop isEqualToString:a[0]]) {
                    lastStop = a[0];
                    NSLog(@"updating trips for %@",lastStop);
                }
                
                OBRScheduleNew* e = [NSEntityDescription insertNewObjectForEntityForName:@"OBRScheduleNew"
                                                   inManagedObjectContext:context];

                OBRStopNew* dstop = [stopDict objectForKey:a[0]];
                OBRTrip* dtrip = [tripDict objectForKey:a[4]];
                
                e.day = [a[2] intValue];
                e.minOfDay = [a[3] intValue];
                e.trip = dtrip;
                e.stop = dstop;
                
                //add the trip to this stop
                if (dtrip && dstop) {
                    [dtrip addStopsObject:dstop];
                    [dstop addTripsObject:dtrip];
                
                }
            }
        }
    }
    NSLog(@"Saving the new database");
    [context save:nil];
    NSLog(@"New Database saved to %@",dbPath);
}


-(void)addPOIAndNodeForWay:(NSDictionary*)way Type:(NSString*)type UsingNodeDict:(NSDictionary*)OSMnodes Context:(NSManagedObjectContext*)context {
    
    NSLog(@"%@",way);
    NSArray* waynodes = way[@"nd"];
    NSString* name = way[@"name"];
    
    if (name && waynodes) {
        
        //check if this POI already exists
        for (POI* pp in addedPOIs) {
            if ([pp.name isEqualToString:name]) {
                return;
            }
        }
        

        NSNumber* waynode = [waynodes firstObject];
        NSDictionary* node = [self getnode:waynode from:OSMnodes];
        CLLocationCoordinate2D p = [self getLocationOfNode:waynode from:OSMnodes];
        NSLog(@"node:%@",node);

        //check if this node already exists
        OBRNode* n = nil;
        for (OBRNode* np in addedNodes) {
            float dlat = 111000*(np.lat - p.latitude);
            float dlon = 111000*(np.lon - p.longitude);
            float d = sqrtf(dlat*dlat + dlon*dlon);
            if (d<25) {
                n = np;
            }
        }
        
        //create a new node if needed
        if (n==nil) {
            n = [NSEntityDescription insertNewObjectForEntityForName:@"OBRNode"
                                                   inManagedObjectContext:context];
        }
        n.lat = p.latitude;
        n.lon = p.longitude;
        if (node[@"street"] == [NSNull null]) {
            n.street = @"";
        } else {
            n.street = node[@"street"];
        }
        
        if (node[@"streetNum"] == [NSNull null]) {
            n.streetNum = -1;
        } else {
            n.streetNum = [node[@"streetNum"] intValue];
        }
        POI* po = [NSEntityDescription insertNewObjectForEntityForName:@"POI"
                                                inManagedObjectContext:context];
        po.name = name;
        po.type = type;
        po.node = n;
        
        [addedNodes addObject:n];
        [addedPOIs addObject:po];
        
        [context save:nil];
    }

}

-(void)evalTripEntry:(NSArray*)strArr {
    for (NSString* s in strArr) {
    NSArray* a = [s componentsSeparatedByString:@","];
    if (a.count >=7) {
        
        NSArray* keys;
        @synchronized(self) {
            keys = [[self tripData] allKeys];
        }
        
        if([keys containsObject:a[4]] ) {
            
            @synchronized (self) {
                NSMutableDictionary* temp = [ self tripData][a[4]];
                int rTS = [a[3] intValue];
                int eTS = [temp[@"earliestTS"] intValue];
                int lTS = [temp[@"latestTS"] intValue];
                if (rTS<eTS) {
                    temp[@"earliestTS"] = a[3];
                    //NSLog(@"updating eTS %@ to %@",a[4],a[3]);
                    
                }
                if (rTS>lTS) {
                    temp[@"latestTS"] = a[3];
                    //NSLog(@"updating lTS %@ to %@",a[4],a[3]);
                    
                }
            }
            
        } else {
            NSMutableDictionary* temp = [[NSMutableDictionary alloc] init];
            [temp setObject:a[5] forKey:@"headsign"];
            [temp setObject:a[6] forKey:@"direction"];
            [temp setObject:a[3] forKey:@"earliestTS"];
            [temp setObject:a[3] forKey:@"latestTS"];
            
            @synchronized (self) {
                [[self tripData] setObject:temp forKey:a[4]];
                NSLog(@"adding %@ %ld",a[4],[self tripData].count);
            }
        }
        
        //                OBRschedule* e = [NSEntityDescription insertNewObjectForEntityForName:@"OBRschedule"
        //                                                               inManagedObjectContext:loadDBContext];
        //                e.stop = [a[0] intValue];
        //                e.route = [a[1] intValue];
        //                e.routestr = a[1];
        //                e.stopDay = [a[2] intValue];
        //                e.stopMin = [a[3] intValue];
        //                e.trip = a[4];
        //                e.headsign = a[5];
        //                e.direction = a[6];
        //NSLog(@"%@",[e description]);
        
        //[self addStopRoutePair:e.stop route:e.routestr];
    }
    }
}



#pragma mark - Button Actions

- (IBAction)pressedStart:(id)sender {
    //NSTimeInterval now = [TF currentTimeSec];
    [self addToText:@"start"];
    
    //begin processing on a separate thread
    [NSThread detachNewThreadSelector:@selector(process) toTarget:self withObject:nil];
  
    

}


-(IBAction)pressedTest:(id)sender {
    //build the filename
    NSArray* docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [docDirs objectAtIndex:0];
    NSString *dbPath = [docDir stringByAppendingPathComponent:@"newstore.data"];
    NSLog(@"path = %@",dbPath);
    
    //where does the SQLite file go?
    NSURL *storeURL = [NSURL fileURLWithPath:dbPath];
    NSError *error=nil;
    
    //create a persistantstorecoor
    NSManagedObjectModel* model = [NSManagedObjectModel mergedModelFromBundles:nil];
    NSPersistentStoreCoordinator* psc;
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    if(![psc addPersistentStoreWithType:NSSQLiteStoreType
                          configuration:nil
                                    URL:storeURL
                                options:nil
                                  error:&error]) {
        [NSException raise:@"Open failed" format:@"Reason: %@",[error localizedDescription]];
    }
    
    //create the managed object context
    NSManagedObjectContext* context;
    context = [[NSManagedObjectContext alloc] init];
    [context setPersistentStoreCoordinator:psc];
    
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"OBRScheduleNew"];
    //NSString* trip =@"6238838.2505";
    //NSPredicate *p = [NSPredicate predicateWithFormat:@"(trip.tripStr=%@)",trip];
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(stop.number=186)"];
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    [rq setPredicate:p];
    NSArray* res = [context executeFetchRequest:rq error:nil];
    OBRScheduleNew* new = [res firstObject];
    NSLog(@"new=%@",new.description);
    
    
    //test the getting stops
    for (int s = 12 ; s<2000 ; s++) {
        OBRStopNew* stop = [self getStop:s fromContext:context withModel:model];
        NSLog(@"%@",stop);
        //NSSet* trips = stop.trips;
        //OBRTrip* trip = [trips anyObject];
        //NSSet* stops = [trip stops];
        //OBRStopNew* anyStop = [stops anyObject];
    }
    


}

-(void)addToText:(NSString*)newtext {
    NSString* newline = [NSString stringWithFormat:@"%@ %@",[TF nowHHmmss],newtext];
    NSString* combined = [NSString stringWithFormat:@"%@ \n%@",textField.text,newline];
    textField.text = combined;
    
    
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


//@property (nonatomic) float lat;
//@property (nonatomic) float lon;
//@property (nonatomic) int16_t number;
//@property (nonatomic, retain) NSString * streets;
//@property (nonatomic, retain) NSSet *trips;
//@end
//
//@interface OBRStopNew (CoreDataGeneratedAccessors)
//
//-(NSString*)description;
//
//- (void)addTripsObject:(OBRTrip *)value;
//- (void)removeTripsObject:(OBRTrip *)value;
//- (void)addTrips:(NSSet *)values;
//- (void)removeTrips:(NSSet *)values;
//

//-(NSString*)description {
//    NSSet* tripsSet = self.trips;
//    return [NSString stringWithFormat:@"STOPNew %d lat:%f lon:%f streets:%@ trips:%ld",self.number,self.lat,self.lon,self.streets,self.trips.count];
//}


//@property (nonatomic) int16_t day;
//@property (nonatomic) int16_t minOfDay;
//@property (nonatomic, retain) OBRStopNew *stop;
//@property (nonatomic, retain) OBRTrip *trip;
//
//-(NSString*)description {
//    return [NSString stringWithFormat:@"SCH day:%d min:%d trip;%@ stop %@",self.day,
//            self.minOfDay, self.trip, self.stop];
//}




//@property (nonatomic) int16_t tripNum;
//@property (nonatomic) int16_t earliestTS;
//@property (nonatomic) int16_t latestTS;
//@property (nonatomic, retain) NSString * direction;
//@property (nonatomic, retain) NSString * headsign;
//@property (nonatomic, retain) NSString * route;
//@property (nonatomic, retain) NSString * tripStr;
//
//-(NSString*)description;
//
//
//-(NSString*)description {
//    return [NSString stringWithFormat:@"OBRTrip %@ rt:%@ dir:%@ head:%@ early:%d late:%d",self.tripStr,
//            self.route, self.direction,self.headsign,self.earliestTS,self.latestTS];
//}


@end
