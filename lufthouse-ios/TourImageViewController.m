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

#import "CSTBeaconManager.h"
#import "CSTMovingAverage.h"

@interface TourImageViewController ()

//Keeps track of beacon currently being displayed
@property (nonatomic, strong) NSNumber          *activeMinor;

//Contains all information regarding beacons in range and their content
@property (nonatomic, strong) NSMutableArray    *contentBeaconArray;
@property (nonatomic, strong) NSDictionary      *displayBeaconContent;

@property (nonatomic, strong) NSMutableDictionary *averages;
@property (nonatomic, strong) NSDate *lastChanged;

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
@property (nonatomic, strong) NSString *tweetText;

//Received data from URL connection
@property (nonatomic, strong) NSMutableData *receivedData;

//Used to grab twitter accounts and confirm privacy access
@property (nonatomic, strong) ACAccountStore *store;

@end

@implementation TourImageViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]) != nil) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.averages = [NSMutableDictionary dictionary];
}

#pragma mark - UI Setup
-(void)viewWillAppear:(BOOL)animated
{
//    if (self.beaconManager != nil) {
//        @try {
//            [self.beaconManager stopMonitoringForRegion:self.beaconRegion];
//            [self.beaconManager stopRangingBeaconsInRegion:self.beaconRegion];
//        }
//        @catch (NSException *exception) {
//            NSLog(@"%@\n%@", exception.description, @"Beacon Manager not initialized");
//        }
//        @finally {
            //Everytime we get to this contoller, make sure the nav bar is white transparent
            [self setNavBarToTransparentAndVisible];
            //Reset the active minor so we can reload a beacon if we accidentally backed
            self.activeMinor = 0000;
//        }
//    }
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
//    if (self.beaconManager != nil) {
//        @try {
//            [self.beaconManager stopMonitoringForRegion:self.beaconRegion];
//            [self.beaconManager stopRangingBeaconsInRegion:self.beaconRegion];
//        }
//        @catch (NSException *exception) {
//            NSLog(@"%@\n%@", exception.description, @"Beacon Manager not initialized");
//        }
//    }
    [super viewWillDisappear:animated];
}

-(void)setNavBarToTransparentAndVisible
{
    //Set nav bar to white transparent
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3];
    self.navigationController.navigationBar.hidden = NO;
    //Set the text color to white
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
}

-(void)viewDidAppear:(BOOL)animated {
    [self addBeaconManagerListeners];
}

- (void)addBeaconManagerListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(beaconManagerDidRangeBeacons:)
                                                 name:@"CSTBeaconManagerDidRangeBeacons" object:nil];
}

- (void)removeBeaconManagerListeners {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) setStatusVariablesToFalse
{
    //If we're using beacons that don't broadcast distance, turn this on;
    self.testBool = false;
    self.jsonDidFail = false;
    self.isDisplayingModal = false;
}

#pragma mark - BLE Beacon setup
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setStatusVariablesToFalse];
    
    //Grab the image from ToursViewController and display it
    UIImage *imageFromUrl = [UIImage imageWithData:self.tourLandingImageData];
    self.tourLandingImage.image = imageFromUrl;
    self.store = [[ACAccountStore alloc] init];
    
    //Create a beacon manager to check if bluetooth is on
    CSTBeaconManager *beaconManager = [CSTBeaconManager sharedManager];
    beaconManager = nil;
}

- (void)createErrorPopupWithMessage:(NSString *)titleMessage bodyMessage:(NSString *) bodyMessage
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:titleMessage
                                                             message:bodyMessage
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
    [alertView show];
}

