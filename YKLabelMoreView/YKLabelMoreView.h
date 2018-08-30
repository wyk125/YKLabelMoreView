//
//  YKLabelMoreView.h
//  YKLabelMoreView
//
//  Created by wangyongkang on 2018/8/30.
//  Copyright © 2018年 wangyongkang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKLabelMoreViewModel : NSObject

//****** 必须指定的属性 ******//
@property (nonatomic, copy) NSString *textContent;    //!<内容文本
@property (nonatomic, copy) NSString *textOpenMore;   //!<展开更多提示文本
@property (nonatomic, assign) NSInteger lineSerial;   //!<第几行折叠 … 1，2，3
@property (nonatomic, strong) UIFont *font;           //!<字体
@property (nonatomic, strong) UIColor *colorTextContent;       //!<内容文本颜色
@property (nonatomic, strong) UIColor *colorTextOpenMore;      //!<展开更多文本颜色
@property (nonatomic, assign) CGFloat preferredMaxLayoutWidth; //!< 文本最大显示宽度
//****** 必须指定的属性 ******//

//****** 扩展属性 ******//
@property (nonatomic, assign) CGFloat lineSpaceing;       //!<行间距
@property (nonatomic, assign) CGFloat spaceContentToMore; //!<文本与更多lab间隙、精度有待优化
@property (nonatomic, assign) BOOL isFolding;             //!< 是否展开，默认折叠YES，NO展开

@end

@protocol YKLabelMoreViewDelegate <NSObject>

- (void)refreshLabelMoreViewSuperView;

@end

@interface YKLabelMoreView : UIView

@property (nonatomic, weak) id <YKLabelMoreViewDelegate> delegate;   //!<代理

- (void)refreshLabelMoreViewWith:(YKLabelMoreViewModel *)moreViewModel;

@end
