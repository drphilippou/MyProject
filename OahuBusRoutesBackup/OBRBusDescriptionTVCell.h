//
//  OBRBusDescriptionTVCell.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 4/26/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OBRBusDescriptionTVCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *busNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *arriveLabel;
@property (weak, nonatomic) IBOutlet UILabel *waitLabel;
@property (weak, nonatomic) IBOutlet UILabel *headsignLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *busImage;

@end
