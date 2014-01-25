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


@implementation ProfileTabView

@synthesize button, name, headline, oAuthLoginView;

- (IBAction)button_TouchUp:(UIButton *)sender
{    
    oAuthLoginView = [[OAuthLoginView alloc] initWithNibName:nil bundle:nil];
    [oAuthLoginView retain];
 
    // register to be told when the login is finished
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(loginViewDidFinish:) 
                                                 name:@"loginViewDidFinish" 
                                               object:oAuthLoginView];
    
    [self presentModalViewController:oAuthLoginView animated:YES];
}

-(void) loginViewDidFinish:(NSNotification*)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	NSDictionary *profile = [notification userInfo];
    if ( profile )
    {
        name.text = [[NSString alloc] initWithFormat:@"%@ %@",
                 [profile objectForKey:@"firstName"], [profile objectForKey:@"lastName"]];
        headline.text = [profile objectForKey:@"headline"];
    }
    [oAuthLoginView release];
    oAuthLoginView = nil;
}






- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
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

@end
