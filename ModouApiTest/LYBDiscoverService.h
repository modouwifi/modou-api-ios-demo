//
//  LYBDiscoverService.h
//  luyoubao
//
//  Created by stranbird on 14-5-10.
//  Copyright (c) 2014年 stranbird. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <dns_sd.h>
#include <resolv.h>
#define knotificationWIFIChanged @"knotificationWIFIChanged"
#define kFoundModouNotification @"FoundModouNotification"
@interface LYBDiscoverService : NSObject



@property (nonatomic,strong) NSString *lastBSSID;
@property (nonatomic,strong) NSString *gateway;

@property (nonatomic,strong) NSString *txtRecord;
@property (nonatomic,strong) NSString *ptrRecord;
@property (nonatomic,strong) NSString *aRecord;


+ (instancetype)sharedService;
- (NSString *)currentWifiBSSID;
- (NSString *)currentWifiSSID;
-(void)rescan;
- (NSURL *)assumedDeviceURL;
-(void)test;

- (void)findModouWithAddress:(NSString*)ipaddr;
@end