- (void)beaconManagerDidRangeBeacons:(NSNotification *)notification
{
    NSArray *beacons = notification.userInfo[@"beacons"];
    ESTBeacon *currentBeacon;       //Beacon to check against
    NSString *stringifiedMinor;     //String type of currentBeacon's minor value
    NSMutableDictionary *beaconDictionary;
    NSMutableArray *beaconAssignment = [NSMutableArray array];
    
    [beacons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ESTBeacon *beacon = obj;
        NSLog(@"beacon: %@ - %@ - %ld", beacon.minor, beacon.distance, beacon.rssi);
    }];
    
    //If content hasn't been loaded
    if (self.beaconContent == nil && !self.jsonDidFail) {
        [self getJSONUpdate];
    }
    if (self.beaconContent != nil && !self.jsonDidFail){
        
        beaconDictionary = [[NSMutableDictionary alloc] init];
        
        //Create array containing all relevant information about the matched beacon and its content
        NSInteger beaconIndex = -1; //Establish an impossible index
        //Current tour you'll be experiencing
        LufthouseTour *currentTour = self.beaconContent;
        NSMutableArray *eligibleBeacons = [NSMutableArray array];
        [beacons enumerateObjectsUsingBlock:^(ESTBeacon *beacon, NSUInteger idx, BOOL *stop) {
            if ([currentTour findIndexOfID:[NSString stringWithFormat:@"%@", [beacon minor]]] > -1) {
                if ([beacon.distance integerValue] == -1) {
                    return;
                }
                
                CSTMovingAverage *avg = self.averages[beacon.minor];
                if (!avg) {
                    avg = [[CSTMovingAverage alloc] initWithSize:5];
                    self.averages[beacon.minor] = avg;
                }
                [avg addSample:[beacon.distance integerValue]];
                beacon.distance = @([avg movingAverage]);
                [eligibleBeacons addObject:beacon];
            }
        }];
        beacons = [eligibleBeacons sortedArrayUsingSelector:@selector(distance)];
        //For each beacon in range
        for(int i = (int)beacons.count-1; i >= 0; i--){
            currentBeacon = [beacons objectAtIndex:i];
            NSLog(@"saw beacon: %@", currentBeacon.minor);
            stringifiedMinor = [NSString stringWithFormat:@"%@", [currentBeacon minor]];
            beaconIndex = [currentTour findIndexOfID:stringifiedMinor];
            //If we can find the beacon, grab the data
            if (beaconIndex != -1) {
                [beaconDictionary setValue:currentBeacon forKey:@"beacon"];
                [beaconDictionary setValue:[currentTour getBeaconContentAtIndex:beaconIndex] forKey:@"content"];
                [beaconDictionary setValue:[currentTour getBeaconContentTypeAtIndex:beaconIndex] forKey:@"content_type"];
                [beaconDictionary setValue:[currentTour getBeaconAudioAtIndex:beaconIndex] forKey:@"beacon_audio"];
                [beaconDictionary setValue:[currentTour getInstallationIDAtIndex:beaconIndex] forKey:@"installation_id"];
                // TODO - Add tweet_text here and in LufthouseTour
                [beaconAssignment addObject:currentBeacon];
                
                NSLog(@"Beacon matched! %@", [currentBeacon minor] );
                
                break;
            }
        }
        //If we found a matched beacon, then set it up for loading
//        NSMutableArray *matchedBeacons = beaconAssignment[0];
//        if ([matchedBeacons count] > 0) {
            self.contentBeaconArray = beaconAssignment;
            self.displayBeaconContent = beaconDictionary;
        NSLog(@"loaded content: %@", beaconDictionary);
//        }
    }
    
    //Update the UI with our new information
    [self performSelectorOnMainThread:@selector(updateUI:) withObject:currentBeacon waitUntilDone:YES];
}

