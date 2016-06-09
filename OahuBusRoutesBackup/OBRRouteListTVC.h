//
//  OBRRouteListTVC.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 4/12/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBRdataStore.h"
#import "MyCustomCellTableViewCell.h"

@interface OBRRouteListTVC : UITableViewController

- (IBAction)pressedQuit:(id)sender;
- (IBAction)routeInfoPressed:(id)sender;
- (IBAction)guidancePressed:(id)sender;
@end
