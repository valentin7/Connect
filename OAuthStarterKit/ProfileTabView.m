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

@implementation ProfileTabView
{
    UIImage *linkedInImage;
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
    
    //[self presentModalViewController:oAuthLoginView animated:YES];
    [self presentViewController:oAuthLoginView animated:YES completion:nil];
}


-(void) loginViewDidFinish:(NSNotification*)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // We're going to do these calls serially just for easy code reading.
    // They can be done asynchronously
    // Get the profile, then the network updates
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
        
        self.name.hidden = NO;
        self.headline.hidden = NO;
        self.navigationItem.leftBarButtonItem = self.logoutButton;
        self.button.hidden = YES;
        self.collectionView.hidden = NO;
        
        // Register current user's presence on Network with SSID
        BTIUser *user = [BTIUser object];
        user.name = name.text;
        user.status = headline.text;
        [user saveAsCurrentUser];
        NSLog(@"%@", [[self fetchSSIDInfo] objectForKey:@"SSID"]);
        sleep(3);
        [user registerMyPresenceOn:[[self fetchSSIDInfo] objectForKey:@"SSID"]];
        
    }
    
    // The next thing we want to do is to retrieve the profile image
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
        NSArray *imageArray = [profile objectForKey:@"values"];
        NSString *url = [imageArray objectAtIndex:0];
        NSURL *imageURL = [NSURL URLWithString:url];
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:imageURL];
        UIImage *image = [UIImage imageWithData:imageData];
        UIImage *resizedImage = [image resizedImageToWidth:132 andHeight:132];
        
        linkedInImage = resizedImage;
        [self.collectionView reloadData];
        
        [self.imageView setImage:resizedImage];
        self.imageView.layer.cornerRadius = 33;
        self.imageView.layer.masksToBounds = YES;
    }
    
    // The next thing we want to do is call the network updates
    [self networkApiCall];
    
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
        status.text = [person objectForKey:@"currentStatus"];
    } else {
        [postButton setHidden:false];
        [postButtonLabel setHidden:false];
        [statusTextView setHidden:false];
        [updateStatusLabel setHidden:false];
        status.text = [[[[person objectForKey:@"personActivities"] 
                            objectForKey:@"values"]
                                objectAtIndex:0]
                                    objectForKey:@"body"];
    }
    
    self.status.hidden = NO;
    
    //[self dismissModalViewControllerAnimated:YES];
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
    
    self.name.hidden = YES;
    self.headline.hidden = YES;
    self.status.hidden = YES;
    self.navigationItem.leftBarButtonItem = nil;
    
    self.collectionView.hidden = YES;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    //[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"ProfileCell"];
    
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
    return 4;
}
// 2
- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}
// 3
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ProfileCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ProfileCell" forIndexPath:indexPath];
    
    cell.nameLabel.text = @"Paul Wong";
    [cell.profileImageView setImage:linkedInImage];
    cell.profileImageView.layer.cornerRadius = 4.0f;
    cell.profileImageView.layer.masksToBounds = YES;
    cell.titleLabel.text = @"Student Again!";
    cell.keywordsLabel.text = @"Obj-C, Ruby on Rails Blah Blah Blah";
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

@end
