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

@interface ProfileTabView : UIViewController 
{
}

@property (nonatomic, retain) IBOutlet UIButton *button;
@property (nonatomic, retain) IBOutlet UITextField *name;
@property (nonatomic, retain) IBOutlet UITextField *headline;
@property (nonatomic, retain) OAuthLoginView *oAuthLoginView;


- (IBAction)button_TouchUp:(UIButton *)sender;


@end
