//
//  YGCenter.h
//  YGNetworking
//
//  Created by Sun on 2019/4/25.
//  Copyright © 2019 YGNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YGConst.h"

NS_ASSUME_NONNULL_BEGIN

@class YGConfig, YGEngine;

/**
 `YGCenter` 是一个全局的放置发送和管理所有网络请求的中心.
 `+center` 方法用来创建一个 `YGCenter` 对象，
 `+defaultCenter` 方法会返回一个默认的 `YGCenter` 单例对象.
 
 以下这些方法将会被 `[YGCenter defaultCenter]` 调用，推荐使用类方法来代替自己管理 `YGCenter` 对象.
 
 用法:
 
 (1) 配置 YGCenter
 
 [YGCenter setupConfig:^(YGConfig *config) {
     config.server = @"服务器地址";
     config.headers = @{@"通用 header key": @"通用 header value"};
     config.parameters = @{@"通用 parameter": @"通用 parameter value"};
     config.callbackQueue = dispatch_get_main_queue(); // 回调队列
 }];
 
 [YGCenter setRequestProcessBlock:^(YGRequest *request) {
     // 自定义请求预处理逻辑.
 }];
 
 [YGCenter setResponseProcessBlock:^(YGRequest *request, id responseObject, NSError *__autoreleasing *error) {
     // 自定义请求预处理逻辑.
     // 当 `error` 发生时可以对 `error` 传入自定义参数(这是个二级指针)，失败的 block 将被调用.
 }];
 
 (2) 发送一个请求
 
 [YGCenter sendRequest:^(YGRequest *request) {
     request.server = @"服务器地址"; // 可选, 如果为 `nil`, 将会使用 gennealServer.
     request.api = @"api 路径";
     request.parameters = @{@"param1": @"value1", @"param2": @"value2"}; // general parameters 将会被追加到这个参数里.
 } onSuccess:^(id responseObject) {
     // 成功
 } onFailure:^(NSError *error) {
     // 失败
 }];
 
 */
@interface YGCenter : NSObject

///---------------------
/// @name 初始化
///---------------------

/**
 创建并返回一个 `YGCenter` 对象.
 */
+ (instancetype)center;

/**
 返回默认的 `YGCenter` 单例对象.
 */
+ (instancetype)defaultCenter;

///-----------------------
/// @name 通用属性
///-----------------------

// NOTE: 以下属性只能通过 `YGConfig` 调用 `-setupConfig:` 方法来传递.

/**
 YGCenter 的通用服务器地址，如果 YGRequest.server 为 `nil` 并且 YGRequest.useGeneralServer 为 `YES`，这个属性将会被赋值到 YGRequest.server.
 */
@property (nonatomic, copy, nullable) NSString *generalServer;

/**
 YGCenter 的通用参数，如果 YGRequest.useGeneralParameters 为 `YES` 并且当前属性不为空，将会把此属性的值追加到 YGRequest.parameters 里.
 */
@property (nonatomic, strong, nullable, readonly) NSMutableDictionary<NSString *, id> *generalParameters;

/**
 YGCenter 的通用头，如果 YGRequest.useGeneralHeaders 为 `YES` 并且当前属性不为空，将会把此属性的值追加到 YGRequest.headers 里.
 */
@property (nonatomic, strong, nullable, readonly) NSMutableDictionary<NSString *, NSString *> *generalHeaders;

/**
 YGCenter 的通用用户信息，如果 YGRequest.userInfo 为 `nil` 并且此属性不为 `nil`，将会把次属性设置成 YGRequest.userInfo.
 */
@property (nonatomic, strong, nullable) NSDictionary *generalUserInfo;

/**
 回调的队列. 如果为 `NULL` (默认为 NULL)，将会使用一个私有的并发队列.
 */
@property (nonatomic, strong, nullable) dispatch_queue_t callbackQueue;

/**
 YGCenter 的全局通用引擎，默认为 `[YGEngine sharedEngine]`.
 */
@property (nonatomic, strong) YGEngine *engine;

/**
 控制台是否打印请求和响应信息，默认为 `NO`.
 */
@property (nonatomic, assign) BOOL consoleLog;

///--------------------------------------------
/// @name 配置 YGCenter 的实例方法
///--------------------------------------------

#pragma mark - Instance Method

