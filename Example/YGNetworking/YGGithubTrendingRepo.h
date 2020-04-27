//
//  YGGithubTrendingRepo.h
//  YGNetworking_Example
//
//  Created by Sun on 2020/4/27.
//  Copyright © 2020 oneofai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGGithubTrendingRepo : NSObject

/*
 {
 "author": "aristocratos",
 "name": "bashtop",
 "avatar": "https://github.com/aristocratos.png",
 "url": "https://github.com/aristocratos/bashtop",
 "description": "Linux resource monitor",
 "language": "Shell",
 "languageColor": "#89e051",
 "stars": 2356,
 "forks": 73,
 "currentPeriodStars": 728,
 "builtBy": [
 {
 "username": "aristocratos",
 "href": "https://github.com/aristocratos",
 "avatar": "https://avatars1.githubusercontent.com/u/59659483"
 },
 {
 "username": "frederic-mahe",
 "href": "https://github.com/frederic-mahe",
 "avatar": "https://avatars1.githubusercontent.com/u/2270759"
 },
 {
 "username": "jdenoy-saagie",
 "href": "https://github.com/jdenoy-saagie",
 "avatar": "https://avatars0.githubusercontent.com/u/55875303"
 },
 {
 "username": "jdenoy",
 "href": "https://github.com/jdenoy",
 "avatar": "https://avatars3.githubusercontent.com/u/246715"
 }
 ]
 },
 */

// repo name
@property (nonatomic, copy) NSString *name;
// author name
@property (nonatomic, copy) NSString *author;
// author avatar
@property (nonatomic, copy) NSString *avatar;
// repo url
@property (nonatomic, copy) NSString *url;
// repo desc
@property (nonatomic, copy) NSString *desc;
// lang
@property (nonatomic, copy) NSString *language;
// lang color(hex)
@property (nonatomic, copy) NSString *languageColor;
// repo stars
@property (nonatomic, assign) NSInteger stars;
// repo forks
@property (nonatomic, assign) NSInteger forks;
// today stars
@property (nonatomic, assign) NSInteger currentPeriodStars;

- (nullable instancetype)initWithDictionary:(nullable NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
