//
//  ISHPermissionsViewController.m
//  ISHPermissionKit
//
//  Created by Felix Lamouroux on 25.06.14.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import "ISHPermissionsViewController.h"
#import "ISHPermissionRequest+All.h"
#import "ISHPermissionRequestViewController+Private.h"

@interface ISHPermissionsViewController () <ISHPermissionRequestViewControllerDelegate>
@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic) NSArray *permissionCategories;
@property (nonatomic) NSArray *permissionRequests;
@property (nonatomic) ISHPermissionRequestViewController *currentViewController;
@end

@implementation ISHPermissionsViewController

+ (instancetype)permissionsViewControllerWithCategories:(NSArray *)categories {
    NSArray *requestableCategories = [self requestablePermissionsCategoriesFromArray:categories];
    
    if (!requestableCategories.count) {
        return nil;
    }
    
    ISHPermissionsViewController *vc = [ISHPermissionsViewController new];
    [vc setPermissionCategories:requestableCategories];
    
    return vc;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        [self setCurrentIndex:0];
        BOOL isIpad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        UIModalPresentationStyle phonePresentation = UIModalPresentationCurrentContext;
#ifdef __IPHONE_8_0
        if ([self respondsToSelector:@selector(presentationController)]) {
            // if built for and running on iOS8 use over presnetation context to use blurred background
            phonePresentation = UIModalPresentationOverCurrentContext;
        }
#endif
        [self setModalPresentationStyle:isIpad ? UIModalPresentationFormSheet:phonePresentation];
    }
    
    return self;
}

- (void)loadView {
    UIView *view = nil;
    
#ifdef __IPHONE_8_0
    if (NSClassFromString(@"UIVisualEffectView") && (self.modalPresentationStyle != UIModalPresentationFormSheet)) {
        view = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        [view setBounds:[[UIScreen mainScreen] bounds]];
        self.view = view;
    }
#endif
    
    if (!view) {
        [super loadView];
        [self.view setBackgroundColor:[UIColor blackColor]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSAssert(self.dataSource, @"Datasource should not be nil");
    
    [self setupRequests];
    
    // setup UI for first permission category:
    [self transitionToPermissionCategoryAtIndex:self.currentIndex];
}

- (void)setupRequests {
    BOOL datasourceConfigureRequests = [self.dataSource respondsToSelector:@selector(permissionsViewController:didConfigureRequest:)];
    NSMutableArray *requests = [NSMutableArray new];
    
    for (NSNumber *categoryObj in self.permissionCategories) {
        ISHPermissionCategory category = [categoryObj integerValue];
        ISHPermissionRequest *request = [ISHPermissionRequest requestForCategory:category];
        
        if (datasourceConfigureRequests) {
            [self.dataSource permissionsViewController:self didConfigureRequest:request];
        }
        
        [requests addObject:request];
    }
    
    [self setPermissionRequests:[NSArray arrayWithArray:requests]];
}

- (void)transitionToPermissionCategoryAtIndex:(NSUInteger)index {
    NSAssert(index < self.permissionCategories.count, @"Transition must lead to an index within bounds");
    
    ISHPermissionCategory category = [self categoryAtIndex:index];
    
    // retrieve view controller for permissions request from data source
    ISHPermissionRequestViewController *newVC = [self.dataSource permissionsViewController:self requestViewControllerForCategory:category];
    NSAssert(newVC, @"Datasource should return an instance of ISHPermissionRequestViewController in -permissionsViewController:requestViewControllerForCategory:");
    
    // configure request view controller
    [newVC setPermissionDelegate:self];
    [newVC setPermissionCategory:category];
    [newVC setPermissionRequest:[self requestAtIndex:index]];
    
    [self transitionFromViewController:self.currentViewController toViewController:newVC];
}

- (ISHPermissionCategory)categoryAtIndex:(NSUInteger)index {
    return [[self.permissionCategories objectAtIndex:index] integerValue];
}

- (ISHPermissionRequest *)requestAtIndex:(NSUInteger)index {
    if (index >= self.permissionRequests.count) {
        return nil;
    }
    
    return [self.permissionRequests objectAtIndex:index];
}

+ (NSArray *)requestablePermissionsCategoriesFromArray:(NSArray *)neededCategories {
    NSMutableArray *requestable = [NSMutableArray arrayWithCapacity:neededCategories.count];
    
    for (NSNumber *categoryObj in neededCategories) {
        ISHPermissionCategory category = [categoryObj integerValue];
        ISHPermissionRequest *request = [ISHPermissionRequest requestForCategory:category];
        ISHPermissionState state = [request permissionState];
        
        switch (state) {
            case ISHPermissionStateUnknown :
            case ISHPermissionStateAskAgain:
                [requestable addObject:categoryObj];
                break;
                
            default:
                break;
        }
    }
    
    return [requestable copy];
}

#pragma mark - ISHPermissionRequestViewControllerDelegate
- (void)permissionRequestViewController:(ISHPermissionRequestViewController *)vc didCompleteWithState:(ISHPermissionState)state {
    NSUInteger nextIndex = self.currentIndex + 1;
    
    if (nextIndex == self.permissionCategories.count) {
        [self.delegate permissionsViewControllerDidComplete:self];
        
        if (!self.delegate) {
            [self dismissViewControllerAnimated:YES completion:self.completionBlock];
        } else if (self.completionBlock) {
            self.completionBlock();
        }
    } else {
        [self transitionToPermissionCategoryAtIndex:nextIndex];
        [self setCurrentIndex:self.currentIndex + 1];
    }
}

#pragma mark -
#pragma mark - UIViewController Containment

- (void)transitionFromViewController:(ISHPermissionRequestViewController *)fromViewController toViewController:(ISHPermissionRequestViewController *)toViewController  {
    [self beginTransitionFromViewController:fromViewController toViewController:toViewController];
    
    if (fromViewController) {
        [toViewController.view setTransform:CGAffineTransformMakeScale(0.8, 0.8)];
        [self transitionFromViewController:fromViewController
                          toViewController:toViewController
                                  duration:0.5
                                   options:UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveEaseInOut
                                animations:^{
                                    [self.view bringSubviewToFront:fromViewController.view];
                                    [toViewController.view setTransform:CGAffineTransformIdentity];
                                    [fromViewController.view setTransform:CGAffineTransformMakeTranslation(0, fromViewController.view.bounds.size.height)];
                                }
         
                                completion:^(BOOL finished) {
                                    if (finished) {
                                        [self completedTransitionFromViewController:fromViewController toViewController:toViewController];
                                    }
                                }];
    } else {
        [[self view] addSubview:toViewController.view];
        [toViewController.view setFrame:self.view.bounds];
        [self completedTransitionFromViewController:nil toViewController:toViewController];
    }
}

- (void)beginTransitionFromViewController:(ISHPermissionRequestViewController *)fromViewController toViewController:(ISHPermissionRequestViewController *)toViewController {
    [self addChildViewController:toViewController];
    [fromViewController willMoveToParentViewController:nil];
}

- (void)completedTransitionFromViewController:(ISHPermissionRequestViewController *)fromViewController toViewController:(ISHPermissionRequestViewController *)toViewController {
    [toViewController didMoveToParentViewController:self];
    [fromViewController.view removeFromSuperview];
    [fromViewController removeFromParentViewController];
    [self setCurrentViewController:toViewController];
}

@end
