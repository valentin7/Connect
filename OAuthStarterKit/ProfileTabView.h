//
//  iPhone OAuth Starter Kit
//
//  Supported providers: LinkedIn (OAuth 1.0a)
//
//  Lee Whitney
//  http://whitneyland.com
//

#import <UIKit/UIKit.h>
#import "OAuthLoginView.h"
#import "JSONKit.h"
#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"
#import "OATokenManager.h"
#import "MBProgressHUD.h"

@interface ProfileTabView : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIAlertViewDelegate, MBProgressHUDDelegate>

@property (retain, nonatomic) IBOutlet UICollectionView *collectionView;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *logoutButton;
@property (nonatomic, retain) IBOutlet UIButton *button;
@property (nonatomic, retain) IBOutlet UIButton *postButton;
@property (nonatomic, retain) IBOutlet UILabel *postButtonLabel;
@property (nonatomic, retain) IBOutlet UILabel *name;
@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UILabel *headline;
@property (nonatomic, retain) IBOutlet UILabel *status;
@property (nonatomic, retain) IBOutlet UILabel *updateStatusLabel;
@property (nonatomic, retain) IBOutlet UITextField *statusTextView;
@property (nonatomic, retain) OAuthLoginView *oAuthLoginView;
@property (nonatomic, strong) NSMutableArray *usersOutThere;
@property (nonatomic, strong) NSMutableArray *userImages;

- (IBAction)button_TouchUp:(UIButton *)sender;
- (void)profileApiCall;
- (void)networkApiCall;

- (IBAction)editKeywords:(id)sender;


@end
