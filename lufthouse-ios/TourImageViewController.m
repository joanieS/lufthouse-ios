//
//  TourImageViewController.m
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/10/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "TourImageViewController.h"
#import "WebContentViewController.h"
#import "StoriesViewController.h"

@interface TourImageViewController ()

//Responsible for finding and tracking beacons in range
@property (nonatomic, strong) ESTBeacon         *beacon;
@property (nonatomic, strong) ESTBeaconManager  *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion   *beaconRegion;

//Keeps track of beacon currently being displayed
@property (nonatomic, strong) NSNumber          *activeMinor;

//Contains all information regarding beacons in range and their content
@property (nonatomic, strong) NSMutableArray    *contentBeaconArray;

//Contains all information from the loaded JSON
@property (nonatomic, strong) LufthouseTour    *beaconContent;

//Audio player for playing mp3 files at exhibits
@property (nonatomic, strong) AVAudioPlayer     *audioPlayer;

//Keeps track of whether or not an exhibit's content is currently being displayed
@property (nonatomic) BOOL                      hasLanded;

//Allows the orientation to rotate if YES
@property (nonatomic) BOOL                      shouldRotate;

//For testing on devices where you want to grab a beacon no matter the proximity
@property (nonatomic) BOOL                      testBool;
@property (nonatomic) BOOL                      isLocalVideo;

@property (nonatomic, strong) NSURL *urlContentForSegue;
@property (nonatomic, strong) NSString *htmlContentForSegue;

@end

@implementation TourImageViewController

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
    self.testBool = true;
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = YES;
  
    UIImage *imageFromUrl = [UIImage imageWithData:self.tourLandingImageData];
    self.tourLandingImage.image = imageFromUrl;
    // Do any additional setup after loading the view.
    
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    // Create a region to search for beacons
    self.beaconRegion = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID identifier:@"RegionIdentifier"];
    @try {
        [self.beaconManager startMonitoringForRegion:self.beaconRegion];
        [self.beaconManager startRangingBeaconsInRegion:self.beaconRegion];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    self.activeMinor = 0000;
    @try {
        [self.beaconManager startMonitoringForRegion:self.beaconRegion];
        [self.beaconManager startRangingBeaconsInRegion:self.beaconRegion];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    }
}


- (void)beaconManager:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region
{
    //If content hasn't been loaded
    if (self.beaconContent == nil) {
        [self loadBeaconData];
        NSLog(@"Beacon content loaded");
    }
    
    ESTBeacon *currentBeacon;       //Beacon to check against
    NSString *stringifiedMinor;     //String type of currentBeacon's minor value
    //Create array containing all relevant information about the matched beacon and its content
    NSMutableArray *beaconAssignment = [NSMutableArray arrayWithObjects:[NSMutableArray array], [NSMutableArray array], [NSMutableArray array], [NSMutableArray array], nil];
    NSInteger beaconIndex = -1;
    LufthouseTour *currentTour;
    
    currentTour = self.beaconContent;
    //For each beacon in range
    for(int i = 0; i < [beacons count]; i++){
        currentBeacon = [beacons objectAtIndex:i];
        stringifiedMinor = [NSString stringWithFormat:@"%@", [currentBeacon minor]];
        
        beaconIndex = [currentTour findIndexOfID:stringifiedMinor];
        //If we can find the beacon, grab the data
        if (beaconIndex != -1) {
            [beaconAssignment[0] addObject:currentBeacon];
            [beaconAssignment[1] addObject:[currentTour getBeaconContentAtIndex:beaconIndex]];
            [beaconAssignment[2] addObject:[currentTour getBeaconContentTypeAtIndex:beaconIndex]];
            [beaconAssignment[3] addObject:[currentTour getBeaconAudioAtIndex:beaconIndex]];
            NSLog(@"Beacon matched! %@", [currentBeacon minor] );
        }
    }
    //If we found a matched beacon, then set it up for loading
    if ([beaconAssignment[0] count] > 0) {
        self.contentBeaconArray = beaconAssignment;
    }
    
    [self performSelectorOnMainThread:@selector(updateUI:) withObject:[beacons firstObject] waitUntilDone:YES];
}

