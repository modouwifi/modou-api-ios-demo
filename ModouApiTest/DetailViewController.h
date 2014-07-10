//
//  DetailViewController.h
//  ModouApiTest
//
//  Created by 孔祥波 on 14-7-10.
//  Copyright (c) 2014年 Kong XiangBo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *ssid;
@property (strong, nonatomic) IBOutlet UILabel *bssid;
@property (strong, nonatomic) IBOutlet UILabel *ssid5G;
@property (strong, nonatomic) IBOutlet UILabel *bssid5G;
@property (nonatomic) AFHTTPRequestOperationManager *manager;
@end
