//
//  IOSLabel.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/3/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "IOSLabel.h"


@implementation IOSLabel

-(id)init {
    return [super init];
}



-(id)initWithText:(NSArray *)a Color:(UIColor *)c Sizex:(int)x Sizey:(int)y{
    self = [super init];
    
    //determine the number of lines of text
    int nlt = (int) a.count;
    
    //compute the original size of the box needed
    int maxwidth = 0;
    int maxheight = 0;
    for (NSString* s in a) {
        CGSize size = [s sizeWithFont:[UIFont boldSystemFontOfSize:40]];
        if (size.width > maxwidth ) maxwidth = size.width;
        if (size.height > maxheight) maxheight = size.height;
    }
    int height = maxheight * nlt + 60;
    int width = maxwidth + 60;

    
    //get the image
    _image = [[IOSImage alloc] init];
    [_image imageWithFilename:@"roundedRect1.png"];
    
    //make the initial image large enough for text
    [_image reSize:CGPointMake(width,height)];
    
    //add the text
    CGPoint dp = CGPointMake(30, 30);
    for (NSString* s in a) {
        [_image drawText:s atPoint:dp FontSize:40];
        dp.y += maxheight;
    }
    
    //colorize the image
    [_image colorize:c];
    
    //resize down to the final size
    if (x>0 && y==-1) {
        float XYratio = (float) width/ (float) height;
        y = x/XYratio;
    } else if (x==-1 && y>0) {
        float YXratio = (float) height/(float) width;
        x = y/YXratio;
    }
    [_image reSize:CGPointMake(x,y)];
    
    
    return self;
}


-(id)initNoBorderWithText:(NSArray *)a Color:(UIColor *)c Sizex:(int)x Sizey:(int)y{
    self = [super init];
    
    //determine the number of lines of text
    int nlt = (int) a.count;
    
    //compute the original size of the box needed
    int maxwidth = 0;
    int maxheight = 0;
    for (NSString* s in a) {
        CGSize size = [s sizeWithFont:[UIFont boldSystemFontOfSize:40]];
        if (size.width > maxwidth ) maxwidth = size.width;
        if (size.height > maxheight) maxheight = size.height;
    }
    int height = maxheight * nlt + 60;
    int width = maxwidth + 60;

    
    //get the image
    _image = [[IOSImage alloc] init];
    [_image imageWithFilename:@"RoundedRectNoBorder.png"];
    
    //make the initial image large enough for text
    [_image reSize:CGPointMake(width,height)];
    
    //add the text
    CGPoint dp = CGPointMake(30, 30);
    for (NSString* s in a) {
        [_image drawText:s atPoint:dp FontSize:40];
        dp.y += maxheight;
    }
    
    //colorize the image
    [_image colorize:c];
    
    //resize down to the final size
    if (x>0 && y==-1) {
        float XYratio = (float) width/ (float) height;
        y = x/XYratio;
    } else if (x==-1 && y>0) {
        float YXratio = (float) height/(float) width;
        x = y/YXratio;
    }
    [_image reSize:CGPointMake(x,y)];
    
    
    return self;
}

@end
