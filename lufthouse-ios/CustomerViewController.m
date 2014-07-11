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


@end

@implementation CustomerViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.tableContent = [self loadNearbyTours];
    self.numberOfRows = [[self.tableContent objectAtIndex:0] count];
    
    self.customerTableView.dataSource = self;
    self.customerTableView.delegate = self;
//    [self.view addSubview:self.tableView];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (NSMutableArray *)loadNearbyTours
{
    // Create filepath to the local JSON
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Lufthouse" ofType:@"JSON"];
    // Begin reading JSON
    NSData *toursJSON = [[NSData alloc] initWithContentsOfFile:filePath];
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:toursJSON options:0 error:&error];
    
    // If JSON didn't blow up
    if([json isKindOfClass:[NSDictionary class]]){
        // Create a dictionary out of the JSON
        NSDictionary *results = json;
        
        // All key values for the three layers to the JSON
        NSArray *outterKeys = [results allKeys];
        NSArray *innerKeys;
        NSMutableArray *tours, *tourIDs, *tourLandingImages, *returnArray;

        returnArray = [NSMutableArray arrayWithObjects:[NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], nil];
        
        for (NSString *outterKey in outterKeys) {
            innerKeys = [[results objectForKey:outterKey] allKeys];
            tours = [NSMutableArray array];
            tourIDs = [NSMutableArray array];
            tourLandingImages = [NSMutableArray array];
            for (NSString *innerKey in innerKeys) {
                for (NSInteger i = 0; i < [[[results objectForKey:outterKey] objectForKey:innerKey] count]; i++) {
                    if ([innerKey isEqualToString: @"tours"]) {
                        [tours addObject:[[[results objectForKey:outterKey] objectForKey:innerKey] objectAtIndex:i]];
                    }
                    else if ([innerKey isEqualToString:@"tourID"]) {
                        [tourIDs addObject:[[[results objectForKey:outterKey] objectForKey:innerKey] objectAtIndex:i]];
                    }
                    else if ([innerKey isEqualToString:@"tourLandingImage"]) {
                        [tourLandingImages addObject:[[[results objectForKey:outterKey] objectForKey:innerKey] objectAtIndex:i]];
                    }
                    
                }
            }
            [[returnArray objectAtIndex:0] addObject:outterKey];
            [[returnArray objectAtIndex:1] addObject:tours];
            [[returnArray objectAtIndex:2] addObject:tourIDs];
            [[returnArray objectAtIndex:3] addObject:tourLandingImages];
        }
        return returnArray;
    }
    return nil;
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
    segueContent = [NSMutableArray arrayWithObjects:[[self.tableContent objectAtIndex:0] objectAtIndex:indexPath.row] , [[self.tableContent objectAtIndex:1] objectAtIndex:indexPath.row], [[self.tableContent objectAtIndex:2] objectAtIndex:indexPath.row], [[self.tableContent objectAtIndex:3] objectAtIndex:indexPath.row], nil];
    self.contentForSegue = segueContent;
    
    [self performSegueWithIdentifier:@"customerToTours" sender:self];
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