/**
 通过 `YGConfig` 对象配置 YGCenter 属性.

 @param block 用于配置的 block(通过在 block 内对 `YGConfig` 对象进行赋值来完成).
 */
- (void)setupConfig:(void(^)(YGConfig *config))block;

/**
 对 YGCenter 请求预处理的 block.
 
 @param block 请求预处理的 block (`YGCenterRequestProcessBlock`).
 */
- (void)setRequestProcessBlock:(YGCenterRequestProcessBlock)block;

/**
 对 YGCenter 响应处理的 block.

 @param block 响应处理的 block (`YGCenterResponseProcessBlock`).
 */
- (void)setResponseProcessBlock:(YGCenterResponseProcessBlock)block;

/**
 对 YGCenter 错误处理的 block.
 
 @param block 错误处理 block (`YGCenterErrorProcessBlock`).
 */
- (void)setErrorProcessBlock:(YGCenterErrorProcessBlock)block;

/**
 对 YGCenter 设置通用的 HTTP 头，如果设为 `nil`，将会移除现有已设置的头.
 
 @param value 指定 header 的值，或 `nil`.
 @param field 指定的 HTTP header.
 */
- (void)setGeneralHeaderValue:(nullable NSString *)value forField:(NSString *)field;

/**
 对 YGCenter 设置通用的参数，如果设为 `nil`，将会移除现有已设置的参数.
 
 @param value 指定参数的值，或 `nil`.
 @param key 指定参数.
 */
- (void)setGeneralParameterValue:(nullable id)value forKey:(NSString *)key;

///---------------------------------------
/// @name Instance Method to Send Requests
///---------------------------------------

#pragma mark -

/**
 Creates and runs a Normal `YGRequest`.

 @param configBlock The config block to setup context info for the new created YGRequest object.
 @return Unique identifier for the new running YGRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock;

/**
 Creates and runs a Normal `YGRequest` with success block.
 
 NOTE: The success block will be called on `callbackQueue` of YGCenter.

 @param configBlock The config block to setup context info for the new created YGRequest object.
 @param successBlock Success callback block for the new created YGRequest object.
 @return Unique identifier for the new running YGRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                         onSuccess:(nullable YGSuccessBlock)successBlock;

/**
 Creates and runs a Normal `YGRequest` with failure block.
 
 NOTE: The failure block will be called on `callbackQueue` of YGCenter.

 @param configBlock The config block to setup context info for the new created YGRequest object.
 @param failureBlock Failure callback block for the new created YGRequest object.
 @return Unique identifier for the new running YGRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                         onFailure:(nullable YGFailureBlock)failureBlock;

/**
 Creates and runs a Normal `YGRequest` with finished block.

 NOTE: The finished block will be called on `callbackQueue` of YGCenter.
 
 @param configBlock The config block to setup context info for the new created YGRequest object.
 @param finishedBlock Finished callback block for the new created YGRequest object.
 @return Unique identifier for the new running YGRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                        onFinished:(nullable YGFinishedBlock)finishedBlock;

/**
 Creates and runs a Normal `YGRequest` with success/failure blocks.

 NOTE: The success/failure blocks will be called on `callbackQueue` of YGCenter.
 
 @param configBlock The config block to setup context info for the new created YGRequest object.
 @param successBlock Success callback block for the new created YGRequest object.
 @param failureBlock Failure callback block for the new created YGRequest object.
 @return Unique identifier for the new running YGRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                         onSuccess:(nullable YGSuccessBlock)successBlock
                         onFailure:(nullable YGFailureBlock)failureBlock;

/**
 Creates and runs a Normal `YGRequest` with success/failure/finished blocks.

 NOTE: The success/failure/finished blocks will be called on `callbackQueue` of YGCenter.
 
 @param configBlock The config block to setup context info for the new created YGRequest object.
 @param successBlock Success callback block for the new created YGRequest object.
 @param failureBlock Failure callback block for the new created YGRequest object.
 @param finishedBlock Finished callback block for the new created YGRequest object.
 @return Unique identifier for the new running YGRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                         onSuccess:(nullable YGSuccessBlock)successBlock
                         onFailure:(nullable YGFailureBlock)failureBlock
                        onFinished:(nullable YGFinishedBlock)finishedBlock;

/**
 Creates and runs an Upload/Download `YGRequest` with progress/success/failure blocks.

 NOTE: The success/failure blocks will be called on `callbackQueue` of YGCenter.
 BUT !!! the progress block is called on the session queue, not the `callbackQueue` of YGCenter.
 
 @param configBlock The config block to setup context info for the new created YGRequest object.
 @param progressBlock Progress callback block for the new created YGRequest object.
 @param successBlock Success callback block for the new created YGRequest object.
 @param failureBlock Failure callback block for the new created YGRequest object.
 @return Unique identifier for the new running YGRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                        onProgress:(nullable YGProgressBlock)progressBlock
                         onSuccess:(nullable YGSuccessBlock)successBlock
                         onFailure:(nullable YGFailureBlock)failureBlock;

/**
 Creates and runs an Upload/Download `YGRequest` with progress/success/failure/finished blocks.

 NOTE: The success/failure/finished blocks will be called on `callbackQueue` of YGCenter.
 BUT !!! the progress block is called on the session queue, not the `callbackQueue` of YGCenter.
 
 @param configBlock The config block to setup context info for the new created YGRequest object.
 @param progressBlock Progress callback block for the new created YGRequest object.
 @param successBlock Success callback block for the new created YGRequest object.
 @param failureBlock Failure callback block for the new created YGRequest object.
 @param finishedBlock Finished callback block for the new created YGRequest object.
 @return Unique identifier for the new running YGRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                        onProgress:(nullable YGProgressBlock)progressBlock
                         onSuccess:(nullable YGSuccessBlock)successBlock
                         onFailure:(nullable YGFailureBlock)failureBlock
                        onFinished:(nullable YGFinishedBlock)finishedBlock;

/**
 Creates and runs batch requests

 @param configBlock The config block to setup batch requests context info for the new created YGBatchRequest object.
 @param successBlock Success callback block called when all batch requests finished successfully.
 @param failureBlock Failure callback block called once a request error occured.
 @param finishedBlock Finished callback block for the new created YGBatchRequest object.
 @return Unique identifier for the new running YGBatchRequest object,`nil` for fail.
 */
