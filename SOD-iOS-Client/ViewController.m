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

@interface ViewController ()
    
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDictionary* requestData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"requestPort", @"requestType", @"extrainfo", @"additionalInfo", nil];
    NSError* error =  nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:requestData
                                                       options:NSJSONWritingPrettyPrinted error: &error];
    NSString* requestDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(requestDataString);

    
    ZMQContext *ctx = [[ZMQContext alloc] initWithIOThreads:1];
    
    NSString *endpoint = @"tcp://192.168.20.12:5570";
    ZMQSocket *requester = [ctx socketWithType:ZMQ_REQ];
    BOOL didConnect = [requester connectToEndpoint:endpoint];
    if (!didConnect) {
		NSLog(@"*** Failed to connect to endpoint [%@].", endpoint);
    }
    
    int kMaxRequest = 10;
	NSData *request = [requestDataString dataUsingEncoding:NSUTF8StringEncoding];
	for (int request_nbr = 0; request_nbr < kMaxRequest; ++request_nbr) {
        
        @autoreleasepool {
            
            NSLog(@"Sending request %d.", request_nbr);
            [requester sendData:request withFlags:0];
            
            NSLog(@"Waiting for reply");
            NSData *reply = [requester receiveDataWithFlags:0];
            NSString *text = [[NSString alloc] initWithData:reply encoding:NSUTF8StringEncoding];
            NSLog(@"Received reply %d: %@", request_nbr, text);
        }
        
	}
    
    
    [ctx closeSockets];
    [ctx terminate];
    
	// Do any additional setup after loading the view, typically from a nib.
}
    
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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