//
//  YGRequest.m
//  YGNetworking
//
//  Created by Sun on 2019/4/25.
//  Copyright © 2019 YGNetworking. All rights reserved.
//

#import "YGRequest.h"

//#define YGMEMORYLOG

@interface YGRequest ()

@end

@implementation YGRequest

+ (instancetype)request {
    return [[[self class] alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Set default value for YGRequest instance
    _requestType = kYGRequestNormal;
    _httpMethod = kYGHTTPMethodPOST;
    _requestSerializerType = kYGRequestSerializerRAW;
    _responseSerializerType = kYGResponseSerializerJSON;
    _timeoutInterval = 60.0;
    
    _useGeneralServer = YES;
    _useGeneralHeaders = YES;
    _useGeneralParameters = YES;
    
    _retryCount = 0;
    
#ifdef YGMEMORYLOG
    NSLog(@"%@: %s", self, __FUNCTION__);
#endif
    
    return self;
}

- (void)cleanCallbackBlocks {
    _successBlock = nil;
    _failureBlock = nil;
    _finishedBlock = nil;
    _progressBlock = nil;
}

- (NSMutableArray<YGUploadFormData *> *)uploadFormDatas {
    if (!_uploadFormDatas) {
        _uploadFormDatas = [NSMutableArray array];
    }
    return _uploadFormDatas;
}

- (void)addFormDataWithName:(NSString *)name fileData:(NSData *)fileData {
    YGUploadFormData *formData = [YGUploadFormData formDataWithName:name fileData:fileData];
    [self.uploadFormDatas addObject:formData];
}

- (void)addFormDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData {
    YGUploadFormData *formData = [YGUploadFormData formDataWithName:name fileName:fileName mimeType:mimeType fileData:fileData];
    [self.uploadFormDatas addObject:formData];
}

- (void)addFormDataWithName:(NSString *)name fileURL:(NSURL *)fileURL {
    YGUploadFormData *formData = [YGUploadFormData formDataWithName:name fileURL:fileURL];
    [self.uploadFormDatas addObject:formData];
}

- (void)addFormDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL {
    YGUploadFormData *formData = [YGUploadFormData formDataWithName:name fileName:fileName mimeType:mimeType fileURL:fileURL];
    [self.uploadFormDatas addObject:formData];
}

#ifdef YGMEMORYLOG
- (void)dealloc {
    NSLog(@"%@: %s", self, __FUNCTION__);
}
#endif

@end

#pragma mark - YGBatchRequest

@interface YGBatchRequest () {
    dispatch_semaphore_t _lock;
    NSUInteger _finishedCount;
    BOOL _failed;
}

@property (nonatomic, copy) YGBCSuccessBlock batchSuccessBlock;
@property (nonatomic, copy) YGBCFailureBlock batchFailureBlock;
@property (nonatomic, copy) YGBCFinishedBlock batchFinishedBlock;

@end

@implementation YGBatchRequest

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _failed = NO;
    _finishedCount = 0;
    _lock = dispatch_semaphore_create(1);

    _requestArray = [NSMutableArray array];
    _responseArray = [NSMutableArray array];

#ifdef YGMEMORYLOG
    NSLog(@"%@: %s", self, __FUNCTION__);
#endif
    
    return self;
}

- (BOOL)onFinishedOneRequest:(YGRequest *)request response:(id)responseObject error:(NSError *)error {
    BOOL isFinished = NO;
    YG_NETWORKING_LOCK();
    NSUInteger index = [_requestArray indexOfObject:request];
    if (responseObject) {
        [_responseArray replaceObjectAtIndex:index withObject:responseObject];
    } else {
        _failed = YES;
        if (error) {
            [_responseArray replaceObjectAtIndex:index withObject:error];
        }
    }
    
    _finishedCount++;
    if (_finishedCount == _requestArray.count) {
        if (!_failed) {
            YG_NETWORKING_SAFE_BLOCK(_batchSuccessBlock, _responseArray);
            YG_NETWORKING_SAFE_BLOCK(_batchFinishedBlock, _responseArray, nil);
        } else {
            YG_NETWORKING_SAFE_BLOCK(_batchFailureBlock, _responseArray);
            YG_NETWORKING_SAFE_BLOCK(_batchFinishedBlock, nil, _responseArray);
        }
        [self cleanCallbackBlocks];
        isFinished = YES;
    }
    YG_NETWORKING_UNLOCK();
    return isFinished;
}

- (void)cleanCallbackBlocks {
    _batchSuccessBlock = nil;
    _batchFailureBlock = nil;
    _batchFinishedBlock = nil;
}

#ifdef YGMEMORYLOG
- (void)dealloc {
    NSLog(@"%@: %s", self, __FUNCTION__);
}
#endif

@end

#pragma mark - YGChainRequest

@interface YGChainRequest () {
    NSUInteger _chainIndex;
}

@property (nonatomic, strong, readwrite) YGRequest *runningRequest;

@property (nonatomic, strong) NSMutableArray<YGBCNextBlock> *nextBlockArray;
@property (nonatomic, strong) NSMutableArray *responseArray;

@property (nonatomic, copy) YGBCSuccessBlock chainSuccessBlock;
@property (nonatomic, copy) YGBCFailureBlock chainFailureBlock;
@property (nonatomic, copy) YGBCFinishedBlock chainFinishedBlock;

@end

@implementation YGChainRequest : NSObject

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _chainIndex = 0;
    _responseArray = [NSMutableArray array];
    _nextBlockArray = [NSMutableArray array];
    
#ifdef YGMEMORYLOG
    NSLog(@"%@: %s", self, __FUNCTION__);
#endif
    
    return self;
}

