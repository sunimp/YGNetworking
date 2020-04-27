//
//  YGGithubTrendingCell.m
//  YGNetworking_Example
//
//  Created by Sun on 2020/4/27.
//  Copyright © 2020 oneofai. All rights reserved.
//

#import "YGGithubTrendingCell.h"
#import "YGGithubTrendingRepo.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

static NSString * kValidString(NSString *string) {
    if ([string isKindOfClass:[NSString class]] && string.length > 0) return string;
    return @"";
}

static CGFloat kColorComponentFrom(NSString *string, NSUInteger start, NSUInteger length) {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

static UIColor * _Nullable kColorFromHex(NSString *hexString) {
    
    if (hexString.length <= 0) return nil;
    
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = kColorComponentFrom(colorString, 0, 1);
            green = kColorComponentFrom(colorString, 1, 1);
            blue  = kColorComponentFrom(colorString, 2, 1);
            break;
        case 4: // #ARGB
            alpha = kColorComponentFrom(colorString, 0, 1);
            red   = kColorComponentFrom(colorString, 1, 1);
            green = kColorComponentFrom(colorString, 2, 1);
            blue  = kColorComponentFrom(colorString, 3, 1);
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = kColorComponentFrom(colorString, 0, 2);
            green = kColorComponentFrom(colorString, 2, 2);
            blue  = kColorComponentFrom(colorString, 4, 2);
            break;
        case 8: // #AARRGGBB
            alpha = kColorComponentFrom(colorString, 0, 2);
            red   = kColorComponentFrom(colorString, 2, 2);
            green = kColorComponentFrom(colorString, 4, 2);
            blue  = kColorComponentFrom(colorString, 6, 2);
            break;
        default: {
            printf("Color value %s is invalid. It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", [hexString UTF8String]);
            return nil;
        }
            break;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
    
}



@interface YGGithubTrendingCell ()

@property (nonatomic, strong) UILabel       *repoNameLabel;
@property (nonatomic, strong) UIImageView   *authorAvatarImageView;
@property (nonatomic, strong) UILabel       *repoDescLabel;

@property (nonatomic, strong) UILabel       *langLabel;
@property (nonatomic, strong) UIView        *langColorView;
@property (nonatomic, strong) UILabel       *starsLabel;
@property (nonatomic, strong) UILabel       *forksLabel;
@property (nonatomic, strong) UILabel       *currentPeriodStarsLabel;

@end

@implementation YGGithubTrendingCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self p_setupSubviews];
    }
    return self;
}

- (void)p_setupSubviews {
    
    // repo name
    _repoNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _repoNameLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.contentView addSubview:_repoNameLabel];
    
    // author avatar
    _authorAvatarImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _authorAvatarImageView.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    _authorAvatarImageView.layer.cornerRadius = 20.f;
    _authorAvatarImageView.layer.masksToBounds = true;
    [self.contentView addSubview:_authorAvatarImageView];
    
    // repo desc
    _repoDescLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _repoDescLabel.font = [UIFont systemFontOfSize:14];
    _repoDescLabel.textColor = [UIColor darkGrayColor];
    _repoDescLabel.numberOfLines = 0;
    [self.contentView addSubview:_repoDescLabel];
    
    
    // lang
    _langLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _langLabel.font = [UIFont systemFontOfSize:16];
    [self.contentView addSubview:_langLabel];
    
    // lang color
    _langColorView = [[UIView alloc] initWithFrame:CGRectZero];
    _langColorView.layer.cornerRadius = 8.f;
    _langColorView.layer.masksToBounds = true;
    [self.contentView addSubview:_langColorView];
    
    // stars
    _starsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _starsLabel.font = [UIFont systemFontOfSize:16];
    _starsLabel.textColor = [UIColor darkGrayColor];
    [self.contentView addSubview:_starsLabel];
    
    // forks
    _forksLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _forksLabel.font = [UIFont systemFontOfSize:16];
    _forksLabel.textColor = [UIColor darkGrayColor];
    [self.contentView addSubview:_forksLabel];
    
    // period stars
    _currentPeriodStarsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _currentPeriodStarsLabel.font = [UIFont systemFontOfSize:16];
    _currentPeriodStarsLabel.textColor = [UIColor darkGrayColor];
    [self.contentView addSubview:_currentPeriodStarsLabel];
    
    [self p_setupConstraints];
}

- (void)p_setupConstraints {
    
    UIEdgeInsets insets = UIEdgeInsetsMake(16, 16, 16, 16);
    
    [_authorAvatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.insets(insets);
        make.height.width.equalTo(@(40));
    }];
    
    [_repoNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.authorAvatarImageView.mas_right).insets(insets);
        make.top.equalTo(self.authorAvatarImageView);
    }];
    
    [_repoDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.repoNameLabel);
        make.right.insets(insets);
        make.top.equalTo(self.repoNameLabel.mas_bottom).offset(4);
    }];
    
    [_langColorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.authorAvatarImageView);
        make.top.equalTo(self.repoDescLabel.mas_bottom).offset(8);
        make.height.width.equalTo(@(16));
    }];
    
    [_langLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.langColorView.mas_right).offset(8);
        make.centerY.equalTo(self.langColorView);
    }];
    
    [_starsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.langLabel.mas_right).offset(8);
        make.centerY.equalTo(self.langLabel);
    }];
    
    [_forksLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.starsLabel.mas_right).offset(8);
        make.centerY.equalTo(self.starsLabel);
    }];
    
    [_currentPeriodStarsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.langColorView);
        make.top.equalTo(self.langLabel.mas_bottom).offset(8);
        make.bottom.equalTo(self.contentView).insets(insets).priority(800);
    }];
}

#pragma mark -

- (void)setRepo:(YGGithubTrendingRepo *)repo {
    _repo = repo;
    if (repo) {
        [_authorAvatarImageView sd_setImageWithURL:[NSURL URLWithString:kValidString(repo.avatar)]];
        
        _repoNameLabel.text             = [NSString stringWithFormat:@"%@ / %@",
                                           kValidString(repo.author), kValidString(repo.name)];
        _repoDescLabel.text             = kValidString(repo.desc);
        _langLabel.text                 = kValidString(repo.language);
        _langColorView.backgroundColor  = kColorFromHex(repo.languageColor);
        _starsLabel.text                = [NSString stringWithFormat:@"Stars: %zd", repo.stars];
        _forksLabel.text                = [NSString stringWithFormat:@"Forks: %zd", repo.forks];
        _currentPeriodStarsLabel.text   = [NSString stringWithFormat:@"%zd stars today",
                                           repo.currentPeriodStars];
    }
}

+ (NSString *)reuseIdentifier {
    return NSStringFromClass(self.class);
}

@end
