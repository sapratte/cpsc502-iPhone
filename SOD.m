//
//  SOD.m
//  SOD-iOS-Client
//
//  Created by ASE Group on 2014-05-14.
//  Copyright (c) 2014 ASE Group. All rights reserved.
//

#import "SOD.h"
#import <CoreMotion/CoreMotion.h>
#import "SocketIO.h"

#define ORIENTATION_UPDATE_THRESHOLD 3.0
#define ORIENTATION_UPDATE_INTERVAL 1.0f/5.0f

@interface SOD (Private)
@property (nonatomic, strong) CMMotionManager *Manager;
@end

@implementation SOD
@synthesize SocketIO;

typedef void(^MyResponseCallback)(NSDictionary* response);

- (id) initWithDelegate:(id<SocketIODelegate>)delegate
{
    self = [super init];
    if (self){
        self.SocketIO = [[SocketIO alloc] initWithDelegate:delegate];
        [self.SocketIO connectToHost:@"192.168.0.104" onPort:3000];
    }
    @autoreleasepool{
        [self sendDeviceInfoToServer];
        [self startMotionManager];
        self.OffsetValue = 0;
 	}
    return self;
}

- (void) startMotionManager
{
    [self.manager setDeviceMotionUpdateInterval:ORIENTATION_UPDATE_INTERVAL];
    [self.manager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
        @autoreleasepool {
            
            NSLog(@"Inside Motion Update");
            //Compute current orientation (in degrees) and diff from previous value
            float degrees = [self convertToDegrees:motion.attitude.yaw];
            
            
            // change orientation according to offset value
            degrees = self.OffsetValue + degrees;
            degrees = [self normalizeDegrees:degrees];
            
            float diff = fabs(degrees - 0);//lastSentOrientationValue);
            NSLog(@"attitude.yaw: %.04f, degrees: %.04f; diff: %f", motion.attitude.yaw, degrees, diff);
            
            NSNumber *orientation = @(degrees);
            [self sendOrientation:orientation];
        }
    }];
}

- (void) restartMotionManager
{
    [self.manager stopDeviceMotionUpdates];
    self.manager = nil;
    [self startMotionManager];
}

-(CMMotionManager *)manager
{
    if (!manager) {
        manager = [[CMMotionManager alloc] init];
    }
    return manager;
}

- (void) sendDeviceInfoToServer{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", @"50", @"height", @"50", @"width", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"initDevice", @"requestType", requestData, @"additionalInfo", nil];
    
    MyResponseCallback requestCallback = ^(id response)
    {
        NSLog(@"status of send device info: %@", [response objectForKey:@"status"]);
    };
    
    [self sendDataWithReply:requestCapsule andKeyword:@"sendDeviceInfoToServer" withCallBack:requestCallback];
    //self.txtStatus.text = [@"Init Device: " stringByAppendingString:reply[@"status"]];
}

- (void)sendOrientation: (NSNumber*) orientation
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", orientation, @"orientation", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"updateOrientation", @"requestType", requestData, @"additionalInfo", nil];
    [self sendData:requestCapsule andKeyword:@"sendOrientation"];
}


- (void)sendData: (NSDictionary*) requestCapsule andKeyword:(NSString*) keyword
{
    [self.SocketIO sendEvent:keyword withData:requestCapsule];
}

- (void)sendDataWithReply: (NSDictionary*) requestCapsule andKeyword: (NSString*) keyword withCallBack:(MyResponseCallback)callback
{
    SocketIOCallback cb = ^(id argsData){
        callback(argsData);
    };
    [self.SocketIO sendEvent:keyword withData:requestCapsule andAcknowledge:cb];
}

-(void)getDevicesWithSelection:(NSString*) selection withCallBack: (void(^)(id response))completionCB
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", selection, @"selection", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"getDevices", @"requestType", requestData, @"additionalInfo", nil];
    
    MyResponseCallback requestCallback = ^(id reply)
    {
        NSString *outputString = @"";
        if([reply isKindOfClass:[NSDictionary class]]){
            NSDictionary* dict = reply;
            outputString = @"ID: %@, Location: %@, Orientation: %@, PairingState: %@, OwnerID: %@",[dict objectForKey:@"ID"], [dict objectForKey:@"Location"], [dict objectForKey:@"Orientation"], [dict objectForKey:@"PairingState"], [dict objectForKey:@"OwnerID"];
            completionCB(reply);
        }
        else{
            NSArray* arr = reply;
            for (int i=0; i<[arr count]; i++) {
                NSDictionary* dict = [arr objectAtIndex:i];
                outputString = [outputString stringByAppendingString:[NSString stringWithFormat:@"ID: %@, Location: %@, Orientation: %@, PairingState: %@, OwnerID: %@",[dict objectForKey:@"ID"], [dict objectForKey:@"Location"], [dict objectForKey:@"Orientation"], [dict objectForKey:@"PairingState"], [dict objectForKey:@"OwnerID"]]];
            }
            completionCB(reply);
        }
    };
    
    [self sendDataWithReply:requestCapsule andKeyword:@"getDevicesWithSelection" withCallBack:requestCallback];
}

-(NSString*) tryPairWithID:(NSString*) personID
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", personID, @"personID", nil];
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"forcePair", @"requestType", requestData, @"additionalInfo", nil];
    
    MyResponseCallback requestCallback = ^(id reply){
        self.OwnerID = reply[@"ownerID"];
    };
    [self sendDataWithReply:requestCapsule andKeyword:@"forcePairRequest" withCallBack:requestCallback];
    return self.OwnerID;
}

- (NSDictionary*) getAllTrackedPeople
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"getPeople", @"requestType", requestData, @"additionalInfo", nil];
    __block NSDictionary* returnValue;
    MyResponseCallback requestCallback = ^(id reply)
    {
        if([reply isKindOfClass:[NSDictionary class]]){
            returnValue = reply;
        }
        else{
            //removed array iteration, maybe add conversion before return if REPLY IS AN ARRAY
            //<insert code to convert array to nsdictionary>
            returnValue = reply;
        }
    };
    
    [self sendDataWithReply:requestCapsule andKeyword:@"getPeopleFromServer" withCallBack:requestCallback];
    return returnValue;
}

- (void) unpairDevice
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", self.OwnerID, @"personID", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"unpairDevice", @"requestType", requestData, @"additionalInfo", nil];
    [self sendData:requestCapsule andKeyword:@"unpairDevice"];
}

- (void) setPairingState
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"setPairingState", @"requestType", requestData, @"additionalInfo", nil];
    [self sendData:requestCapsule andKeyword:@"setPairingState"];
}

- (NSString*) unpairEveryone
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", nil];
    
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"unpairAllPeople", @"requestType", requestData, @"additionalInfo", nil];
    __block NSString* status;
    MyResponseCallback requestCallback = ^(id response)
    {
        status = response[@"status"];
    };
    [self sendDataWithReply:requestCapsule andKeyword:@"unpairAllPeople" withCallBack:requestCallback];
    return status;
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

@end
