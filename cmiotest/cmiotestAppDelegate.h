//
//  cmiotestAppDelegate.h
//  cmiotest
//
//  Created by Tom Butterworth on 30/08/2011.
//  Copyright 2011 Tom Butterworth. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreMediaIO/CMIOHardware.h>

@interface cmiotestAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    CMIODeviceID selectedDevice;
    CMSimpleQueueRef queue;
    NSImage *image;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) NSImage *image;
@property (assign) CMIODeviceID selectedDevice;
@property (assign) CMSimpleQueueRef queue;
- (void)start;
@end
