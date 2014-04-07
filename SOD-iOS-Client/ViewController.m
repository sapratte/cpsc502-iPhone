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
    @property (nonatomic, strong) NSString* pushendpoint;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self = [super init];
    if(self){
        self.offsetValue = 0;
    }
    NSString *endpoint = @"tcp://192.168.20.12:5570";
    @autoreleasepool{
        NSString *pushendpoint = [self getPushEndPoint: endpoint];
        
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
                [self sendOrientation:pushendpoint andOrientation:orientation];
            }
        }];

	}
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)sendOrientation: (NSString*) endpoint andOrientation: (NSNumber*) orientation
{
    ZMQContext *ctx = [[ZMQContext alloc] initWithIOThreads:1];
    ZMQSocket *pushSocket = [ctx socketWithType:ZMQ_PUSH];
    BOOL didConnectPush = [pushSocket connectToEndpoint:endpoint];
    if (!didConnectPush) {
        NSLog(@"*** Failed to connect to endpoint [%@].", endpoint);
    }
    else{
        NSLog(@"*** CONNECTED TO PUSH [%@].", endpoint);
    }
    
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                        [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID", orientation, @"orientation", nil];
            
    NSDictionary* requestCapsule = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"updateOrientation", @"requestType", requestData, @"device", nil];
    NSError* error =  nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:requestCapsule
                                                        options:NSJSONWritingPrettyPrinted error: &error];
    NSString* requestDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(requestDataString);
    NSData *request = [requestDataString dataUsingEncoding:NSUTF8StringEncoding];
    [pushSocket sendData:request withFlags:0];
    [ctx closeSockets];
    [ctx terminate];
}

- (NSString*)getPushEndPoint:(NSString*) endpoint
{
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"requestPort", @"requestType", @"extrainfo", @"additionalInfo", nil];
    NSError* error =  nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:requestData
                                                       options:NSJSONWritingPrettyPrinted error: &error];
    NSString* requestDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(requestDataString);
    
    ZMQContext *ctx = [[ZMQContext alloc] initWithIOThreads:1];
    
    ZMQSocket *requester = [ctx socketWithType:ZMQ_REQ];
    BOOL didConnect = [requester connectToEndpoint:endpoint];
    if (!didConnect) {
		NSLog(@"*** Failed to connect to endpoint [%@].", endpoint);
    }
	NSData *request = [requestDataString dataUsingEncoding:NSUTF8StringEncoding];

        NSLog(@"Sending request");
        [requester sendData:request withFlags:0];
        
        NSLog(@"Waiting for reply");
        NSData *reply = [requester receiveDataWithFlags:0];
        NSString *text = [[NSString alloc] initWithData:reply encoding:NSUTF8StringEncoding];
        NSLog(@"Received reply %@", text);
    [ctx closeSockets];
    [ctx terminate];
        return [@"tcp://192.168.20.12:" stringByAppendingString:text];
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
    
    -(CMMotionManager *)manager
    {
        if (!_manager) {
            _manager = [[CMMotionManager alloc] init];
        }
        return _manager;
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