/* loadBeaconData
 * Retrieves JSON file from a source (currently local Lufthouse.JSON) and reads
 * the file into LufthouseCustomer and LufthouseTour objects.
 */
-(void)loadBeaconData
{
    // Create filepath to the local JSON
    NSString *filePath = [[NSBundle mainBundle] pathForResource:self.tourID ofType:@"JSON"];
    // Begin reading JSON
    NSData *beaconJSON = [[NSData alloc] initWithContentsOfFile:filePath];
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:beaconJSON options:0 error:&error];
    
    // If JSON didn't blow up
    if([json isKindOfClass:[NSDictionary class]]){
        // Create a dictionary out of the JSON
        NSDictionary *results = json;
        // All key values for the three layers to the JSON
        NSArray *outterKeys = [results allKeys];
        NSArray *innerKeys;
        
        /* Arrays to hold data before storing it into tours, customers, and ulimately
         * self.beaconContent
         */
        NSMutableArray *beaconIDs, *beaconValues, *beaconAudio, *beaconTypes;
        
        //Temporary customer and tour
        
        LufthouseTour *tempTour;
        
        //Clear customers for all incoming new customers
        
        if ([outterKeys count] > 1) {
            [NSException raise:@"Invalid number of tours" format:@"Only one tour should exist"];
        }
        
        //For each customer in the JSON
        for (NSString *outterKey in outterKeys) {
            //Get the tour names
            innerKeys = [[results objectForKey:outterKey] allKeys];
            //Prep tours for storing new tours
            
            
            //Prep for data
            beaconIDs = [NSMutableArray array];
            beaconValues = [NSMutableArray array];
            beaconTypes = [NSMutableArray array];
            beaconAudio = [NSMutableArray array];
            
            //For each tour in a customer
            for (NSString *innerKey in innerKeys) {
                //Add the id, content, content type, and audio
                [beaconIDs addObject:innerKey];
                [beaconValues addObject:[[[results objectForKey:outterKey] objectForKey:innerKey] objectAtIndex: 0]];
                [beaconTypes addObject:[[[results objectForKey:outterKey] objectForKey:innerKey] objectAtIndex: 1]];
                [beaconAudio addObject: [[[results objectForKey:outterKey] objectForKey:innerKey] objectAtIndex: 2]];
            }
            
            //Create a tour out of all the data just loaded
            tempTour = [[LufthouseTour alloc] initTourWithName:outterKey beaconIDArray:beaconIDs beaconContentArray:beaconValues beaconContentTypeArray:beaconTypes beaconAudioArray:beaconAudio];
        }
        
        
        //Assign the beacon content for access elsewhere
        self.beaconContent = tempTour;
    }
}

/* updateUI
 * Gets the closest beacon and displays content of the nearest beacon
 */
- (void)updateUI:(ESTBeacon *)checkBeacon
{
    //Get the array of nearby beacons and their content
    NSMutableArray *beaconArray = self.contentBeaconArray;
    //Variables for loading content in the UIWebView
    NSURL *beaconURL;
    NSString *url, *htmlString, *beaconHTML;
    NSMutableArray *photoArray;
    
    //For each beacon we ranged and matched
    for(int i = 0; i < [beaconArray[0] count]; i++) {
        //If our proximity is immediate, the beacon isn't currently on display, and the beacon is the closest
        if((self.testBool || [checkBeacon proximity] == CLProximityNear || [checkBeacon proximity] == CLProximityImmediate) && !([checkBeacon.minor isEqual:self.activeMinor]) && [checkBeacon.minor isEqual:[[[beaconArray objectAtIndex:0] objectAtIndex:i] minor]]) {
            
            //If there is no audio to play, then send no audio
            if ([[[beaconArray objectAtIndex:3] objectAtIndex:i] isEqualToString:@"nil"]) {
                url = nil;
            }
            else { //Otherwise, play that funky music, white boy
                url = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], [[beaconArray objectAtIndex:3] objectAtIndex:i]];
            }
            
            //Transition into the next song with an audio fade
            [self doVolumeFade:url];
            
            
            
            //If the content is an image, load it as an image
            if(!([beaconArray[2][i] rangeOfString:@"image"].location == NSNotFound)) {
                while ([self.navigationController topViewController] != self) {
                    [self.navigationController popViewControllerAnimated:NO];
                }
                beaconURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], beaconArray[1][i]]];
                htmlString = @"<style media='screen' type='text/css'> IMG.displayed {display: block; margin-left: auto;    margin-right: auto; background-color: rgb(71,77,73) } </style><html><body><img class='displayed' src='%@' height='100%%'  align='middle'></body></html>";
                beaconHTML = [[NSString alloc] initWithFormat:htmlString,beaconURL];
                self.urlContentForSegue = nil;
                self.htmlContentForSegue = beaconHTML;
                self.activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
                [self performSegueWithIdentifier:@"tourImageToWebContent" sender:self];
