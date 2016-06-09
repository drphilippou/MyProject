//
//  OBRsolving.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 9/30/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBRdatastore.h"

@interface OBRsolvingVC : UIViewController


@property (weak, nonatomic) IBOutlet UILabel *SolvingLabel;
@property (weak, nonatomic) IBOutlet UILabel *solutionsFoundLabel;
@property (weak, nonatomic) IBOutlet UILabel *routesConsideredLabel;
@property (weak, nonatomic) IBOutlet UILabel *shortestTravelTimeLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *viewButton;
@property (weak, nonatomic) IBOutlet UILabel *earliestArrivalLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityInd;

- (IBAction)pressedView:(id)sender;
- (IBAction)pressedDone:(id)sender;

@end
