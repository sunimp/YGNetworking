//
//  YGCenter.m
//  YGNetworking
//
//  Created by Sun on 2019/4/25.
//  Copyright © 2019 YGNetworking. All rights reserved.
//

#import "YGCenter.h"
#import "YGRequest.h"
#import "YGEngine.h"

#ifndef YGLog(...)
    #define YGLog(...) printf("%s", [[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#endif

@interface YGCenter () {
    dispatch_semaphore_t _lock;
}

@property (nonatomic, assign) NSUInteger autoIncrement;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *runningBatchAndChainPool;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, id> *generalParameters;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSString *> *generalHeaders;

@property (nonatomic, copy) YGCenterResponseProcessBlock responseProcessHandler;
@property (nonatomic, copy) YGCenterRequestProcessBlock requestProcessHandler;
@property (nonatomic, copy) YGCenterErrorProcessBlock errorProcessHandler;

@end

@implementation YGCenter

+ (instancetype)center {
    return [[[self class] alloc] init];
}

+ (instancetype)defaultCenter {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self center];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _autoIncrement = 0;
    _lock = dispatch_semaphore_create(1);
    _engine = [YGEngine sharedEngine];
    return self;
}

#pragma mark - Public Instance Methods for YGCenter

- (void)setupConfig:(void(^)(YGConfig *config))block {
    YGConfig *config = [[YGConfig alloc] init];
    config.consoleLog = NO;
    YG_NETWORKING_SAFE_BLOCK(block, config);
    
    if (config.generalServer) {
        self.generalServer = config.generalServer;
    }
    if (config.generalParameters.count > 0) {
        [self.generalParameters addEntriesFromDictionary:config.generalParameters];
    }
    if (config.generalHeaders.count > 0) {
        [self.generalHeaders addEntriesFromDictionary:config.generalHeaders];
    }
    if (config.callbackQueue != NULL) {
        self.callbackQueue = config.callbackQueue;
    }
    if (config.generalUserInfo) {
        self.generalUserInfo = config.generalUserInfo;
    }
    if (config.engine) {
        self.engine = config.engine;
    }
    self.consoleLog = config.consoleLog;
}

- (void)setRequestProcessBlock:(YGCenterRequestProcessBlock)block {
    self.requestProcessHandler = block;
}

- (void)setResponseProcessBlock:(YGCenterResponseProcessBlock)block {
    self.responseProcessHandler = block;
}

- (void)setErrorProcessBlock:(YGCenterErrorProcessBlock)block {
    self.errorProcessHandler = block;
}

- (void)setGeneralHeaderValue:(NSString *)value forField:(NSString *)field {
    [self.generalHeaders setValue:value forKey:field];
}

- (void)setGeneralParameterValue:(id)value forKey:(NSString *)key {
    [self.generalParameters setValue:value forKey:key];
}

#pragma mark -

- (NSString *)sendRequest:(YGRequestConfigBlock)configBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:nil onFinished:nil];
}

- (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                onSuccess:(nullable YGSuccessBlock)successBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:nil onFinished:nil];
}

- (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                onFailure:(nullable YGFailureBlock)failureBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:failureBlock onFinished:nil];
}

- (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
               onFinished:(nullable YGFinishedBlock)finishedBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:nil onFinished:finishedBlock];
}

- (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                onSuccess:(nullable YGSuccessBlock)successBlock
                onFailure:(nullable YGFailureBlock)failureBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:failureBlock onFinished:nil];
}

