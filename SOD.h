//
//  SOD.h
//  SOD-iOS-Client
//
//  Created by ASE Group on 2014-05-14.
//  Copyright (c) 2014 ASE Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <src/socket.IO-objc-master/SocketIO.h>

@class SOD;

@interface SOD : NSObject{
    CMMotionManager *manager;
}

- (id) initWithDelegate:(id<SocketIODelegate>)delegate andAddress:(NSString*)address andPort:(int)port;
- (void) reconnectToServer;
- (void) calibrateDeviceAngle;
- (void) startMotionManager;
- (void) restartMotionManager;
- (NSString*) tryPairWithID:(NSString*) personID;
- (void) getDevicesWithSelection:(NSString*) selection withCallBack: (void(^)(id response))completionCB;
- (void) getAllTrackedPeoplewithCallBack: (void(^)(id response))completionCB;
- (NSString*) unpairEveryone;
- (void) setPairingState;
- (void) unpairDevice;
- (void) unpairAllDevices;
@property (nonatomic, strong) SocketIO *SocketIO;
@property float OffsetValue;
@property (nonatomic, strong) NSString* OwnerID;
@property (nonatomic, strong) CMMotionManager *Manager;
@property (nonatomic, strong) NSString *address;
@property int port;
@property float degrees;
@end
