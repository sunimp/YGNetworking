//
//  YGNetworkManager.h
//  YGNetworking_Example
//
//  Created by Sun on 2020/4/27.
//  Copyright © 2020 oneofai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YGNetworking/YGNetworking.h>

NS_ASSUME_NONNULL_BEGIN

/**
 YGNetworking 使用示例
 */

typedef NS_ENUM(NSInteger, YGNetworkingCode) {
    // 接口请求成功
    kYGNetworkingSuccessCode    = 0,
    // 接口请求失败
    kYGNetworkingErrorCode      = 1,
    // 未知错误
    kYGNetworkingUnknownCode    = -1,
};

// 根据业务场景扩展 XMRequest

@interface YGRequest (Business)

// 接口版本号
@property (nonatomic, copy) NSString *version;

@end

@interface NSDictionary (Locale)

@end

@interface NSArray (Locale)

@end

#pragma mark - 管理类

@interface YGNetworkManager : NSObject

/**
 初始化网络配置
 */
+ (void)setup;

@end

NS_ASSUME_NONNULL_END
