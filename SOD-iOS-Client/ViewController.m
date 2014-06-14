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

@interface ViewController ()
@property (nonatomic, strong) SOD *SOD;
@end

@implementation ViewController
typedef void(^MyResponseCallback)(NSDictionary* response);

- (void)viewDidLoad
{
    [super viewDidLoad];
    self = [super init];
    self.SOD = [[SOD alloc] initWithAddress:@"192.168.1.69" andPort:3000];
    if(self){
        self.txtTestData.delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stringReceivedHandler:) name:@"stringReceived" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dictionaryReceivedHandler:) name:@"dictionaryReceived" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventReceivedHandler:) name:@"eventReceived" object:nil];
    }
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)reconnectToServer:(id)sender {
    [self.SOD reconnectToServer];
}

- (IBAction)calibrateDeviceAngle:(id)sender {
    [self.SOD calibrateDeviceAngle];
}

- (IBAction)sendTestData:(id)sender {
    NSString* stringData = self.txtTestData.text;
    MyResponseCallback requestCallback = ^(id reply)
    {
        self.txtStatus.text = [reply objectForKey:@"status"];
    };
    [self.SOD sendString:stringData withSelection:@"inView" andCallBack:requestCallback];
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
    [self.SOD unpairEveryone];
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

- (void)stringReceivedHandler: (NSNotification*) event
{
    NSDictionary *theData = [[event userInfo] objectForKey:@"data"];
    NSLog(@"String received: %@", [theData objectForKey:@"data"]);
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(NSString*) dictionaryToString:(NSDictionary*) dictionary{
    NSMutableString *returnString = [[NSMutableString alloc] init];
    for(NSString *aKey in [dictionary allKeys])
        [returnString appendFormat:@"%@ : %@\n", aKey, [dictionary valueForKey:aKey]];
    return returnString;
}

- (void)dealloc {
    [_txtStatus release];
    [_txtTestData release];
    [super dealloc];
}
@end
