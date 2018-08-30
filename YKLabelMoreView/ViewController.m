//
//  ViewController.m
//  YKLabelMoreView
//
//  Created by wangyongkang on 2018/8/30.
//  Copyright © 2018年 wangyongkang. All rights reserved.
//

#import "ViewController.h"

#import "Masonry.h"
#import "YKLabelMoreView.h"
#import "UIView+Extension.h"

@interface ViewController () <YKLabelMoreViewDelegate>

@property (nonatomic, strong) YKLabelMoreView *labelMoreView;        //!<

@property (nonatomic, strong) YKLabelMoreViewModel *moreViewModel;   //!<

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"开始创建");
    self.view.backgroundColor = UIColor.whiteColor;
    YKLabelMoreViewModel *moreViewModel = [[YKLabelMoreViewModel alloc] init];
    moreViewModel.textContent = @"富文本计算文本宽度在包含标点符号的情况下，计算有偏差，将进行了封装封装并不完全以后会继续完善简化了操作";
    moreViewModel.textOpenMore = @"阅读更多";
    moreViewModel.colorTextContent = UIColor.purpleColor;
    moreViewModel.colorTextOpenMore = UIColor.orangeColor;
    moreViewModel.font = [UIFont systemFontOfSize:16];
    moreViewModel.lineSerial = 2;
    moreViewModel.lineSpaceing = 5;
    moreViewModel.spaceContentToMore = 10;
    moreViewModel.isFolding = YES;
    moreViewModel.preferredMaxLayoutWidth = 310;
    self.moreViewModel = moreViewModel;
    
    self.labelMoreView = [[YKLabelMoreView alloc] initWithFrame:CGRectZero];
    self.labelMoreView.delegate = self;
    [self.labelMoreView refreshLabelMoreViewWith:self.moreViewModel];
    [self.view addSubview:self.labelMoreView];
    
    [self.labelMoreView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view);
    }];
    
    UIGestureRecognizer *tap = [[UIGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(updateLabelMoreViewSuperView)];
    self.labelMoreView.userInteractionEnabled = YES;
    [self.labelMoreView addGestureRecognizer:tap];
}

- (void)updateLabelMoreViewSuperView
{
    self.moreViewModel.isFolding = !self.moreViewModel.isFolding;
    [self.labelMoreView refreshLabelMoreViewWith:self.moreViewModel];
}

- (void)refreshLabelMoreViewSuperView
{
    [self.labelMoreView refreshLabelMoreViewWith:self.moreViewModel];
}



@end
