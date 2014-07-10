//
//  DetailViewController.m
//  ModouApiTest
//
//  Created by 孔祥波 on 14-7-10.
//  Copyright (c) 2014年 Kong XiangBo. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self fetchWIFIInfo];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)fetchWIFIInfo {
   
    
    [self.manager GET:@"api/wifi/get_config" parameters:nil success:^(AFHTTPRequestOperation *operation, id value) {
        
        NSDictionary *dict2G =[value objectForKey:@"2g"];
        NSDictionary *dict5G =[value objectForKey:@"5g"];
        
        self.ssid.text =[dict2G objectForKey:@"ssid"];
        self.bssid.text = [dict2G objectForKey:@"mac"];
        self.ssid5G.text =[dict5G objectForKey:@"ssid"];
        self.bssid5G.text = [dict5G objectForKey:@"mac"];
//        [string appendString:@"2.4G\n"];
//        [string appendFormat:@"ssid:%@\n",];
//        [string appendFormat:@"密码:%@\n",[dict2G objectForKey:@"password"]];
//        [string appendFormat:@"bssid:%@\n",[dict2G objectForKey:@"mac"]];
//        [string appendString:@"5G\n"];
//        [string appendFormat:@"ssid:%@\n",[dict5G objectForKey:@"ssid"]];
//        [string appendFormat:@"密码:%@\n",[dict5G objectForKey:@"password"]];
//        [string appendFormat:@"bssid:%@\n",[dict5G objectForKey:@"mac"]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"%@",[error description]);
    }];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
