//
//  AppDelegate.m
//  XJAPNS_Demo
//
//  Created by XJIMI on 2015/3/12.
//  Copyright (c) 2015年 XJIMI. All rights reserved.
//

#import "AppDelegate.h"
#import "XJAPNS.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [self APNSRegister];
    return YES;
}

- (void)APNSRegister
{
    //開通推播權限
    [XJAPNS registerUserNotification];
    
    //處理您要上傳至server的事件
    [XJAPNS postRrequestProcess:^(id parameters) {
        
        NSString *uid = parameters[@"uid"];
        NSLog(@"uid : %@ , deviceToke : %@", uid, [XJAPNS deviceToken]);
        //server資料更新完成後 請執行 --> [XJAPNS completedRegister];
        
    }];
    
    //例如：user登入取得uid,可 updateWithParameters 會觸發 postRrequestProcess 處理上傳事件
    //[XJAPNS updateWithParameters:@{@"uid":@"uid7533967"}];
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    //註冊之後 會觸發 postRrequestProcess 處理上傳事件
    //[XJAPNS registerDeviceToken:deviceToken];
    
    //如果需要參數 例如 uid
    [XJAPNS registerDeviceToken:deviceToken parameters:@{@"uid":@"uid7533967"}];
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //若網路不穩 上傳資料失敗  當app喚醒時  會檢查是否要再上傳資料
    [XJAPNS updateIfNeeded];
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
