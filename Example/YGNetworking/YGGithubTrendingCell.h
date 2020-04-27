//
//  YGGithubTrendingCell.h
//  YGNetworking_Example
//
//  Created by Sun on 2020/4/27.
//  Copyright © 2020 oneofai. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YGGithubTrendingRepo;

@interface YGGithubTrendingCell : UITableViewCell

// data souce
@property (nonatomic, strong) YGGithubTrendingRepo *repo;

+ (NSString *)reuseIdentifier;

@end

NS_ASSUME_NONNULL_END
