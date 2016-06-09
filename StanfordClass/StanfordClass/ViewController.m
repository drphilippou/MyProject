//
//  ViewController.m
//  StanfordClass
//
//  Created by Paul Philippou on 6/7/16.
//  Copyright (c) 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *flipsLabel;
@property (nonatomic) int flipCount;
@property (strong, nonatomic) Deck *deck;

@end

@implementation ViewController


-(void)setFlipCount:(int)flipCount {
    _flipCount = flipCount;
    self.flipsLabel.text = [NSString stringWithFormat:@"Flips:%d",self.flipCount];
    NSLog(@"flipCount changed to %d",self.flipCount);
}

- (IBAction)touchCardButton:(UIButton *)sender {
    
    if ([sender.currentTitle length]) {
        [sender setBackgroundImage:[UIImage imageNamed:@"cardback"]
                          forState:UIControlStateNormal];
        [sender setTitle:@"" forState:UIControlStateNormal];
    } else {
        [sender setBackgroundImage:[UIImage imageNamed:@"cardfront"]
                          forState:UIControlStateNormal];
        [sender setTitle:@"A♣︎" forState:UIControlStateNormal];
    }
    self.flipCount++;
}










- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
