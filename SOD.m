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
@end

@implementation SOD
@synthesize SocketIO;

typedef void(^MyResponseCallback)(NSDictionary* response);

- (id) initWithDelegate:(id<SocketIODelegate>)delegate andAddress:(NSString*) address andPort:(int)port
{
   
    self = [super init];
    if (self){
       
        self.SocketIO = [[SocketIO alloc] initWithDelegate:delegate];
        self.address = address;
        self.port = port;
        NSLog(address);
        NSLog(@"Port: %d",(int)port);
        [self.SocketIO connectToHost:address onPort:port];
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
            self.degrees = [self convertToDegrees:motion.attitude.yaw];
            
            
            // change orientation according to offset value
            self.degrees = self.degrees - self.OffsetValue;
            self.degrees = [self normalizeDegrees:self.degrees];
            
            
            float diff = fabs(self.degrees - 0);//lastSentOrientationValue);
            NSLog(@"attitude.yaw: %.04f, degrees: %.04f; diff: %f", motion.attitude.yaw, self.degrees, diff);
            
            NSNumber *orientation = @(self.degrees);
            [self sendOrientation:orientation];
        }
    }];
}

- (void) reconnectToServer
{
    [self.SocketIO disconnect];
    [self.SocketIO connectToHost:self.address onPort:self.port];
    [self sendDeviceInfoToServer];
}

- (void) calibrateDeviceAngle
{
    self.OffsetValue = [self normalizeDegrees:(self.OffsetValue+self.degrees)];
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
                                    [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID",
                                    @"iPad", @"deviceType",
                                    @"50", @"height",
                                    @"50", @"width",
                                    nil];
    
    MyResponseCallback requestCallback = ^(id response)
    {
        NSLog(@"status of send device info: %@", [response objectForKey:@"status"]);
    };
    
    [self sendDataWithReply:requestData andKeyword:@"registerDevice" withCallBack:requestCallback];
}

- (void)sendOrientation: (NSNumber*) orientation
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", orientation, @"orientation", nil];
    [self sendData:requestData andKeyword:@"updateOrientation"];
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

-(void)sendString:(NSString*) string withSelection: (NSString*) selection andCallBack: (void(^)(id response))completionCB
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", selection, @"selection", string, @"data", nil];
    [self sendDataWithReply:requestData andKeyword:@"sendStringToDevicesWithSelection" withCallBack:completionCB];
}

-(void)getDevicesWithSelection:(NSString*) selection withCallBack: (void(^)(id response))completionCB
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", selection, @"selection", nil];
    
    [self sendDataWithReply:requestData andKeyword:@"getDevicesWithSelection" withCallBack:completionCB];
}


/*
 Try to pair with one of the people that are being tracked with ID.
 */
-(NSString*) tryPairWithID:(NSString*) personID
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", personID, @"personID", nil];
    
    MyResponseCallback requestCallback = ^(id reply){
        self.OwnerID = reply[@"ownerID"];
    };
    [self sendDataWithReply:requestData andKeyword:@"forcePairRequest" withCallBack:requestCallback];
    return self.OwnerID;
}

- (void) getAllTrackedPeoplewithCallBack: (void(^)(id response))completionCB
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", nil];
    [self sendDataWithReply:requestData andKeyword:@"getPeopleFromServer" withCallBack:completionCB];
}

- (void) unpairDevice
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", self.OwnerID, @"personID", nil];
    [self sendData:requestData andKeyword:@"unpairDevice"];
}

- (void) unpairAllDevices
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", self.OwnerID, @"personID", nil];
    [self sendData:requestData andKeyword:@"unpairAllDevices"];
}
	
- (void) setPairingState
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", nil];
    [self sendData:requestData andKeyword:@"setPairingState"];
}

- (NSString*) unpairEveryone
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", nil];
    __block NSString* status;
    MyResponseCallback requestCallback = ^(id response)
    {
        status = response[@"status"];
    };
    [self sendDataWithReply:requestData andKeyword:@"unpairAllPeople" withCallBack:requestCallback];
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
