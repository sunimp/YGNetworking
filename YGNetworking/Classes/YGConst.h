//
//  YGConst.h
//  YGNetworking
//
//  Created by Sun on 2019/4/25.
//  Copyright © 2019 YGNetworking. All rights reserved.
//

#ifndef YGConst_h
#define YGConst_h

#define YG_NETWORKING_SAFE_BLOCK(BlockName, ...) ({ !BlockName ? nil : BlockName(__VA_ARGS__); })
#define YG_NETWORKING_LOCK() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define YG_NETWORKING_UNLOCK() dispatch_semaphore_signal(self->_lock)

NS_ASSUME_NONNULL_BEGIN

@class YGRequest, YGBatchRequest, YGChainRequest;

/**
 YGRequest 请求类型枚举.
 */
typedef NS_ENUM(NSInteger, YGRequestType) {
    kYGRequestNormal    = 0,    //!< 标准的 HTTP 请求类型, 例如 GET, POST, ...
    kYGRequestUpload    = 1,    //!< 上传请求类型
    kYGRequestDownload  = 2,    //!< 下载请求类型
};

/**
 YGRequest HTTP 请求方法枚举.
 */
typedef NS_ENUM(NSInteger, YGHTTPMethodType) {
    kYGHTTPMethodGET    = 0,    //!< GET
    kYGHTTPMethodPOST   = 1,    //!< POST
    kYGHTTPMethodHEAD   = 2,    //!< HEAD
    kYGHTTPMethodDELETE = 3,    //!< DELETE
    kYGHTTPMethodPUT    = 4,    //!< PUT
    kYGHTTPMethodPATCH  = 5,    //!< PATCH
};

/**
 YGRequest 请求参数序列化类型枚举, 具体查看 `AFURLRequestSerialization.h`.
 */
typedef NS_ENUM(NSInteger, YGRequestSerializerType) {
    kYGRequestSerializerRAW     = 0,    //!< 将参数编码为 query 形式并将其放入 HTTP body 中，将编码后的请求的 `Content-Type` 设置为默认的 `application/x-www-form-urlencoded`.
    kYGRequestSerializerJSON    = 1,    //!< 将参数通过 `NSJSONSerialization` 编码为 JSON 形式，将编码后的请求 `Content-Type` 设置为 `application/json`.
    kYGRequestSerializerPlist   = 2,    //!< 将参数通过 `NSPropertyListSerialization` 编码为 plist 形式，将编码后的请求 `Content-Type` 设置为 `application/x-plist`.
};

/**
 YGRequest 响应体序列化类型枚举, 具体查看 `AFURLResponseSerialization.h`.
 */
typedef NS_ENUM(NSInteger, YGResponseSerializerType) {
    kYGResponseSerializerRAW    = 0,    //!< 验证响应体的 status code 和 content type，并返回默认响应体数据.
    kYGResponseSerializerJSON   = 1,    //!< 验证响应体，通过 `NSJSONSerialization` 解析为 JSON，并返回 NSDictionary/NSArray/... JSON 对象.
    kYGResponseSerializerPlist  = 2,    //!< 验证响应体，通过 `NSPropertyListSerialization` 解析为 plist，并返回一个 plist 对象.
    kYGResponseSerializerXML    = 3,    //!< 验证 XML 响应体，并解析为一个 `NSXMLParser` 对象.
};

/**
 网络连接类型枚举
 */
typedef NS_ENUM(NSInteger, YGNetworkConnectionType) {
    kYGNetworkConnectionTypeUnknown          = -1, // 未知
    kYGNetworkConnectionTypeNotReachable     = 0,  // 无网络
    kYGNetworkConnectionTypeViaWWAN          = 1,  // 移动网络
    kYGNetworkConnectionTypeViaWiFi          = 2,  // Wi-Fi
};

///------------------------------
/// @name YGRequest 配置 Blocks
///------------------------------

typedef void (^YGRequestConfigBlock)(YGRequest *request);
typedef void (^YGBatchRequestConfigBlock)(YGBatchRequest *batchRequest);
typedef void (^YGChainRequestConfigBlock)(YGChainRequest *chainRequest);

///--------------------------------
/// @name YGRequest 回调 Blocks
///--------------------------------

typedef void (^YGProgressBlock)(NSProgress *progress);
typedef void (^YGSuccessBlock)(id _Nullable responseObject);
typedef void (^YGFailureBlock)(NSError * _Nullable error);
typedef void (^YGFinishedBlock)(id _Nullable responseObject, NSError * _Nullable error);
typedef void (^YGCancelBlock)(id _Nullable request); // `request` 可能是一个 YGRequest/YGBatchRequest/YGChainRequest 对象.

///-------------------------------------------------
/// @name Batch 和 Chain 请求的回调 Blocks
///-------------------------------------------------

typedef void (^YGBCSuccessBlock)(NSArray *responseObjects);
typedef void (^YGBCFailureBlock)(NSArray *errors);
typedef void (^YGBCFinishedBlock)(NSArray * _Nullable responseObjects, NSArray * _Nullable errors);
typedef void (^YGBCNextBlock)(YGRequest *request, id _Nullable responseObject, BOOL *isSent);

///------------------------------
/// @name YGCenter 处理的 Blocks
///------------------------------

/**
 针对所有被 YGCenter 调用的 YGRequests 自定义请求预处理 block.
 
 @param request 当前 YGRequest 对象.
 */
typedef void (^YGCenterRequestProcessBlock)(YGRequest *request);

/**
 针对所有被 YGCenter 调用的 YGRequests 自定义响应处理 block.

 @param request 当前 YGRequest 对象.
 @param responseObject 从服务器返回的数据对象.
 @param error 当响应数据未遵循业务逻辑时发生的错误.
 */
typedef id _Nullable (^YGCenterResponseProcessBlock)(YGRequest *request, id _Nullable responseObject, NSError * _Nullable __autoreleasing *error);

/**
 针对所有被 YGCenter 调用的 YGRequests 自定义错误处理 block.
 
 @param request 当前 YGRequest 对象.
 @param error 当响应数据未遵循业务逻辑时发生的错误.
 */
typedef void (^YGCenterErrorProcessBlock)(YGRequest *request, NSError * _Nullable __autoreleasing *error);

NS_ASSUME_NONNULL_END

#endif /* YGConst_h */
