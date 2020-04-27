//
//  YGGithubTrendingRepo.m
//  YGNetworking_Example
//
//  Created by Sun on 2020/4/27.
//  Copyright © 2020 oneofai. All rights reserved.
//

#import "YGGithubTrendingRepo.h"

@implementation YGGithubTrendingRepo

// ignore unused keys
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([value isKindOfClass:[NSNull class]]) return;
    if ([value isKindOfClass:[NSString class]]) {
        NSString *stringValue = value;
        if ([stringValue isEqualToString:@"null"]) {
            return;
        }
    }
    
    if ([key isEqualToString:@"description"]) {
        self.desc = value;
    }
    
    [super setValue:value forKey:key];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    return self;
}

@end
