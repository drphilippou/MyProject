//
//  MyCustomCellTableViewCell.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 4/19/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBRdatastore.h"
#import "OBRprefVC.h"
#import "OBRRouteDetailListVC.h"

@interface MyCustomCellTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *departureLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (weak, nonatomic) IBOutlet UIImageView *timeline1;
@property (weak, nonatomic) IBOutlet UIImageView *timeline2;
@property (weak, nonatomic) IBOutlet UIImageView *timeline3;
@property (weak, nonatomic) IBOutlet UIImageView *timeline4;
@property (weak, nonatomic) IBOutlet UIImageView *timeline5;
@property (weak, nonatomic) IBOutlet UIImageView *timeline6;
@property (weak, nonatomic) IBOutlet UIImageView *timeline7;
@property (weak, nonatomic) IBOutlet UIImageView *timeline8;
@property (weak, nonatomic) IBOutlet UIImageView *timeline9;

@property (weak, nonatomic) IBOutlet UILabel *tl1;
@property (weak, nonatomic) IBOutlet UILabel *tl2;
@property (weak, nonatomic) IBOutlet UILabel *tl3;
@property (weak, nonatomic) IBOutlet UILabel *tl4;
@property (weak, nonatomic) IBOutlet UILabel *tl5;
@property (weak, nonatomic) IBOutlet UILabel *tl6;
@property (weak, nonatomic) IBOutlet UILabel *tl7;
@property (weak, nonatomic) IBOutlet UILabel *tl8;
@property (weak, nonatomic) IBOutlet UILabel *tl9;

@property (nonatomic) long row;
@property (nonatomic) OBRsolvedRouteRecord* route;

@end
