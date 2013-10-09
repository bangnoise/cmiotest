//
//  cmiotestAppDelegate.m
//  cmiotest
//
//  Created by Tom Butterworth on 30/08/2011.
//  Copyright 2011 Tom Butterworth. All rights reserved.
//

#import "cmiotestAppDelegate.h"
#import <CoreMedia/CoreMedia.h>

static void _describeCMIOObject(CMIOObjectID object, unsigned int depth, BOOL useShortDescription)
{
    if (useShortDescription)
    {
        CMIOObjectShow(object);
    }
    else
    {
        UInt32 dataSize;
        OSStatus result;
        
        char tab[depth + 1];
        for (unsigned int i = 0; i < (depth * 4); i++) {
            tab[i] = ' ';
        }
        tab[depth] = 0U;
            
        CMIOObjectPropertyAddress opa = {kCMIOObjectPropertyClass, kCMIOObjectPropertyScopeGlobal, 0};

        CMIOClassID classID = 0;
        
        CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(CMIOClassID), &dataSize, &classID);
        
        char *className;
        switch (classID) {
            case kCMIODeviceClassID:
                className = "kCMIODeviceClassID";
                break;
            case kCMIOPlugInClassID:
                className = "kCMIOPlugInClassID";
                break;
            case kCMIOStreamClassID:
                className = "kCMIOStreamClassID";
                break;
            case kCMIOGammaControlClassID:
                className = "kCMIOGammaControlClassID";
                break;
            case kCMIOSaturationControlClassID:
                className = "kCMIOSaturationControlClassID";
                break;
            case kCMIOSharpnessControlClassID:
                className = "kCMIOSharpnessControlClassID";
                break;
            case kCMIOExposureControlClassID:
                className = "kCMIOExposureControlClassID";
                break;
            default:
                className = NULL;
                break;
        }
        printf("%sobject ID:%u class:%s (%u)\n", tab, object, className, classID);
        
        if (classID == kCMIOStreamClassID)
        {
            opa.mSelector = kCMIOStreamPropertyFormatDescriptions;
            CFArrayRef streamDescriptions = NULL;
            if (CMIOObjectHasProperty(object, &opa))
            {
                result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(CFArrayRef), &dataSize, &streamDescriptions);
                if (result != 0)
                {
                    printf("%sError in CMIOObjectGetPropertyData for stream\n", tab);
                    return;
                }
            }
            else
            {
                opa.mSelector = kCMIOStreamPropertyFormatDescription;
                if (CMIOObjectHasProperty(object, &opa))
                {
                    CMFormatDescriptionRef description;
                    result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(CMFormatDescriptionRef), &dataSize, &description);
                    if (result != 0)
                    {
                        printf("%sError in CMIOObjectGetPropertyData for stream\n", tab);
                        return;
                    }
                    streamDescriptions = CFArrayCreate(kCFAllocatorDefault, (const void **)&description, 1, &kCFTypeArrayCallBacks);
                }
            }
            if (streamDescriptions != NULL)
            {
                CFShow(streamDescriptions);
                CFRelease(streamDescriptions);
            }
            opa.mSelector = kCMIOStreamPropertyClock;
            CFTypeRef clock = NULL;
            if (CMIOObjectHasProperty(object, &opa))
            {
                result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(CFTypeRef), &dataSize, &clock);
                if (result != 0)
                {
                    printf("%sError in CMIOObjectGetPropertyData\n", tab);
                    return;
                }
            }
            if (clock)
            {
                printf("%sStream has clock\n", tab);
                CFRelease(clock);
            }
            else
            {
                printf("%sStream has no clock\n", tab);
            }
            opa.mSelector = kCMIOStreamPropertyTerminalType;
            if (CMIOObjectHasProperty(object, &opa))
            {
                UInt32 type;
                result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(UInt32), &dataSize, &type);
                printf("%sStream terminal type 0x%x\n", tab, type);
            }
            else
            {
                printf("%sStream has no terminal type property\n", tab);
            }
            opa.mSelector = kCMIOStreamPropertyStartingChannel;
            if (CMIOObjectHasProperty(object, &opa))
            {
                UInt32 channel;
                result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(UInt32), &dataSize, &channel);
                printf("%sStream starting channel %u\n", tab, channel);
            }
            else
            {
                printf("%sStream has no starting channel property\n", tab);
            }
        }
        opa.mSelector = kCMIOObjectPropertyOwnedObjects;
        
        UInt32 objectCount = 0;
        
        if (CMIOObjectHasProperty(object, &opa))
        {
            printf("\n");
            result = CMIOObjectGetPropertyDataSize(object, &opa, 0, NULL, &dataSize);
            if (result != 0)
            {
                printf("%sunexpected result for object ID %u: %u (%x)\n", tab, object, result, result);
                return;
            }
            objectCount = dataSize / sizeof(CMIOObjectID);
            CMIOObjectID children[objectCount * 2];
            result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, dataSize * 2, &dataSize, children);
            if (result != 0)
            {
                printf("%sunexpected result for object ID %u: %u (%x) %s\n", tab, object, result, result, GetMacOSStatusErrorString(result));
                return;
            }
            
            objectCount = dataSize / sizeof(CMIOObjectID); // Maybe the count changed
            
            for (int i = 0; i < objectCount; i++) {
                _describeCMIOObject(children[i], depth+1, useShortDescription);
            }
        }
    }
}

