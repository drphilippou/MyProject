//
//  POI.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 11/14/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class OBRNode;

@interface POI : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) OBRNode *node;

@end
