//
//  ViewController.m
//  SOD-iOS-Client
//
//  Created by ASE Group on 3/13/2014.
//  Copyright (c) 2014 ASE Group. All rights reserved.
//

#import "ViewController.h"
#import <zeromq-ios.framework/Headers/zmq.h>
#import "ZMQObjC.h"
#import <CoreMotion/CoreMotion.h>

#define ORIENTATION_UPDATE_THRESHOLD 3.0
#define ORIENTATION_UPDATE_INTERVAL 1.0f/5.0f

@interface ViewController ()
@property (nonatomic, strong) CMMotionManager *manager;
@property float offsetValue;
@property (nonatomic, strong) NSString* endpoint;
@property (nonatomic, strong) NSString* pairendpoint;
@property (nonatomic, strong) NSString* requestendpoint;
@property (nonatomic, strong) NSString* OwnerID;
@end

@implementation ViewController

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
    if(self){
        self.offsetValue = 0;
        self.userSpecifiedID.delegate = self;
    }
    self.endpoint = @"tcp://192.168.20.12:5570";
    @autoreleasepool{
        [self requestNewEndPoints];
        NSLog(@"%@", self.pairendpoint);
        NSLog(@"%@", self.requestendpoint);
        [self startMotionManager];
	}
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)startMotionManager
{
    [self.manager setDeviceMotionUpdateInterval:ORIENTATION_UPDATE_INTERVAL];
    [self.manager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
        @autoreleasepool {
            
            NSLog(@"Inside Motion Update");
            //Compute current orientation (in degrees) and diff from previous value
            float degrees = [self convertToDegrees:motion.attitude.yaw];
            
            
            // change orientation according to offset value
            degrees = self.offsetValue + degrees;
            degrees = [self normalizeDegrees:degrees];
            
            float diff = fabs(degrees - 0);//lastSentOrientationValue);
            NSLog(@"attitude.yaw: %.04f, degrees: %.04f; diff: %f", motion.attitude.yaw, degrees, diff);
            
            
            //IF value exceeds diff, dispatch orientation to other devices
            //if(diff > ORIENTATION_UPDATE_THRESHOLD){// || firstValue) {
            
            NSNumber *orientation = @(degrees);
            [self sendOrientation:orientation];
        }
    }];
}

- (IBAction)setPairingState:(id)sender {
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"setPairingState", @"requestType", requestData, @"additionalInfo", nil];
    [self sendData:requestCapsule];
    self.txtStatus.text = @"Pairing State clicked";
}
- (IBAction)unpairDevice:(id)sender {
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", self.OwnerID, @"personID", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"unpairDevice", @"requestType", requestData, @"additionalInfo", nil];
    [self sendData:requestCapsule];
    self.txtStatus.text = @"Unpair clicked";
}

- (void)sendOrientation: (NSNumber*) orientation
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                        [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", orientation, @"orientation", nil];
            
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"updateOrientation", @"requestType", requestData, @"additionalInfo", nil];
    [self sendData:requestCapsule];
}

- (void)sendData: (NSDictionary*) requestCapsule
{
    ZMQContext *ctx = [[ZMQContext alloc] initWithIOThreads:1];
    ZMQSocket *pairSocket = [ctx socketWithType:ZMQ_PUSH];
    int diditwork = zmq_setsockopt(pairSocket, ZMQ_SNDTIMEO, 0, 1);
    diditwork = zmq_setsockopt((void*)pairSocket, ZMQ_SNDTIMEO, (void*)0, sizeof((void*)0));
    NSLog(@"%d", diditwork);
    
    NSLog(@"%d", errno);
    BOOL didConnectPush = [pairSocket connectToEndpoint:self.pairendpoint];
    if (!didConnectPush) {
        NSLog(@"*** Failed to connect to endpoint [%@].", self.pairendpoint);
    }
    else{
        NSLog(@"*** CONNECTED TO PUSH [%@].", self.pairendpoint);
        NSError* error =  nil;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:requestCapsule
                                                           options:NSJSONWritingPrettyPrinted error: &error];
        NSString* requestDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"%@",requestDataString);
        NSData *request = [requestDataString dataUsingEncoding:NSUTF8StringEncoding];
        @try{
            if([pairSocket sendData:request withFlags:0]){
                NSLog(@"send successful");
                [ctx closeSockets];
                [ctx terminate];
                NSLog(@"nope");
                return;
            }
            else{
                NSLog(@"KABOOM");
                [ctx closeSockets];
                [ctx terminate];
                return;
            }
        }
        @catch(NSError *er){
            NSLog(@"error?");
            self.txtStatus.text = er.description;
        }
        
        [ctx closeSockets];
        [ctx terminate];
        NSLog(@"does it ever reach here");
    }
}

