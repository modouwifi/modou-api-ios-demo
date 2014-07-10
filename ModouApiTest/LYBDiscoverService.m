//
//  LYBDiscoverService.m
//  luyoubao
//
//  Created by stranbird on 14-5-10.
//  Copyright (c) 2014年 stranbird. All rights reserved.
//

#import <SystemConfiguration/CaptiveNetwork.h>



#import "LYBDiscoverService.h"

#include <dns_sd.h>
#include <resolv.h>
int prrouter();// define routecmd
int ahost(char *ipaddr);//反向解析gateway
int txtrecord(char *ipaddr,char *name,int aflag);
//rmbp:tmp yarshure$ nslookup  192.168.18.1
//Server:		192.168.18.1
//Address:	192.168.18.1#53
//
//1.18.168.192.in-addr.arpa	name = matrix.modouwifi.com.
void DNSSD_API callback
(
 DNSServiceRef sdRef,
 DNSServiceFlags flags,
 uint32_t interfaceIndex,
 DNSServiceErrorType errorCode,
 const char                          *fullname,
 uint16_t rrtype,
 uint16_t rrclass,
 uint16_t rdlen,
 const void                          *rdata,
 uint32_t ttl,
 void                                *context
 );
struct  Record {
    const char                          *fullname;
    uint16_t rrtype;
    uint16_t rrclass;
    uint32_t ttl;
    uint16_t rdlen;
    const void                          *rdata;
} Record;
@interface LYBDiscoverService ()
- (void)failed:(DNSServiceErrorType)theErrorCode;
- (void)record:(const struct Record*)theRecord onInterface:(uint32_t)theIndex;

- (void)recordExpired:(const struct Record*)theRecord;

@end
@implementation LYBDiscoverService
#pragma mark dnsquery
#pragma mark -
void DNSSD_API callback
(
 DNSServiceRef sdRef,
 DNSServiceFlags flags,
 uint32_t interfaceIndex,
 DNSServiceErrorType errorCode,
 const char                          *fullname,
 uint16_t rrtype,
 uint16_t rrclass,
 uint16_t rdlen,
 const void                          *rdata,
 uint32_t ttl,
 void                                *context
 )
{
    NSLog(@"queryCallback: flags == %d error code == %d", flags, errorCode);
    LYBDiscoverService *service =(__bridge LYBDiscoverService*)context;
    if (errorCode != kDNSServiceErr_NoError)
    {
        [service failed:errorCode];
    }
    else
    {
        NSLog(@"theName == %s theType == %u", fullname, rrtype);
        
         struct Record  rr = {
            fullname,
            rrtype,
            rrclass,
            ttl,
            rdlen,
            rdata
        };
        
        if ((flags & kDNSServiceFlagsAdd) != 0)
        {
            [service record:&rr onInterface:interfaceIndex];
        }
        else
        {
            [service recordExpired:&rr];
        }
    }
    
}
- (void)record:(const struct  Record*)theRecord onInterface:(uint32_t)theIndex
{
    //[self.delegate query:self didGetResponse:theRecord onInterface:theIndex];
    const void                          *rdata=theRecord->rdata;
    uint16_t rdlen = theRecord->rdlen;
   
    //memcpy(result, rdata, rdlen);
    //NSString *a=[[NSString alloc] initWithBytes:rdata length:rdlen encoding:NSUTF8StringEncoding];
    
    
    switch (theRecord->rrtype ) {
        case kDNSServiceType_PTR:
        {
            char result[256]={0};
            dn_expand(rdata, rdata + rdlen, rdata, result, 256);
            DLog(@"result %s",result);
            self.ptrRecord = [[NSString alloc] initWithUTF8String:result];
            [self sendDNSRequry:@"all" type:kDNSServiceType_TXT];
            break;
        }
        case kDNSServiceType_TXT:
        {
            char result[256]={0};
            dn_expand(rdata, rdata + rdlen, rdata, result, 256);
            
            NSMutableData *txtData = [NSMutableData dataWithCapacity:rdlen];
            
            char *p=(char*)rdata;
            
            for (uint16_t i = 0; i < rdlen; i++) {
                
                DLog(@"%c\n",*p);
                if (*p > 24) {
                    [txtData appendBytes:p length:1];
                    

                }
                p++;
            }
            
            self.txtRecord = [[NSString alloc] initWithBytes:txtData.bytes length:txtData.length encoding:NSUTF8StringEncoding];
            DLog(@"%@",self.txtRecord);
            NSRegularExpression* regex=nil;
            
            //hwver#M101Cswver#0.5.33_beta52gmac#C0:3D:46:00:08:D25gmac#C0:3D:46:00:08:D3
            regex =[[NSRegularExpression alloc] initWithPattern:@"(hwver#.*)(swver#.*)(2gmac#.*)(5gmac#.*)"
                                                        options:NSRegularExpressionCaseInsensitive error:nil];
            
            NSMutableDictionary *dict=[[NSMutableDictionary alloc] init];
            [regex enumerateMatchesInString:self.txtRecord options:0 range:NSMakeRange(0, [self.txtRecord length])
                                 usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
             {
                 
                 NSInteger count=[result numberOfRanges];
//                 if (count==4) {
//                     NSString *hwver = [self.txtRecord substringWithRange:[result rangeAtIndex:0]];
//                     NSString *swwver = [self.txtRecord substringWithRange:[result rangeAtIndex:1]];
//                     NSString *gmac2 = [self.txtRecord substringWithRange:[result rangeAtIndex:2]];
//                     NSString *gmac4 = [self.txtRecord substringWithRange:[result rangeAtIndex:3]];
//                 }
                 for (int i=0; i<count; i++) {
                     @try {
                        NSString *item = [self.txtRecord substringWithRange:[result rangeAtIndex:i]];
                        NSArray *items=[item componentsSeparatedByString:@"#"];
                        [dict setObject:[items objectAtIndex:1] forKey:[items objectAtIndex:0]];
                         
                         //[columns addObject:s1];
                     }
                     @catch (NSException *exception) {
                         NSLog(@"%@",exception);
                     }
                     
                     
                 }
                 
             }];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addDeviceWithDict:dict];//[self sendDNSRequry:@"matrix.modouwifi.com" type:kDNSServiceType_A];
            });
            
            break;
        }
        case kDNSServiceType_A:
        {
            char result[1000] = "";
            const unsigned char *rd  = rdata;

            snprintf(result, sizeof(result), "%d.%d.%d.%d", rd[0], rd[1], rd[2], rd[3]);
            char ipAddr[256];
            sprintf(ipAddr, "%d.%d.%d.%d", rd[3], rd[2], rd[1], rd[0]);
            
            self.aRecord = [[NSString alloc] initWithUTF8String:result];
            self.gateway = self.aRecord;
            NSString *qStr=[NSString stringWithFormat:@"%s.in-addr.arpa.",ipAddr];
            DLog(@"matrix.modouwifi.com IN A %@",self.aRecord);
            [self sendDNSRequry:qStr type:kDNSServiceType_PTR];
            break;
        }
        default:
            break;
    }
}

