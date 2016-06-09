//
//  MyCustomCellTableViewCell.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 4/19/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "MyCustomCellTableViewCell.h"

@implementation MyCustomCellTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
