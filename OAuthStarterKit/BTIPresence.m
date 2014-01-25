//
//  BTIPresence.m
//  NetworkInterface
//
//  Created by Dan Spinosa on 1/24/14.
//  Copyright (c) 2014 Dan Spinosa. All rights reserved.
//

#import "BTIPresence.h"
#import <Parse/PFObject+Subclass.h>

@implementation BTIPresence

+ (NSDate *)validIfUpdatedAfter
{
    //presence
    return [NSDate dateWithTimeIntervalSinceNow:-60*1000];
}

#pragma mark - Parse stuff

@dynamic user;
@dynamic networkSSID;

+ (NSString *)parseClassName
{
    static NSString *className = @"BTIPresence";
    return className;
}

@end