- (nullable NSString *)sendBatchRequest:(YGBatchRequestConfigBlock)configBlock
                              onSuccess:(nullable YGBCSuccessBlock)successBlock
                              onFailure:(nullable YGBCFailureBlock)failureBlock
                             onFinished:(nullable YGBCFinishedBlock)finishedBlock;

/**
 Creates and runs chain requests

 @param configBlock The config block to setup chain requests context info for the new created YGBatchRequest object.
 @param successBlock Success callback block called when all chain requests finished successfully.
 @param failureBlock Failure callback block called once a request error occured.
 @param finishedBlock Finished callback block for the new created YGChainRequest object.
 @return Unique identifier for the new running YGChainRequest object,`nil` for fail.
 */
- (nullable NSString *)sendChainRequest:(YGChainRequestConfigBlock)configBlock
                              onSuccess:(nullable YGBCSuccessBlock)successBlock
                              onFailure:(nullable YGBCFailureBlock)failureBlock
                             onFinished:(nullable YGBCFinishedBlock)finishedBlock;

///------------------------------------------
/// @name Instance Method to Operate Requests
///------------------------------------------

#pragma mark -

/**
 Method to cancel a runnig request by identifier.
 
 @param identifier The unique identifier of a running request.
 */
- (void)cancelRequest:(NSString *)identifier;

/**
 Method to cancel a runnig request by identifier with a cancel block.
 
 NOTE: The cancel block is called on current thread who invoked the method, not the `callbackQueue` of YGCenter.
 
 @param identifier The unique identifier of a running request.
 @param cancelBlock The callback block to be executed after the running request is canceled. The canceled request object (if exist) will be passed in argument to the cancel block.
 */
- (void)cancelRequest:(NSString *)identifier
             onCancel:(nullable YGCancelBlock)cancelBlock;

/**
 Method to get a runnig request object matching to identifier.
 
 @param identifier The unique identifier of a running request.
 @return return The runing YGRequest/YGBatchRequest/YGChainRequest object (if exist) matching to identifier.
 */
- (nullable id)getRequest:(NSString *)identifier;

/**
 Method to get current network reachablity status.
 
 @return The network is reachable or not.
 */
- (BOOL)isNetworkReachable;

/**
 Method to get current network connection type.
 
 @return The network connection type, see `YGNetworkConnectionType` for details.
 */