- (IBAction)resetEndPointsAndRestartOrientation:(id)sender {
    self.txtStatus.text = @"Reset clicked";
    [self.manager stopDeviceMotionUpdates];
    self.manager = nil;
    [self requestNewEndPoints];
    [self startMotionManager];
}
- (IBAction)getPeopleFromServer:(id)sender {
    self.txtStatus.text = @"Getting people...";
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"getPeople", @"requestType", requestData, @"additionalInfo", nil];
    id obj = [self sendDataWithReply:requestCapsule andEndpoint:self.requestendpoint];
    NSString *outputString = @"";
    if([obj isKindOfClass:[NSDictionary class]]){
        NSDictionary* dict = obj;
        NSLog(@"Count: %d",[dict count]);
        NSLog(@"ID: %@, Location: %@, Pair Status: %@",[dict objectForKey:@"ID"],[dict objectForKey:@"Location"], [dict objectForKey:@"TrackedBy"]);
        outputString = @"ID: %@, Location: %@, Pair Status: %@",[dict objectForKey:@"ID"],[dict objectForKey:@"Location"], [dict objectForKey:@"OwnedDeviceID"];
    }
    else{
        NSArray* arr = obj;
        for (int i=0; i<[arr count]; i++) {
            NSDictionary* dict = [arr objectAtIndex:i];
            outputString = [outputString stringByAppendingString:[NSString stringWithFormat:@"ID: %@, Location: %@, Orientation: %@, PairingState: %@, OwnedDeviceID: %@",[dict objectForKey:@"ID"],[dict objectForKey:@"Location"], [dict objectForKey:@"Orientation"], [dict objectForKey:@"PairingState"], [dict objectForKey:@"OwnedDeviceID"]]];
        }
        self.txtStatus.text = outputString;
    }
}
- (IBAction)getDevicesFromServer:(id)sender {
    self.txtStatus.text = @"Getting devices...";
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"getDevices", @"requestType", requestData, @"additionalInfo", nil];
    id obj = [self sendDataWithReply:requestCapsule andEndpoint:self.requestendpoint];
    NSString *outputString = @"";
    if([obj isKindOfClass:[NSDictionary class]]){
        NSDictionary* dict = obj;
        NSLog(@"Count: %d",[dict count]);
        NSLog(@"ID: %@, Orientation: %@",[dict objectForKey:@"ID"],[dict objectForKey:@"Orientation"]);
        outputString = @"ID: %@, Location: %@, Orientation: %@, PairingState: %@, OwnerID: %@",[dict objectForKey:@"ID"], [dict objectForKey:@"Location"], [dict objectForKey:@"Orientation"], [dict objectForKey:@"PairingState"], [dict objectForKey:@"OwnerID"];
    }
    else{
        NSArray* arr = obj;
        for (int i=0; i<[arr count]; i++) {
            NSDictionary* dict = [arr objectAtIndex:i];
            outputString = [outputString stringByAppendingString:[NSString stringWithFormat:@"ID: %@, Location: %@, Orientation: %@, PairingState: %@, OwnerID: %@",[dict objectForKey:@"ID"], [dict objectForKey:@"Location"], [dict objectForKey:@"Orientation"], [dict objectForKey:@"PairingState"], [dict objectForKey:@"OwnerID"]]];
        }
    self.txtStatus.text = outputString;
    }
}
- (IBAction)forcePairRequest:(id)sender {
    self.txtStatus.text = @"Forcing pair...";
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", self.userSpecifiedID.text, @"personID", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"forcePair", @"requestType", requestData, @"additionalInfo", nil];
    NSDictionary *reply = [self sendDataWithReply:requestCapsule andEndpoint:self.requestendpoint];
    self.OwnerID = reply[@"ownerID"];
    self.txtStatus.text = [[[@"Force pair with " stringByAppendingString:self.userSpecifiedID.text] stringByAppendingString:@": "] stringByAppendingString:reply[@"status"]];
}

