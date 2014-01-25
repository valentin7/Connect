//
//  iPhone OAuth Starter Kit
//
//  Supported providers: LinkedIn (OAuth 1.0a)
//
//  Lee Whitney
//  http://whitneyland.com
//

#import <Foundation/NSNotificationQueue.h>
#import "ProfileTabView.h"
#import "UIImage+Resize.h"
#import "ProfileCell.h"
#import "BTIUser.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "UIImageView+AFNetworking.h"

@implementation ProfileTabView
{
    UIImage *linkedInImage;
    NSString *avatarURL;
    BTIUser *currentUser;
}

@synthesize button, name, headline, oAuthLoginView, 
            status, postButton, postButtonLabel,
            statusTextView, updateStatusLabel;

- (IBAction)button_TouchUp:(UIButton *)sender
{    
    oAuthLoginView = [[OAuthLoginView alloc] initWithNibName:nil bundle:nil];
 
    // register to be told when the login is finished
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(loginViewDidFinish:) 
                                                 name:@"loginViewDidFinish" 
                                               object:oAuthLoginView];
    
    [self presentViewController:oAuthLoginView animated:YES completion:nil];
}


-(void) loginViewDidFinish:(NSNotification*)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // We're going to do these calls serially just for easy code reading.
    // They can be done asynchronously
    // Get the profile, then the network updates
    [self profileImageApiCall];
	
}

- (void)profileImageApiCall
{
    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people/~/picture-urls::(original)"];
    
    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:oAuthLoginView.consumer
                                       token:oAuthLoginView.accessToken
                                    callback:nil
                           signatureProvider:nil];
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(profileImageApiCallResult:didFinish:)
                  didFailSelector:@selector(profileImageApiCallResult:didFail:)];
    
}

- (void)profileImageApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    
    NSDictionary *profile = [responseBody objectFromJSONString];
    
    if ( profile )
    {
        self.button.hidden = YES;
        self.collectionView.hidden = NO;
        NSArray *imageArray = [profile objectForKey:@"values"];
        
        NSString *url = [imageArray objectAtIndex:0];
        avatarURL = url;
        
        NSURL *imageURL = [NSURL URLWithString:url];
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:imageURL];
        UIImage *image = [UIImage imageWithData:imageData];
        UIImage *resizedImage = [image resizedImageToWidth:132 andHeight:132];
        
        linkedInImage = resizedImage;
        
        // fetch all users over the same network
        [BTIUser findUsersPresentOn:[[self fetchSSIDInfo] objectForKey:@"SSID"] inBackgroundWithBlock:^(NSSet *users, NSError *error) {
            [BTIUser getCurrentUserInBackgroundWithBlock:^(BTIUser *user, NSError *error) {
                currentUser = user;
                NSMutableSet *mutableUsers = [NSMutableSet setWithSet:users];
                
                // Don't display myself...  :)
                BTIUser *userToRemove;
                if (currentUser != nil) {
                    for (BTIUser *user in mutableUsers) {
                        if ([user.objectId isEqualToString:currentUser.objectId]) {
                            userToRemove = user;
                        }
                    }
                    [mutableUsers removeObject:userToRemove];
                }
                
                self.usersOutThere = [[NSMutableArray alloc] initWithArray:[mutableUsers allObjects]];
                
                /*
                NSMutableArray *mutableArray = [self updateUsersAlgorithm];
                for (NSDictionary *dict in mutableArray) {
                    for (NSString* key in [dict allKeys]) {
                        NSLog(@"key: %@, value: %@", key, [dict objectForKey:key]);
                    }
                }
                 */
                
                // Add MBProgressHUD as indicator!
                MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
                
                HUD.delegate = self;
                HUD.labelText = @"Loading...";
                
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                    // Do something...
                    [self loadImagesIntoArray];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        [self.collectionView reloadData];
                    });
                });
                
            }];
            
        }];
        
        [self.imageView setImage:resizedImage];
        self.imageView.layer.cornerRadius = 33;
        self.imageView.layer.masksToBounds = YES;
    }
    
    // The next thing we want to do is call the network updates
    [self profileApiCall];
    
}

- (void)profileApiCall
{
    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people/~"];
    
    OAMutableURLRequest *request = 
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:oAuthLoginView.consumer
                                       token:oAuthLoginView.accessToken
                                    callback:nil
                           signatureProvider:nil];
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(profileApiCallResult:didFinish:)
                  didFailSelector:@selector(profileApiCallResult:didFail:)];    
    
}