- (void)recordExpired:(const struct Record *)theRecord
{
    //[self.delegate query:self recordDidExpire:theRecord];
}
- (void)failed:(DNSServiceErrorType)theErrorCode
{
    if (theErrorCode != kDNSServiceErr_Timeout)
    {
        //[self.delegate queryDidFail:self withError:theErrorCode];
    }
    else
    {
        //[self.delegate queryDidTimeout:self];
    }
}
#pragma mark -
+ (instancetype)sharedService {
    static LYBDiscoverService *service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[self alloc] init];
    });
    
    return service;
}

- (instancetype)init {
    self = [super init];
    if (self == nil) return nil;
    
    //_connectedSignal = [self connectedDevice] ;
  
//    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(monitorWIFIChange)]];
//    [NSTimer scheduledTimerWithTimeInterval:5.0 invocation:inv repeats:YES];
   // [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(monitorWIFIChange:) userInfo:nil repeats:YES];
//    _discoveredSignal = [self.connectedSignal
//                         filter:^BOOL(Device *device) {
//                             return !(device.loggedIn);
//                         }];
    
    return self;
}
-(void)monitorWIFIChange:(NSTimer*)timer
{
    //DLog(@"%@",timer);
    if ([self currentWifiBSSID]) {
        if (![self.currentWifiBSSID isEqualToString: self.lastBSSID]) {
            NSDictionary *dict=[NSMutableDictionary dictionary];
            [dict setValue:self.currentWifiBSSID forKey:@"bssid"];
            [dict setValue:self.lastBSSID forKey:@"oldbssid"];
            //DLog(@"knotificationWIFIChanged !");
            [[NSNotificationCenter defaultCenter] postNotificationName:knotificationWIFIChanged object:self userInfo:dict];
            self.lastBSSID = self.currentWifiBSSID;
        }
    }
}

