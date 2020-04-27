//
//  YGEngine.h
//  YGNetworking
//
//  Created by Sun on 2019/4/25.
//  Copyright © 2019 YGNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YGRequest;

/**
 网络请求的完成回调.
 
 @param responseObject 响应体序列化后的响应对象.
 @param error 描述网络错误或者解析发生的错误.
 */
typedef void (^YGCompletionHandler) (id _Nullable responseObject, NSError * _Nullable error);

/**
 `YGEngine` 是一个全局的网络请求引擎，对 `AFNetworking` 的封装.
 */
@interface YGEngine : NSObject

///---------------------
/// @name 初始化
///---------------------

/**
 创建一个 `YGEngine` 对象.
 */
+ (instancetype)engine;

/**
 创建并返回一个 `YGEngine` 单例对象.
 */
+ (instancetype)sharedEngine;

///------------------------
/// @name 请求操作
///------------------------

/**
 运行实际的 `YGRequest` 对象.
 
 @param request 启动的 `YGRequest` 对象.
 @param completionHandler 响应回调.
 */
- (void)sendRequest:(YGRequest *)request completionHandler:(nullable YGCompletionHandler)completionHandler;

/**
 通过 `identifier` 取消请求
 
 @param identifier 正在运行请求的唯一标示.
 @return 返回匹配 `identifier` 的 `YGRequest` 对象(如果有).
 */
- (nullable YGRequest *)cancelRequestByIdentifier:(NSString *)identifier;

/**
 获取匹配 `identifier` 的 `YGRequest` 对象(如果有).
 
 @param identifier 正在运行请求的唯一标示.
 @return 返回匹配 `identifier` 的 `YGRequest` 对象(如果有).
 */
- (nullable YGRequest *)getRequestByIdentifier:(NSString *)identifier;

/**
 设置并发操作个数.
 
 @param count 最大并发个数.
 */
- (void)setConcurrentOperationCount:(NSInteger)count;

///--------------------------
/// @name 网络质量监测
///--------------------------

/**
 获取当前网络状态，具体查看 `AFNetworkReachabilityManager.h`.

 @return Network reachablity status code
 */
- (NSInteger)reachabilityStatus;

///----------------------------
/// @name SSL Pinning for HTTPS
///----------------------------

/**
 添加根据 pinned SSL 证书评估其信任度的服务器 URL.

 @param url 服务器 URL.
 */
- (void)addSSLPinningURL:(NSString *)url;

/**
 添加用于根据 SSL pinning URL 评估服务器信任的证书.

 @param cert 本地证书文件数据.
 */
- (void)addSSLPinningCert:(NSData *)cert;

///---------------------------------------
/// @name HTTPS 两步验证
///---------------------------------------

/**
 添加用于 HTTPS 两步验证的客户端 p12 证书.

 @param p12 PKCS#12 证书文件数据.
 @param password PKCS#12 数据指定的 key password.
 */
- (void)addTwowayAuthenticationPKCS12:(NSData *)p12 keyPassword:(NSString *)password;

@end

NS_ASSUME_NONNULL_END
