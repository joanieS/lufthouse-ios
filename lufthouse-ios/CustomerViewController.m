//
//  ToursViewController.m
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/10/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "CustomerViewController.h"
#import "ToursViewController.h"     //Make content passable to next controller

@interface CustomerViewController ()

//Manager to grab current geographic location to query the server with
@property (nonatomic, strong) CLLocationManager *locationManager;

//Raw data retrieved from URL connection
@property (nonatomic, strong) NSMutableData *receivedData;

//Data retrieved from JSON to populate table
@property (nonatomic, strong) NSArray *tableContent;
@property (nonatomic) NSInteger numberOfRows;

//Select a customer to display tours in next controller
@property (nonatomic, strong) NSArray *contentForSegue;

@end

@implementation CustomerViewController

#pragma mark - Customer loading
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Hide the lines for UITableView
    self.customerTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //Whenever we get back from suspension or the background, get the nearby tours
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadCustomerFromURL) name:UIApplicationWillEnterForegroundNotification object:nil];
}


- (void)viewDidAppear:(BOOL)animated
{
    //Everytime we get back to customer selection, check for nearby tours
    [self loadCustomerFromURL];
}

/*  loadCustomerFromURL
 *  Queries server for JSON based on current location and sets into motion the
 *  table generation.
 */
- (void)loadCustomerFromURL
{
    //Set delegate to create the table
    self.customerTableView.dataSource = self;
    self.customerTableView.delegate = self;
    
    //Create a location manager and get the current lat/long
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager startUpdatingLocation];
    
    CLLocationDegrees latitude = self.locationManager.location.coordinate.latitude;
    CLLocationDegrees longitude = self.locationManager.location.coordinate.longitude;
    
    [self.locationManager stopUpdatingLocation];
    
    //Construct an acceptable slug for the server by combining lat/long, replacing . with _, and appending filetype
    NSString *latLong = [NSString stringWithFormat:@"%f/%f", latitude, longitude];
    latLong = [latLong stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    latLong = [NSString stringWithFormat:@"%@.json", latLong];
    
    //Format the URL request with location slug
    NSMutableURLRequest *getCustJSON = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://lufthouse-cms.herokuapp.com/location/%@", latLong]]];
    [getCustJSON setHTTPMethod:@"GET"];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:getCustJSON delegate:self];
    self.receivedData = [NSMutableData dataWithCapacity: 0];
  
    //  If the app fails, we need to stop and let someone know
    if (!connection) {
        // Release the receivedData object.
        self.receivedData = nil;
        UIAlertView *serverError = [[UIAlertView alloc] initWithTitle:@"Uh-oh!"
                                                              message:@"We're really sorry, but you're unable to connect to the server right now. Please try again soon!"
                                                             delegate:self
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
        [serverError show];
        serverError = nil;
    }
}


/*  loadNearbyTours
 *  Parses the array of data that should be a customer/tour JSON and returns
 *  a formatted array for displaying the customers
 */
