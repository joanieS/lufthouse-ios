//
//  TourImageViewController.m
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/10/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "TourImageViewController.h"
//For all possible routes
#import "WebContentViewController.h"
#import "StoriesViewController.h"
#import "MemoriesViewController.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>

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
@property (nonatomic) BOOL                      jsonDidFail;

@property (nonatomic) BOOL                      isDisplayingModal;

@property (nonatomic, strong) NSURL *urlContentForSegue;
@property (nonatomic, strong) NSString *htmlContentForSegue;
@property (nonatomic, strong) NSString *installationIDForSegue;
@property (nonatomic, strong) NSData *firstMemory;
@property (nonatomic, strong) NSData *secondMemory;
@property (nonatomic, strong) NSArray *memories;

//Received data from URL connection
@property (nonatomic, strong) NSMutableData *receivedData;

@property (nonatomic, strong) ACAccountStore *store;

@end

@implementation TourImageViewController

#pragma mark - UI Setup
-(void)viewWillAppear:(BOOL)animated
{
    //Everytime we get to this contoller, make sure the nav bar is white transparent
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3];
    self.navigationController.navigationBar.hidden = NO;
    //Set the text color to white
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
    
    //Reset the active minor so we can reload a beacon if we accidentally backed
    self.activeMinor = 0000;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


#pragma mark - BLE Beacon setup
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //If we're returning from suspension, go to root
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popToRootUnanimated) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    //If we're using beacons that don't broadcast distance, turn this on;
    self.testBool = true;
    self.jsonDidFail = false;
    self.isDisplayingModal = false;
  
    //Grab the image from ToursViewController and display it
    UIImage *imageFromUrl = [UIImage imageWithData:self.tourLandingImageData];
    self.tourLandingImage.image = imageFromUrl;
    
    self.store = [[ACAccountStore alloc] init];

    //Create a bluetooth manager to check if bluetooth is on
    CBCentralManager *bluetoothManager = [[CBCentralManager alloc] init];
    bluetoothManager = nil;
    
    //Establish a beacon manager
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    // Create a region to search for beacons
    self.beaconRegion = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID identifier:@"RegionIdentifier"];
    @try {
        [self.beaconManager startMonitoringForRegion:self.beaconRegion];
        [self.beaconManager startRangingBeaconsInRegion:self.beaconRegion];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        UIAlertView *bluetoothError = [[UIAlertView alloc] initWithTitle:@"Uh-oh!"
                                                             message:@"It looks like your bluetooth is either off or not cooperating. Please make sure it's on and try again!"
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
        [bluetoothError show];
        bluetoothError= nil;
    }
}

- (void)beaconManager:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region
{
    //If content hasn't been loaded
    if (self.beaconContent == nil && !self.jsonDidFail) {
        //Setup a URL request
        NSMutableURLRequest *getCustJSON = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://lufthouse-cms.herokuapp.com/customers/%@/installations/%@.json", self.customerID, self.tourID]]];
        [getCustJSON setHTTPMethod:@"GET"];
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:getCustJSON delegate:self];
        self.receivedData = [NSMutableData dataWithCapacity: 0];
        if (!connection) {
            //If the poop hit the oscillating aeroblade device
            self.receivedData = nil;
            // Inform the user that the connection failed.
            UIAlertView *serverError = [[UIAlertView alloc] initWithTitle:@"Uh-oh!"
                                                                  message:@"We're really sorry, but you're unable to connect to the server right now. Please try again soon!"
                                                                 delegate:self
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
            [serverError show];
            serverError = nil;

        } else { //We successfully got the data
            NSLog(@"Beacon content loaded");
        }
    } else {
        
        ESTBeacon *currentBeacon;       //Beacon to check against
        NSString *stringifiedMinor;     //String type of currentBeacon's minor value
        
        //Create array containing all relevant information about the matched beacon and its content
        NSMutableArray *beaconAssignment = [NSMutableArray arrayWithObjects:
                                            [NSMutableArray array],
                                            [NSMutableArray array],
                                            [NSMutableArray array],
                                            [NSMutableArray array],
                                            [NSMutableArray array],nil];

        NSInteger beaconIndex = -1; //Establish an impossible index
        //Current tour you'll be experiencing
        LufthouseTour *currentTour;
        //Grab the tour from the processed content
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
                [beaconAssignment[4] addObject:[currentTour getInstallationIDAtIndex:beaconIndex]];
                NSLog(@"Beacon matched! %@", [currentBeacon minor] );
            }
        }
        //If we found a matched beacon, then set it up for loading
        NSMutableArray *matchedBeacons = beaconAssignment[0];
        if ([matchedBeacons count] > 0) {
            self.contentBeaconArray = beaconAssignment;
        }
    }
    
    //Update the UI with our new information
    [self performSelectorOnMainThread:@selector(updateUI:) withObject:[beacons firstObject] waitUntilDone:YES];
}

