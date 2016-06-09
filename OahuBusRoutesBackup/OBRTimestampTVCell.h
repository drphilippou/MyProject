//
//  OBRTimestampTVCell.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 5/7/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OBRTimestampTVCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *actualTime;

@end
