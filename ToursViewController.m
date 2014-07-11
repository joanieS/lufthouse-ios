//
//  ToursViewController.m
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/10/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "ToursViewController.h"
#import "TourImageViewController.h"

@interface ToursViewController ()

@property (nonatomic, strong) NSData *contentForSegue;

@end

@implementation ToursViewController

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
    self.customerName.text = [self.tableContent objectAtIndex:0];
    self.toursTableView.dataSource = self;
    self.toursTableView.delegate = self;
    
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.navigationBar.hidden = NO;
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
    return [[self.tableContent objectAtIndex:1] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"tourCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = [[self.tableContent objectAtIndex:1] objectAtIndex:indexPath.row];
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d tours available", [self.tableContent[1][indexPath.row] count]];
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSError *error;
    NSData *imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: @"http://s3.roosterteeth.com/images/BoomLiger5092c30963da3.jpg"] options:0 error:&error];
    self.contentForSegue = imageData;
    
    [self performSegueWithIdentifier:@"tourToTourImage" sender:self];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"tourToTourImage"]) {
        TourImageViewController *destination = [segue destinationViewController];
        destination.tourLandingImageData = self.contentForSegue;
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