-(void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    //Do nothing, just satisfy the delegate
}

#pragma mark - Content processing and generation

/* loadBeaconData
 * Retrieves JSON file from a source (currently local Lufthouse.JSON) and reads
 * the file into LufthouseCustomer and LufthouseTour objects.
 */
-(void)loadBeaconData: (NSDictionary*) json
{
    
    // If JSON didn't blow up
    if([json isKindOfClass:[NSDictionary class]]){
        // Create a dictionary out of the JSON
        NSDictionary *results = json;

        //Array to hold all beacons associated to a tour
        NSArray *beacons;

        //Hold name of the tour being processed
        NSString *tourName;
       
        /* Arrays to hold data before storing it into tours, customers, and ulimately
         * self.beaconContent
         */
        NSMutableArray *beaconIDs, *beaconValues, *beaconAudio, *beaconTypes, *installationIDs;
        beaconIDs = [NSMutableArray array];
        beaconValues = [NSMutableArray array];
        beaconTypes = [NSMutableArray array];
        beaconAudio = [NSMutableArray array];
        installationIDs = [NSMutableArray array];
        
        //Clear customers for all incoming new customers
        
        tourName = [results objectForKey:@"name"];
        beacons = [results objectForKey:@"beacons"];
        
        //For each beacon in the tour, get all needed data
        for (NSDictionary *beacon in beacons) {
            
            [beaconIDs addObject:[NSString stringWithFormat:@"%@", [beacon objectForKey:@"minor_id"]]];
            [beaconValues addObject:[beacon objectForKey:@"content"]];
            [beaconTypes addObject:[beacon objectForKey:@"content_type"]];
            [beaconAudio addObject:[beacon objectForKey:@"audio_url"]];
            [installationIDs addObject:[beacon objectForKey:@"id"]];
        
        }
        
        //Assign the beacon content for access elsewhere
        self.beaconContent = [[LufthouseTour alloc] initTourWithName:tourName beaconIDArray:beaconIDs beaconContentArray:beaconValues beaconContentTypeArray:beaconTypes beaconAudioArray:beaconAudio installationIDArray:installationIDs];
    }
}


#pragma mark - UI Generation and Execution
/* updateUI
 * Gets the closest beacon and displays content of the nearest beacon
 */