-(void) getJSONUpdate
{
    if (self.receivedData != nil) {
        NSLog(@"we are already talking to server, don't ask again");
        return ;
    }
    
    
    //Setup a URL request
    NSMutableURLRequest *getCustJSON = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://lufthouse-cms.herokuapp.com/customers/%@/installations/%@.json", self.customerID, self.tourID]]];
    [getCustJSON setHTTPMethod:@"GET"];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:getCustJSON delegate:self];
    self.receivedData = [NSMutableData dataWithCapacity: 0];
    
    if (!connection) {
        //If the poop hit the oscillating aeroblade device
        self.receivedData = nil;
        // Inform the user that the connection failed.
        [self createErrorPopupWithMessage:@"Uh-oh!"
                              bodyMessage:@"We're really sorry, but you're unable to connect to the server right now. Please try again soon!"];
    } else {
        NSLog(@"Beacon content loaded");
    }
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
            id isActive = [beacon objectForKey:@"active"];
            BOOL active = [isActive boolValue];
            if (active) {
                [beaconIDs addObject:[NSString stringWithFormat:@"%@", [beacon objectForKey:@"minor_id"]]];
                [beaconValues addObject:[beacon objectForKey:@"content"]];
                [beaconTypes addObject:[beacon objectForKey:@"content_type"]];
                [beaconAudio addObject:[beacon objectForKey:@"audio_url"]];
                [installationIDs addObject:[beacon objectForKey:@"id"]];
            }
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
    //Variables for loading content in the UIWebView
    NSURL *beaconURL, *audioUrl;
    NSString *const htmlString = @"<style media='screen' type='text/css'> IMG.displayed {display: block; margin-left: auto;    margin-right: auto; background-color: rgb(71,77,73) } </style><html><body><img class='displayed' src='%@' width='100%%'  align='middle'></body></html>";
    NSString *beaconHTML;
    NSMutableArray *photoArray, *galleryImages;
    NSDictionary *beaconDictionary = self.displayBeaconContent;

    //If our proximity is immediate, the beacon isn't currently on display, and the beacon is the closest
    if([self beaconShouldBeDisplayed:checkBeacon]) {
//        self.lastChanged = [NSDate date];
        
//        if (self.navigationController.topViewController != self) {
//            [self.navigationController popToViewController:self animated:YES];
//            [self performSelectorOnMainThread:@selector(updateUI:) withObject:checkBeacon waitUntilDone:YES];
//            return;
//        }
        
        //If there is no audio to play, then send no audio
        if ([[beaconDictionary objectForKey:@"audio_url"] isKindOfClass:[NSNull class]]) {
            audioUrl = nil;
        }
        else { //Otherwise, play that funky music, white boy
            if ([self contentIsLocal:[beaconDictionary objectForKey:@"audio_url"]]) {
                audioUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], [beaconDictionary objectForKey:@"audio_url"]]];
            } else {
                audioUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@", [beaconDictionary objectForKey:@"beacon_audio"]]];
            }
        }
        
        //Transition into the next song with an audio fade
        [self doVolumeFade:audioUrl];
        
        self.activeMinor = [[beaconDictionary objectForKey:@"beacon"] minor];
        //Associate an integer value to each content type
        switch ([self getIntegerForContentType:[beaconDictionary valueForKey:@"content_type"]]) {
            case 0: //image
                if ([self contentIsLocal:[beaconDictionary objectForKey:@"content"]]) {
                    beaconURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], [beaconDictionary objectForKey:@"content"]]];
                } else {
                    beaconURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", [beaconDictionary objectForKey:@"content"]]];
                }

                beaconHTML = [[NSString alloc] initWithFormat:htmlString, beaconURL];
                
                //Set content for segue depending on which method is to be used
                self.urlContentForSegue = nil;
                self.htmlContentForSegue = beaconHTML;
                
                //Set the active minor so we aren't reloading this as we're on it

                [self performSegueWithIdentifier:@"tourImageToWebContent" sender:self];
                break;
                
            case 1: //web-video
                //There's a lot more gunk with this, so we put it in another function
                
                [self playVideoWithId:[beaconDictionary objectForKey:@"content"]];
                break;
                
            case 2: //local-video
                beaconURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], [beaconDictionary objectForKey:@"content"]]];
                //Set content for segue depending on which method is to be used
                self.urlContentForSegue = beaconURL;
                self.htmlContentForSegue = nil;
                
                [self performSegueWithIdentifier:@"tourImageToWebContent" sender:self];
                break;
                
            case 3: //web
                beaconURL = [NSURL URLWithString:[beaconDictionary objectForKey:@"content"]];
                
                //Set content for segue depending on which method is to be used
                self.urlContentForSegue = beaconURL;
                self.htmlContentForSegue = nil;
                
                [self performSegueWithIdentifier:@"tourImageToWebContent" sender:self];
                break;

            case 4: //photo-gallery
                photoArray = [NSMutableArray array];
                
                if ([[beaconDictionary objectForKey:@"content"] isKindOfClass: [NSMutableArray class]]) {
                    galleryImages = [beaconDictionary objectForKey:@"content"];
                    //For each image in the gallery
                    for(NSString *imagePath in galleryImages) {
                        //If it's local, create a local URL
                        if ([self contentIsLocal:imagePath]) {
                            [photoArray addObject:[MWPhoto photoWithURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], imagePath]]]];
                        } else {
                            [photoArray addObject:[MWPhoto photoWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", imagePath]]]];
                        }
                    }
                    //Create the photo gallery and display it
                    [self createPhotoGallery:photoArray];
                } else {
                    NSLog(@"Error in processing photo gallery: content is not an array");
                }
                break;

            case 5: //record-audio
                self.installationIDForSegue = [beaconDictionary objectForKey:@"id"];
                //We go to a different place
                [self performSegueWithIdentifier:@"tourImageToStoriesPost" sender:self];
                break;
                
            case 6: //memories
                if ([[beaconDictionary objectForKey:@"content"] isKindOfClass: [NSArray class]]) {
                    self.memories = [beaconDictionary objectForKey:@"content"];
                    self.firstMemory = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString:self.memories[0]]];
                    self.secondMemory = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:self.memories[1]]];
                
                    [self performSegueWithIdentifier:@"tourImageToMemories" sender:self];
                } else {
                    NSLog(@"Error loading memories: content is not an array of urls");
                }
                break;
                
            case 7: //photobooth
                if ([[beaconDictionary objectForKey:@"content"] isKindOfClass: [NSString class]]) {
                    self.tweetText = [beaconDictionary objectForKey:@"content"];
                } else {
                    self.tweetText = @"Share your @Lufthouse experience!";
                }
                [self launchPhoto];
                break;
                
                
            default:
                break;
        }

        //Assert we are not on the landing image
        self.hasLanded = false;
    } else if (checkBeacon == nil && self.hasLanded == false) {
    //If there are no beacons to display, go to the landing image
        [self popToThisController:YES];
        //Load the image, transition to no audio, set the landed option, reset the active beacon, and restrict rotation
        [self doVolumeFade:nil];
        self.hasLanded = true;
        self.activeMinor = 0000;
        self.shouldRotate = NO;
    }
}
                     
