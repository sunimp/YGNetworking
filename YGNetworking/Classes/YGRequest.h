//
//  YGRequest.h
//  YGNetworking
//
//  Created by Sun on 2019/4/25.
//  Copyright © 2019 YGNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YGConst.h"

NS_ASSUME_NONNULL_BEGIN

@class YGUploadFormData;

/**
 `YGRequest` 是被 `YGCenter` 调用的所有网络请求的基础类.
 */
@interface YGRequest : NSObject

/**
 创建并返回一个 `YGRequest` 对象.
 */
+ (instancetype)request;

/**
 YGRequest 对象的唯一标示, 当请求发送时被 YGCenter 赋值.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 请求的服务器地址，eg. "http://example.com/v1/"，如果为 `nil` (默认为 nil) 并且 `useGeneralServer` 属性为 `YES` (默认为 YES)，将会使用 YGCenter 的 `generalServer`.
 */
@property (nonatomic, copy, nullable) NSString *server;

/**
 请求的 API 接口路径，eg. "foo/bar"，默认为 `nil`.
 */
@property (nonatomic, copy, nullable) NSString *api;

/**
 请求的最终 URL，通过 `server` 和 `api` 两个属性组合而成，eg. "http://example.com/v1/foo/bar", 默认为 `nil`.
 NOTE: 当你手动对 `url` 设置值以后，`server` 和 `api` 两个属性的值会被忽略.
 */
@property (nonatomic, copy, nullable) NSString *url;

/**
 请求参数， 如果 `useGeneralParameters` 属性为 `YES` (默认为 YES)，YGCenter 中的 `generalParameters` 将会追加到 `parameters` 里.
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *parameters;

/**
 请求头，如果 `useGeneralHeaders` 属性为 `YES` (默认为 YES)，YGCenter 中的 `generalHeaders` 将会追加道 `headers` 里.
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *headers;

/// 当 `server` 为 `nil`时，是否使用 YGCenter 中的 `generalServer`，默认为 `YES`.
@property (nonatomic, assign) BOOL useGeneralServer;

/// 是否把 YGCenter 中的 `generalHeaders` 追加到请求的 `headers` 里，默认为 `YES`.
@property (nonatomic, assign) BOOL useGeneralHeaders;


/// 是否把 YGCenter 中的 `generalParameters` 追加到请求的 `parameters` 里，默认为 `YES`.
@property (nonatomic, assign) BOOL useGeneralParameters;

/**
 请求类型: Normal, Upload 或 Download, 默认为 `kYGRequestNormal`.
 */
@property (nonatomic, assign) YGRequestType requestType;

/**
 HTTP 请求方法, 默认为 `kYGHTTPMethodPOST`, 具体查看 `YGHTTPMethodType` 枚举.
 */
@property (nonatomic, assign) YGHTTPMethodType httpMethod;

/**
 请求参数序列化类型，默认为 `kYGRequestSerializerRAW`，具体查看 `YGRequestSerializerType` 枚举.
 */
@property (nonatomic, assign) YGRequestSerializerType requestSerializerType;

/**
 请求响应体序列化类型，默认为 `kYGResponseSerializerJSON`，具体查看 `YGResponseSerializerType` 枚举.
 */
@property (nonatomic, assign) YGResponseSerializerType responseSerializerType;

/**
 请求超时时间，默认为 `60` 秒.
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 当错误发生时的重试次数，默认为 `0`.
 */
@property (nonatomic, assign) NSUInteger retryCount;

/**
 当前请求的用户信息，可以用来区分具有相同上下文的请求，如果为 `nil` (默认为 nil)，将使用 YGCenter 中的 `generalUserInfo`.
 */
@property (nonatomic, strong, nullable) NSDictionary *userInfo;

/**
 请求成功的回调，当请求成功完成时调用，block 将在 YGCenter 设置的 `callbackQueue` 中被执行.
 */
@property (nonatomic, copy, readonly, nullable) YGSuccessBlock successBlock;

/**
 请求失败的回调，当错误发生时调用，block 将在 YGCenter 设置的 `callbackQueue` 中被执行.
 */
@property (nonatomic, copy, readonly, nullable) YGFailureBlock failureBlock;