- (void)updateUI:(ESTBeacon *)checkBeacon
{
    //Get the array of nearby beacons and their content
    NSMutableArray *beaconArray = self.contentBeaconArray;
    //Variables for loading content in the UIWebView
    NSURL *beaconURL, *url;
    NSString *htmlString, *beaconHTML;
    NSMutableArray *photoArray;
    NSMutableArray *matchedBeacons = beaconArray[0];

    //For each beacon we ranged and matched
    for(int i = 0; i < [matchedBeacons count]; i++) {
        //If our proximity is immediate, the beacon isn't currently on display, and the beacon is the closest
        if((self.testBool || [checkBeacon proximity] == CLProximityNear || [checkBeacon proximity] == CLProximityImmediate) && !([checkBeacon.minor isEqual:self.activeMinor]) && [checkBeacon.minor isEqual:[[[beaconArray objectAtIndex:0] objectAtIndex:i] minor]]) {
            
            //If there is no audio to play, then send no audio
            if ([[[beaconArray objectAtIndex:3] objectAtIndex:i] isKindOfClass:[NSNull class]]) {
                url = nil;
            }
            else { //Otherwise, play that funky music, white boy
                if ([[[beaconArray objectAtIndex:3] objectAtIndex:i] rangeOfString:@"http"].location == NSNotFound) {
                    url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], [[beaconArray objectAtIndex:3] objectAtIndex:i]]];
                } else {
                    url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", [[beaconArray objectAtIndex:3] objectAtIndex:i]]];
                }
            }
            
            //Transition into the next song with an audio fade
            [self doVolumeFade:url];
            
            //If the content is an image, load it as an image
            if(!([beaconArray[2][i] rangeOfString:@"image"].location == NSNotFound)) {
                if ([beaconArray[1][i] rangeOfString:@"http"].location == NSNotFound && [beaconArray[1][i] rangeOfString:@"www."].location == NSNotFound) {
                    beaconURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], beaconArray[1][i]]];
                } else {
                    beaconURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", beaconArray[1][i]]];
                }
                //Center and stretch
                htmlString = @"<style media='screen' type='text/css'> IMG.displayed {display: block; margin-left: auto;    margin-right: auto; background-color: rgb(71,77,73) } </style><html><body><img class='displayed' src='%@' width='100%%'  align='middle'></body></html>";
                beaconHTML = [[NSString alloc] initWithFormat:htmlString, beaconURL];

                //Set content for segue depending on which method is to be used
                self.urlContentForSegue = nil;
                self.htmlContentForSegue = beaconHTML;
                
                //Set the active minor so we aren't reloading this as we're on it
                self.activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
                [self performSegueWithIdentifier:@"tourImageToWebContent" sender:self];
            }
            //If the content is an online video, embed it and play
            else if(!([beaconArray[2][i] rangeOfString:@"web-video"].location == NSNotFound)) {
                self.activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
                //There's a lot more gunk with this, so we put it in another function
                [self playVideoWithId:beaconArray[1][i]];
            }
            //If the content is a local video, load it in WebView
            else if(!([beaconArray[2][i] rangeOfString:@"local-video"].location == NSNotFound) && ![checkBeacon.minor isEqual:self.activeMinor]) {
                //Setup the URL
                beaconURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], beaconArray[1][i]]];
                //Set content for segue depending on which method is to be used
                self.urlContentForSegue = beaconURL;
                self.htmlContentForSegue = nil;
                
                //Set the active minor and go!
                self.activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
                [self performSegueWithIdentifier:@"tourImageToWebContent" sender:self];
            }
            //If the content is a web page, load it
            else if(!([beaconArray[2][i] rangeOfString:@"web"].location == NSNotFound)) {
                beaconURL = [NSURL URLWithString:beaconArray[1][i]];

                //Set content for segue depending on which method is to be used
                self.urlContentForSegue = beaconURL;
                self.htmlContentForSegue = nil;
                
                //GOGOGO
                self.activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
                [self performSegueWithIdentifier:@"tourImageToWebContent" sender:self];
            }
            //If the content is a photo gallery
            else if(!([beaconArray[2][i] rangeOfString:@"photo-gallery"].location == NSNotFound)) {
                //Set and get ready
                self.activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
                photoArray = [NSMutableArray array];
                
                //For each image in the gallery
                NSMutableArray *galleryImages = beaconArray[1][i];
                for(int j = 0; j < [galleryImages count]; j++) {
                    //If it's local, create a local URL
                    if ([beaconArray[1][i][j] rangeOfString:@"http"].location == NSNotFound && [beaconArray[1][i][j] rangeOfString:@"www."].location == NSNotFound) {
                        [photoArray addObject:[MWPhoto photoWithURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], beaconArray[1][i][j]]]]];
                        //If there is a caption, add it
//                        if (![beaconArray[1][i][j + 1] isEqualToString:@"nil"]) {
//                            [[photoArray lastObject] addCaption:beaconArray[1][i][j + 1]];
//                        }
                    }
                    //If it's online, create a web url
                    else {
                        [photoArray addObject:[MWPhoto photoWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", beaconArray[1][i][j]]]]];
                        //If there is a caption, add it
//                        if (![beaconArray[1][i][j + 1] isKindOfClass:[NSNull class]]) {
//                            [[photoArray lastObject] addCaption:beaconArray[1][i][j + 1]];
//                        }
                    }
                }
                //Create the photo gallery and display it
                [self createPhotoGallery:photoArray];
            }
            //Else if we're creating memories
            else if(!([beaconArray[2][i] rangeOfString:@"record-audio"].location == NSNotFound)) {
                self.activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
                self.installationIDForSegue = [[beaconArray objectAtIndex:4] objectAtIndex:i];
                //We go to a different place
                [self performSegueWithIdentifier:@"tourImageToStoriesPost" sender:self];
            }
            //If we're displaying memories
            else if(!([beaconArray[2][i] rangeOfString:@"memories"].location == NSNotFound)) {
                //Set and get ready
                self.activeMinor = [[[beaconArray objectAtIndex:0] objectAtIndex:i] minor];
                
                self.memories = beaconArray[1][i];
                self.firstMemory = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:beaconArray[1][i][0]]];
                self.secondMemory = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:beaconArray[1][i][1]]];
                
                [self performSegueWithIdentifier:@"tourImageToMemories" sender:self];
                
                
            }
            
            //Assert we are not on the landing image
            self.hasLanded = false;
        }
    }
    //If there are no beacons to display, go to the landing image
    if (checkBeacon == nil && self.hasLanded == false) {
        [self popToThisController];
        //Load the image, transition to no audio, set the landed option, reset the active beacon, and restrict rotation
        
        [self doVolumeFade:nil];
        self.hasLanded = true;
        self.activeMinor = 0000;
        self.shouldRotate = NO;
    }
}

