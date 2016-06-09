//
//  IOSImage.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/3/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "IOSImage.h"

@implementation IOSImage


-(id)init {
    self = [super init];
    return self;
}

-(void) clearCache {
    [_cache removeAllObjects];
}

-(UIImage*)imageWithFilename:(NSString*) filename {
    _image = [UIImage imageNamed:filename];
    _name = filename;
    return _image;
}

-(IOSImage*)IOSimageWithFilename:(NSString *)f {
    [self imageWithFilename:f];
    return self;
}


-(UIImage*)imageWithFilename:(NSString *)f Size:(int)s
{
    //check cache
    char cString[255];
    sprintf(cString, "filename %s %d",[f cStringUsingEncoding:NSUTF8StringEncoding],s);
    NSString* key = [[NSString alloc] initWithUTF8String:cString];
    UIImage* res = [[self cache] objectForKey:key];
    if (res != nil) {
        return res;
    }

    
    _image = [UIImage imageNamed:f];
    [self reSize:CGPointMake(s, s)];
    
    //store in cache
    if (_image != nil) {
        [_cache setObject:_image forKey:key];
    }
    
    return _image;
}


-(UIImage*)imageWithFilename:(NSString *)f Color:(UIColor *)c Size:(int)s
{
    //check cache
    char cString[255];
    CGFloat red = 0;
    CGFloat green = 0;
    CGFloat blue = 0;
    CGFloat alpha = 0;
    [c getRed:&red green:&green blue:&blue alpha:&alpha];
    sprintf(cString, "filename %s %2.2f %2.2f %2.2f %2.2f %d",[f cStringUsingEncoding:NSUTF8StringEncoding],red,green,blue,alpha,s);
    NSString* key = [[NSString alloc] initWithUTF8String:cString];
    UIImage* res = [[self cache] objectForKey:key];
    if (res != nil) {
        return res;
    }
    
    //build new image
    _image = [UIImage imageNamed:f];
    [self colorize:c ];
    [self reSize:CGPointMake(s, s)];
    
    //store in cache
    if (_image != nil) {
        [_cache setObject:_image forKey:key];
    }
    
    return _image;
}


-(UIImage*)imageWithFilename:(NSString *)f Color:(UIColor *)c Size:(int)s Orientation:(float)o Cache:(BOOL)useCache
{
    NSString* key;
    if (useCache) {
        key = [NSString stringWithFormat:@"%@ %@ %d %2.2f",f,c,s,o];
        UIImage* res = [[self cache] objectForKey:key];
        if (res != nil) {
            return res;
        }
    }
    
    _image = [UIImage imageNamed:f];
    [self colorize:c ];
    [self rotateOnDegrees:o];
    [self reSize:CGPointMake(s, s)];
    
    if (useCache && key!= nil && _image!= nil ) {
        [_cache setObject:_image forKey:key];
    }
    
    return _image;
}

-(UIImage*)imageWithFilename:(NSString *)f FillColor:(UIColor *)fc TextColor:(UIColor*)tc Size:(int)s At:(CGPoint)p Text:(NSString*) t FontSize:(int)fs Cache:(BOOL)usecache{
    
    NSString* key;
    if (usecache) {
        key = [NSString stringWithFormat:@"%@ %@ %@ %d %f %f %@ %d",f,fc,tc,s,p.x,p.y,t,fs];
        UIImage* res = [[self cache] objectForKey:key];
        if (res != nil) {
            return res;
        }
    }
    
    //build the image
    _image  = [UIImage imageNamed:f];
    [self drawText:t atPoint:p FontSize:fs TextColor:tc];
    [self colorize:fc];
    [self reSize:CGPointMake(s, s)];
    
    if (usecache && key!= nil && _image!= nil ) {
        [_cache setObject:_image forKey:key];
    }
    return _image;
    
}



-(UIImage*)getImage {
    return _image;
}

-(NSMutableDictionary*)cache {
    if (_cache == nil) {
        _cache = [[NSMutableDictionary alloc] init];
    }
    return _cache;
}

-(UIImage*)reSize:(CGPoint)p {
    CGSize scaleSize = CGSizeMake(p.x, p.y);
    UIGraphicsBeginImageContextWithOptions(scaleSize, NO, 0.0);
    [self.image drawInRect:CGRectMake(0, 0, scaleSize.width, scaleSize.height)];
    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.image = resizedImage;
    return self.image;
    
}

-(UIImage*)resizeImage:(UIImage*)input
                 xsize:(int)x
                 ysize:(int)y {
    CGSize scaleSize = CGSizeMake(x, y);
    UIGraphicsBeginImageContextWithOptions(scaleSize, NO, 0.0);
    [input drawInRect:CGRectMake(0, 0, scaleSize.width, scaleSize.height)];
    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}



-(UIImage*)drawText:(NSString*) text
             atPoint:(CGPoint)point
            FontSize:(int)fs {
    //set the font
    UIFont *font = [UIFont boldSystemFontOfSize:fs];
    
    UIGraphicsBeginImageContext(self.image.size);
    [self.image drawInRect:CGRectMake(0,0,self.image.size.width,self.image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, self.image.size.width, self.image.size.height);
    [BLACK set];
    [text drawInRect:CGRectIntegral(rect) withFont:font];
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return self.image;
}


-(UIImage*)drawText:(NSString*) text
             atPoint:(CGPoint)point
            FontSize:(int)fs
           TextColor:(UIColor*)c{
    //set the font
    UIFont *font = [UIFont boldSystemFontOfSize:fs];
    
    UIGraphicsBeginImageContext(self.image.size);
    [self.image drawInRect:CGRectMake(0,0,self.image.size.width,self.image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, self.image.size.width, self.image.size.height);
    [c set];
    [text drawInRect:CGRectIntegral(rect) withFont:font];
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return self.image;
}

- (UIImage *)rotateOnDegrees:(float)degrees {
    CGFloat rads = M_PI * degrees / 180;
    float newSide = MAX([_image size].width, [_image size].height);
    CGSize size =  CGSizeMake(newSide, newSide);
    UIGraphicsBeginImageContext(size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, newSide/2, newSide/2);
    CGContextRotateCTM(ctx, rads);
    CGContextDrawImage(UIGraphicsGetCurrentContext(),CGRectMake(-[_image size].width/2,-[_image size].height/2,size.width, size.height),_image.CGImage);
    _image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return self.image;
}

-(UIImage*)colorize:(UIColor*)c {
    
    // begin a new image context, to draw our colored image onto
    UIGraphicsBeginImageContext(self.image.size);
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // set the fill color
    [c setFill];
    
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, self.image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // set the blend mode to color burn, and the original image
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    CGRect rect = CGRectMake(0, 0, self.image.size.width, self.image.size.height);
    CGContextDrawImage(context, rect, self.image.CGImage);
    
    // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
    CGContextClipToMask(context, rect, self.image.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return self.image;
}

@end