- (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                onSuccess:(nullable YGSuccessBlock)successBlock
                onFailure:(nullable YGFailureBlock)failureBlock
               onFinished:(nullable YGFinishedBlock)finishedBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

- (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
               onProgress:(nullable YGProgressBlock)progressBlock
                onSuccess:(nullable YGSuccessBlock)successBlock
                onFailure:(nullable YGFailureBlock)failureBlock {
    return [self sendRequest:configBlock onProgress:progressBlock onSuccess:successBlock onFailure:failureBlock onFinished:nil];
}

- (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
               onProgress:(nullable YGProgressBlock)progressBlock
                onSuccess:(nullable YGSuccessBlock)successBlock
                onFailure:(nullable YGFailureBlock)failureBlock
               onFinished:(nullable YGFinishedBlock)finishedBlock {
    YGRequest *request = [YGRequest request];
    YG_NETWORKING_SAFE_BLOCK(configBlock, request);
    
    [self yg_processRequest:request onProgress:progressBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
    [self yg_sendRequest:request];
    
    return request.identifier;
}

- (NSString *)sendBatchRequest:(YGBatchRequestConfigBlock)configBlock
                     onSuccess:(nullable YGBCSuccessBlock)successBlock
                     onFailure:(nullable YGBCFailureBlock)failureBlock
                    onFinished:(nullable YGBCFinishedBlock)finishedBlock {
    YGBatchRequest *batchRequest = [[YGBatchRequest alloc] init];
    YG_NETWORKING_SAFE_BLOCK(configBlock, batchRequest);
    
    if (batchRequest.requestArray.count > 0) {
        if (successBlock) {
            [batchRequest setValue:successBlock forKey:@"_batchSuccessBlock"];
        }
        if (failureBlock) {
            [batchRequest setValue:failureBlock forKey:@"_batchFailureBlock"];
        }
        if (finishedBlock) {
            [batchRequest setValue:finishedBlock forKey:@"_batchFinishedBlock"];
        }
        
        [batchRequest.responseArray removeAllObjects];
        for (YGRequest *request in batchRequest.requestArray) {
            [batchRequest.responseArray addObject:[NSNull null]];
            __weak __typeof(self)weakSelf = self;
            [self yg_processRequest:request
                         onProgress:nil
                          onSuccess:nil
                          onFailure:nil
                         onFinished:^(id responseObject, NSError *error) {
                             if ([batchRequest onFinishedOneRequest:request response:responseObject error:error]) {
                                 __strong __typeof(weakSelf)strongSelf = weakSelf;
                                 dispatch_semaphore_wait(strongSelf->_lock, DISPATCH_TIME_FOREVER);
                                 [strongSelf.runningBatchAndChainPool removeObjectForKey:batchRequest.identifier];
                                 dispatch_semaphore_signal(strongSelf->_lock);
                             }
                         }];
            [self yg_sendRequest:request];
        }
        
        NSString *identifier = [self yg_identifierForBatchAndChainRequest];
        [batchRequest setValue:identifier forKey:@"_identifier"];
        YG_NETWORKING_LOCK();
        [self.runningBatchAndChainPool setValue:batchRequest forKey:identifier];
        YG_NETWORKING_UNLOCK();
        
        return identifier;
    } else {
        return nil;
    }
}

- (NSString *)sendChainRequest:(YGChainRequestConfigBlock)configBlock
                     onSuccess:(nullable YGBCSuccessBlock)successBlock
                     onFailure:(nullable YGBCFailureBlock)failureBlock
                    onFinished:(nullable YGBCFinishedBlock)finishedBlock {
    YGChainRequest *chainRequest = [[YGChainRequest alloc] init];
    YG_NETWORKING_SAFE_BLOCK(configBlock, chainRequest);
    
    if (chainRequest.runningRequest) {
        if (successBlock) {
            [chainRequest setValue:successBlock forKey:@"_chainSuccessBlock"];
        }
        if (failureBlock) {
            [chainRequest setValue:failureBlock forKey:@"_chainFailureBlock"];
        }
        if (finishedBlock) {
            [chainRequest setValue:finishedBlock forKey:@"_chainFinishedBlock"];
        }
        
        [self yg_sendChainRequest:chainRequest];
        
        NSString *identifier = [self yg_identifierForBatchAndChainRequest];
        [chainRequest setValue:identifier forKey:@"_identifier"];
        YG_NETWORKING_LOCK();
        [self.runningBatchAndChainPool setValue:chainRequest forKey:identifier];
        YG_NETWORKING_UNLOCK();
        
        return identifier;
    } else {
        return nil;
    }
}

#pragma mark -

- (void)cancelRequest:(NSString *)identifier {
    [self cancelRequest:identifier onCancel:nil];
}

- (void)cancelRequest:(NSString *)identifier
             onCancel:(nullable YGCancelBlock)cancelBlock {
    id request = nil;
    if ([identifier hasPrefix:@"BC"]) {
        YG_NETWORKING_LOCK();
        request = [self.runningBatchAndChainPool objectForKey:identifier];
        [self.runningBatchAndChainPool removeObjectForKey:identifier];
        YG_NETWORKING_UNLOCK();
        if ([request isKindOfClass:[YGBatchRequest class]]) {
            YGBatchRequest *batchRequest = request;
            if (batchRequest.requestArray.count > 0) {
                for (YGRequest *rq in batchRequest.requestArray) {
                    if (rq.identifier.length > 0) {
                        [self.engine cancelRequestByIdentifier:rq.identifier];
                    }
                }
            }
        } else if ([request isKindOfClass:[YGChainRequest class]]) {
            YGChainRequest *chainRequest = request;
            if (chainRequest.runningRequest && chainRequest.runningRequest.identifier.length > 0) {
                [self.engine cancelRequestByIdentifier:chainRequest.runningRequest.identifier];
            }
        }
    } else if (identifier.length > 0) {
        request = [self.engine cancelRequestByIdentifier:identifier];
    }
    YG_NETWORKING_SAFE_BLOCK(cancelBlock, request);
}

- (id)getRequest:(NSString *)identifier {
    if (identifier == nil) {
        return nil;
    } else if ([identifier hasPrefix:@"BC"]) {
        YG_NETWORKING_LOCK();
        id request = [self.runningBatchAndChainPool objectForKey:identifier];
        YG_NETWORKING_UNLOCK();
        return request;
    } else {
        return [self.engine getRequestByIdentifier:identifier];
    }
}

- (BOOL)isNetworkReachable {
    return self.engine.reachabilityStatus != 0;
}

- (YGNetworkConnectionType)networkConnectionType {
    return self.engine.reachabilityStatus;
}

#pragma mark - Public Class Methods for YGCenter

+ (void)setupConfig:(void(^)(YGConfig *config))block {
    [[YGCenter defaultCenter] setupConfig:block];
}

+ (void)setRequestProcessBlock:(YGCenterRequestProcessBlock)block {
    [[YGCenter defaultCenter] setRequestProcessBlock:block];
}

+ (void)setResponseProcessBlock:(YGCenterResponseProcessBlock)block {
    [[YGCenter defaultCenter] setResponseProcessBlock:block];
}

+ (void)setErrorProcessBlock:(YGCenterErrorProcessBlock)block {
    [[YGCenter defaultCenter] setErrorProcessBlock:block];
}

+ (void)setGeneralHeaderValue:(NSString *)value forField:(NSString *)field {
    [[YGCenter defaultCenter].generalHeaders setValue:value forKey:field];
}

+ (void)setGeneralParameterValue:(id)value forKey:(NSString *)key {
    [[YGCenter defaultCenter].generalParameters setValue:value forKey:key];
}

#pragma mark -

+ (NSString *)sendRequest:(YGRequestConfigBlock)configBlock {
    return [[YGCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:nil onFinished:nil];
}

+ (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                onSuccess:(nullable YGSuccessBlock)successBlock {
    return [[YGCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:nil onFinished:nil];
}

+ (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                onFailure:(nullable YGFailureBlock)failureBlock {
    return [[YGCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:failureBlock onFinished:nil];
}

+ (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
               onFinished:(nullable YGFinishedBlock)finishedBlock {
    return [[YGCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:nil onFinished:finishedBlock];
}

+ (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                onSuccess:(nullable YGSuccessBlock)successBlock
                onFailure:(nullable YGFailureBlock)failureBlock {
    return [[YGCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:failureBlock onFinished:nil];
}

+ (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
                onSuccess:(nullable YGSuccessBlock)successBlock
                onFailure:(nullable YGFailureBlock)failureBlock
               onFinished:(nullable YGFinishedBlock)finishedBlock {
    return [[YGCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

+ (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
               onProgress:(nullable YGProgressBlock)progressBlock
                onSuccess:(nullable YGSuccessBlock)successBlock
                onFailure:(nullable YGFailureBlock)failureBlock {
    return [[YGCenter defaultCenter] sendRequest:configBlock onProgress:progressBlock onSuccess:successBlock onFailure:failureBlock onFinished:nil];
}

+ (NSString *)sendRequest:(YGRequestConfigBlock)configBlock
               onProgress:(nullable YGProgressBlock)progressBlock
                onSuccess:(nullable YGSuccessBlock)successBlock
                onFailure:(nullable YGFailureBlock)failureBlock
               onFinished:(nullable YGFinishedBlock)finishedBlock {
    return [[YGCenter defaultCenter] sendRequest:configBlock onProgress:progressBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

+ (NSString *)sendBatchRequest:(YGBatchRequestConfigBlock)configBlock
                     onSuccess:(nullable YGBCSuccessBlock)successBlock
                     onFailure:(nullable YGBCFailureBlock)failureBlock
                    onFinished:(nullable YGBCFinishedBlock)finishedBlock {
    return [[YGCenter defaultCenter] sendBatchRequest:configBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

+ (NSString *)sendChainRequest:(YGChainRequestConfigBlock)configBlock
                     onSuccess:(nullable YGBCSuccessBlock)successBlock
                     onFailure:(nullable YGBCFailureBlock)failureBlock
                    onFinished:(nullable YGBCFinishedBlock)finishedBlock {
    return [[YGCenter defaultCenter] sendChainRequest:configBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

#pragma mark -

+ (void)cancelRequest:(NSString *)identifier {
    [[YGCenter defaultCenter] cancelRequest:identifier onCancel:nil];
}

+ (void)cancelRequest:(NSString *)identifier
             onCancel:(nullable YGCancelBlock)cancelBlock {
    [[YGCenter defaultCenter] cancelRequest:identifier onCancel:cancelBlock];
}

+ (nullable id)getRequest:(NSString *)identifier {
    return [[YGCenter defaultCenter] getRequest:identifier];
}

+ (BOOL)isNetworkReachable {
    return [[YGCenter defaultCenter] isNetworkReachable];
}

+ (YGNetworkConnectionType)networkConnectionType {
    return [[YGCenter defaultCenter] networkConnectionType];
}

#pragma mark -

+ (void)addSSLPinningURL:(NSString *)url {
    [[YGCenter defaultCenter].engine addSSLPinningURL:url];
}

+ (void)addSSLPinningCert:(NSData *)cert {
    [[YGCenter defaultCenter].engine addSSLPinningCert:cert];
}

+ (void)addTwowayAuthenticationPKCS12:(NSData *)p12 keyPassword:(NSString *)password {
    [[YGCenter defaultCenter].engine addTwowayAuthenticationPKCS12:p12 keyPassword:password];
}

#pragma mark - Private Methods for YGCenter

- (void)yg_sendChainRequest:(YGChainRequest *)chainRequest {
    if (chainRequest.runningRequest != nil) {
        __weak __typeof(self)weakSelf = self;
        [self yg_processRequest:chainRequest.runningRequest
                     onProgress:nil
                      onSuccess:nil
                      onFailure:nil
                     onFinished:^(id responseObject, NSError *error) {
                         __strong __typeof(weakSelf)strongSelf = weakSelf;
                         if ([chainRequest onFinishedOneRequest:chainRequest.runningRequest response:responseObject error:error]) {
                             dispatch_semaphore_wait(strongSelf->_lock, DISPATCH_TIME_FOREVER);
                             [strongSelf.runningBatchAndChainPool removeObjectForKey:chainRequest.identifier];
                             dispatch_semaphore_signal(strongSelf->_lock);
                         } else {
                             if (chainRequest.runningRequest != nil) {
                                 [strongSelf yg_sendChainRequest:chainRequest];
                             }
                         }
                     }];
        
        [self yg_sendRequest:chainRequest.runningRequest];
    }
}

- (void)yg_processRequest:(YGRequest *)request
               onProgress:(YGProgressBlock)progressBlock
                onSuccess:(YGSuccessBlock)successBlock
                onFailure:(YGFailureBlock)failureBlock
               onFinished:(YGFinishedBlock)finishedBlock {
    
    // set callback blocks for the request object.
    if (successBlock) {
        [request setValue:successBlock forKey:@"_successBlock"];
    }
    if (failureBlock) {
        [request setValue:failureBlock forKey:@"_failureBlock"];
    }
    if (finishedBlock) {
        [request setValue:finishedBlock forKey:@"_finishedBlock"];
    }
    if (progressBlock && request.requestType != kYGRequestNormal) {
        [request setValue:progressBlock forKey:@"_progressBlock"];
    }
    
    // add general user info to the request object.
    if (!request.userInfo && self.generalUserInfo) {
        request.userInfo = self.generalUserInfo;
    }
    
    // add general parameters to the request object.
    if (request.useGeneralParameters && self.generalParameters.count > 0) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters addEntriesFromDictionary:self.generalParameters];
        if (request.parameters.count > 0) {
            [parameters addEntriesFromDictionary:request.parameters];
        }
        request.parameters = parameters;
    }
    
    // add general headers to the request object.
    if (request.useGeneralHeaders && self.generalHeaders.count > 0) {
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        [headers addEntriesFromDictionary:self.generalHeaders];
        if (request.headers) {
            [headers addEntriesFromDictionary:request.headers];
        }
        request.headers = headers;
    }
    
    // process url for the request object.
    if (request.url.length == 0) {
        if (request.server.length == 0 && request.useGeneralServer && self.generalServer.length > 0) {
            request.server = self.generalServer;
        }
        if (request.api.length > 0) {
            NSURL *baseURL = [NSURL URLWithString:request.server];
            // ensure terminal slash for baseURL path, so that NSURL +URLWithString:relativeToURL: works as expected.
            if ([[baseURL path] length] > 0 && ![[baseURL absoluteString] hasSuffix:@"/"]) {
                baseURL = [baseURL URLByAppendingPathComponent:@""];
            }
            request.url = [[NSURL URLWithString:request.api relativeToURL:baseURL] absoluteString];
        } else {
            request.url = request.server;
        }
    }
    
    YG_NETWORKING_SAFE_BLOCK(self.requestProcessHandler, request);
    NSAssert(request.url.length > 0, @"The request url can't be null.");
}

- (void)yg_sendRequest:(YGRequest *)request {
    
    if (self.consoleLog) {
        if (request.requestType == kYGRequestDownload) {
            YGLog(@"\n============ [YGRequest Info] ============\nrequest download url: %@\nrequest save path: %@ \nrequest headers: \n%@ \nrequest parameters: \n%@ \n==========================================\n", request.url, request.downloadSavePath, request.headers, request.parameters);
        } else {
            YGLog(@"\n============ [YGRequest Info] ============\nrequest url: %@ \nrequest headers: \n%@ \nrequest parameters: \n%@ \n==========================================\n", request.url, request.headers, request.parameters);
        }
    }
    
    // send the request through YGEngine.
    [self.engine sendRequest:request completionHandler:^(id responseObject, NSError *error) {
        // the completionHandler will be execured in a private concurrent dispatch queue.
        if (error) {
            [self yg_failureWithError:error forRequest:request];
        } else {
            [self yg_successWithResponse:responseObject forRequest:request];
        }
    }];
}

- (void)yg_successWithResponse:(id)responseObject forRequest:(YGRequest *)request {
    
    NSError *processError = nil;
    // custom processing the response data.
    id newResponseObject = YG_NETWORKING_SAFE_BLOCK(self.responseProcessHandler, request, responseObject, &processError);
    if (newResponseObject) {
        responseObject = newResponseObject;
    }
    if (processError) {
        [self yg_failureWithError:processError forRequest:request];
        return;
    }
    
    if (self.consoleLog) {
        if (request.requestType == kYGRequestDownload) {
            YGLog(@"\n============ [YGResponse Data] ===========\nrequest download url: %@\nresponse data: %@\n==========================================\n", request.url, responseObject);
        } else {
            if (request.responseSerializerType == kYGResponseSerializerRAW) {
                YGLog(@"\n============ [YGResponse Data] ===========\nrequest url: %@ \nresponse data: \n%@\n==========================================\n", request.url, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            } else {
                YGLog(@"\n============ [YGResponse Data] ===========\nrequest url: %@ \nresponse data: \n%@\n==========================================\n", request.url, responseObject);
            }
        }
    }
    
    if (self.callbackQueue) {
        __weak __typeof(self)weakSelf = self;
        dispatch_async(self.callbackQueue, ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf yg_execureSuccessBlockWithResponse:responseObject forRequest:request];
        });
    } else {
        // execure success block on a private concurrent dispatch queue.
        [self yg_execureSuccessBlockWithResponse:responseObject forRequest:request];
    }
}

- (void)yg_execureSuccessBlockWithResponse:(id)responseObject forRequest:(YGRequest *)request {
    YG_NETWORKING_SAFE_BLOCK(request.successBlock, responseObject);
    YG_NETWORKING_SAFE_BLOCK(request.finishedBlock, responseObject, nil);
    [request cleanCallbackBlocks];
}

- (void)yg_failureWithError:(NSError *)error forRequest:(YGRequest *)request {
    
    if (self.consoleLog) {
        YGLog(@"\n=========== [YGResponse Error] ===========\nrequest url: %@ \nerror info: \n%@\n==========================================\n", request.url, error);
    }
    
    YG_NETWORKING_SAFE_BLOCK(self.errorProcessHandler, request, &error);
    
    if (request.retryCount > 0) {
        request.retryCount --;
        // retry current request after 2 seconds.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self yg_sendRequest:request];
        });
        return;
    }
    
    if (self.callbackQueue) {
        __weak __typeof(self)weakSelf = self;
        dispatch_async(self.callbackQueue, ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf yg_execureFailureBlockWithError:error forRequest:request];
        });
    } else {
        // execure failure block in a private concurrent dispatch queue.
        [self yg_execureFailureBlockWithError:error forRequest:request];
    }
}

- (void)yg_execureFailureBlockWithError:(NSError *)error forRequest:(YGRequest *)request {
    YG_NETWORKING_SAFE_BLOCK(request.failureBlock, error);
    YG_NETWORKING_SAFE_BLOCK(request.finishedBlock, nil, error);
    [request cleanCallbackBlocks];
}

- (NSString *)yg_identifierForBatchAndChainRequest {
    NSString *identifier = nil;
    YG_NETWORKING_LOCK();
    self.autoIncrement++;
    identifier = [NSString stringWithFormat:@"BC%lu", (unsigned long)self.autoIncrement];
    YG_NETWORKING_UNLOCK();
    return identifier;
}

#pragma mark - Accessor

- (NSMutableDictionary<NSString *, id> *)runningBatchAndChainPool {
    if (!_runningBatchAndChainPool) {
        _runningBatchAndChainPool = [NSMutableDictionary dictionary];
    }
    return _runningBatchAndChainPool;
}

- (NSMutableDictionary<NSString *, id> *)generalParameters {
    if (!_generalParameters) {
        _generalParameters = [NSMutableDictionary dictionary];
    }
    return _generalParameters;
}

- (NSMutableDictionary<NSString *, NSString *> *)generalHeaders {
    if (!_generalHeaders) {
        _generalHeaders = [NSMutableDictionary dictionary];
    }
    return _generalHeaders;
}

@end

#pragma mark - YGConfig

@implementation YGConfig
@end