- (void)requestNewEndPoints
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"requestPorts", @"requestType", requestData, @"additionalInfo", nil];
    NSDictionary *reply = [self sendDataWithReply:requestCapsule andEndpoint:self.endpoint];
    self.pairendpoint = [@"tcp://192.168.20.12:" stringByAppendingString:[reply[@"pairPort"] stringValue]];
    self.requestendpoint = [@"tcp://192.168.20.12:" stringByAppendingString:[reply[@"requestPort"] stringValue]];
}

- (id)sendDataWithReply: (NSDictionary*) requestCapsule andEndpoint: (NSString*) endPoint
{
    ZMQContext *ctx = [[ZMQContext alloc] initWithIOThreads:1];
    ZMQSocket *requester = [ctx socketWithType:ZMQ_REQ];
    //NSError *error;
    BOOL didConnect = [requester connectToEndpoint:endPoint];
    if (!didConnect) {
		NSLog(@"*** Failed to connect to endpoint [%@].", endPoint);
    }
    else{
        NSLog(@"*** CONNECTED TO PUSH [%@].", self.pairendpoint);
        NSError* error =  nil;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:requestCapsule
                                                           options:NSJSONWritingPrettyPrinted error: &error];
        NSString* requestDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", requestDataString);
        NSData *request = [requestDataString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSLog(@"Sending request");
        [requester sendData:request withFlags:0];
        
        NSLog(@"Waiting for reply");
        NSData *reply = [requester receiveDataWithFlags:0];
        id obj = [NSJSONSerialization
                              JSONObjectWithData:reply options:kNilOptions error:&error];
        [ctx closeSockets];
        [ctx terminate];
        return obj;
    }
    return NULL;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
    
#pragma mark - Helper functions
    
-(float) convertToDegrees:(float) radians {
    float degrees = radians/M_PI * 180.0;
	if (degrees < 0)
    degrees = 360 + degrees;
	return degrees;
}
    
-(float) normalizeDegrees:(float) degrees {
	if (degrees < 0) {
		degrees = 360 + degrees;
    }
    else {
        while (degrees > 360)
        degrees -= 360;
    }
	return degrees;
}

-(NSString*) dictionaryToString:(NSDictionary*) dictionary{
    NSMutableString *returnString = [[NSMutableString alloc] init];
    for(NSString *aKey in [dictionary allKeys])
        [returnString appendFormat:@"%@ : %@\n", aKey, [dictionary valueForKey:aKey]];
    return returnString;
}
    
-(CMMotionManager *)manager
{
    if (!_manager) {
        _manager = [[CMMotionManager alloc] init];
    }
    return _manager;
}

- (void)dealloc {
    [_txtStatus release];
    [_userSpecifiedID release];
    [super dealloc];
}
@end

@interface DataCapsule : NSObject
{
    NSString *requestType;
    NSString *additionalInfo;
}
    - (id)initWithInitialRequestType: (NSString*)initialRequestType;
    - (id)initWithInitialAdditionalInfo: (NSString*)initialAdditionalInfo;
@end

@implementation DataCapsule
    -(id)initWithInitialRequestType:(NSString*)initialRequestType{
        requestType = initialRequestType;
        return self;
    }
    -(id)initWithInitialAdditionalInfo:(NSString *)initialAdditionalInfo{
        additionalInfo = initialAdditionalInfo;
        return self;
    }
@end
