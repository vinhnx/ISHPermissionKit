//
//  AppDelegate.m
//  PermissionsTestApp
//
//  Created by Felix Lamouroux on 25.06.14.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import "AppDelegate.h"
#import "SamplePermissionViewController.h"
#import <ISHPermissionKit/ISHPermissionKit.h>

@interface AppDelegate () <ISHPermissionsViewControllerDatasource>
        
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupWindow];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self presentPermissionsIfNeeded];
    });
    
    return YES;
}

- (void)presentPermissionsIfNeeded {
    NSArray *permissions = @[
                             @(ISHPermissionCategoryLocationWhenInUse),
                             @(ISHPermissionCategoryActivity),
                             @(ISHPermissionCategoryMicrophone),
                             @(ISHPermissionCategoryPhotoLibrary),
                             @(ISHPermissionCategoryPhotoCamera),
                             @(ISHPermissionCategoryNotificationLocal)
                             ];
    ISHPermissionsViewController *permissionsVC = [ISHPermissionsViewController permissionsViewControllerWithCategories:permissions];
    if (permissionsVC) {
        [permissionsVC setDataSource:self];
        [self.window.rootViewController presentViewController:permissionsVC animated:YES completion:nil];
    }
}

#pragma mark ISHPermissionsViewControllerDatasource

- (ISHPermissionRequestViewController *)permissionsViewController:(ISHPermissionsViewController *)vc requestViewControllerForCategory:(ISHPermissionCategory)category {
    return [SamplePermissionViewController new];
}

-(void)permissionsViewController:(ISHPermissionsViewController *)vc didConfigureRequest:(ISHPermissionRequest *)request {
#ifdef __IPHONE_8_0
    if (request.permissionCategory == ISHPermissionCategoryNotificationLocal) {
        // the demo app only requests permissions for badges
        UIUserNotificationSettings *setting = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge categories:nil];
        ISHPermissionRequestNotificationsLocal *localNotesRequest = (ISHPermissionRequestNotificationsLocal *)([request isKindOfClass:[ISHPermissionRequestNotificationsLocal class]] ? request : nil);
        [localNotesRequest setNoticationSettings:setting];
    }
#endif
}

#pragma mark Important for local Notifications
#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [[NSNotificationCenter defaultCenter] postNotificationName:ISHPermissionNotificationApplicationDidRegisterUserNotificationSettings
                                                        object:self];
}
#endif

#pragma mark Boiler plate

- (void)setupWindow {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    UIViewController *rootVC = [UIViewController new];
    [rootVC.view setBackgroundColor:[UIColor colorWithRed:0.400 green:0.800 blue:1.000 alpha:1.000]];
    [self.window setRootViewController:rootVC];
    [self.window makeKeyAndVisible];
}

@end
