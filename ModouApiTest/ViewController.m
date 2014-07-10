//
//  ViewController.m
//  ModouApiTest
//
//  Created by 孔祥波 on 14-7-10.
//  Copyright (c) 2014年 Kong XiangBo. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+ImageEffects.h"
#import "LYBDiscoverService.h"
#import "DetailViewController.h"
@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *backgroundView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView *imageView=[[UIImageView alloc] initWithFrame:self.view.bounds];
    UIImage *image=[UIImage imageNamed:@"services_default_bg"];
    
    imageView.contentMode = UIViewContentModeCenter;
    self.title = @"登录魔豆WIFI";
    self.backgroundView.image= [image applyLightEffect];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kFoundModouNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        self.LoginButton.enabled = YES;
        NSDictionary *info=[note userInfo];
        NSString *host=[NSString stringWithFormat:@"http://%@",[info objectForKey:@"ip"]];
        NSURL *url=[NSURL URLWithString:host];
        AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:url];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
        self.manager = manager;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    [[LYBDiscoverService sharedService] rescan];
   
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doLogin:(id)sender {
    NSDictionary *params = @{ @"password": self.passwordField.text };

    [self.manager POST:@"api/auth/login" parameters:params success:^(AFHTTPRequestOperation *operation, id value) {
        
        NSInteger code=[value[@"code"] intValue];
        if (code==0) {
            [self showDetail];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"%@",[error description]);
    }];
}
-(void)showDetail
{
    UIStoryboard *board=[UIStoryboard storyboardWithName:@"Main" bundle:nil] ;
    DetailViewController *vc = [board instantiateViewControllerWithIdentifier:@"DetailViewController"];
    vc.manager = self.manager;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark --
- (void)keyboardWillShow:(NSNotification *)notification
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_2
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
#endif
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_2
		NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
#else
		NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
#endif
		CGRect keyboardBounds;
		[keyboardBoundsValue getValue:&keyboardBounds];
		
		CGRect rect = self.view.frame;
        rect.origin.y -= keyboardBounds.size.height;
        self.view.frame = rect;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_2
	}
#endif
}
- (void)keyboardWillHidden:(NSNotification *)notification
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_2
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
#endif
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_2
		NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
#else
		NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
#endif
		CGRect keyboardBounds;
		[keyboardBoundsValue getValue:&keyboardBounds];
		
		CGRect rect = self.view.frame;
        rect.origin.y += keyboardBounds.size.height;
        self.view.frame = rect;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_2
	}
#endif
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
@end
