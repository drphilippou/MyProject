//
//  card.m
//  
//
//  Created by Paul Philippou on 6/7/16.
//
//

#import "card.h"

@implementation Card
//private declarations here





-(int)match:(NSArray *)otherCards
{
    int score = 0;
    
    for (Card* card in otherCards) {
        if ([card.contents isEqualToString:self.contents]) {
            score = 1;
        }
    }
    
    return score;
}

@end