static void describeCMIOObject(CMIOObjectID object, BOOL useShortDescription)
{
    _describeCMIOObject(object, 0, useShortDescription);
}

static void handleStreamQueueAltered(CMIOStreamID streamID, void* token, void* refCon)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CMSimpleQueueRef q = ((cmiotestAppDelegate *)refCon).queue;
    CMSampleBufferRef buffer = (CMSampleBufferRef)CMSimpleQueueDequeue(q);
    if (buffer)
    {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(buffer);
        if (pixelBuffer)
        {
            /*
             This is a terrible way to display video, don't do it in a real app
             */
            CIImage *cii = [CIImage imageWithCVImageBuffer:pixelBuffer];
            NSBitmapImageRep *bir = [[[NSBitmapImageRep alloc] initWithCIImage:cii] autorelease];
            NSImage *i = [[[NSImage alloc] init] autorelease];
            [i addRepresentation:bir];
            ((cmiotestAppDelegate *)refCon).image = i;
        }
        CFRelease(buffer);
    } 
    [pool drain];
}

@implementation cmiotestAppDelegate

@synthesize window, selectedDevice, queue, image;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    OSStatus result;
    /*
     Discover all available CMIO devices
     */
    UInt32 dataUsed = 0;
    CMIOObjectPropertyAddress opa = {kCMIOHardwarePropertyDevices, kCMIOObjectPropertyScopeGlobal, kCMIOObjectPropertyElementMaster};
    
    /*
     A device could conceivably be attached between our calls to query the property size
     and query the property, so be prepared for the second call to fail because dataSize
     would be wrong in that case.
     */
    
    UInt32 dataSize = 0;
    CMIOObjectID *devices = NULL;
    
    do {
        /*
         First get the property size to determine how many devices are available
         */
        result = CMIOObjectGetPropertyDataSize(kCMIOObjectSystemObject, &opa, 0, NULL, &dataSize);
        
        /*
         Allocate the required amount of memory to store the device array
         */
        free(devices);
        devices = malloc(dataSize);
        
        /*
         Query the property. If this fails because the size was wrong (due to the arrival of a new device)
         we will perform the loop again.
         */
        result = CMIOObjectGetPropertyData(kCMIOObjectSystemObject, &opa, 0, NULL, dataSize, &dataUsed, devices);
        
    } while (result == kCMIOHardwareBadPropertySizeError);
    
    
    for (int i = 0; i < dataSize / sizeof(CMIOObjectID); i++) {
        printf("-------------------------------\n");
        /*
         Pass YES as last argument for a much briefer description
         */
        describeCMIOObject(devices[i], NO);
        printf("-------------------------------\n");
    }
    
    self.selectedDevice = devices[0];
    
    [self start];
    
    free(devices);
}

- (void)start
{
    CMIODeviceID device = self.selectedDevice;
    OSStatus result;
    UInt32 dataSize = 0;
    
    /*
     We query the device name to log it
     */
    CMIOObjectPropertyAddress opa = {
        kCMIOObjectPropertyName,
        kCMIOObjectPropertyScopeGlobal,
        kCMIOObjectPropertyElementMaster
    };
    
    CFStringRef name = NULL;
    result = CMIOObjectGetPropertyData(device, &opa, 0, NULL, sizeof(CFStringRef), &dataSize, &name);
    if (result == 0 && name) {
        NSLog(@"Starting session for %@", name);
        CFRelease(name);
    }

    /*
     Now query the size of the kCMIODevicePropertyStreams property to determine
     the number of streams
     */
    opa.mSelector = kCMIODevicePropertyStreams;
    opa.mScope = kCMIODevicePropertyScopeInput;
    
    result = CMIOObjectGetPropertyDataSize(device, &opa, 0, NULL, &dataSize);
    
    /*
     Create appropriately sized storage to request the list of streams
     */
    CMIOStreamID streams[dataSize / sizeof(CMIOStreamID)];
    
    /*
     Query the kCMIODevicePropertyStreams property with our storage
     */
    result = CMIOObjectGetPropertyData(device, &opa, 0, NULL, dataSize, &dataSize, streams);
    
    /*
     Normally at this stage you would want to check if kCMIOStreamPropertyFormatDescription is settable
     for the stream, and if so, set it to one of the entries returned from the stream's
     kCMIOStreamPropertyFormatDescriptions property to suit your needs
     */
    
    /*
     Copy a buffer queue for the first stream, passing our function to receive events on the queue
     */
    CMSimpleQueueRef q;
    result = CMIOStreamCopyBufferQueue(streams[0], handleStreamQueueAltered, self, &q);
    
    /*
     We simply copy the queue and never release it, but normally you would want to release it when you are
     done with it
     */
    self.queue = q;
    
    /*
     Start the stream (for eternity, in our case)
     */
    result = CMIODeviceStartStream(device, streams[0]);
}
@end
