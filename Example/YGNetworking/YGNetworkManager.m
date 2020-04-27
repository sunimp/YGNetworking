//
//  YGNetworkManager.m
//  YGNetworking_Example
//
//  Created by Sun on 2020/4/27.
//  Copyright © 2020 oneofai. All rights reserved.
//

#import "YGNetworkManager.h"
#import <objc/runtime.h>

#define YG_GITHUB_API_HOST @"https://github-trending-api.now.sh"

NSString * const YGNetworkingErrorDomain = @"YGNetworkingErrorDomain";

static NSError * YGNetworkingErrorGenerator(NSInteger code, NSString *msg) {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @""};
    NSError * __autoreleasing error = [NSError errorWithDomain:YGNetworkingErrorDomain code:code userInfo:userInfo];
    return error;
}


@implementation YGRequest (Business)

- (NSString *)version {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setVersion:(NSString *)version {
    objc_setAssociatedObject(self, @selector(version), version, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

#pragma mark - 控制台打印中文

#ifdef DEBUG
@implementation NSArray (Locale)

- (NSString *)descriptionWithLocale:(id)locale {
    NSString *result = nil;
    @try {
        NSString *consequence = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
        result = [consequence stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    } @catch (NSException *exception) {
        NSString *reason = [NSString stringWithFormat:@"reason:%@", exception.reason];
        result = [NSString stringWithFormat:@"转换失败:\n%@,\n转换终止,输出如下:\n%@", reason, self.description];
    } @finally {}
    return result;
}

@end

@implementation NSDictionary (Locale)

- (NSString *)descriptionWithLocale:(id)locale {
    NSString *result = nil;
    @try {
        NSString *consequence = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
        result = [consequence stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    } @catch (NSException *exception) {
        NSString *reason = [NSString stringWithFormat:@"reason:%@", exception.reason];
        result = [NSString stringWithFormat:@"转换失败:\n%@,\n转换终止,输出如下:\n%@", reason, self.description];
    } @finally {}
    return result;
}

@end
#endif


@implementation YGNetworkManager

+ (void)setup {
    // 网络请求全局配置
    [YGCenter setupConfig:^(YGConfig *config) {
        config.generalServer = YG_GITHUB_API_HOST;
        config.callbackQueue = dispatch_get_main_queue();
#ifdef DEBUG
        config.consoleLog = YES;
#endif
    }];
    
    // 请求预处理插件
    [YGCenter setRequestProcessBlock:^(YGRequest *request) {
        // 在这里对所有的请求进行统一的预处理，如业务数据加密等
        if (request.version.length > 0) {
            NSMutableDictionary *headers = [[NSMutableDictionary alloc] initWithDictionary:request.headers];
            headers[@"version"] = request.version;
            request.headers = headers;
        }
    }];
    
    // 响应后处理插件
    // 如果 Block 的返回值不为空，则 responseObject 会被替换为 Block 的返回值
    [YGCenter setResponseProcessBlock:^id(YGRequest *request, id responseObject, NSError *__autoreleasing * error) {
        // 在这里对请求的响应结果进行统一处理，如业务数据解密等
        if (![request.server isEqualToString:YG_GITHUB_API_HOST]) {
            return nil;
        }
        if ([responseObject isKindOfClass:[NSDictionary class]] && [[responseObject allKeys] count] > 0) {
            NSInteger code = [responseObject[@"code"] integerValue];
            if (code != kYGNetworkingSuccessCode) {
                // 网络请求成功，但接口返回的 Code 表示失败，这里给 *error 赋值，后续走 failureBlock 回调
                *error = YGNetworkingErrorGenerator(code, responseObject[@"msg"]);
            } else {
                // 返回的 Code 表示成功，对数据进行加工过滤，返回给上层业务
                NSDictionary *resultData = responseObject[@"data"];
                return resultData;
            }
        }
        return nil;
    }];
    
    // 错误统一过滤处理
    [YGCenter setErrorProcessBlock:^(YGRequest *request, NSError *__autoreleasing * error) {
        // 比如对不同的错误码统一错误提示等
        
    }];
}

@end
