//
//  OBRNode.h
//  OahuBusRoutes
//
//  Created by Paul Philippou on 11/14/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class POI;

@interface OBRNode : NSManagedObject

@property (nonatomic) float lat;
@property (nonatomic) float lon;
@property (nonatomic, retain) NSString * street;
@property (nonatomic) int16_t streetNum;
@property (nonatomic, retain) NSSet *pois;
@end

@interface OBRNode (CoreDataGeneratedAccessors)

- (void)addPoisObject:(POI *)value;
- (void)removePoisObject:(POI *)value;
- (void)addPois:(NSSet *)values;
- (void)removePois:(NSSet *)values;

@end