- (NSMutableArray *)loadNearbyTours: (NSArray*) results
{
    //Array to hold data from JSON that shouldn't be able to change, namely the installation data
    NSArray *installations;
    //Arrays to hold pieces of data as we tranfer info from the results array to a more usable results array
    NSMutableArray *tours, *tourIDs, *tourLandingImages, *returnArray;
    //Temp strings to hold important identifiers and display information
    NSString *customerName, *customerID;
    //Temporary variable to hold an installation for active checking
    NSDictionary *installation;

    //Format the array for adding the chunks
    returnArray = [NSMutableArray arrayWithObjects:[NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], nil];
    
    //For each customer in the JSON results
    for (NSDictionary *customer in results) {
        
        //Grab the name and ID
        customerName = [customer objectForKey:@"name"];
        customerID = [NSString stringWithFormat:@"%@", [customer objectForKey:@"id"]];
        
        //Load up all of the installations
        installations = [customer objectForKey:@"installations"];
        
        //Clear the temps for new data
        tours = [NSMutableArray array];
        tourIDs = [NSMutableArray array];
        tourLandingImages = [NSMutableArray array];
        
        
        //For each tour a customer has
        for (int i = 0; i < [installations count]; i++) {
            //Select an installation, and if it's active, grab it's name, id, and landing image
            installation = [installations objectAtIndex:i];
            if ([installation objectForKey:@"active"]) {
                [tours addObject:[installation objectForKey:@"name"]];
                [tourIDs addObject:[installation objectForKey:@"id"]];
//                [tourLandingImages addObject:@"http://s3.roosterteeth.com/images/BoomLiger5092c30963da3.jpg"];
                [tourLandingImages addObject:[installation objectForKey:@"image_url"]];
            }
        }
        
        //If we have active tours, add them to the return array
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //We will always have only 1 section
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Cell identifier correlates to prototype in Storyboard
    static NSString *cellIdentifier = @"tourCell";
    UITableViewCell *cell = [tableView
                             dequeueReusableCellWithIdentifier:cellIdentifier];
    
    //Set a clear background so we can use an image instead
    cell.backgroundColor = [UIColor clearColor];
    cell.opaque = NO;
    
    //Sets backgroundView to display an image instead of a solid color
    cell.backgroundView = [[UIImageView alloc] initWithImage: [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath],@"lh_tab_w_arrow.png"]]];
    
    //Set the cell text to a blue color
    cell.textLabel.textColor = [UIColor colorWithRed:0/255.0f green: 87/255.0f blue: 141/255.0f alpha:1];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:0/255.0f green: 87/255.0f blue: 141/255.0f alpha:1];
    
    //Print out relevant information regarting customer and his tours
    cell.textLabel.text = [[self.tableContent objectAtIndex:0] objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu tours available", (unsigned long)[self.tableContent[1][indexPath.row] count]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Setup array for transferrable content
    NSMutableArray *segueContent = [NSMutableArray array];
    
    //Copy content specific to the customer selected into array to be sent to the next controller
    segueContent = [NSMutableArray arrayWithObjects:
                    [[self.tableContent objectAtIndex:0] objectAtIndex:indexPath.row] ,
                    [[self.tableContent objectAtIndex:1] objectAtIndex:indexPath.row],
                    [[self.tableContent objectAtIndex:2] objectAtIndex:indexPath.row],
                    [[self.tableContent objectAtIndex:3] objectAtIndex:indexPath.row],
                    [[self.tableContent objectAtIndex:4] objectAtIndex:indexPath.row],
                    nil];
    
    self.contentForSegue = segueContent;
    //PASS DAT
    [self performSegueWithIdentifier:@"customerToTours" sender:self];
}

#pragma mark - URL Connection

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //Reset data each redirect
    [self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //Add new data to recievedData
    if (data != nil) {
        [self.receivedData appendData:data];
    }
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    //In case of failure, reset everything and tell the user that connection is impossible
    connection = nil;
    self.receivedData = nil;
    
    // Let the user know things be messed up
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    UIAlertView *connectionError = [[UIAlertView alloc] initWithTitle:@"Uh-oh!"
                                                          message:@"It looks like you either don't have an internet connection or something has gone terribly wrong; please make sure you're connected to your network provider and try again!"
                                                         delegate:self
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
    [connectionError show];
    connectionError = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //Once we get all of the data, we need to make sure we want it
    NSError *error = nil;
    if (self.receivedData != nil) {
        
        id json = [NSJSONSerialization JSONObjectWithData:self.receivedData options:0 error:&error];
        
        // If JSON didn't blow up and if it's an array (because we're expecting one)
        if([json isKindOfClass:[NSArray class]]){
            //Grab the results into an array and parse it
            NSArray *results = json;
            self.tableContent = [self loadNearbyTours:results];
            
            //Reset the table with the appropriate info and dimensions
            self.numberOfRows = [[self.tableContent objectAtIndex:0] count];
            [self.customerTableView reloadData];
        } else {
            NSLog(@"Error: JSON is corrupt");
            //Tell the user something messed up
            UIAlertView *jsonError = [[UIAlertView alloc] initWithTitle:@"Uh-oh!"
                                                                      message:@"It looks like the tour is currently unavailable; please try again later!"
                                                                     delegate:self
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
            [jsonError show];
            jsonError = nil;
        }
    } else {
        UIAlertView *jsonError = [[UIAlertView alloc] initWithTitle:@"Uh-oh!"
                                                            message:@"It looks like something has gone wrong! Please try again later."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [jsonError show];
        jsonError = nil;
    }

    //Once we're done, reset everything to free up space
    connection = nil;
    self.receivedData = nil;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //If it's the right segue and we aren't be hijacked, then GOGOGOGOGO
    if ([[segue identifier] isEqualToString:@"customerToTours"]) {
        ToursViewController *destination = [segue destinationViewController];
        destination.tableContent = self.contentForSegue;
    }
}


@end
