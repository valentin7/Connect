//
//  main.m
//  OAuthStarterKit
//
//  Created by Christina Whitney on 4/11/11.
//  Copyright 2011 self. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAuthStarterKitAppDelegate.h"

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([OAuthStarterKitAppDelegate class]));
    [pool release];
    return retVal;
}
