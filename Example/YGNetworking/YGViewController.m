//
//  YGViewController.m
//  YGNetworking
//
//  Created by oneofai on 04/27/2020.
//  Copyright (c) 2020 oneofai. All rights reserved.
//

#import "YGViewController.h"
#import "YGGithubTrendingCell.h"
#import "YGGithubTrendingRepo.h"
#import "YGNetworkManager.h"
#import <SafariServices/SafariServices.h>

@interface YGViewController ()

@property (nonatomic, assign, getter=isLoadingData) BOOL loadingData;

@property (nonatomic, strong) NSMutableArray<YGGithubTrendingRepo *> *dataList;

@end

@implementation YGViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[YGNetworkManager setup];
    [self p_setupSubviews];
    [self p_getTrendingFromNet];
}

- (void)p_setupSubviews {
    self.title = @"Github Trending";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    
    [self.tableView registerClass:YGGithubTrendingCell.class forCellReuseIdentifier: [YGGithubTrendingCell reuseIdentifier]];
    [self.refreshControl addTarget:self action:@selector(p_shouldRefreshAction:) forControlEvents:UIControlEventValueChanged];
}


- (void)p_shouldRefreshAction:(UIRefreshControl *)sender {
    if (self.isLoadingData) {
        [self.refreshControl endRefreshing];
        return;
    }
    [self p_getTrendingFromNet];
}

#pragma mark - Network

- (void)p_getTrendingFromNet {
    if (self.isLoadingData) {
        return;
    }
    self.loadingData = YES;
    
    [YGCenter sendRequest:^(YGRequest * _Nonnull request) {
        request.api = @"/repositories";
        request.httpMethod = kYGHTTPMethodGET;
    } onSuccess:^(id  _Nullable responseObject) {
        
        if ([responseObject isKindOfClass:[NSArray class]] && [responseObject count] > 0) {
            [responseObject enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                YGGithubTrendingRepo *repo = [[YGGithubTrendingRepo alloc] initWithDictionary:obj];
                if (repo) {
                    [self.dataList addObject:repo];
                }
            }];
        }
        [self.tableView reloadData];
    } onFailure:^(NSError * _Nullable error) {
        NSLog(@"[Net Error]: %@", error.localizedDescription);
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        [self p_didEndRefreshing];
    }];
}

- (void)p_didEndRefreshing {
    self.loadingData = NO;
    // 延迟 1 秒结束刷新
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YGGithubTrendingCell *cell = [tableView dequeueReusableCellWithIdentifier:[YGGithubTrendingCell reuseIdentifier]];
    cell.repo = self.dataList[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:self.dataList[indexPath.row].url]];
    [self presentViewController:safariViewController animated:true  completion:NULL];
}

#pragma mark - Getter
- (NSMutableArray<YGGithubTrendingRepo *> *)dataList {
    if (!_dataList) {
        _dataList = [NSMutableArray array];
    }
    return _dataList;
}

@end
