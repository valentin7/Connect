//
//  BTIPresence.h
//  NetworkInterface
//
//  Created by Dan Spinosa on 1/24/14.
//  Copyright (c) 2014 Dan Spinosa. All rights reserved.
//

#import <Parse/Parse.h>
#import "BTIUser.h"

@interface BTIPresence : PFObject <PFSubclassing>

@property (strong) BTIUser *user;
@property (strong) NSString *networkSSID;

+ (NSDate *)validIfUpdatedAfter;

@end
