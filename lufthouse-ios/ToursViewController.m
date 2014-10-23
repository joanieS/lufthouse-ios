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


//Property for sending data to next segue
@property (nonatomic, strong) NSMutableArray *contentForSegue;

@end

@implementation ToursViewController

#pragma mark - Visual setup
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set this as the table delegate
    self.toursTableView.dataSource = self;
    self.toursTableView.delegate = self;
    
    //Turn off the lines on the table and initialize a background color
    self.toursTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.toursTableView.backgroundView = nil;
    self.toursTableView.backgroundView = [[UIView alloc] init];
    self.toursTableView.backgroundView.backgroundColor = [UIColor colorWithRed:204/255.0f green:221/255.0f blue:232/255.0f alpha:1.0f];
    self.toursTableView.opaque = NO;// backgroundView.opaque = NO;
    
    //Set the header text
    self.customerName.text = [self.tableContent objectAtIndex:0];
    self.numberOfTours.text = [NSString stringWithFormat:@"%lu tours available", (unsigned long)[[self.tableContent objectAtIndex:2] count]];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Whenever we come back to this view, make sure we have the correct style by setting it
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0/255.0f green:87/255.0f blue:141/255.0f alpha:1.0f]];
    [self.navigationController.navigationBar setTranslucent:NO];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationItem.hidesBackButton = NO;
    self.contentForSegue = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //One is the lonliest number that you ever do.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.tableContent objectAtIndex:1] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //cellIdentifier correlated to protoype cell
    static NSString *cellIdentifier = @"tourCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    //Clear out the background so we can put an image there instead
    cell.backgroundColor = [UIColor clearColor];
    cell.opaque = NO;
    cell.backgroundView = [[UIImageView alloc] initWithImage: [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath],@"lh_tour_cell.png"]]];
    cell.textLabel.textColor = [UIColor whiteColor];
//    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    //Print out the tour title
    cell.textLabel.text = [[self.tableContent objectAtIndex:1] objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL startBool = false;
    NSThread *animationThread = [[NSThread alloc] initWithTarget:self selector:@selector(toggleLoadingAnimation) object:nil];
    [animationThread start];

    while ([self.waiting isHidden]) {
        startBool = true;
    }
    
    if (startBool) {

        NSError *error;
        NSData *imageData;
        if ([[[self.tableContent objectAtIndex:3] objectAtIndex:indexPath.row] isKindOfClass:[NSNull class]]) {
            imageData = nil;
        } else {
            imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString:[[self.tableContent objectAtIndex:3] objectAtIndex: indexPath.row ]] options:0 error:&error];
        }
        //If we don't have an image, FULL STOP
        if (imageData == nil) {

            imageData = [[NSData alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/defaultTourImage.png"]];
            //            UIAlertView *imageError = [[UIAlertView alloc] initWithTitle:@"Uh-oh!"
//                                                                      message:@"Something has gone horribly wrong and this tour is unavailable; please try again later, though!"
//                                                                     delegate:self
//                                                            cancelButtonTitle:@"OK"
//                                                            otherButtonTitles:nil];
//            [imageError show];
//            imageError = nil;
            //[self toggleLoadingAnimation];
        } //else {
            //Otherwise, let's get the show on the rode!
        NSString *tourID = [[self.tableContent objectAtIndex:2] objectAtIndex: indexPath.row];
        NSString *customerID = [self.tableContent objectAtIndex:4];
        self.contentForSegue = [NSMutableArray arrayWithObjects: imageData, tourID, customerID, nil];
        [self toggleLoadingAnimation];
        [self performSegueWithIdentifier:@"tourToTourImage" sender:self];
        //}
    } else {
        NSLog(@"Error: Cannot start loading animation");
    }
}

-(BOOL)toggleLoadingAnimation
{
    if ([self.waiting isHidden]) {
        [self.waiting startAnimating];
        return true;
    } else {
        [self.waiting stopAnimating];
        return false;
    }
    return false;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"tourToTourImage"]) {
        //Get our destination
        TourImageViewController *destination = [segue destinationViewController];
        //Pass the image data and the IDs for later referencing
        destination.tourLandingImageData = [self.contentForSegue objectAtIndex:0];
        destination.tourID = [self.contentForSegue objectAtIndex:1];
        destination.customerID = [self.contentForSegue objectAtIndex:2];
    }
}

@end
