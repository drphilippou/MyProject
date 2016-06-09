//
//  OBRsolvingVC.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 9/30/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRsolvingVC.h"

@interface OBRsolvingVC ()
{
    long numSolutionsFound;
    long numRoutesConsidered;
    int earliestArrival;
    int shortestTravelTime;
    BOOL viewHasAppeared;
    NSTimer* updateLabelTimer;
    NSTimer* checkForSolvingCompleteTimer;
    OBRdataStore* db;
    
    
}




@end

@implementation OBRsolvingVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //point to the datastore
    db = [OBRdataStore defaultStore];
    
    //reset the solution variables
    numSolutionsFound=0;
    numRoutesConsidered=0;
    earliestArrival = -1;
    shortestTravelTime = -1;
    viewHasAppeared = false;
    [self updateLabels];
    
    //set the display for solving mode
    [_activityInd startAnimating];
    [_activityInd setHidden:FALSE];
    [_SolvingLabel setHidden:FALSE];
    [_earliestArrivalLabel setHidden:FALSE];
    [_shortestTravelTimeLabel setHidden:FALSE];
    [_solutionsFoundLabel setHidden:FALSE];
    [_routesConsideredLabel setHidden:FALSE];
    //[_viewButton setTitle:@"View Routes" forState:UIControlStateNormal];
    //[_doneButton setTitle:@"Stop Searching" forState:UIControlStateNormal];
}


-(void)viewWillAppear:(BOOL)animated {
    viewHasAppeared = false;
    
    if (updateLabelTimer==nil) {
        updateLabelTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateLabels) userInfo:nil repeats:YES];
    }
    
     //restart the update label timer if still processing
    if (updateLabelTimer == nil) {
        updateLabelTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateLabels) userInfo:nil repeats:YES];
    }
    
    
}

-(void)viewDidAppear:(BOOL)animated {
    viewHasAppeared = true;
    
    BOOL solving = [OBRdataStore defaultStore].solving;
    BOOL reversing = [OBRdataStore defaultStore].routeListViewed;
    if (!solving && reversing) {
        [self.navigationController popViewControllerAnimated:NO];
    }

}

-(void)viewDidDisappear:(BOOL)animated {
    [updateLabelTimer invalidate];
    updateLabelTimer = nil;
}


-(void)updateLabels {
    //update the data from the datastore
    NSString* SolvingLabelText = db.solvingLabelText;
    numSolutionsFound = db.solvingNumRoutesFound;
    numRoutesConsidered = db.solvingNumRoutesConsidered;
    earliestArrival = db.solvingEarliestArrival;
    shortestTravelTime = db.solvingShortestTripDuration;

    
    [_solutionsFoundLabel setText:[NSString stringWithFormat:@"%ld Solutions Found",numSolutionsFound]];
    [_routesConsideredLabel setText:[NSString stringWithFormat:@"%ld Routes Considered",numRoutesConsidered]];
    [_SolvingLabel setText:SolvingLabelText];
    
    //update the earliest Arrival Field
    if (earliestArrival>0) {
        int hour = floor(earliestArrival/60);
        int min = floor((earliestArrival-(hour*60)));
        if (hour <12) {
            [_earliestArrivalLabel setText:[NSString stringWithFormat:@"Earliest Arrival: %dhr %dmin AM",hour,min]];
        } else {
            [_earliestArrivalLabel setText:[NSString stringWithFormat:@"Earliest Arrival: %dhr %dmin PM",hour-12,min]];
        }
    } else {
        [_earliestArrivalLabel setText:@"Earliest Arrival: --:--"];
        
    }
    
    //update the shortest duration field
    if (shortestTravelTime>0) {
        int hour = floor(shortestTravelTime/60);
        int min = floor((shortestTravelTime-(hour*60)));
        [_shortestTravelTimeLabel setText:[NSString stringWithFormat:@"Shortest Travel Time: %dhr %dmin",hour,min]];
    } else {
        [_shortestTravelTimeLabel setText:@"Shortest Travel Time: --:--"];
    }
    
    
    //try to push a new controller
    if (viewHasAppeared) {
        if (numSolutionsFound>0 && db.forwardToList) {
            db.forwardToList = false;
            [self performSegueWithIdentifier:@"SolvingToRouteList" sender:self];
        }
        
        //check if we have solutions
        if (numSolutionsFound>0) {
            _viewButton.enabled = true;
        } else {
            _viewButton.enabled = false;
        }
        
        //check if we are done
        if (!db.solving) {
            [self doneSolving];
            [updateLabelTimer invalidate];
            updateLabelTimer = nil;
        }
    }
}


-(void)doneSolving{
    [_activityInd stopAnimating];
    [_activityInd setHidden:true];
    //[_doneButton setTitle:@"Back" forState:UIControlStateNormal];
    
}







- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [db clearCache];
}



- (IBAction)pressedDone:(id)sender {
    
    //stop the processing if still running
    db.interupt = true;
    
    //jump back to the previous screen once solving has quit
    NSLog(@"Trying to dismiss VC interupt=%d solving=%d",db.interupt,db.solving);
    if (!db.solving) {
        [self dismissViewControllerAnimated:YES completion:nil];
        [checkForSolvingCompleteTimer invalidate];
        checkForSolvingCompleteTimer = nil;
    } else {
        checkForSolvingCompleteTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                                        target:self
                                                                      selector:@selector(checkForSolvingComplete)
                                                                      userInfo:nil
                                                                       repeats:TRUE];
    }
}


-(void)checkForSolvingComplete
{
    NSLog(@"Trying to dismiss VC interupt=%d solving=%d",db.interupt,db.solving);
    if (!db.solving) {
        [checkForSolvingCompleteTimer invalidate];
        checkForSolvingCompleteTimer = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(IBAction)pressedView:(id) sender {
    [self performSegueWithIdentifier:@"SolvingToRouteList" sender:self];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
