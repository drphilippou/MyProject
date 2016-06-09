//
//  PlayingCard.h
//  
//
//  Created by Paul Philippou on 6/7/16.
//
//

#import <Foundation/Foundation.h>
#import "card.h"

@interface PlayingCard : Card

@property (strong,nonatomic) NSString *suit;
@property (nonatomic) NSUInteger rank;

+ (NSArray *)validSuits;
+ (NSUInteger)maxRank;

@end
