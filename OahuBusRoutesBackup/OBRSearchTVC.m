//
//  OBRSearchTVC.m
//  OahuBusRoutes
//
//  Created by Paul Philippou on 11/8/14.
//  Copyright (c) 2014 Paul Philippou. All rights reserved.
//

#import "OBRSearchTVC.h"

@interface OBRSearchTVC ()

@end

@implementation OBRSearchTVC


-(NSMutableArray*)searchList {
    if (_searchList == nil) {
        _searchList = [[NSMutableArray alloc] init];
        
        
        //add the vehicles
        for (OBRVehicle* v in [[OBRdataStore defaultStore] vehicles]) {
            
            //check the last update time
            
            //check the trip info
            
            NSString* s;
            if (v.number <2000) {
                if ([v.route isEqualToString:@"-1"]) {
                    s = [NSString stringWithFormat:@"Bus %d",v.number];
                } else {
                    s = [NSString stringWithFormat:@"Bus %d   Rt:%@ %@",v.number,v.route,v.direction];
                }
                [_searchList addObject:s];
            } else {
                NSLog(@"Search is skipping virtual bus %d",v.number);
            }
        }
        
        
        //add the stops
        for (OBRStopNew* stop in [[OBRdataStore defaultStore] stops]) {
            NSString* s = [NSString stringWithFormat:@"Stop %d %@",stop.number, stop.streets];
            [_searchList addObject:s];
        }
        
        //add the routes
        NSArray* routes = [[OBRdataStore defaultStore] routes];
        for (NSString* route in routes) {
            NSString* s = [NSString stringWithFormat:@"Route %@",route ];
            [_searchList addObject:s];
        }
        
        //add the POIs
        NSMutableArray* pois = [[OBRdataStore defaultStore] pois];
        for (POI*   poi in pois) {
            NSString* s = [NSString stringWithFormat:@"POI: %@",poi.name];
            [_searchList addObject:s];
        }
        
        //[_searchList addObject:@"Transit Station 1"];
        //[_searchList addObject:@"Transit Station 2"];
        //[_searchList addObject:@"Transit Station 3"];
    }
    return _searchList;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //initialize local varables
    _filteredList = [NSMutableArray arrayWithCapacity:[[self searchList] count]];
}

-(void)viewWillAppear:(BOOL)animated {
    [OBRdataStore defaultStore].searchSelection = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   
    
    // Check to see whether the normal table or search results table is being displayed and return the count from the appropriate array
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [[self filteredList] count];
    } else {
        return [[self searchList] count];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
  
    // Check to see whether the normal table or search results table is being displayed and set the Candy object from the appropriate array
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = [[self filteredList] objectAtIndex:indexPath.row];
        
    } else {
        cell.textLabel.text = [[self searchList] objectAtIndex:indexPath.row];
    }
    
    // Configure the cell
   
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    return cell;
}



#pragma mark - TableView Delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* selection;
    if(tableView == self.searchDisplayController.searchResultsTableView) {
        selection = [[self filteredList] objectAtIndex:indexPath.row];
    } else {
        selection = [[self searchList] objectAtIndex:indexPath.row];
    }
    [OBRdataStore defaultStore].searchSelection = selection;
    [[self navigationController] popViewControllerAnimated:YES];
}


#pragma mark - Segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"candyDetail"]) {
        UIViewController *candyDetailViewController = [segue destinationViewController];
        // In order to manipulate the destination view controller, another check on which table (search or normal) is displayed is needed
        if(sender == self.searchDisplayController.searchResultsTableView) {
            NSIndexPath *indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
            NSString *destinationTitle = [[self filteredList] objectAtIndex:[indexPath row]];
            [candyDetailViewController setTitle:destinationTitle];
        }
        else {
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            NSString *destinationTitle = [[self filteredList] objectAtIndex:[indexPath row]];
            [candyDetailViewController setTitle:destinationTitle];
        }
        
    }
}


#pragma mark Content Filtering
-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    [self.filteredList removeAllObjects];
    // Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@",searchText];
    NSArray *tempArray = [NSMutableArray arrayWithArray:[_searchList filteredArrayUsingPredicate:predicate]];
    
    if (![scope isEqualToString:@"All"]) {
        // Further filter the array with the scope
        NSPredicate *scopePredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@",scope];
        tempArray = [tempArray filteredArrayUsingPredicate:scopePredicate];
    }
    _filteredList = [NSMutableArray arrayWithArray:tempArray];
}


#pragma mark - UISearchDisplayController Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


@end
