//
//  IOSImage.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/3/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "palette.h"

@interface IOSImage : NSObject

@property(nonatomic,copy) NSString* name;
@property(nonatomic) UIImage* image;
@property (nonatomic) NSMutableDictionary* cache;


-(id)init;

-(void)clearCache;

-(UIImage*)imageWithFilename:(NSString*)f;
-(IOSImage*)IOSimageWithFilename:(NSString*)f;

-(UIImage*)imageWithFilename:(NSString*)f Size:(int)s;
-(UIImage*)imageWithFilename:(NSString*)f Color:(UIColor*)c Size:(int)s;
-(UIImage*)imageWithFilename:(NSString *)f Color:(UIColor*)c Size:(int)s Orientation:(float)o Cache:(BOOL)b;
-(UIImage*)imageWithFilename:(NSString *)f FillColor:(UIColor*)fc TextColor:(UIColor*)tc Size:(int)s At:(CGPoint)p Text:(NSString*) t FontSize:(int)fs Cache:(BOOL)b;


-(UIImage*)getImage;

//resizing funtions
-(UIImage*)reSize:(CGPoint)p ;

//text functions
-(UIImage*)drawText:(NSString*)t atPoint:(CGPoint)p FontSize:(int)fs;
-(UIImage*)drawText:(NSString*)t atPoint:(CGPoint)p FontSize:(int)fs TextColor:(UIColor*)c;

//color functions
-(UIImage*)colorize:(UIColor*)c;

//rotation functions
-(UIImage*)rotateOnDegrees:(float)degrees;

@end