/**
 请求结束的回调，当请求结束时调用，block 将在 YGCenter 设置的 `callbackQueue` 中被执行.
 */
@property (nonatomic, copy, readonly, nullable) YGFinishedBlock finishedBlock;

/**
 上传/下载请求的进度回调，当上传/下载进度更新时调用.
 NOTE: 这个 block 时再 session 队列里调用，不是 YGCenter 设置的 `callbackQueue` 中！！！
 */
@property (nonatomic, copy, readonly, nullable) YGProgressBlock progressBlock;

/**
 清空所有回调，当请求结束用以打破潜在的循环引用.
 */
- (void)cleanCallbackBlocks;

/**
 上传请求的表单数据，默认为 `nil`，具体查看 `YGUploadFormData` 和 `AFMultipartFormData` 协议
 NOTE: 这个属性只在 `requestType` 为 `kYGRequestUpload` 时有效果.
 */
@property (nonatomic, strong, nullable) NSMutableArray<YGUploadFormData *> *uploadFormDatas;

/**
 下载文件的本地保存路径，默认为 `nil`.
 NOTE: 这个属性只在 `requestType` 为 `kYGRequestDownload` 时有效果.
 */
@property (nonatomic, copy, nullable) NSString *downloadSavePath;

///----------------------------------------------------
/// @name 添加上传文件表单数据的便捷方法
///----------------------------------------------------

- (void)addFormDataWithName:(NSString *)name fileData:(NSData *)fileData;
- (void)addFormDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData;
- (void)addFormDataWithName:(NSString *)name fileURL:(NSURL *)fileURL;
- (void)addFormDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL;

@end

#pragma mark - YGBatchRequest

///------------------------------------------------------
/// @name YGBatchRequest 是批量请求的类
///------------------------------------------------------

@interface YGBatchRequest : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSMutableArray *requestArray;
@property (nonatomic, strong, readonly) NSMutableArray *responseArray;

- (BOOL)onFinishedOneRequest:(YGRequest *)request response:(nullable id)responseObject error:(nullable NSError *)error;

@end

#pragma mark - YGChainRequest

///------------------------------------------------------
/// @name YGChainRequest 是链式请求的类
///------------------------------------------------------

@interface YGChainRequest : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) YGRequest *runningRequest;

- (YGChainRequest *)onFirst:(YGRequestConfigBlock)firstBlock;
- (YGChainRequest *)onNext:(YGBCNextBlock)nextBlock;

- (BOOL)onFinishedOneRequest:(YGRequest *)request response:(nullable id)responseObject error:(nullable NSError *)error;

@end

#pragma mark - YGUploadFormData

/**
 `YGUploadFormData` 是描述和承载上传文件数据的类，具体查看 `AFMultipartFormData` 协议.
 */
@interface YGUploadFormData : NSObject

/**
 为指定数据关联的名字，这个属性一定不能设为 `nil`.
 */
@property (nonatomic, copy) NSString *name;

/**
 文件名字用在 `Content-Disposition` 头里. 这个属性不推荐设为 `nil`.
 */
@property (nonatomic, copy, nullable) NSString *fileName;

/**
 文件数据的 MIME 类型. 这个属性不推荐设为 `nil`.
 */
@property (nonatomic, copy, nullable) NSString *mimeType;

/**
 被编码和追加到表单里的数据，比 `fileURL` 优先级高.
 */
@property (nonatomic, strong, nullable) NSData *fileData;

/**
 被追到表单里的文件的 URL，当设置了 `fileData` 时，这个属性将被忽略.
 NOTE: `fileData` 和 `fileURL` 不应该同时为 `nil`，并且 `fileName` 和 `mimeType` 必须都设为 `nil` 或者同时设置.
 */
@property (nonatomic, strong, nullable) NSURL *fileURL;

///-----------------------------------------------------
/// @name 创建对象的便捷静态方法
///-----------------------------------------------------

+ (instancetype)formDataWithName:(NSString *)name fileData:(NSData *)fileData;
+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData;
+ (instancetype)formDataWithName:(NSString *)name fileURL:(NSURL *)fileURL;
+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL;

@end

NS_ASSUME_NONNULL_END