-(BOOL) contentIsLocal: (NSString *)contentString
{
    if ([contentString rangeOfString:@"http"].location == NSNotFound && [contentString rangeOfString:@"www."].location == NSNotFound)
        return true;
    else
        return false;
}

-(int) getIntegerForContentType: (NSString *)contentType
{
    int returnInt = -1;
    
    if ([contentType isEqualToString:@"image"]) {
        returnInt = 0;
    } else if ([contentType isEqualToString:@"web-video"]) {
        returnInt = 1;
    } else if ([contentType isEqualToString:@"local-video"]) {
        returnInt = 2;
    } else if ([contentType isEqualToString:@"web"]) {
        returnInt = 3;
    } else if ([contentType isEqualToString:@"photo-gallery"]) {
        returnInt = 4;
    } else if ([contentType isEqualToString:@"record-audio"]) {
        returnInt = 5;
    } else if ([contentType isEqualToString:@"memories"]) {
        returnInt = 6;
    } else if ([contentType isEqualToString:@"photobooth"]) {
        returnInt = 7;
    }
        
    return returnInt;
}

-(BOOL) beaconShouldBeDisplayed:(ESTBeacon *)checkBeacon
{
    BOOL nearby = (self.testBool || [checkBeacon proximity] == CLProximityNear || [checkBeacon proximity] == CLProximityImmediate);
    BOOL isCurrentBeacon = [checkBeacon.minor isEqual:self.activeMinor];
    BOOL isCurrentlyLoadedContent = [checkBeacon.minor isEqual:[[self.displayBeaconContent objectForKey:@"beacon"] minor]];
    BOOL recentlyChanged = self.lastChanged && [self.lastChanged timeIntervalSinceNow] < 2;
    
    if (nearby && !isCurrentBeacon && isCurrentlyLoadedContent && !recentlyChanged) {
        return true;
    } else {
        return false;
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

            NSData * data = [NSData dataWithContentsOfURL:nextSong];
            self.audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
//            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:nextSong error:&error];
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
    NSString *const youTubeVideoHTML = @"<html><head><style>body{margin:0px 0px 0px 0px;}</style></head> <body> <div id=\"player\"></div> <script> var tag = document.createElement('script'); tag.src = 'http://www.youtube.com/player_api'; var firstScriptTag = document.getElementsByTagName('script')[0]; firstScriptTag.parentNode.insertBefore(tag, firstScriptTag); var player; function onYouTubePlayerAPIReady() { player = new YT.Player('player', { width:'100%%', height:'100%%', videoId:'%@' }); } </script> </body> </html>";
    //Format the html for the player
    NSString *html = [NSString stringWithFormat:youTubeVideoHTML, videoId];
    
    //Prep the content and segue
    self.urlContentForSegue = nil;
    self.htmlContentForSegue = html;
    [self performSegueWithIdentifier:@"tourImageToWebContent" sender:self];
    
}
- (void)launchPhoto {
    UIImagePickerController * imagePicker = [[UIImagePickerController alloc] init];
//    UIImageView * overlay = [[UIImageView alloc] initWithFrame:imagePicker.view.frame];
//    overlay.image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"overlay.png"]];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    imagePicker.delegate = self;
//    imagePicker.cameraOverlayView = overlay;
    [self presentViewController:imagePicker animated:YES completion:^(void){
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Photobooth"
                                  message:@"Go ahead and take a selfie, then share it on Twitter with us!"
                                  delegate:self
                                  cancelButtonTitle:@"Sure!"
                                  otherButtonTitles:nil];
        [alertView show];
    }];
}
- (IBAction)triggerLaunchPhoto:(id)sender {
    [self launchPhoto];
}