-(void)rescan
{

    
    [self findGateway];
    //            dispatch_async(dispatch_queue_create("com.modouwifi", NULL), ^{
    //                [self sendDNSRequry:@"matrix.modouwifi.com" type:kDNSServiceType_A];
    //            });
    
}
-(void)sendDNSRequry:(NSString*)record  type:(uint16_t)rrtype
{
    DNSServiceRef sdRef;
    DNSServiceErrorType res;
    
    res=DNSServiceQueryRecord(
                              &sdRef, 0, 0,
                              [record UTF8String], //"1.18.168.192.in-addr.arpa."
                               rrtype,//kDNSServiceType_PTR
                              kDNSServiceClass_IN,
                              callback,
                              (__bridge void*)self
                              );
    if (res != kDNSServiceErr_NoError)
    {
        NSLog(@"DNSServiceQueryRecord: %d", res);
        //[self.delegate queryDidFail:self withError:error];
    }
    DNSServiceProcessResult(sdRef);
    DNSServiceRefDeallocate(sdRef);
  
    

    
}
- (void)redirectNSlogToDocumentFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"dr.log"];// 注意不是NSData!
    NSString *logFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    // 先删除已经存在的文件
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    [defaultManager removeItemAtPath:logFilePath error:nil];
    
    // 将log输入到文件
    freopen([logFilePath cStringUsingEncoding:NSUTF8StringEncoding], "a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSUTF8StringEncoding], "a+", stderr);
}
-(NSString*)logfile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"dr.log"];// 注意不是NSData!
    NSString *logFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    return logFilePath;
    
}
- (void)findGateway
{
    
    dispatch_queue_t q= dispatch_queue_create("com.modouwifi.gateway", NULL);
    //LYBDiscoverService* __weak weakSelf = self;
    LYBDiscoverService*  strongSelf = self;
    self.gateway = nil;
    dispatch_async(q, ^{
        
        [strongSelf redirectNSlogToDocumentFolder];
        prrouter();
        BOOL result;//[strongSelf test];
        NSString *logFilePath=[self logfile];
        NSError *error;
        NSString *content =[NSString stringWithContentsOfFile:logFilePath encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            //NSLog(@"%@",[error debugDescription]);
        }
        if (content) {
            NSRegularExpression* regex=nil;
            
            regex =[[NSRegularExpression alloc] initWithPattern:@"default\\s*(\\S+).*en0"
                                                        options:NSRegularExpressionCaseInsensitive error:nil];
            __block NSString *gateway;
            
            [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, [content length])
                                 usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
             {
                 
                 NSInteger count=[result numberOfRanges];
                 for (int i=1; i<=count; i++) {
                     @try {
                         gateway = [content substringWithRange:[result rangeAtIndex:i]];
                         
                         
                         //[columns addObject:s1];
                     }
                     @catch (NSException *exception) {
                         NSLog(@"%@",exception);
                     }
                     
                     
                 }
                 
             }];
            strongSelf.gateway = gateway;
            result = YES;
        }else{
            result= NO;
        }


        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (strongSelf.gateway) {
                //[strongSelf addDeviceWithURL];
                [strongSelf findModouWithAddress:strongSelf.gateway];
            }else{
                
            }
           
        });
    });
}

