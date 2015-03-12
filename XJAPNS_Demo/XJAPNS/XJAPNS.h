//
//  XJAPNS.h
//  Waker
//
//  Created by XJIMI on 2015/3/6.
//  Copyright (c) 2015年 xjimi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, XJAPNSRegisterStatus) {
    XJAPNSRegisterStatusNone = 0,
    XJAPNSRegisterStatusNeedUpdate,
    XJAPNSRegisterStatusCompletion
};

typedef void (^XJAPNSPostRequestBlock)(id parameters);

@interface XJAPNS : NSObject

+ (instancetype)sharedObject;

+ (void)registerDeviceToken:(NSData *)deviceToken;

+ (void)registerDeviceToken:(NSData *)deviceToken parameters:(id)parameters;

/* 更新資料,不帶任何參數 會觸發 postRrequestProcess */
+ (void)update;

/* 更新資料,帶參數 會觸發 postRrequestProcess */
+ (void)updateWithParameters:(NSDictionary *)parameters;

/* 檢查是否還要上傳資料 (網路不穩出錯 造成更新資料失敗) */
+ (void)updateIfNeeded;

/* 處理您要上傳至server事件 */
+ (void)postRrequestProcess:(XJAPNSPostRequestBlock)postRequestProcess;

/* 如果更新成功 請呼叫completedRegister */
+ (void)completedRegister;

/* 取得用戶 deviceToken */
+ (NSString *)deviceToken;

/* 取得裝置推播權限 */
+ (void)registerUserNotification;

//HTTP POST

+ (void)performHttpURL:(NSString *)url
            parameters:(NSDictionary *)parameters
     completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))handler;

@end