//                self.webView.scalesPageToFit = YES;
//                [self.webView loadHTMLString:beaconHTML baseURL:nil];
            }
            //If the content is an online video, embed it and play
            else if(!([beaconArray[2][i] rangeOfString:@"web-video"].location == NSNotFound)) {
                self.activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
                [self playVideoWithId:beaconArray[1][i]];
            }
            //If the content is a local video, load it in WebView
            else if(!([beaconArray[2][i] rangeOfString:@"local-video"].location == NSNotFound) && !([checkBeacon.minor isEqual:self.activeMinor]) && !self.isLocalVideo) {
//                self.isLocalVideo = true;
//                NSNumber *activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
//                while ([self.navigationController topViewController] != self) {
//                    [self.navigationController popViewControllerAnimated:NO];
//                }
//                self.activeMinor = activeMinor;
                beaconURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], beaconArray[1][i]]];
                self.urlContentForSegue = beaconURL;
                self.htmlContentForSegue = nil;
                self.activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
                [self performSegueWithIdentifier:@"tourImageToWebContent" sender:self];
//                beaconRequest = [NSURLRequest requestWithURL:beaconURL];
//                [self.webView loadRequest:beaconRequest];
            }
            //If the content is a web page, load it
            else if(!([beaconArray[2][i] rangeOfString:@"web"].location == NSNotFound)) {
                beaconURL = [NSURL URLWithString:beaconArray[1][i]];
                self.urlContentForSegue = beaconURL;
                self.htmlContentForSegue = nil;
                self.activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
                [self performSegueWithIdentifier:@"tourImageToWebContent" sender:self];
//                beaconRequest = [NSURLRequest requestWithURL:beaconURL];
            }
            //If the content is a photo gallery
            else if(!([beaconArray[2][i] rangeOfString:@"photo-gallery"].location == NSNotFound)) {
                //Clear any residue
                self.activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
                photoArray = [NSMutableArray array];
                
                //For each image in the gallery
                for(int j = 0; j < [beaconArray[1][i] count]; j = j + 2) {
                    //If it's local, create a local URL
                    if ([beaconArray[1][i][j] rangeOfString:@"http"].location == NSNotFound && [beaconArray[1][i][j] rangeOfString:@"www."].location == NSNotFound) {
                        [photoArray addObject:[MWPhoto photoWithURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], beaconArray[1][i][j]]]]];
                        //If there is a caption, add it
                        if (![beaconArray[1][i][j + 1] isEqualToString:@"nil"]) {
                            [[photoArray lastObject] addCaption:beaconArray[1][i][j + 1]];
                        }
                    }
                    //If it's online, create a web url
                    else {
                        [photoArray addObject:[MWPhoto photoWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", beaconArray[1][i][j]]]]];
                        //If there is a caption, add it
                        if (![beaconArray[1][i][j + 1] isEqualToString:@"nil"]) {
                            [[photoArray lastObject] addCaption:beaconArray[1][i][j + 1]];
                        }
                    }
                }
                //Create the photo gallery and display it
                [self createPhotoGallery:photoArray];
            }
            else if(!([beaconArray[2][i] rangeOfString:@"create-story"].location == NSNotFound)) {
                [self performSegueWithIdentifier:@"tourImageToStoriesPost" sender:self];
            }
            
//            if([beaconArray[2][i] rangeOfString:@"local-video"].location == NSNotFound) {
//                self.isLocalVideo = false;
//            }
            
            //Assert we are not on the landing image and that we can rotate here
            self.hasLanded = false;