- (void)findModouWithAddress:(NSString*)ipaddr
{

    dispatch_queue_t q= dispatch_queue_create("com.modouwifi.matrix", NULL);
    LYBDiscoverService*  strongSelf = self;
    [self redirectNSlogToDocumentFolder];
    dispatch_async(q, ^{
        NSString *logFilePath=[self logfile];
        __block BOOL result=NO;
        char *addr=(char *)[ipaddr UTF8String];
        __block NSString *addr2;
        NSError *error;
        if (ipaddr) {
            char *ip =(char*)[ipaddr UTF8String];
            ahost(ip);
            
            fflush(stdout);
            fflush(stderr);
            
            
            NSString *content =[NSString stringWithContentsOfFile:logFilePath encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                NSLog(@"%@",[error debugDescription]);
            }
            NSRange range =[content rangeOfString:@"matrix.modouwifi.com"];
            if (range.length !=0) {
                
                result=YES;
            }else{
                //解析 A record matrix.modouwifi.com
                txtrecord(addr,"matrix.modouwifi.com",1);
                fflush(stdout);
                fflush(stderr);
                //matrix.modouwifi.com.0A	192.168.19.1
                NSString *content =[NSString stringWithContentsOfFile:logFilePath encoding:NSUTF8StringEncoding error:&error];
                
                NSRegularExpression* regex=nil;
                NSString *parten=@"matrix.modouwifi.com.*\\b(([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
                "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
                "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
                "([01]?\\d\\d?|2[0-4]\\d|25[0-5]))";
                regex =[[NSRegularExpression alloc] initWithPattern:parten
                                                            options:NSRegularExpressionCaseInsensitive error:nil];
                [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, [content length])
                                     usingBlock:^(NSTextCheckingResult *resultReg, NSMatchingFlags flags, BOOL *stop)
                 {
                     
                     NSInteger count=[resultReg numberOfRanges];
                     if (count>1) {
                         NSString *item = [content substringWithRange:[resultReg rangeAtIndex:1]];
                         addr2 = item;
                         result = YES;
                     }
                     
                 }];
            }
        }
        NSMutableDictionary *dict;
        dict=[[NSMutableDictionary alloc] init];

        
        if (result) {
            if (addr2) {
                char *addrStr=(char*)[addr2 UTF8String];
               txtrecord(addrStr,"all",0);
               [dict setObject:addr2 forKey:@"ip"];
            }else{
                txtrecord(addr,"all",0);
                [dict setObject:ipaddr forKey:@"ip"];
            }
            
            fflush(stdout);
            fflush(stderr);
            self.txtRecord =[NSString stringWithContentsOfFile:logFilePath encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                NSLog(@"%@",[error debugDescription]);
            }
            
           
            NSRegularExpression* regex=nil;
            
            //hwver#M101Cswver#0.5.33_beta52gmac#C0:3D:46:00:08:D25gmac#C0:3D:46:00:08:D3
            regex =[[NSRegularExpression alloc] initWithPattern:@"(hwver#.*)(swver#.*)(2gmac#.*)(5gmac#.*)"
                                                        options:NSRegularExpressionCaseInsensitive error:nil];
            
            
            [regex enumerateMatchesInString:self.txtRecord options:0 range:NSMakeRange(0, [self.txtRecord length])
                                 usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
             {
                 
                 NSInteger count=[result numberOfRanges];
                 
                 for (int i=0; i<count; i++) {
                     @try {
                         NSString *item = [self.txtRecord substringWithRange:[result rangeAtIndex:i]];
                         NSArray *items=[item componentsSeparatedByString:@"#"];
                         [dict setObject:[items objectAtIndex:1] forKey:[items objectAtIndex:0]];
                         
                         //[columns addObject:s1];
                     }
                     @catch (NSException *exception) {
                         DLog(@"%@",exception);
                     }
                     
                     
                 }
             }];
            
        }
        fclose(stderr);
        fclose(stdout);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                [strongSelf addDeviceWithDict:dict];
            }
            
        });
    });
  
    
}

-(void)addDeviceWithDict:(NSDictionary*)info
{
  
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kFoundModouNotification object:self userInfo:info];

}
//-(void)postNotification:(Event*)event
//{
//    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
//                          @"bssid", event.bssid, @"ssid", event.ssid,@"url",event.url, nil];
//    
//    [[NSNotificationCenter defaultCenter] postNotificationName:kNotfoundDevice object:self userInfo:dict];
//}
- (NSDictionary *)currentNetworkInfo {
    CFArrayRef interfaces = CNCopySupportedInterfaces();
    return (__bridge NSDictionary *)CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(interfaces, 0));
}

//- (NSString *)currentWifiBSSID {
//    return [[Device fixSSIDString:[[self currentNetworkInfo] objectForKey:@"BSSID"]] uppercaseString];
//}

- (NSString *)currentWifiSSID {
    return [[self currentNetworkInfo] objectForKey:@"SSID"];
}

- (NSURL *)assumedDeviceURL {
//    static NSString *kIPComponentsSeperator = @".";
//    NSString *currentDeviceIP = [[SystemServices sharedServices] wiFiIPAddress];
//    NSMutableArray *ipComponents = [[currentDeviceIP componentsSeparatedByString:kIPComponentsSeperator] mutableCopy];
//    ipComponents[ipComponents.count - 1] = @"1";
//    
//    NSString *routerIPString = [ipComponents componentsJoinedByString:kIPComponentsSeperator];
//    NSURL *routerURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", routerIPString]];
//    
//    return routerURL;
    return nil;
}

@end
