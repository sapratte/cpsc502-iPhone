//
//  ViewController.m
//  SOD-iOS-Client
//
//  Created by ASE Group on 3/13/2014.
//  Copyright (c) 2014 ASE Group. All rights reserved.
//

#import "ViewController.h"
#import "SOD.h"
#import "SocketIOPacket.h"
#import "Device.h"

@interface ViewController ()
@property (nonatomic, strong) SOD *SOD;
@end

@implementation ViewController
typedef void(^MyResponseCallback)(NSDictionary* response);

- (void)viewDidLoad
{
    [super viewDidLoad];
    self = [super init];
    
    //create SoD instance, setup dimensions and device type
    self.SOD = [[SOD alloc] initWithAddress:@"beastwin.marinhomoreira.com" andPort:3000];
//	self.SOD = [[SOD alloc] initWithAddress:@"localhost" andPort:3000];
    self.SOD.device.height = 1;
    self.SOD.device.width = 1;
    self.SOD.device.name = @"Retail iPhone";
    self.SOD.device.deviceType = @"iPhone";
    self.SOD.device.FOV = 33;
    self.SOD.device.orientation = 45;
    //self.SOD.height = 50;
    //self.SOD.width = 50;
    //self.SOD.name = @"Test iPad";
    //self.SOD.deviceType = @"iPad";
    
    //send info about this device to server
    [self.SOD registerDevice];
    
    if(self){
        self.txtTestData.delegate = self;
        
        //add event handlers, name = eventName which server sent to
        //For example, socket.emit("string", "testString") will call stringReceivedHandler
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stringReceivedHandler:) name:@"string" object:nil];
        
        // Enter view leave view event
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enviewEventHandler:) name:@"enterView" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(leaveViewEventHandler:) name:@"leaveView" object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dictionaryReceivedHandler:) name:@"dictionary" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventReceivedHandler:) name:@"event" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestReceivedHandler:) name:@"request" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestedDataReceivedHandler:) name:@"requestedData" object:nil];
		
		
		// My event on entering a data point view
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nearItemReceivedHandler:) name:@"nearItem" object:nil];
    }
    
	// Do any additional setup after loading the view, typically from a nib.
}


// ----------------------------------------- USING -----------------------------------------



- (void)nearItemReceivedHandler: (NSNotification*) event
{
	NSDictionary *theData = [[event userInfo] objectForKey:@"data"];
	NSLog(@"Event received: %@", [theData objectForKey:@"data"]);
	
	UIViewController *productview = [self.storyboard instantiateViewControllerWithIdentifier:@"ProductView"];
	[self presentViewController:productview animated:YES completion:nil];
}










// ------------------------------------------ END ------------------------------------------

// [self.SOD sendEvent:stringData toEvent:@"changePosition" withSelection:@"all" andCallBack:requestCallback];





- (IBAction)reconnectToServer:(id)sender {
    [self.SOD reconnectToServer];
}

- (IBAction)calibrateDeviceAngle:(id)sender {
    [self.SOD calibrateDeviceAngle];
}

- (IBAction)sendTestString:(id)sender {
    NSString* stringData = self.txtTestData.text;
    MyResponseCallback requestCallback = ^(id reply)
    {
        self.txtStatus.text = [reply objectForKey:@"status"];
    };
    [self.SOD sendString:stringData withSelection:@"inView" andCallBack:requestCallback];
    
}
- (IBAction)sendTestDictionary:(id)sender {
    NSString* stringData = self.txtTestData.text;
    NSDictionary* dictionaryData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", stringData, @"string", nil];
    MyResponseCallback requestCallback = ^(id reply)
    {
        self.txtStatus.text = [reply objectForKey:@"status"];
    };
    [self.SOD sendDictionary:dictionaryData withSelection:@"all" andCallBack:requestCallback];
}
- (IBAction)sendRequest:(id)sender {
    NSString* requestName = self.txtTestData.text;
    MyResponseCallback requestCallback = ^(id reply)
    {
        self.txtStatus.text = [reply objectForKey:@"status"];
    };
    [self.SOD requestDataWithRequestName:requestName andSelection:@"all" andCallBack:requestCallback];
}

