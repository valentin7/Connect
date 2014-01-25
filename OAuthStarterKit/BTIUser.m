//
//  BTIUser.m
//  NetworkInterface
//
//  Created by Dan Spinosa on 1/24/14.
//  Copyright (c) 2014 Dan Spinosa. All rights reserved.
//

#import "BTIUser.h"
#import "BTIPresence.h"
#import <Parse/PFObject+Subclass.h>

static NSString *kUserDefaultsUserIDKey = @"parseUserID";

@implementation BTIUser

+ (void)findUsersPresentOn:(NSString *)networkSSID inBackgroundWithBlock:(void (^)(NSSet *users, NSError *error))block
{
    NSParameterAssert(networkSSID);
    NSParameterAssert(block);
    
    PFQuery *query = [BTIPresence query];
    [query whereKey:@"updatedAt" greaterThan:[BTIPresence validIfUpdatedAfter]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *presenceObjects, NSError *error) {
        NSMutableSet *userIDs = nil;
        if (presenceObjects) {
            userIDs = [NSMutableSet setWithCapacity:[presenceObjects count]];
            for (BTIPresence *presence in presenceObjects) {
                [userIDs addObject:presence.user.objectId];
            }
            PFQuery *userQuery = [BTIUser query];
            [userQuery whereKey:@"objectId" containedIn:[userIDs allObjects]];
            [userQuery findObjectsInBackgroundWithBlock:^(NSArray *userObjects, NSError *error) {
                //turned those presence objects into fully fetched user objects
                block([NSSet setWithArray:userObjects], error);
            }];
            
        } else {
            //no presence objects
            block(nil, error);
        }
    }];
}

+ (void)getCurrentUserInBackgroundWithBlock:(void (^)(BTIUser *user, NSError *error))block
{
    NSParameterAssert(block);
    
    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaultsUserIDKey];
    if (!userId) {
        block(nil, nil);
        return;
    }
    
    PFQuery *userQuery = [PFQuery queryWithClassName:[BTIUser parseClassName]];
    [userQuery getObjectInBackgroundWithId:userId block:^(PFObject *object, NSError *error) {
        block((BTIUser *)object, error);
    }];
}

+ (BOOL)hasCurrentUser
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaultsUserIDKey] != nil;
}

+ (void)forgetCurrentUser
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs removeObjectForKey:kUserDefaultsUserIDKey];
    [defs synchronize];
}

- (void)saveAsCurrentUserInBackgroundWithBlock:(void(^)(BOOL succeeded, NSError *error))block
{
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
            [defs setObject:self.objectId forKey:kUserDefaultsUserIDKey];
            [defs synchronize];
        }
        block(succeeded, error);
    }];
}

- (void)registerMyPresenceOn:(NSString *)networkSSID
{
    NSParameterAssert(networkSSID);
    
    // look for an existing, unexpired presence
    PFQuery *query = [BTIPresence query];
    [query whereKey:@"user" equalTo:self];
    [query whereKey:@"updatedAt" greaterThan:[BTIPresence validIfUpdatedAfter]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count] > 0) {
            //should only be one
            BTIPresence *presence = [objects firstObject];
            presence.networkSSID = networkSSID; // <-- parse considers object dirty even if no diff
            [presence saveInBackground];
        } else {
            //create a new presence
            BTIPresence *presence = [BTIPresence object];
            presence.networkSSID = networkSSID;
            presence.user = self;
            
            [presence saveInBackground];
        }
    }];
}

#pragma mark - Parse required stuff

@dynamic name;
@dynamic avatarURL;
@dynamic keywords;
@dynamic status;

+ (NSString *)parseClassName
{
    static NSString *className = @"BTIUser";
    return className;
}

@end