//            if ([beaconArray[2][i] rangeOfString:@"web-video"].location == NSNotFound && [beaconArray[2][i] rangeOfString:@"photo-gallery"].location == NSNotFound)
//                self.shouldRotate = YES;
        }
    }
    //If there are no beacons to display, go to the landing image
    if (checkBeacon == nil && self.hasLanded == false) {
        while ([self.navigationController topViewController] != self) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        //Load the image, transition to no audio, set the landed option, reset the active beacon, and restrict rotation
        
        [self doVolumeFade:nil];
        self.hasLanded = true;
        self.activeMinor = 0000;
        self.shouldRotate = NO;
        self.isLocalVideo = false;
    }
}

/* doVolumeFade
 * Given the next song path, transition between the current and next songs with an audio fade
 */
-(void)doVolumeFade: (NSString *)nextSong
{
    //If a song is playing, fade out
    if (self.audioPlayer.volume > 0.1 && [self.audioPlayer isPlaying]) {
        self.audioPlayer.volume = self.audioPlayer.volume - 0.05;
        [self performSelector:@selector(doVolumeFade:) withObject:nextSong afterDelay:0.05];
    } else {    //Once it's done fading, prep and play
        [self.audioPlayer stop];
        self.audioPlayer.currentTime = 0;
        [self.audioPlayer prepareToPlay];
        self.audioPlayer.volume = 1.0;
        
        
        NSError *error;
        if (nextSong != nil) {
            self.audioPlayer = nil;
            self.audioPlayer = [[AVAudioPlayer alloc] initWithData:[[NSData alloc] initWithContentsOfFile:nextSong] error:&error];
            self.audioPlayer.numberOfLoops = 0; //Don't loop
            
            if (self.audioPlayer == nil)
                NSLog(@"%@", [error description]);
            else
                [self.audioPlayer play];
        }
    }
}

-(void)popToThisController
{
        [self.navigationController popToViewController:self animated:NO];
}

/* playVideoWithId
 * Given a videoId from YouTube, play an embedded version of the video
 */
- (void)playVideoWithId:(NSString *)videoId {
    //Super long HTML for the player
    static NSString *youTubeVideoHTML = @"<html><head><style>body{margin:0px 0px 0px 0px;}</style></head> <body> <div id=\"player\"></div> <script> var tag = document.createElement('script'); tag.src = 'http://www.youtube.com/player_api'; var firstScriptTag = document.getElementsByTagName('script')[0]; firstScriptTag.parentNode.insertBefore(tag, firstScriptTag); var player; function onYouTubePlayerAPIReady() { player = new YT.Player('player', { width:'100%%', height:'100%%', videoId:'%@' }); } </script> </body> </html>";
    //Format the html for the player
    NSString *html = [NSString stringWithFormat:youTubeVideoHTML, videoId];
    self.urlContentForSegue = nil;
    self.htmlContentForSegue = html;
    [self performSegueWithIdentifier:@"tourImageToWebContent" sender:self];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)back:(id)sender {
    [self.beaconManager stopMonitoringForRegion:self.beaconRegion];
    [self.beaconManager stopRangingBeaconsInRegion:self.beaconRegion];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)createPhotoGallery: (NSMutableArray *) photoArray
{
    //Gallery accesses photos through self.photos, so add our array to that
    self.photos = photoArray;
    
    // Create browser (must be done each time photo browser is
    // displayed. Photo browser objects cannot be re-used)
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    browser.displayActionButton = NO; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = NO; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    
    // Optionally set the current visible photo before displaying
    [browser setCurrentPhotoIndex:0];
    
    
    // Present
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController pushViewController:browser animated:NO];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.photos.count)
        return [self.photos objectAtIndex:index];
    return nil;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"tourImageToWebContent"]) {
        [self popToThisController];
        WebContentViewController *destination = [segue destinationViewController];
        destination.segueContentURL = self.urlContentForSegue;
        destination.segueContentHTML = self.htmlContentForSegue;
    }
    else if ([[segue identifier] isEqualToString:@"tourImageToStoriesPost"]) {
        [self popToThisController];
//        [self.beaconManager stopMonitoringForRegion:self.beaconRegion];
//        [self.beaconManager stopRangingBeaconsInRegion:self.beaconRegion];
    }
    
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
