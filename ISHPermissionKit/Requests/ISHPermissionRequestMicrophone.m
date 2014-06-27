//
//  ISHPermissionRequestMicrophone.m
//  ISHPermissionKit
//
//  Created by Felix Lamouroux on 27.06.14.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import "ISHPermissionRequestMicrophone.h"
@import AVFoundation;

@implementation ISHPermissionRequestMicrophone

- (ISHPermissionState)permissionState {
    AVAudioSessionRecordPermission systemState = [[AVAudioSession sharedInstance] recordPermission];
    switch (systemState) {
        case AVAudioSessionRecordPermissionDenied:
            return ISHPermissionStateDenied;
        case AVAudioSessionRecordPermissionGranted:
            return ISHPermissionStateGranted;
        case AVAudioSessionRecordPermissionUndetermined:
            return [self internalPermissionState];
    }
}

- (void)requestUserPermissionWithCompletionBlock:(ISHPermissionRequestCompletionBlock)completion {
    NSAssert(completion, @"requestUserPermissionWithCompletionBlock requires a completion block");

    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(self, granted, nil);
        });
    }];
}

@end