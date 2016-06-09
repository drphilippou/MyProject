//
//  OBRRouteOverlay.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 10/19/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRRouteOverlay.h"

@interface OBRRouteOverlay () {
    
}

@end


@implementation OBRRouteOverlay


-(NSMutableArray*)overlayInfo {
    if (_overlayInfo == nil) {
        _overlayInfo = [[NSMutableArray alloc]init];
    }
    return _overlayInfo;
}


-(NSDictionary*) routeColorDict {
    if (_routeColorDict == nil) {
        _routeColorDict = @{@"C":PURPLE,
                            @"A":CRANBERRY,
                            @"PH6":GREEN,
                            @"1":LIME,
                            @"1L":CYAN,
                            @"4":CRANBERRY,
                            @"5":BLUE,
                            @"6":REDISH_ORANGE,
                            @"7":YELLOW,
                            @"8":BLUISH_PURPLE,
                            @"9":BLUISH_GREEN,
                            @"10":ORANGE,
                            @"13":EMERALD,
                            @"11":REDISH_PURPLE,
                            @"14":MAGENTA,
                            @"15":CYAN,
                            @"16":PURPLE,
                            @"17":MAGENTA,
                            @"18":EMERALD,
                            @"19":LIME,
                            @"101":ORANGE,
                            @"102":RED,
                            @"20":BURNT_ORANGE,
                            @"22":BLUE,
                            @"23":RED,
                            @"234":LIME,
                            @"235":TOPAZ,
                            @"24":CRANBERRY,
                            @"31":BLUE,
                            @"32":RED,
                            @"40":YELLOW,
                            @"41":MAGENTA,
                            @"42":BLUE,
                            @"43":BLUISH_GREEN,
                            @"44":EMERALD,
                            @"401":RED,
                            @"402":BLUE,
                            @"403":GREEN,
                            @"411":CYAN,
                            @"412":GREEN,
                            @"413":RED,
                            @"414":BLUE,
                            @"415":AMBER,
                            @"432":TOPAZ,
                            @"501":LIME,
                            @"503":RED,
                            @"504":MAGENTA,
                            @"52":GREEN,
                            @"53":TOPAZ,
                            @"54":BLUISH_GREEN,
                            @"55":PURPLE,
                            @"56": BLUE,
                            @"57":MAGENTA,
                            @"57A":ORANGE,
                            @"62":YELLOW,
                            @"70":GREEN,
                            @"71":RED,
                            @"72":RED,
                            @"73":REDISH_PURPLE,
                            @"74":ORANGE,
                            @"76":BLUE,
                            @"77":CYAN,
                            @"80":PURPLE,
                            @"80A":AMBER,
                            @"80B":EMERALD,
                            @"81":GREEN,
                            @"82":ORANGE,
                            @"83":CYAN,
                            @"84":BLUE,
                            @"84A":ORANGE,
                            @"85":RED,
                            @"90":GREEN,
                            @"91":CYAN,
                            @"96":AMBER };
        
        
    }
    return _routeColorDict;
}


-(void)addSingleRoute:(NSString*)routestr onMap:(MKMapView *)mapView{
        NSArray* points = [[OBRdataStore defaultStore] getPointsForRouteStr:routestr];
        [self GenerateLines:points onMap:mapView];
}



- (MKOverlayView *)viewForOverlay:(id<MKOverlay>)overlay {
    
    OBRoverlayInfo* oi = [self getInfoForOverlay:overlay];
    NSLog(@"color= %@",oi.color.description);
    
    if([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolylineView *lineView = [[MKPolylineView alloc] initWithPolyline:overlay];
        lineView.lineWidth = 12;
        lineView.strokeColor = oi.color;
        lineView.fillColor = oi.color;
        return lineView;
    }
    return nil;
}

-(OBRoverlayInfo*)getInfoForOverlay:(id<MKOverlay>)routeLine {
    for (OBRoverlayInfo* oi in [self overlayInfo]) {
        if (oi.overlay == routeLine) {
            return oi;
        }
    }
    return nil;
}

- (void)GenerateLines:(NSArray*)routePoints onMap:(MKMapView *)mapView{
    
    //determine number of segments
    int minSeg = 999;
    int maxSeg = -999;
    for (OBRRoutePoints* rp in routePoints) {
        if (rp.segment>maxSeg) maxSeg = rp.segment;
        if (rp.segment<minSeg) minSeg = rp.segment;
    }
    
    for (int seg=minSeg ; seg<=maxSeg; seg++) {
        
        //determine number of points in this segment
        int numPoints=0;
        NSString* routestr;
        for (OBRRoutePoints* rp in routePoints) {
            if (rp.segment == seg) {
                routestr = rp.routestr;
                numPoints++;
            }
        }
        
        //get the color of the routestr
        UIColor* color = [[self routeColorDict] objectForKey:routestr];
        
        CLLocationCoordinate2D* pointArr = malloc(sizeof(CLLocationCoordinate2D)*numPoints);
        
        int Indx = 0;
        for  (OBRRoutePoints* rp in routePoints) {
            if (rp.segment == seg) {
                pointArr[Indx++] = CLLocationCoordinate2DMake(rp.lat, rp.lon);
            }
        }
        
        if (Indx>0) {
            MKPolyline* routeLine = [MKPolyline polylineWithCoordinates:pointArr count:numPoints ];
            
            OBRoverlayInfo* oi = [[OBRoverlayInfo alloc] init];
            oi.overlay = routeLine;
            oi.color = color;
            oi.routestr = routestr;
            [[self overlayInfo] addObject:oi];
            
            [mapView addOverlay:routeLine];
        }
    }
}


@end