-(UIImage*)mergeImage:(UIImage*)mask overImage:(UIImage*)source inSize:(CGSize)size
{
    //Capture image context ref
    UIGraphicsBeginImageContext(size);
    
    //Draw images onto the context
    [source drawInRect:CGRectMake(0, 0, source.size.width, source.size.height)];
    [mask drawInRect:CGRectMake(0, 0, mask.size.width, mask.size.height)];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();    
    return viewImage;
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage * overlayImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"overlay.png"]];
    UIImage * newImage = [self mergeImage: overlayImage overImage:image inSize:image.size];
    
    UIImageWriteToSavedPhotosAlbum(newImage, self, nil, nil);
    
    [self dismissViewControllerAnimated:NO completion:NULL];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        [self.store requestAccessToAccountsWithType:[self.store accountTypeWithAccountTypeIdentifier: ACAccountTypeIdentifierTwitter] options:nil completion:^(BOOL granted, NSError *error) {
            if (!granted) {
                NSLog(@"%@", error);
            }
        }];
        
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        NSString *shareMessage = self.tweetText;
        [tweetSheet setInitialText:[NSString stringWithFormat:@"%@",shareMessage]];
        if (image)
        {
                [tweetSheet addImage:image];
        }
        
        [self presentViewController:tweetSheet animated:YES completion:^(void){}];

    } else {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Yikes!"
                                  message:@"It looks like you can't send a tweet right now, but that's okay! We've saved the photo to your pictures for safe keeping!"
                                  delegate:self
                                  cancelButtonTitle:@"Thanks!"
                                  otherButtonTitles:nil];
        [alertView show];
    }
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
    [self createErrorPopupWithMessage:@"Uh-oh!"
                          bodyMessage:@"It looks like you either don't have an internet connection or something has gone terribly wrong; please make sure you're connected to your network provider and try again!"];
    self.jsonDidFail = true;
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
            NSLog(@"Dumping hex: %@", self.receivedData.description);
            [self createErrorPopupWithMessage :@"Uh-oh!"
                                   bodyMessage:@"It looks like the tour is currently unavailable; please try again later!"];
            self.jsonDidFail = true;
        }
    } else {
        NSLog(@"Error: Recieved data is nil");
        //Tell the user something messed up
        [self createErrorPopupWithMessage:@"Uh-oh!"
                              bodyMessage:@"It looks like we can't grab the tour right now; please check your internet connection and try again later!"];
//        self.jsonDidFail = true;
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
        [self removeBeaconManagerListeners];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //If we're displaying web content, send the URL or HTML
    if ([[segue identifier] isEqualToString:@"tourImageToWebContent"]) {
        [self popToThisController:NO];
        WebContentViewController *destination = [segue destinationViewController];
        destination.segueContentURL = self.urlContentForSegue;
        destination.segueContentHTML = self.htmlContentForSegue;
    }
    //Else if we're going to create memories, prep relevant info
    else if ([[segue identifier] isEqualToString:@"tourImageToStoriesPost"]) {
        [self popToThisController:NO];
        StoriesViewController *destination = [segue destinationViewController];
        destination.custID = self.customerID;
        destination.tourID = self.tourID;
        destination.instID = self.installationIDForSegue;
    }
    //If we're going to display some memories
    else if ([[segue identifier] isEqualToString:@"tourImageToMemories"]) {
        [self popToThisController:NO];
        MemoriesViewController *destination = [segue destinationViewController];
        destination.firstMemory = self.firstMemory;
        destination.secondMemory = self.secondMemory;
        destination.memories = self.memories;
    }

}

//Helper method to not overlap content views
-(void)popToThisController: (BOOL)animated
{
    if (self.isDisplayingModal == true) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [self.navigationController popToViewController:self animated:animated];
//    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)unwindFromConfirmationForm:(UIStoryboardSegue *)segue {
}


@end