- (YGChainRequest *)onFirst:(YGRequestConfigBlock)firstBlock {
    NSAssert(firstBlock != nil, @"The first block for chain requests can't be nil.");
    NSAssert(_nextBlockArray.count == 0, @"The `-onFirst:` method must called befault `-onNext:` method");
    _runningRequest = [YGRequest request];
    firstBlock(_runningRequest);
    [_responseArray addObject:[NSNull null]];
    return self;
}

- (YGChainRequest *)onNext:(YGBCNextBlock)nextBlock {
    NSAssert(nextBlock != nil, @"The next block for chain requests can't be nil.");
    [_nextBlockArray addObject:nextBlock];
    [_responseArray addObject:[NSNull null]];
    return self;
}

- (BOOL)onFinishedOneRequest:(YGRequest *)request response:(id)responseObject error:(NSError *)error {
    BOOL isFinished = NO;
    if (responseObject) {
        [_responseArray replaceObjectAtIndex:_chainIndex withObject:responseObject];
        if (_chainIndex < _nextBlockArray.count) {
            _runningRequest = [YGRequest request];
            YGBCNextBlock nextBlock = _nextBlockArray[_chainIndex];
            BOOL isSent = YES;
            nextBlock(_runningRequest, responseObject, &isSent);
            if (!isSent) {
                YG_NETWORKING_SAFE_BLOCK(_chainFailureBlock, _responseArray);
                YG_NETWORKING_SAFE_BLOCK(_chainFinishedBlock, nil, _responseArray);
                [self cleanCallbackBlocks];
                isFinished = YES;
            }
        } else {
            YG_NETWORKING_SAFE_BLOCK(_chainSuccessBlock, _responseArray);
            YG_NETWORKING_SAFE_BLOCK(_chainFinishedBlock, _responseArray, nil);
            [self cleanCallbackBlocks];
            isFinished = YES;
        }
    } else {
        if (error) {
            [_responseArray replaceObjectAtIndex:_chainIndex withObject:error];
        }
        YG_NETWORKING_SAFE_BLOCK(_chainFailureBlock, _responseArray);
        YG_NETWORKING_SAFE_BLOCK(_chainFinishedBlock, nil, _responseArray);
        [self cleanCallbackBlocks];
        isFinished = YES;
    }
    _chainIndex++;
    return isFinished;
}

- (void)cleanCallbackBlocks {
    _runningRequest = nil;
    _chainSuccessBlock = nil;
    _chainFailureBlock = nil;
    _chainFinishedBlock = nil;
    [_nextBlockArray removeAllObjects];
}

#ifdef YGMEMORYLOG
- (void)dealloc {
    NSLog(@"%@: %s", self, __FUNCTION__);
}
#endif

@end

#pragma mark - YGUploadFormData

@implementation YGUploadFormData

+ (instancetype)formDataWithName:(NSString *)name fileData:(NSData *)fileData {
    YGUploadFormData *formData = [[YGUploadFormData alloc] init];
    formData.name = name;
    formData.fileData = fileData;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData {
    YGUploadFormData *formData = [[YGUploadFormData alloc] init];
    formData.name = name;
    formData.fileName = fileName;
    formData.mimeType = mimeType;
    formData.fileData = fileData;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileURL:(NSURL *)fileURL {
    YGUploadFormData *formData = [[YGUploadFormData alloc] init];
    formData.name = name;
    formData.fileURL = fileURL;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL {
    YGUploadFormData *formData = [[YGUploadFormData alloc] init];
    formData.name = name;
    formData.fileName = fileName;
    formData.mimeType = mimeType;
    formData.fileURL = fileURL;
    return formData;
}

@end