- (void)profileApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data 
{
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    
    NSDictionary *profile = [responseBody objectFromJSONString];

    if ( profile )
    {
        name.text = [[NSString alloc] initWithFormat:@"%@ %@",
                     [profile objectForKey:@"firstName"], [profile objectForKey:@"lastName"]];
        headline.text = [profile objectForKey:@"headline"];
        
        self.navigationItem.leftBarButtonItem = self.logoutButton;
        
        if ([BTIUser hasCurrentUser]) {
            [BTIUser getCurrentUserInBackgroundWithBlock:^(BTIUser *user, NSError *error) {
                
                self.status.text = user.keywords[0];
                
                self.addInterestsButton.hidden = [[self.status.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0 ? NO : YES;
                self.editInterestsButton.hidden = !self.addInterestsButton.hidden;
                
                [user registerMyPresenceOn:[[self fetchSSIDInfo] objectForKey:@"SSID"]];
            }];
        } else {
            // Register current user's presence on Network with SSID
            BTIUser *user = [BTIUser object];
            user.name = name.text;
            user.title = headline.text;
            user.avatarURL = avatarURL;
            
            self.status.text = user.keywords[0];
            
            self.addInterestsButton.hidden = [[self.status.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0 ? NO : YES;
            self.editInterestsButton.hidden = !self.addInterestsButton.hidden;
            
            [user saveAsCurrentUserInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [user registerMyPresenceOn:[[self fetchSSIDInfo] objectForKey:@"SSID"]];
            }];
        }
    }
    
    // The next thing we want to do is to retrieve the profile image
    [self networkApiCall];
}

- (void)loadImagesIntoArray
{
    for (BTIUser *user in self.usersOutThere) {
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:user.avatarURL]];
        UIImage *image = [UIImage imageWithData:imageData];
        if (image != nil) {
            [self.userImages addObject:image];
        } else {
            [self.userImages addObject:linkedInImage];
        }
    }
}

- (void)profileImageApiCallResult:(OAServiceTicket *)ticket didFail:(NSData *)error
{
    NSLog(@"%@",[error description]);
}

- (void)networkApiCall
{
    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people/~/network/updates?scope=self&count=1&type=STAT"];
    OAMutableURLRequest *request = 
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:oAuthLoginView.consumer
                                       token:oAuthLoginView.accessToken
                                    callback:nil
                           signatureProvider:nil];
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(networkApiCallResult:didFinish:)
                  didFailSelector:@selector(networkApiCallResult:didFail:)];    
    
}

- (IBAction)editKeywords:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Edit Your Interests"
                                                    message:nil delegate: self cancelButtonTitle:@"Cancel" otherButtonTitles:
                          @"Done",nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alertView textFieldAtIndex:0];
     
    textField.text = self.status.text;
    [alertView show];
    

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        
        // do nothing...
        
    } else if (buttonIndex == 1) {
        
        // update keywords
        NSString *currentKeyword = [alertView textFieldAtIndex:0].text;
        NSMutableArray *mutableKeywords = [[NSMutableArray alloc] initWithArray:[currentUser.keywords mutableCopy]];
        
        if ([mutableKeywords count] > 0) {
            [mutableKeywords replaceObjectAtIndex:0 withObject:currentKeyword];
        } else {
            [mutableKeywords addObject:currentKeyword];
        }
        
        [BTIUser getCurrentUserInBackgroundWithBlock:^(BTIUser *user, NSError *error) {
            currentUser = user;
        }];
        
        currentUser.keywords = mutableKeywords;
        [currentUser saveAsCurrentUserInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            // do nothing
            self.status.text = currentKeyword;
            self.addInterestsButton.hidden = [[self.status.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0 ? NO : YES;
            self.editInterestsButton.hidden = !self.addInterestsButton.hidden;
            
            [self updateUsersAlgorithm];
            
            /*
            for (NSDictionary *dict in mutableArray) {
                for (NSString* key in [dict allKeys]) {
                    NSLog(@"key: %@, value: %@", key, [dict objectForKey:key]);
                }
            }
             */
            
        }];
        
    }
}

- (void)networkApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data 
{
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    
    NSDictionary *person = [[[[[responseBody objectFromJSONString] 
                                objectForKey:@"values"] 
                                    objectAtIndex:0]
                                        objectForKey:@"updateContent"]
                                            objectForKey:@"person"];
    
    if ( [person objectForKey:@"currentStatus"] )
    {
        [postButton setHidden:false];
        [postButtonLabel setHidden:false];
        [statusTextView setHidden:false];
        [updateStatusLabel setHidden:false];
        
        // status.text = [person objectForKey:@"currentStatus"];
    
    } else {
        [postButton setHidden:false];
        [postButtonLabel setHidden:false];
        [statusTextView setHidden:false];
        [updateStatusLabel setHidden:false];
        
        /*
        status.text = [[[[person objectForKey:@"personActivities"]
                            objectForKey:@"values"]
                                objectAtIndex:0]
                                    objectForKey:@"body"];
         */
    }
        
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)networkApiCallResult:(OAServiceTicket *)ticket didFail:(NSData *)error 
{
    NSLog(@"%@",[error description]);
}

