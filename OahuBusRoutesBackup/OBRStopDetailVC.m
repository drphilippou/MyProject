//
//  OBRStopDetailVC.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 1/20/15.
//  Copyright (c) 2015 Paul Philippou. All rights reserved.
//

#import "OBRStopDetailVC.h"

@interface OBRStopDetailVC () {
    OBRdataStore* DB;
    IOSImage* IOSI;
    NSArray* schedules;
}


@end



@implementation OBRStopDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //allocate helper functions
    DB = [OBRdataStore defaultStore];
    IOSI = [[IOSImage alloc] init];
    
    //get the selected stop from the datastore
    
    //get the schedule for this stop
    schedules = [DB getSchForStop:30];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -  table view Data Source

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    
////    //tvp = tableView;
////    
////    //the number of cells is one greater then the number of rows in the _route array
////    //the last one being the map.
////    if (indexPath.row >= _route.count) {
////        static NSString *CellIdentifier = @"RouteDetailMap";
////        OBRmapDetailTVCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
////        if (cell == nil) {
////            [tableView registerNib:[UINib nibWithNibName:@"OBRmapDetailTVCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
////            
////            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
////        }
////        _detailMap = cell.mapRef;
////        [_detailMap setDelegate:self];
////        return cell;
////    }
////    
////    OBRsolvedRouteRecord* r = _route[indexPath.row];
////    if ([r isStop]) {
////        
////        //if it is a stop description get a stop cell
////        static NSString *CellIdentifier = @"RouteDetailStop";
////        OBRStopDescriptionTVCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
////        if (cell == nil) {
////            [tableView registerNib:[UINib nibWithNibName:@"OBRStopDescriptionTVCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
////            
////            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
////        }
////        
////        return cell;
////    } else if ([r isRoute]) {
////        
////        //if it is a route then get the bus cell
////        static NSString* ci = @"RouteDetailBus";
////        OBRBusDescriptionTVCell* c = [tableView dequeueReusableCellWithIdentifier:ci];
////        if (c == nil) {
////            [tableView registerNib:[UINib nibWithNibName:@"OBRBusDescriptionTVCell" bundle:nil] forCellReuseIdentifier:ci];
////            
////            c = [tableView dequeueReusableCellWithIdentifier:ci];
////        }
////        
////        return c;
////    } else if ([r isWalk]) {
////        // This is a walking cell
////        static NSString* ci = @"routeDetailWalk";
////        OBRBusDescriptionTVCell* c = [tableView dequeueReusableCellWithIdentifier:ci];
////        if (c == nil) {
////            [tableView registerNib:[UINib nibWithNibName:@"OBRwalkTVCell" bundle:nil] forCellReuseIdentifier:ci];
////            
////            c = [tableView dequeueReusableCellWithIdentifier:ci];
////        }
////        
////        return c;
////        
////    } else {
////        // a timestamp is the default
////        NSString* ci = @"timeStampCell";
////        OBRTimestampTVCell* c = [tableView dequeueReusableCellWithIdentifier:ci];
////        if (c == nil) {
////            [tableView registerNib:[UINib nibWithNibName:@"OBRTimestampTVCell" bundle:nil] forCellReuseIdentifier:ci];
////            c = [tableView dequeueReusableCellWithIdentifier:ci];
////        }
////        return c;
////    }
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    // Return the number of rows in the section.
//    return 0;
//}
//
//
////- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
////{
////    OBRsolvedRouteRecord* r = _route[indexPath.row];
////    if (r.type == TIMESTAMP) return 20;
////    if (r.type == WALK) return 56;
////    if (r.type == STOP) return 60;
////    return 70;
////}


@end