/* doVolumeFade
 * Given the next song path, transition between the current and next songs with an audio fade
 */
-(void)doVolumeFade: (NSURL *)nextSong
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
            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:nextSong error:&error];
            self.audioPlayer.numberOfLoops = 0; //Don't loop
            
            if (self.audioPlayer == nil)
                NSLog(@"%@", [error description]);
            else
                [self.audioPlayer play];
        }
    }
}

/* playVideoWithId
 * Given a videoId from YouTube, play an embedded version of the video
 */
- (void)playVideoWithId:(NSString *)videoId {
    //Super long HTML for the player
    static NSString *youTubeVideoHTML = @"<html><head><style>body{margin:0px 0px 0px 0px;}</style></head> <body> <div id=\"player\"></div> <script> var tag = document.createElement('script'); tag.src = 'http://www.youtube.com/player_api'; var firstScriptTag = document.getElementsByTagName('script')[0]; firstScriptTag.parentNode.insertBefore(tag, firstScriptTag); var player; function onYouTubePlayerAPIReady() { player = new YT.Player('player', { width:'100%%', height:'100%%', videoId:'%@' }); } </script> </body> </html>";
    //Format the html for the player
    NSString *html = [NSString stringWithFormat:youTubeVideoHTML, videoId];
    
    //Prep the content and segue
    self.urlContentForSegue = nil;
    self.htmlContentForSegue = html;
    [self performSegueWithIdentifier:@"tourImageToWebContent" sender:self];
    
}
- (IBAction)lauchPhoto:(id)sender {
    UIImagePickerController * imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:NULL];// presentModalViewController:imagePicker animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.tourLandingImage.image = image;
    [self dismissViewControllerAnimated:NO completion:NULL];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        [self.store requestAccessToAccountsWithType:[self.store accountTypeWithAccountTypeIdentifier: ACAccountTypeIdentifierTwitter] options:nil completion:^(BOOL granted, NSError *error) {
            if (!granted) {
                NSLog(@"%@", error);
            }
        }];
        
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        NSString *shareMessage = @"Making memories with the Lufthouse app!";
        [tweetSheet setInitialText:[NSString stringWithFormat:@"%@",shareMessage]];
        if (image)
        {
                [tweetSheet addImage:image];
        }
        
        [self presentViewController:tweetSheet animated:YES completion:^(void){}];

    } else {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

-(ACAccount *)storeAccountWithAccessToken:(NSString *)token secret:(NSString *)secret
{
    // Each account has a credential, which is comprised of a verified token
    //  and secret
    
    ACAccountCredential *credential = [[ACAccountCredential alloc] initWithOAuthToken:token tokenSecret:secret];
    
    //  Obtain the Twitter account type from the store
    ACAccountType *twitterAcctType =
    [self.store accountTypeWithAccountTypeIdentifier:
     ACAccountTypeIdentifierTwitter];
    
    //  Create a new account of the intended type
    ACAccount *newAccount =
    [[ACAccount alloc] initWithAccountType:twitterAcctType];
    
    //  Attach the credential for this user
    newAccount.username = @"lufthousetest";
    newAccount.credential = credential;
    NSLog(@"HEY, LISTEN!");
    // Finally, ask the account store instance to save the account Note: that
    // the completion handler is not guaranteed to be executed on any thread,
    // so care should be taken if you wish to update the UI, etc.
    __block BOOL waitingOnCompletionHandler = YES;
    [_store saveAccount:newAccount withCompletionHandler:
     ^(BOOL success, NSError *error) {
         if (success) {
             // we've stored the account!
             NSLog(@"the account was saved!");
             waitingOnCompletionHandler = NO;
         }
         else {
             //something went wrong, check value of error
             NSLog(@"the account was NOT saved");
             
             // see the note below regarding errors...
             //  this is only for demonstration purposes
             if ([[error domain] isEqualToString:ACErrorDomain]) {
                  waitingOnCompletionHandler = NO;
                 // The following error codes and descriptions are found in ACError.h
                 switch ([error code]) {
                     case ACErrorAccountMissingRequiredProperty:
                         NSLog(@"Account wasn't saved because "
                               "it is missing a required property.");
                         break;
                     case ACErrorAccountAuthenticationFailed:
                         NSLog(@"Account wasn't saved because "
                               "authentication of the supplied "
                               "credential failed.");
                         break;
                     case ACErrorAccountTypeInvalid:
                         NSLog(@"Account wasn't saved because "
                               "the account type is invalid.");
                         break;
                     case ACErrorAccountAlreadyExists:
                         NSLog(@"Account wasn't added because "
                               "it already exists.");
                         break;
                     case ACErrorAccountNotFound:
                         NSLog(@"Account wasn't deleted because"
                               "it could not be found.");
                         break;
                     case ACErrorPermissionDenied:
                         NSLog(@"Permission Denied");
                         break;
                     case ACErrorUnknown:
                     default: // fall through for any unknown errors...
                         NSLog(@"An unknown error occurred.");
                         break;
                 }
             } else {
                 // handle other error domains and their associated response codes...
                 NSLog(@"%@", [error localizedDescription]);
             }
         }
     }];
    
    while (waitingOnCompletionHandler) {
        NSDate *futureTime = [NSDate dateWithTimeIntervalSinceNow:0.1];
        [[NSRunLoop currentRunLoop] runUntilDate:futureTime];
    }
    
    return newAccount;
}

#pragma mark - MSPhotoBrowser

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
    self.isDisplayingModal = true;
    [self presentViewController:browser animated:YES completion:nil];
//    [self.navigationController pushViewController:browser animated:NO];
}

