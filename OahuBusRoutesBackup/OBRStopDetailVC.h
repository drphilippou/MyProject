//
//  OBRStopDetailVC.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 1/20/15.
//  Copyright (c) 2015 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "OBRdataStore.h"
#import "OBRMapViewAnnotation.h"


@interface OBRStopDetailVC : UIViewController <UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UIImageView *busStopImage;


@end
