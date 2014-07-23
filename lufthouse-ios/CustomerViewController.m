//
//  ToursViewController.m
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/10/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "CustomerViewController.h"
#import "ToursViewController.h"

@interface CustomerViewController ()

@property (nonatomic, strong) NSArray *tableContent;
@property (nonatomic, strong) NSArray *contentForSegue;
@property (nonatomic) NSInteger numberOfRows;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) NSMutableData *receivedData;

@end

@implementation CustomerViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.numberOfRows = [[self.tableContent objectAtIndex:0] count];
    
    self.customerTableView.dataSource = self;
    self.customerTableView.delegate = self;
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    [self.locationManager startUpdatingLocation];
    CLLocationDegrees latitude = self.locationManager.location.coordinate.latitude;
    CLLocationDegrees longitude = self.locationManager.location.coordinate.longitude;
    [self.locationManager stopUpdatingLocation];
    
    NSString *latLong = [NSString stringWithFormat:@"%f/%f", latitude, longitude];
    latLong = [latLong stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    latLong = [NSString stringWithFormat:@"%@.json", latLong];
//    NSString *latLong = [NSString stringWithFormat:@"123/456.json"];
    
    NSMutableURLRequest *getCustJSON = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://lufthouse-placeholder.herokuapp.com/location/%@", latLong]]];
    [getCustJSON setHTTPMethod:@"GET"];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:getCustJSON delegate:self];
    self.receivedData = [NSMutableData dataWithCapacity: 0];
    if (!connection) {
        // Release the receivedData object.
        self.receivedData = nil;
        
        // Inform the user that the connection failed.
    }
    
    
    
    
//    [self.view addSubview:self.tableView];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}



- (NSMutableArray *)loadNearbyTours: (NSArray*) results
{
    
        // All key values for the three layers to the JSON
    NSArray *outterKeys;// = [results allKeys];
    NSArray *installations;
    NSMutableArray *tours, *tourIDs, *tourLandingImages, *returnArray;
    NSString *customerName, *customerID;
    NSDictionary *installation;

    returnArray = [NSMutableArray arrayWithObjects:[NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], nil];
    
    for (NSDictionary *customer in results) {
        
        customerName = [customer objectForKey:@"name"];
        customerID = [NSString stringWithFormat:@"%@", [customer objectForKey:@"id"]];
        installations = [customer objectForKey:@"installations"];
        
        tours = [NSMutableArray array];
        tourIDs = [NSMutableArray array];
        tourLandingImages = [NSMutableArray array];
        
        
        for (int i = 0; i < [installations count]; i++) {
            installation = [installations objectAtIndex:i];
            if ([installation objectForKey:@"active"]) {
                [tours addObject:[installation objectForKey:@"name"]];
                [tourIDs addObject:[installation objectForKey:@"id"]];
                [tourLandingImages addObject:@"http://s3.roosterteeth.com/images/BoomLiger5092c30963da3.jpg"];//[[installations objectAtIndex:i] objectForKey:@"landingImage"]];
            }
        }
        
        if ([tours count] > 0) {
            [[returnArray objectAtIndex:0] addObject:customerName];
            [[returnArray objectAtIndex:1] addObject:tours];
            [[returnArray objectAtIndex:2] addObject:tourIDs];
            [[returnArray objectAtIndex:3] addObject:tourLandingImages];
            [[returnArray objectAtIndex:4] addObject:customerID];
        }
    }
    
    return returnArray;
}

    

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"tourCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = [[self.tableContent objectAtIndex:0] objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu tours available", (unsigned long)[self.tableContent[1][indexPath.row] count]];

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *segueContent = [NSMutableArray array];
    segueContent = [NSMutableArray arrayWithObjects:
                    [[self.tableContent objectAtIndex:0] objectAtIndex:indexPath.row] ,
                    [[self.tableContent objectAtIndex:1] objectAtIndex:indexPath.row],
                    [[self.tableContent objectAtIndex:2] objectAtIndex:indexPath.row],
                    [[self.tableContent objectAtIndex:3] objectAtIndex:indexPath.row],
                    [[self.tableContent objectAtIndex:4] objectAtIndex:indexPath.row],
                    nil];
    self.contentForSegue = segueContent;
    
    [self performSegueWithIdentifier:@"customerToTours" sender:self];
}

#pragma mark - URL Connection

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse object.
    
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    
    // receivedData is an instance variable declared elsewhere.
    [self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // Release the connection and the data object
    // by setting the properties (declared elsewhere)
    // to nil.  Note that a real-world app usually
    // requires the delegate to manage more than one
    // connection at a time, so these lines would
    // typically be replaced by code to iterate through
    // whatever data structures you are using.
    connection = nil;
    self.receivedData = nil;
    
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // do something with the data
    // receivedData is declared as a property elsewhere
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:self.receivedData options:0 error:&error];
    
    // If JSON didn't blow up
    if([json isKindOfClass:[NSArray class]]){
        // Create a dictionary out of the JSON
        NSArray *results = json;
        self.tableContent = [self loadNearbyTours:results];
        self.numberOfRows = [[self.tableContent objectAtIndex:0] count];
        [self.customerTableView reloadData];
    } else {
        NSLog(@"Error: JSON is corrupt");
    }

    
    // Release the connection and the data object
    // by setting the properties (declared elsewhere)
    // to nil.  Note that a real-world app usually
    // requires the delegate to manage more than one
    // connection at a time, so these lines would
    // typically be replaced by code to iterate through
    // whatever data structures you are using.
    connection = nil;
    self.receivedData = nil;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"customerToTours"]) {
        ToursViewController *destination = [segue destinationViewController];
        destination.tableContent = self.contentForSegue;
    }
}


@end