- (IBAction)postButton_TouchUp:(UIButton *)sender
{    
    [statusTextView resignFirstResponder];
    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people/~/shares"];
    OAMutableURLRequest *request = 
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:oAuthLoginView.consumer
                                       token:oAuthLoginView.accessToken
                                    callback:nil
                           signatureProvider:nil];
    
    NSDictionary *update = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] 
                             initWithObjectsAndKeys:
                             @"anyone",@"code",nil], @"visibility", 
                            statusTextView.text, @"comment", nil];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *updateString = [update JSONString];
    
    [request setHTTPBodyWithString:updateString];
	[request setHTTPMethod:@"POST"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(postUpdateApiCallResult:didFinish:)
                  didFailSelector:@selector(postUpdateApiCallResult:didFail:)];    
}

- (void)postUpdateApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data 
{
    // The next thing we want to do is call the network updates
    [self networkApiCall];
}

- (void)postUpdateApiCallResult:(OAServiceTicket *)ticket didFail:(NSData *)error 
{
    NSLog(@"%@",[error description]);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = nil;
    
    self.collectionView.hidden = YES;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.userImages = [[NSMutableArray alloc] initWithCapacity:10];
    
    self.addInterestsButton.hidden = YES;
    self.editInterestsButton.hidden = YES;

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UICollectionView Datasource

// 1
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return [self.usersOutThere count];
}

// 2
- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

// 3
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ProfileCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ProfileCell" forIndexPath:indexPath];
    
    BTIUser *user = [self.usersOutThere objectAtIndex:indexPath.row];
    
    [cell.profileImageView setImage:[self.userImages objectAtIndex:indexPath.row]];
    
    cell.profileImageView.layer.cornerRadius = 4.0f;
    cell.profileImageView.layer.masksToBounds = YES;
    cell.nameLabel.text = user.name;
    cell.titleLabel.text = user.title;
    cell.keywordsLabel.text = user.keywords[0];
    ///[cell.keywordsLabel sizeToFit];
    cell.keywordsLabel.textAlignment = NSTextAlignmentCenter;
    cell.backgroundColor = [UIColor lightGrayColor];
    return cell;

}

#pragma mark – UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(2.5, 5, 2.5, 5);
}

- (id)fetchSSIDInfo {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    NSLog(@"Supported interfaces: %@", ifs);
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%@ => %@", ifnam, info);
        if (info && [info count]) { break; }
    }
    return info;
}

- (void) updateUsersAlgorithm
{
    [BTIUser getCurrentUserInBackgroundWithBlock:^(BTIUser *user, NSError *error) {
        currentUser = user;
        NSString *currentUserKeywords = currentUser.keywords[0];
        NSMutableArray *dictArray = [self getRankingDictArray:currentUserKeywords];
        for (NSDictionary *dict in dictArray) {
            for (NSString* key in [dict allKeys]) {
                NSLog(@"key: %@, value: %@", key, [dict objectForKey:key]);
            }
        }
    }];
}

- (NSMutableArray *)getRankingDictArray:(NSString *)keywords
{
    NSMutableArray *dictArray = [[NSMutableArray alloc] init];
    NSArray *currentUserKeywordsArray = [self stringToArray:keywords];
    NSLog(@"current user keywords array: %@", currentUserKeywordsArray);
    for (BTIUser *user in self.usersOutThere) {
        NSMutableDictionary *userRankingDict = [[NSMutableDictionary alloc] init];
        [userRankingDict setObject:[NSNumber numberWithInt:0] forKey:user.objectId];
        NSArray *userKeywordsArray = [self stringToArray:user.keywords[0]];
        NSLog(@"user keywords array: %@", userKeywordsArray);
        for (NSString *keywordStr in userKeywordsArray) {
            
            for (NSString *currentUserKeywordStr in currentUserKeywordsArray) {
                BOOL identicalStrFound = [currentUserKeywordStr isEqualToString:keywordStr];
                if (identicalStrFound) {
                    [userRankingDict setObject:[NSNumber numberWithInt:[[userRankingDict objectForKey:user.objectId] integerValue] + 1] forKey:user.objectId];
                }
            }
        }
        [dictArray addObject:userRankingDict];
    }
    return dictArray;
}

- (NSMutableArray *)stringToArray:(NSString *)keywords
{
    NSArray *keywordsArray = [keywords componentsSeparatedByString:@","];
    NSMutableArray *trimmedKeywordsArray = [[NSMutableArray alloc] initWithArray:keywordsArray];
    for (NSString *keyword in keywordsArray) {
        [trimmedKeywordsArray replaceObjectAtIndex:[keywordsArray indexOfObject:keyword] withObject:[keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
    return trimmedKeywordsArray;
}

@end