- (IBAction)setPairingState:(id)sender {
    self.txtStatus.text = @"Pairing State clicked";
    [self.SOD setPairingState];
}

- (IBAction)unpairDevice:(id)sender {
    self.txtStatus.text = @"Unpair clicked";
    [self.SOD unpairDevice];
}

- (IBAction)unpairAllDevices:(id)sender {
    [self.SOD unpairAllDevices];
}

- (IBAction)unpairAllPeople:(id)sender {
    self.txtStatus.text = @"Unpairing all people...";
    [self.SOD unpairAllPeople];
}

- (IBAction)restartMotionManager:(id)sender {
    self.txtStatus.text = @"Reset clicked";
    [self.SOD restartMotionManager];
}

- (IBAction)getPeopleFromServer:(id)sender {
    self.txtStatus.text = @"Getting people...";
    MyResponseCallback requestCallback = ^(id reply)
    {
        NSString *outputString = @"";
        if([reply isKindOfClass:[NSDictionary class]]){
            NSDictionary* dict = reply;
            outputString = @"ID: %@, Location: %@, Pair Status: %@",[dict objectForKey:@"ID"],[dict objectForKey:@"Location"], [dict objectForKey:@"OwnedDeviceID"];
        }
        else{
            NSArray* arr = reply;
            for (int i=0; i<[arr count]; i++) {
                NSDictionary* dict = [arr objectAtIndex:i];
                outputString = [outputString stringByAppendingString:[NSString stringWithFormat:@"ID: %@, Location: %@, Orientation: %@, PairingState: %@, OwnedDeviceID: %@",[dict objectForKey:@"ID"],[dict objectForKey:@"Location"], [dict objectForKey:@"Orientation"], [dict objectForKey:@"PairingState"], [dict objectForKey:@"OwnedDeviceID"]]];
            }
        }
        self.txtStatus.text = outputString;
    };
    [self.SOD getAllTrackedPeoplewithCallBack:requestCallback];
}

- (IBAction)getDevicesFromServer:(id)sender {
    MyResponseCallback requestCallback = ^(id reply)
    {
        NSString *outputString = @"";
        for(id key in reply){
            NSDictionary* dict = [reply valueForKeyPath:key];
            outputString = [outputString stringByAppendingString:[NSString stringWithFormat:@"ID: %@, SocketID: %@, Location: %@, Orientation: %@, PairingState: %@, OwnerID: %@",[dict objectForKey:@"ID"], [dict objectForKey:@"socketID"], [dict objectForKey:@"Location"], [dict objectForKey:@"Orientation"], [dict objectForKey:@"PairingState"], [dict objectForKey:@"OwnerID"]]];
        }
        self.txtStatus.text = outputString;
    };

    [self.SOD getDevicesWithSelection:@"all" withCallBack:requestCallback];
}

- (IBAction)getDevicesInView:(id)sender {
    MyResponseCallback requestCallback = ^(id reply)
    {
        NSString *outputString = @"";
        for(id key in reply){
            NSDictionary* dict = [reply valueForKeyPath:key];
            outputString = [outputString stringByAppendingString:[NSString stringWithFormat:@"ID: %@, SocketID: %@, Location: %@, Orientation: %@, PairingState: %@, OwnerID: %@",[dict objectForKey:@"ID"], [dict objectForKey:@"socketID"], [dict objectForKey:@"Location"], [dict objectForKey:@"Orientation"], [dict objectForKey:@"PairingState"], [dict objectForKey:@"OwnerID"]]];
        }
        self.txtStatus.text = outputString;
    };
    [self.SOD getDevicesWithSelection:@"inView" withCallBack:requestCallback];
}