/* MWPhotoBrowser delegate methods */
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.photos.count)
        return [self.photos objectAtIndex:index];
    return nil;
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
        
        // If JSON didn't blow up
        if([json isKindOfClass:[NSDictionary class]]){
            [self loadBeaconData: json];
        } else {
            NSLog(@"Error: JSON is corrupt");
            self.jsonDidFail = true;
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
        NSLog(@"Error: Recieved data is nil");
        //Tell the user something messed up
        UIAlertView *dataError = [[UIAlertView alloc] initWithTitle:@"Uh-oh!"
                                                            message:@"It looks like we can't grab the tour right now; please check your internet connection and try again later!"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [dataError show];
        dataError = nil;
    }
    
    
    //Release data for duty's sake
    connection = nil;
    self.receivedData = nil;
}


#pragma mark - Navigation

// Upon going back from this controller, we want to stop ranging for beacons
- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if (![parent isEqual:self.parentViewController]) {
        [self.beaconManager stopMonitoringForRegion:self.beaconRegion];
        [self.beaconManager stopRangingBeaconsInRegion:self.beaconRegion];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //If we're displaying web content, send the URL or HTML
    if ([[segue identifier] isEqualToString:@"tourImageToWebContent"]) {
        [self popToThisController];
        WebContentViewController *destination = [segue destinationViewController];
        destination.segueContentURL = self.urlContentForSegue;
        destination.segueContentHTML = self.htmlContentForSegue;
    }
    //Else if we're going to create memories, prep relevant info
    else if ([[segue identifier] isEqualToString:@"tourImageToStoriesPost"]) {
        [self popToThisController];
        StoriesViewController *destination = [segue destinationViewController];
        destination.custID = self.customerID;
        destination.tourID = self.tourID;
        destination.instID = self.installationIDForSegue;
    }
    //If we're going to display some memories
    else if ([[segue identifier] isEqualToString:@"tourImageToMemories"]) {
        [self popToThisController];
        MemoriesViewController *destination = [segue destinationViewController];
        destination.firstMemory = self.firstMemory;
        destination.secondMemory = self.secondMemory;
        destination.memories = self.memories;
    }

}

//Helper method to not overlap content views
-(void)popToThisController
{
    if (self.isDisplayingModal = true) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [self.navigationController popToViewController:self animated:NO];
}


@end
