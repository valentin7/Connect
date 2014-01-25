//
//  OAuthStarterKitAppDelegate.m
//  OAuthStarterKit
//
//  Created by Christina Whitney on 4/11/11.
//  Copyright 2011 self. All rights reserved.
//

#import "OAuthStarterKitAppDelegate.h"
#import "ProfileTabView.h"
#import <Parse/Parse.h>
#import "BTIUser.h"
#import "BTIPresence.h"

@implementation OAuthStarterKitAppDelegate


@synthesize window=_window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupParseWithLaunchOptions:launchOptions];
    
    return YES;
}

- (void)setupParseWithLaunchOptions:(NSDictionary *)launchOptions
{
    [BTIUser registerSubclass];
    [BTIPresence registerSubclass];
    [Parse setApplicationId:@"6QTvjj4OBiY7bfMPt9AZUlqpddF4rAwW3PSlupIs"
                  clientKey:@"czIGDRrfEaEM1xx7TG1nsIGfkfFCKacqLbbb7sN7"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