- (YGNetworkConnectionType)networkConnectionType;

///--------------------------------
/// @name Class Method for YGCenter
///--------------------------------

// NOTE: The following class method is invoke through the `[YGCenter defaultCenter]` singleton object.

#pragma mark - Class Method

+ (void)setupConfig:(void(^)(YGConfig *config))block;
+ (void)setRequestProcessBlock:(YGCenterRequestProcessBlock)block;
+ (void)setResponseProcessBlock:(YGCenterResponseProcessBlock)block;
+ (void)setErrorProcessBlock:(YGCenterErrorProcessBlock)block;
+ (void)setGeneralHeaderValue:(nullable NSString *)value forField:(NSString *)field;
+ (void)setGeneralParameterValue:(nullable id)value forKey:(NSString *)key;

#pragma mark -

+ (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock;

+ (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                         onSuccess:(nullable YGSuccessBlock)successBlock;

+ (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                         onFailure:(nullable YGFailureBlock)failureBlock;

+ (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                        onFinished:(nullable YGFinishedBlock)finishedBlock;

+ (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                         onSuccess:(nullable YGSuccessBlock)successBlock
                         onFailure:(nullable YGFailureBlock)failureBlock;

+ (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                         onSuccess:(nullable YGSuccessBlock)successBlock
                         onFailure:(nullable YGFailureBlock)failureBlock
                        onFinished:(nullable YGFinishedBlock)finishedBlock;

+ (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                        onProgress:(nullable YGProgressBlock)progressBlock
                         onSuccess:(nullable YGSuccessBlock)successBlock
                         onFailure:(nullable YGFailureBlock)failureBlock;

+ (nullable NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                        onProgress:(nullable YGProgressBlock)progressBlock
                         onSuccess:(nullable YGSuccessBlock)successBlock
                         onFailure:(nullable YGFailureBlock)failureBlock
                        onFinished:(nullable YGFinishedBlock)finishedBlock;

+ (nullable NSString *)sendBatchRequest:(YGBatchRequestConfigBlock)configBlock
                              onSuccess:(nullable YGBCSuccessBlock)successBlock
                              onFailure:(nullable YGBCFailureBlock)failureBlock
                             onFinished:(nullable YGBCFinishedBlock)finishedBlock;

+ (nullable NSString *)sendChainRequest:(YGChainRequestConfigBlock)configBlock
                              onSuccess:(nullable YGBCSuccessBlock)successBlock
                              onFailure:(nullable YGBCFailureBlock)failureBlock
                             onFinished:(nullable YGBCFinishedBlock)finishedBlock;

#pragma mark -

+ (void)cancelRequest:(NSString *)identifier;

+ (void)cancelRequest:(NSString *)identifier
             onCancel:(nullable YGCancelBlock)cancelBlock;

+ (nullable id)getRequest:(NSString *)identifier;

+ (BOOL)isNetworkReachable;

+ (YGNetworkConnectionType)networkConnectionType;

#pragma mark -

+ (void)addSSLPinningURL:(NSString *)url;
+ (void)addSSLPinningCert:(NSData *)cert;
+ (void)addTwowayAuthenticationPKCS12:(NSData *)p12 keyPassword:(NSString *)password;

@end

#pragma mark - YGConfig

/**
 `YGConfig` is used to assign values for YGCenter's properties through invoking `-setupConfig:` method.
 */
@interface YGConfig : NSObject

///-----------------------------------------------
/// @name Properties to Assign Values for YGCenter
///----------ƒ-------------------------------------

/**
The general server address to assign for YGCenter.
*/
@property (nonatomic, copy, nullable) NSString *generalServer;

/**
 The general parameters to assign for YGCenter.
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *generalParameters;

/**
 The general headers to assign for YGCenter.
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *generalHeaders;

/**
 The general user info to assign for YGCenter.
 */
@property (nonatomic, strong, nullable) NSDictionary *generalUserInfo;

/**
 The dispatch callback queue to assign for YGCenter.
 */
@property (nonatomic, strong, nullable) dispatch_queue_t callbackQueue;

/**
 The global requests engine to assign for YGCenter.
 */
@property (nonatomic, strong, nullable) YGEngine *engine;

/**
 The console log BOOL value to assign for YGCenter.
 */
@property (nonatomic, assign) BOOL consoleLog;

@end

NS_ASSUME_NONNULL_END
