//
//  ViewController.m
//  SOD-iOS-Client
//
//  Created by ASE Group on 3/13/2014.
//  Copyright (c) 2014 ASE Group. All rights reserved.
//

#import "ViewController.h"
#import "SOD.h"

@interface ViewController ()
@property (nonatomic, strong) SOD *SOD;
@end

@implementation ViewController
typedef void(^MyResponseCallback)(NSDictionary* response);

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"hey" message:@"boss" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
    [alert show];
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self = [super init];
    self.SOD = [[SOD alloc] initWithDelegate:self];
    if(self){
        self.userSpecifiedID.delegate = self;
    }
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)setPairingState:(id)sender {
    self.txtStatus.text = @"Pairing State clicked";
    [self.SOD setPairingState];
}

- (IBAction)unpairDevice:(id)sender {
    self.txtStatus.text = @"Unpair clicked";
    [self.SOD unpairDevice];
}

- (IBAction)unpairAllPeople:(id)sender {
    self.txtStatus.text = @"Unpairing all people...";
    self.txtStatus.text = [self.SOD unpairEveryone];
}

- (IBAction)restartMotionManager:(id)sender {
    self.txtStatus.text = @"Reset clicked";
    [self.SOD restartMotionManager];
}

- (IBAction)getPeopleFromServer:(id)sender {
    self.txtStatus.text = @"Getting people...";
    NSString *outputString = @"";
    id reply = [self.SOD getAllTrackedPeople];
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
}

- (IBAction)forcePairRequest:(id)sender {
    self.txtStatus.text = @"Forcing pair...";
    NSString* ownerID = [self.SOD tryPairWithID:self.userSpecifiedID.text];
    self.txtStatus.text = [[[@"Force pair with " stringByAppendingString:self.userSpecifiedID.text] stringByAppendingString:@": "] stringByAppendingString:ownerID];
}

- (IBAction)getDevicesFromServer:(id)sender {
    MyResponseCallback requestCallback = ^(id reply)
    {
        NSString *outputString = @"";
        if([reply isKindOfClass:[NSDictionary class]]){
            NSDictionary* dict = reply;
            outputString = @"ID: %@, Location: %@, Orientation: %@, PairingState: %@, OwnerID: %@",[dict objectForKey:@"ID"], [dict objectForKey:@"Location"], [dict objectForKey:@"Orientation"], [dict objectForKey:@"PairingState"], [dict objectForKey:@"OwnerID"];
        }
        else{
            NSArray* arr = reply;
            for (int i=0; i<[arr count]; i++) {
                NSDictionary* dict = [arr objectAtIndex:i];
                outputString = [outputString stringByAppendingString:[NSString stringWithFormat:@"ID: %@, Location: %@, Orientation: %@, PairingState: %@, OwnerID: %@",[dict objectForKey:@"ID"], [dict objectForKey:@"Location"], [dict objectForKey:@"Orientation"], [dict objectForKey:@"PairingState"], [dict objectForKey:@"OwnerID"]]];
            }
        }
        self.txtStatus.text = outputString;
    };

    [self.SOD getDevicesWithSelection:@"all" withCallBack:requestCallback];
}

- (IBAction)getDevicesInView:(id)sender {
    MyResponseCallback requestCallback = ^(id reply)
    {
    };
    [self.SOD getDevicesWithSelection:@"inView" withCallBack:requestCallback];
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
    [_userSpecifiedID release];
    [super dealloc];
}
@end
