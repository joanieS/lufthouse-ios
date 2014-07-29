//
//  ViewController.m
//  basic-museum-ios
//
//  Created by Adam Gleichsner on 6/5/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//


#import "WebContentViewController.h"


@interface WebContentViewController ()

//Responsible for finding and tracking beacons in range
@property (nonatomic, strong) ESTBeacon         *beacon;
@property (nonatomic, strong) ESTBeaconManager  *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion   *beaconRegion;

//Keeps track of beacon currently being displayed
@property (nonatomic, strong) NSNumber          *activeMinor;

//Contains all information regarding beacons in range and their content
@property (nonatomic, strong) NSMutableArray    *contentBeaconArray;


//Keeps track of whether or not an exhibit's content is currently being displayed
@property (nonatomic) BOOL                      hasLanded;

//Allows the orientation to rotate if YES
@property (nonatomic) BOOL                      shouldRotate;

//For testing on devices where you want to grab a beacon no matter the proximity
@property (nonatomic) BOOL                      testBool;
@property (nonatomic) BOOL                      isLocalVideo;

@end


/* LandingViewController
 * Currently the one and only view controller, this takes care of all beacon management
 * and content displaying.
 * @TODO Implement additional view controllers for customer, tours, modes, etc.
 */
@implementation WebContentViewController

#pragma mark - Setup Controller
/* viewDidLoad
 * On starting up, start beacon managing and ranging
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Add observer to tell when youtube player is playing
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateDidChange:)
                                                 name:@"MPAVControllerPlaybackStateChangedNotification"
                                               object:nil];
    [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:YES];
    
}

/* viewDidAppear
 * Upon exiting another view controller, reset landing to no rotation and no 
 * active minor
 */
-(void)viewDidAppear:(BOOL)animated
{
    self.shouldRotate = NO;
    self.activeMinor = 0000;
    self.webView.delegate = self;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - UI Generation and Execution

- (void)updateUI
{
    //Variables for loading content in the UIWebView
    NSURLRequest *beaconRequest = nil;

    //If we're loading HTML content, load it
    if (self.segueContentURL == nil && self.segueContentHTML != nil) {
        self.webView.scalesPageToFit = YES;
        [self.webView loadHTMLString:self.segueContentHTML baseURL:[[NSBundle mainBundle] resourceURL]];
    } else { //If we want to load URL content
        beaconRequest = [NSURLRequest requestWithURL:self.segueContentURL];
        [self.webView loadRequest:beaconRequest];
    }
}



/* playbackStateDidChange
 * When the player starts, allow rotation
 */
- (void)playbackStateDidChange:(NSNotification *)note
{
    self.shouldRotate = YES;
    NSLog(@"%@", note);
}

/* shouldAutorotate
 * Allows for rotation when specified or when we're not oriented the right way
 */
- (BOOL)shouldAutorotate {
    //If we aren't showing content but we are horizontal
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) &&  self.shouldRotate == NO) {
        return YES;
    }
    else
        return self.shouldRotate;
}

#pragma  mark - Web View management

//Manage any error by getting a user refresh
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    UIAlertView *webError = [[UIAlertView alloc] initWithTitle:@"Uh-oh!"
                                                       message:@"It appears something went wrong loading the content; please check your network connection and try again!"
                                                      delegate:self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
    [webError show];
    webError = nil;
}

/* webViewDidStartLoad
 * Provides loading animation
 */
- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.waiting startAnimating];
    self.waiting.hidden = FALSE;
}

/* webViewDidFinishLoad
 * Stops loading animation
 */
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.waiting stopAnimating];
    self.waiting.hidden = TRUE;
}



@end