- (IBAction)getSingleDeviceByID:(id)sender {
    MyResponseCallback completionCB = ^(id reply)
    {
        NSString *outputString = @"";
        if(reply != [NSNull null]){
            NSDictionary* dict = reply;
            outputString = [outputString stringByAppendingString:[NSString stringWithFormat:@"ID: %@, SocketID: %@, Location: %@, Orientation: %@, PairingState: %@, OwnerID: %@",[dict objectForKey:@"ID"], [dict objectForKey:@"socketID"], [dict objectForKey:@"Location"], [dict objectForKey:@"Orientation"], [dict objectForKey:@"PairingState"], [dict objectForKey:@"OwnerID"]]];
        }
        else{
            outputString = [NSString stringWithFormat:@"No device found with specified ID %@.", self.txtTestData.text];
        }
        
        self.txtStatus.text = outputString;
    };
    [self.SOD getDeviceWithID:self.txtTestData.text.integerValue withCallBack:completionCB];
}


- (void)stringReceivedHandler: (NSNotification*) event
{
    NSDictionary *theData = [[event userInfo] objectForKey:@"data"];
    NSLog(@"String received: %@", [theData objectForKey:@"data"]);
}

- (void)enviewEventHandler: (NSNotification*) event
{
    NSDictionary *theData = [[event userInfo] objectForKey:@"data"];
    NSLog(@"Enter View event received: %@,%@", [theData objectForKey:@"observer"],[theData objectForKey:@"visitor"]);
}
- (void)leaveViewEventHandler: (NSNotification*) event
{
    NSDictionary *theData = [[event userInfo] objectForKey:@"data"];
    NSLog(@"Leave View event received: %@,%@", [theData objectForKey:@"observer"],[theData objectForKey:@"visitor"]);

}

- (void)dictionaryReceivedHandler: (NSNotification*) event
{
    NSDictionary *theData = [[event userInfo] objectForKey:@"data"];
    NSLog(@"Dictionary received: %@", [theData objectForKey:@"data"]);
}

- (void)eventReceivedHandler: (NSNotification*) event
{
    NSDictionary *theData = [[event userInfo] objectForKey:@"data"];
    NSLog(@"Event received: %@", [theData objectForKey:@"data"]);
}

/**
 *  <#Description#>
 *
 *  @param event <#event description#>
 */
- (void)requestReceivedHandler: (NSNotification*) event
{
    NSDictionary *theData = [[event userInfo] objectForKey:@"data"];
    NSLog(@"Received request for... %@", [theData objectForKey:@"data"]);
    NSString* PID = [[event userInfo] objectForKey:@"PID"];
    NSDictionary *dataToSendBack = [NSDictionary dictionaryWithObjectsAndKeys:
                                                              @"this is the sample data", @"data", nil];
    NSLog(@"Viewcontroller sending an acknowledgement with PID %@ and data... %@", PID, dataToSendBack);
    [self.SOD sendAcknowledgementWithPID:PID andData:dataToSendBack];
}

//handler for receiving the requested data (Request/reply pattern)
- (void)requestedDataReceivedHandler: (NSNotification*) event
{
    NSDictionary *theData = [[event userInfo] objectForKey:@"data"];
    NSLog(@"Requested data received: %@", [theData objectForKey:@"data"]);
}

/**
 *  Memory warning...
 */
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

/**
 *  Convert a dictionary to string for output.
 *
 *  @param dictionary dictionary to be converted
 *
 *  @return string representation of dictionary
 */
-(NSString*) dictionaryToString:(NSDictionary*) dictionary{
    NSMutableString *returnString = [[NSMutableString alloc] init];
    for(NSString *aKey in [dictionary allKeys])
        [returnString appendFormat:@"%@ : %@\n", aKey, [dictionary valueForKey:aKey]];
    return returnString;
}

- (void)dealloc {
    [_txtStatus release];
    [_txtTestData release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}
@end
