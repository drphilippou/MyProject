//
//  OBRStopDescriptionTVCell.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 4/26/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OBRStopDescriptionTVCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *stopNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *arriveLabel;
@property (weak, nonatomic) IBOutlet UILabel *waitLabel;
@property (weak, nonatomic) IBOutlet UILabel *departLabel;
@property (weak, nonatomic) IBOutlet UILabel *streetLabel;

@end
