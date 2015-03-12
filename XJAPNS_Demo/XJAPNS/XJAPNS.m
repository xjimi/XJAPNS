//
//  XJAPNS.m
//  Waker
//
//  Created by XJIMI on 2015/3/6.
//  Copyright (c) 2015年 xjimi. All rights reserved.
//

#import "XJAPNS.h"

static NSString * const kAPNSDeviceToken = @"kAPNSDeviceToken";
static NSString * const kAPNSRegisterStatus = @"kAPNSRegisterStatus";
static NSString * const kAPNSRegisterParameters = @"kAPNSRegisterParameters";

@interface XJAPNS ()

@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, assign) XJAPNSRegisterStatus registerStatus;
@property (nonatomic, weak) id registerParameters;
@property (nonatomic, copy) XJAPNSPostRequestBlock postRequestBlock;

@end

@implementation XJAPNS

+ (void)registerDeviceToken:(NSData *)deviceToken
{
    [XJAPNS registerDeviceToken:deviceToken parameters:nil];
}

+ (void)registerDeviceToken:(NSData *)deviceToken parameters:(id)parameters
{
    NSString *token = [deviceToken description];
    token = [token stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    BOOL isNewDeviceToken = ![[XJAPNS sharedObject].deviceToken isEqualToString:token];
    [XJAPNS sharedObject].deviceToken = token;
    [XJAPNS sharedObject].registerParameters = parameters;
    isNewDeviceToken ? [XJAPNS updateWithParameters:parameters] : [XJAPNS updateIfNeeded];
}

+ (void)update {
    [self updateWithParameters:nil];
}

+ (void)updateWithParameters:(id)parameters
{
    [XJAPNS sharedObject].registerParameters = parameters;
    [XJAPNS sharedObject].registerStatus = XJAPNSRegisterStatusNeedUpdate;
    [XJAPNS updateIfNeeded];
}

+ (void)updateIfNeeded
{
    
    if ([XJAPNS sharedObject].registerStatus == XJAPNSRegisterStatusCompletion ||
        ![XJAPNS sharedObject].deviceToken.length) return;
    [XJAPNS sharedObject].registerStatus = XJAPNSRegisterStatusNeedUpdate;
    if ([XJAPNS sharedObject].postRequestBlock) {
        [XJAPNS sharedObject].postRequestBlock([XJAPNS sharedObject].registerParameters);
    }
}

+ (void)postRrequestProcess:(XJAPNSPostRequestBlock)postRequestProcess {
    [XJAPNS sharedObject].postRequestBlock = postRequestProcess;
}

+ (void)completedRegister {
    [XJAPNS sharedObject].registerStatus = XJAPNSRegisterStatusCompletion;
}

+ (NSString *)deviceToken {
    return [XJAPNS sharedObject].deviceToken;
}

#pragma mark - private method

- (void)setDeviceToken:(NSString *)deviceToken {
    [self setObject:deviceToken forKey:kAPNSDeviceToken];
}

- (NSString *)deviceToken {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kAPNSDeviceToken];
}

- (void)setRegisterStatus:(XJAPNSRegisterStatus)registerStatus {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setInteger:registerStatus forKey:kAPNSRegisterStatus];
    [userDefault synchronize];
}

- (XJAPNSRegisterStatus)registerStatus {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:kAPNSRegisterStatus] integerValue];
}

- (void)setRegisterParameters:(id)registerParameters {
    [self setObject:registerParameters forKey:kAPNSRegisterParameters];
}

- (id)registerParameters {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kAPNSRegisterParameters];
}

- (void)setObject:(id)value forKey:(NSString *)defaultName;
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:value forKey:defaultName];
    [userDefault synchronize];
}

+ (instancetype)sharedObject
{
    static XJAPNS *_sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[XJAPNS alloc] init];
    });
    return _sharedObject;
}

+ (void)registerUserNotification
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else
    {
        UIRemoteNotificationType remoteTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:remoteTypes];
    }
}

#pragma mark - HTTP POST

+ (void)performHttpURL:(NSString *)url
            parameters:(NSDictionary *)parameters
     completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))handler
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSData *postData = [XJAPNS dataForHTTPPostParameters:parameters];
    NSString *postLength = [NSString stringWithFormat:@"%ld", (long)[postData length]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue new] completionHandler:handler];
}

+ (NSString *)stringForHTTPPostString:(NSString *)string
{
    NSString *result = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (CFStringRef)string,
                                                                                 (CFStringRef)@" ",
                                                                                 (CFStringRef)@";/?:@&=+$,",
                                                                                 kCFStringEncodingUTF8));
    return [result stringByReplacingOccurrencesOfString:@" " withString:@"+"];
}

+ (NSData *)dataForHTTPPostParameters:(NSDictionary *)parameters
{
    NSMutableArray *array = [NSMutableArray array];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *valueString;
        
        if ([obj isKindOfClass:[NSString class]])
            valueString = obj;
        else if ([obj isKindOfClass:[NSNumber class]])
            valueString = [(NSNumber *)obj stringValue];
        else if ([obj isKindOfClass:[NSURL class]])
            valueString = [(NSURL *)obj absoluteString];
        else
            valueString = [obj description];
        
        [array addObject:[NSString stringWithFormat:@"%@=%@", key, [XJAPNS stringForHTTPPostString:valueString]]];
    }];
    
    NSString *postString = [array componentsJoinedByString:@"&"];
    
    return [postString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
