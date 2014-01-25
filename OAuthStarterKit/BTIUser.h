//
//  BTIUser.h
//  NetworkInterface
//
//  Created by Dan Spinosa on 1/24/14.
//  Copyright (c) 2014 Dan Spinosa. All rights reserved.
//

#import <Parse/Parse.h>

@interface BTIUser : PFObject <PFSubclassing>

@property (strong) NSString *name;
@property (strong) NSString *avatarURL;
@property (strong) NSArray *keywords;
@property (strong) NSString *title;

/* Get all the users who have recently been present on the given network SSID.
 *
 * @discussion Block returns an array of User objects, possibly empty.
 */
+ (void)findUsersPresentOn:(NSString *)networkSSID inBackgroundWithBlock:(void (^)(NSSet *users, NSError *error))block;

/* Get the current user object if one has been created.
 *
 * @discussion If a user has been created, fetches that user in the background and returns
 * them via the block.  If a user has never been created block is called with (nil, nil).
 * Use -hasCurrentUser to determine if a user has ever been created.
 */
+ (void)getCurrentUserInBackgroundWithBlock:(void (^)(BTIUser *user, NSError *error))block;

/*
 * @returns YES if a user has been created and saved, otherwise NO.
 */
+ (BOOL)hasCurrentUser;

/* Removes current user ID from device.
 *
 * @discussion Because user's don't have account, the forgotten user object is abandoned.
 */
+ (void)forgetCurrentUser;

/* Save this user as the current user for the app.
 *
 * @discussion This method will the set user returned by
 * +getCurrentUser...
 */
- (void)saveAsCurrentUserInBackgroundWithBlock:(void(^)(BOOL succeeded, NSError *error))block;

/* Sets this user as currently present on the given network.
 * Call this method regularly while user is active in the app.
 * Users who have not been active on a given network SSID will stop being returned after some
 * attrition time.
 */
- (void)registerMyPresenceOn:(NSString *)networkSSID;

@end
