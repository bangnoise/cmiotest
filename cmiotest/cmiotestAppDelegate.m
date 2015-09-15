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
        tab[depth * 4] = 0U;
            
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
                className = "?";
                break;
        }
        const char *objectName = "";
        CFStringRef name = NULL;
        opa.mSelector = kCMIOObjectPropertyName;
        if (CMIOObjectHasProperty(object, &opa))
        {
            result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(name), &dataSize, &name);
            if (result == 0)
                objectName = CFStringGetCStringPtr(name, kCFStringEncodingUTF8);
        }

        printf("%sobject ID:%u class:%s (%u) \"%s\"\n", tab, object, className, classID, objectName);
        if (name)
            CFRelease(name);

        if (classID == kCMIODeviceClassID)
        {
            opa.mSelector = kCMIODevicePropertyTransportType;
            if (CMIOObjectHasProperty(object, &opa))
            {
                UInt32 type;
                result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(UInt32), &dataSize, &type);
                printf("%sDevice transport type 0x%x\n", tab, type);
            }
            else
            {
                printf("%sDevice has no transport type property\n", tab);
            }
            opa.mSelector = kCMIODevicePropertyCanProcessAVCCommand;
            if (CMIOObjectHasProperty(object, &opa))
            {
                Boolean can;
                result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(Boolean), &dataSize, &can);
                printf("%sDevice %s process AVC commands\n", tab, can ? "CAN" : "can't");
            }
            else
            {
                printf("%sDevice has no kCMIODevicePropertyCanProcessAVCCommand property\n", tab);
            }
            opa.mSelector = kCMIODevicePropertyCanProcessRS422Command;
            if (CMIOObjectHasProperty(object, &opa))
            {
                Boolean can;
                result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(Boolean), &dataSize, &can);
                printf("%sDevice %s process RS422 commands\n", tab, can ? "CAN" : "can't");
            }
            else
            {
                printf("%sDevice has no kCMIODevicePropertyCanProcessRS422Command property\n", tab);
            }
            opa.mSelector = kCMIODevicePropertyDeviceMaster;
            if (CMIOObjectHasProperty(object, &opa))
            {
                Boolean isSettable;
                result = CMIOObjectIsPropertySettable(object, &opa, &isSettable);
                printf("%sDevice property %s settable for kCMIODevicePropertyDeviceMaster\n", tab, isSettable ? "IS" : "isn't");
            }
            else
            {
                printf("%sDevice has no kCMIODevicePropertyCanProcessRS422Command property\n", tab);
            }
            opa.mSelector = 'dord';
            printf("%sDevice %s mysterious 'dord' property\n", tab, CMIOObjectHasProperty(object, &opa) ? "HAS" : "hasn't");

            opa.mSelector = kCMIODevicePropertyStreams;
            opa.mScope = kCMIODevicePropertyScopeInput;
            if (CMIOObjectHasProperty(object, &opa))
            {
                result = CMIOObjectGetPropertyDataSize(object, &opa, 0, NULL, &dataSize);
                if (result == kCMIOHardwareNoError)
                {
                    int count = dataSize / sizeof(CMIOStreamID);
                    printf("%sDevice has %d input stream%s:", tab, count, count == 1 ? "" : "s");
                    CMIOStreamID streams[count];
                    CMIOObjectGetPropertyData(object, &opa, 0, NULL, dataSize, &dataSize, &streams);
                    for (int i = 0; i < count; i++) {
                        if (i != 0)
                            printf(",");
                        printf("%d", streams[i]);
                    }
                    printf("\n");
                }
            }
            else
            {
                printf("%sDevice has no input streams\n", tab);
            }
            opa.mScope = kCMIODevicePropertyScopeOutput;
            if (CMIOObjectHasProperty(object, &opa))
            {
                result = CMIOObjectGetPropertyDataSize(object, &opa, 0, NULL, &dataSize);
                if (result == kCMIOHardwareNoError)
                {
                    int count = dataSize / sizeof(CMIOStreamID);
                    printf("%sDevice has %d output stream%s:", tab, count, count == 1 ? "" : "s");
                    CMIOStreamID streams[count];
                    CMIOObjectGetPropertyData(object, &opa, 0, NULL, dataSize, &dataSize, &streams);
                    for (int i = 0; i < count; i++) {
                        if (i != 0)
                            printf(",");
                        printf("%d", streams[i]);
                    }
                    printf("\n");
                }
            }
            else
            {
                printf("%sDevice has no output streams\n", tab);
            }
            opa.mScope = kCMIOObjectPropertyScopeGlobal;
        }
        if (classID == kCMIOStreamClassID)
        {
            opa.mSelector = kCMIOStreamPropertyDirection;
            UInt32 direction;
            result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(UInt32), &dataSize, &direction);
            if (result != 0)
            {
                printf("%sError getting kCMIOStreamPropertyDirection for stream\n", tab);
                return;
            }
            printf("%sStream is %s\n", tab, direction == 0 ? "output" : "input");
            opa.mSelector = kCMIOStreamPropertyFormatDescriptions;
            CFArrayRef streamDescriptions = NULL;
            if (CMIOObjectHasProperty(object, &opa))
            {
                printf("%sStream offers multiple formats\n", tab);
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
                    printf("%sStream has fixed format\n", tab);
                    CMFormatDescriptionRef description;
                    result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(CMFormatDescriptionRef), &dataSize, &description);
                    if (result != 0)
                    {
                        printf("%sError in CMIOObjectGetPropertyData for stream\n", tab);
                        return;
                    }
                    streamDescriptions = CFArrayCreate(kCFAllocatorDefault, (const void **)&description, 1, &kCFTypeArrayCallBacks);
                    CFRelease(description);
                }
                else
                {
                    printf("%sStream has no formats??\n", tab);
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
            opa.mSelector = kCMIOStreamPropertyFrameRate;
            if (CMIOObjectHasProperty(object, &opa))
            {
                Float64 rate;
                result = CMIOObjectGetPropertyData(object, &opa, 0, NULL, sizeof(Float64), &dataSize, &rate);
                printf("%sStream frame rate %f\n", tab, rate);
            }
            else
            {
                printf("%sStream has no frame rate property\n", tab);
            }
            opa.mSelector = kCMIOStreamPropertyEndOfData;
            if (CMIOObjectHasProperty(object, &opa))
            {
                Boolean isSettable;
                result = CMIOObjectIsPropertySettable(object, &opa, &isSettable);
                printf("%sStream property %s settable for kCMIOStreamPropertyEndOfData\n", tab, isSettable ? "IS" : "isn't");
            }
            else
            {
                printf("%sStream has no property kCMIOStreamPropertyEndOfData\n", tab);
            }
            opa.mSelector = kCMIOStreamPropertyScheduledOutputNotificationProc;
            if (CMIOObjectHasProperty(object, &opa))
            {
                Boolean isSettable;
                result = CMIOObjectIsPropertySettable(object, &opa, &isSettable);
                printf("%sStream property %s settable for kCMIOStreamPropertyScheduledOutputNotificationProc\n", tab, isSettable ? "IS" : "isn't");
            }
            else
            {
                printf("%sStream has no property kCMIOStreamPropertyScheduledOutputNotificationProc\n", tab);
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
    /*
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CMSimpleQueueRef q = ((cmiotestAppDelegate *)refCon).queue;
    CMSampleBufferRef buffer = (CMSampleBufferRef)CMSimpleQueueDequeue(q);
    if (buffer)
    {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(buffer);
        if (pixelBuffer)
        {
     //This is a terrible way to display video, don't do it in a real app
            CIImage *cii = [CIImage imageWithCVImageBuffer:pixelBuffer];
            NSBitmapImageRep *bir = [[[NSBitmapImageRep alloc] initWithCIImage:cii] autorelease];
            NSImage *i = [[[NSImage alloc] init] autorelease];
            [i addRepresentation:bir];
            ((cmiotestAppDelegate *)refCon).image = i;
        }
        CFRelease(buffer);
    }
    [pool drain];
*/
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
