//
//  OBRprefVC.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 4/22/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRprefVC.h"

@interface OBRprefVC ()
@property (weak, nonatomic) IBOutlet UITextField *departTF;
@property (weak, nonatomic) IBOutlet UITextField *arriveTF;
@property (weak, nonatomic) IBOutlet UITextField *maxWaitTF;
@property (weak, nonatomic) IBOutlet UITextField *maxWalkTF;
@property (weak, nonatomic) IBOutlet UISlider *departSlider;
@property (weak, nonatomic) IBOutlet UISlider *arriveSlider;
@property (weak, nonatomic) IBOutlet UISlider *maxWaitSlider;
@property (weak, nonatomic) IBOutlet UISlider *maxWalkSlider;
@property (weak, nonatomic) IBOutlet UISlider *daySlider;
@property (weak, nonatomic) IBOutlet UITextField *dayTF;
@property (nonatomic) NSArray* dayStringArray;
- (IBAction)departChanged:(id)sender;
- (IBAction)arrivalChanged:(id)sender;
- (IBAction)maxWaitChanged:(id)sender;
- (IBAction)maxWalkChanged:(id)sender;
- (IBAction)pressedReturn:(id)sender;
- (IBAction)dayChanged:(id)sender;

@end

@implementation OBRprefVC

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
}


-(void)viewWillAppear:(BOOL)animated  {
     OBRdataStore* db = [OBRdataStore defaultStore];
    
    //the new primative behavior will be to reset the preferences to the current
    //day and the current time every time that the view is opened.
    
    //get the current weekday
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate:[NSDate date]];
    long weekday = [comps weekday];
    
    //get the current hour and minute
    comps = [gregorian components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:[NSDate date]];
    long hour = [comps hour];
    long minute = [comps minute];
    
    //erase the settings
    db.arrivalDay = weekday;
    db.departureMin = (hour * 60 + minute)-120;
    db.arrivalMin = (hour *60 +minute)+240;
    db.maxWalkingDistance = 500;

    //confirm that the settings have taken and apply to the sliders
    int dm = (int)[db departureMin];
    int am = (int)[db arrivalMin];
    int maxWalk = [db maxWalkingDistance];
    int maxWait = [db maxWaitMin];
    int day = (int)[db arrivalDay];

    _departSlider.value = dm/60.0;
    _arriveSlider.value = am/60.0;
    _maxWaitSlider.value = maxWait;
    _maxWalkSlider.value = maxWalk;
    _daySlider.value = day-1;
    
    _arriveTF.text = [self timestring:am];
    _departTF.text = [self timestring:dm];
    _maxWaitTF.text = [NSString stringWithFormat:@"%d",maxWait];
    _maxWalkTF.text = [NSString stringWithFormat:@"%d",maxWalk];
    
    _dayStringArray = [[NSArray alloc] initWithObjects:@"Sunday",@"Monday",@"Tuesday",@"Wednesday",@"Thursday",@"Friday",@"Saturday",nil];

    //set the day
    NSString* daystr = _dayStringArray[day-1];
    _dayTF.text = daystr;
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[OBRdataStore defaultStore] clearCache];
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

-(NSString*)timestring:(int)min {
    int h = (int) min/60;
    int m = min - (60*h);
    if (h<12) {
        if (h==0) h=12;
        return [NSString stringWithFormat:@" %d:%02d AM",h,m];
    } else {
        if (h>=13) {
            h = h-12;
            if (h==12 & m==00) {
                h=11;
                m=59;
            }
        }
        return [NSString stringWithFormat:@" %d:%02d PM",h,m];
    }
}

- (IBAction)departChanged:(id)sender {
    int min = (int) 60* _departSlider.value;
    _departTF.text = [self timestring:min];
    if (_arriveSlider.value < _departSlider.value) {
        _arriveSlider.value = _departSlider.value;
        _arriveTF.text = [self timestring:min];
    }
}

- (IBAction)arrivalChanged:(id)sender {
    int min = (int) 60* _arriveSlider.value;
    _arriveTF.text = [self timestring:min];
    if (_departSlider.value > _arriveSlider.value) {
        _departSlider.value = _arriveSlider.value;
        _departTF.text = [self timestring:min];
    }
  
    
}

- (IBAction)maxWaitChanged:(id)sender {
    int v = _maxWaitSlider.value;
    _maxWaitTF.text = [NSString stringWithFormat:@"%d",v];
}

- (IBAction)maxWalkChanged:(id)sender {
    int mw = _maxWalkSlider.value;
    _maxWalkTF.text = [NSString stringWithFormat:@"%d",mw];
}

- (IBAction)pressedReturn:(id)sender {
    //set the preferences into the model
    OBRdataStore* model = [OBRdataStore defaultStore];
    model.departureMin = 60 * _departSlider.value;
    model.arrivalMin = 60 * _arriveSlider.value;
    model.maxWalkingDistance = _maxWalkSlider.value;
    model.maxWaitMin = _maxWaitSlider.value;
    model.arrivalDay = _daySlider.value + 1;
    
    //record the time that this time was set
    NSTimeInterval nowSec = [model currentTimeSec];
    model.solverTimeSetSec = nowSec;
    
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)dayChanged:(id)sender {
    int day = _daySlider.value;
    NSString* ds = [_dayStringArray objectAtIndex:day];
    _dayTF.text = ds;
}

@end
