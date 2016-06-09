//
//  Deck.h
//  
//
//  Created by Paul Philippou on 6/7/16.
//
//

#import <Foundation/Foundation.h>
#import "card.h"


@interface Deck : NSObject

-(void)addCard:(Card *)card atTop:(BOOL)atTop;
-(void)addCard:(Card *)card;

-(Card *)drawRandomCard;

@end
