//
//  PlayingCard.m
//  
//
//  Created by Paul Philippou on 6/7/16.
//
//

#import "PlayingCard.h"

@implementation PlayingCard

@synthesize suit = _suit;

+(NSArray *)validSuits {
    return @[@"H",@"D",@"S",@"C"];
}

-(NSString *)contents {
    
    NSArray *rankStrings = @ [ @"?",@"A",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"J",@"Q",@"K"];
    return [rankStrings[self.rank] stringByAppendingString:self.suit];
}

-(void)setSuit:(NSString *)suit {
    if ([[PlayingCard validSuits] containsObject:suit]) {
        _suit = suit;
    }
}

-(NSString *)suit {
    return _suit ? _suit : @"?";
}

+(NSArray *) rankStrings {
    return @[ @"?",@"A",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"J",@"Q",@"K"];
}

+(NSUInteger)maxRank { return [[self rankStrings] count]-1;}

-(void)setRank:(NSUInteger)rank {
    if (rank <= [PlayingCard maxRank]) {
        _rank = rank;
    }
}
@end
