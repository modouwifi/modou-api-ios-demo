//
//  ViewController.h
//  ModouApiTest
//
//  Created by 孔祥波 on 14-7-10.
//  Copyright (c) 2014年 Kong XiangBo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UIButton *LoginButton;
- (IBAction)doLogin:(id)sender;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
@property (nonatomic) AFHTTPRequestOperationManager *manager;
@end
