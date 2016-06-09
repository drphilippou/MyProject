//
//  OBRSearchTVC.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 11/8/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBRdataStore.h"
#import "OBRVehicle.h"
#import "OBRStopNew.h"
#import "POI.h"

@interface OBRSearchTVC : UITableViewController <UISearchBarDelegate,UISearchDisplayDelegate>

@property (nonatomic) NSMutableArray* searchList;
@property (nonatomic) NSMutableArray* filteredList;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end
