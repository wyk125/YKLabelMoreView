//
//  YKLabelMoreView.m
//  YKLabelMoreView
//
//  Created by wangyongkang on 2018/8/30.
//  Copyright © 2018年 wangyongkang. All rights reserved.
//

#import "YKLabelMoreView.h"
#import <CoreGraphics/CoreGraphics.h>
#import <CoreText/CoreText.h>
#import "Masonry.h"
#import "UIView+Extension.h"

const CGFloat floatDeviationValue = 5.0; //!<浮点计算误差值
NSString * const foldingSignChar = @"…";  //!<折叠标记字符
NSString * const changeLineChar = @"\n";  //!<换行符

@interface YKLabelMoreView ()

@property (nonatomic, strong) UILabel *labelContent;      //!<长文本
@property (nonatomic, strong) UILabel *labelMore;         //!<阅读更多
@property (nonatomic, assign) CGFloat heightAllUnfolding; //!<指定折叠行之前的文本高度
@property (nonatomic, assign) CGFloat heightFolding;      //!<指定折叠行之前的文本高度
@property (nonatomic, strong) NSMutableAttributedString *attributedUnfoldText;  //!<展开的富文本
@property (nonatomic, strong) NSMutableAttributedString *attributedFoldingText; //!<折叠时展示的富文本

@property (nonatomic, strong) YKLabelMoreViewModel *modelMoreView;   //!<样式配置
@property (nonatomic, assign) NSRange rangePreLineSerialLineShow;    //!<指定折叠行前一行的预展示文本范围
@property (nonatomic, assign) CGFloat heightFoldingPreLineReference; //!<指定折叠行之前的文本高度
@property (nonatomic, assign) NSRange rangeSerialLineShow;           //!<指定折叠行的预展示文本范围
@property (nonatomic, assign) CGFloat heightFoldingReference;        //!<指定折叠行和之前的文本总高度
@property (nonatomic, assign) CGFloat widthSerialLineShow;           //!<指定折叠行可展示的文本宽度

@end

@implementation YKLabelMoreView

#pragma mark- 初始化对象
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initData];
        [self createSubViews];
    }
    return self;
}

#pragma mark- 配置文本，计算折叠样式
- (void)refreshLabelMoreViewWith:(YKLabelMoreViewModel *)moreViewModel
{
    self.modelMoreView = moreViewModel;
    //展开或折叠操作
    if (self.heightAllUnfolding > 1 || self.heightAllUnfolding > 1) {
        [self updateLabelMoreViewWith:moreViewModel];
        return;
    }
    //第一次组装数据
    self.labelContent.textColor = self.modelMoreView.colorTextContent;
    self.labelContent.preferredMaxLayoutWidth = self.modelMoreView.preferredMaxLayoutWidth;
    self.attributedUnfoldText = [self configAttributedTextWith:self.modelMoreView.textContent];
    CGSize attributedUnfoldTextSize =
    [self.attributedUnfoldText boundingRectWithSize:CGSizeMake(self.modelMoreView.preferredMaxLayoutWidth,MAXFLOAT)
                                            options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            context:nil].size;
    self.heightAllUnfolding = ceil(attributedUnfoldTextSize.height);
    if (self.heightFolding < 1) {
        self.heightFolding = self.heightAllUnfolding;
        self.attributedFoldingText = self.attributedUnfoldText;
    }
    //明确不折叠直接展开
    if (!self.modelMoreView.isFolding) {
        return;
    }
    //计算需要折叠处理的字符范围，计算有偏差，需要进一步校正
    [self getSingleLineCanShowCharRange];
    NSRange rangeZero = {0, 0};
    //行数小于lineSerial,文本明显不足占满直接展开显示
    if (NSEqualRanges(self.rangeSerialLineShow, rangeZero)) {
        //数据明显不足占满直接展开显示
        self.modelMoreView.isFolding = NO;
    } else {
        //精确计算折行位置
        NSRange rangeShow = [self getSingleLineShowingCharWithRange:self.rangeSerialLineShow
                                                           preRange:self.rangePreLineSerialLineShow];
        //数据计算出错，全文展示
        if (NSEqualRanges(self.rangeSerialLineShow, rangeZero) || rangeShow.length <= 0) {
            self.modelMoreView.isFolding = NO;
        } else if (self.modelMoreView.textContent.length <= rangeShow.location + rangeShow.length) {
            //数据不足占满直接展开显示
            self.modelMoreView.isFolding = NO;
        } else {
            self.modelMoreView.isFolding = YES;
            [self setLabelMore];
            //处理指定行折叠富文本
            [self handleFoldViewWithRange:rangeShow];
        }
    }
    
    //精确计算后，刷新视图
    [self updateLabelMoreViewWith:moreViewModel];
}

#pragma mark- 刷新展示视图
- (void)updateLabelMoreViewWith:(YKLabelMoreViewModel *)moreViewModel
{
    //配置文本视图
    self.labelMore.hidden = !self.modelMoreView.isFolding;
    if (self.modelMoreView.isFolding) {
        [self showFoldingView];
    } else {
        [self showUnfoldView];
    }
    [_labelContent mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
        make.width.mas_equalTo(self.modelMoreView.preferredMaxLayoutWidth);
    }];
    //读取缓存的高度
    if (self.modelMoreView.isFolding) {
        if (self.heightFolding > 1) {
            self.height = ceil(self.heightFolding);
            return;
        }
    } else {
        if (self.heightAllUnfolding > 1) {
            self.height = ceil(self.heightAllUnfolding);
            return;
        }
    }
    //读取缓存失败，再次计算
    CGSize labelContentSize =
    [self.labelContent.attributedText boundingRectWithSize:CGSizeMake(self.modelMoreView.preferredMaxLayoutWidth,MAXFLOAT)
                                                   options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                   context:nil].size;
    self.height = ceil(labelContentSize.height);
}

#pragma mark- 展开或收起文本
- (void)openOrFoldMoreView
{
    self.modelMoreView.isFolding = !self.modelMoreView.isFolding;
    if (self.delegate && [self.delegate respondsToSelector:@selector(refreshLabelMoreViewSuperView)]) {
        [self.delegate refreshLabelMoreViewSuperView];
    }
}

#pragma mark- ————————————显示配置——————————————
//折叠
- (void)showFoldingView
{
    self.labelContent.numberOfLines = self.modelMoreView.lineSerial;
    self.labelContent.attributedText = self.attributedFoldingText;
}

//全部展开
- (void)showUnfoldView
{
    self.labelContent.numberOfLines = 0;
    self.labelContent.attributedText = self.attributedUnfoldText;
}

//设置阅读更多
- (void)setLabelMore
{
    self.labelMore.hidden = !self.modelMoreView.isFolding;
    self.labelMore.textColor = self.modelMoreView.colorTextOpenMore;
    self.labelMore.text = self.modelMoreView.textOpenMore;
    self.labelMore.font = self.modelMoreView.font;
    [self.labelMore sizeToFit];
}

#pragma mark- 处理折叠行富文本
- (void)handleFoldViewWithRange:(NSRange)rangeLine
{
    NSInteger lengthFolding = rangeLine.length;
    
    for (; lengthFolding > 0; lengthFolding--) {
        NSRange rangeFolding = {rangeLine.location, lengthFolding};
        NSString *stringFolding = [self.modelMoreView.textContent substringWithRange:rangeFolding];
        stringFolding = [stringFolding stringByAppendingString:foldingSignChar];
        NSMutableAttributedString *mAttributedString = [self configAttributedTextWith:stringFolding];
        CGSize textSize =
        [mAttributedString boundingRectWithSize:CGSizeMake(MAXFLOAT,CGRectGetHeight(self.labelMore.frame))
                                        options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                        context:nil].size;
        //找到替换位置
        if (textSize.width <= self.modelMoreView.preferredMaxLayoutWidth - CGRectGetWidth(self.labelMore.frame) - self.modelMoreView.spaceContentToMore) {
            NSString *stringShow =
            [self.modelMoreView.textContent substringToIndex:rangeLine.location + lengthFolding];
            stringShow = [stringShow stringByAppendingString:foldingSignChar];
            self.attributedFoldingText = [self configAttributedTextWith:stringShow];
            //修改默认字间距离,精确展示、self.modelMoreView.spaceContentToMore精度待优化
            CGFloat strokeMargin = (self.modelMoreView.preferredMaxLayoutWidth - CGRectGetWidth(self.labelMore.frame) - self.modelMoreView.spaceContentToMore - textSize.width) / (stringFolding.length - 1);
            NSNumber *number = [NSNumber numberWithFloat:strokeMargin];
            NSRange range = {0,stringFolding.length};
            [self.attributedFoldingText addAttribute:NSKernAttributeName value:number range:range];
            CGSize attributedFoldingSize =
            [self.attributedFoldingText boundingRectWithSize:CGSizeMake(self.modelMoreView.preferredMaxLayoutWidth,MAXFLOAT)
                                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                     context:nil].size;
            self.heightFolding = ceil(attributedFoldingSize.height);
            //代理更新高度
            if (self.delegate && [self.delegate respondsToSelector:@selector(refreshLabelMoreViewSuperView)]) {
                [self.delegate refreshLabelMoreViewSuperView];
            }
            break;
        }
    }
}

#pragma mark- 精确计算指定折叠行的显示文本范围
- (NSRange)getSingleLineShowingCharWithRange:(NSRange)rangeLine preRange:(NSRange)preRange
{
    //校正——精确定位前一行的折行位置
    NSInteger lengthPreWillShow = [self getIntegerLineShowingStringWithRange:preRange
                                                             heightReference:self.heightFoldingPreLineReference];
    NSInteger lengthWillShow = [self getIntegerLineShowingStringWithRange:rangeLine
                                                          heightReference:self.heightFoldingReference];
    NSInteger length = lengthWillShow - lengthPreWillShow;
    if (length <= 0 || length > self.modelMoreView.textContent.length) {
        length = 0;
    }
    NSRange rangeWillShow = {lengthPreWillShow, length};
    
    return rangeWillShow;
}

//获得实际展示时的折行之前的文字长度
- (NSInteger)getIntegerLineShowingStringWithRange:(NSRange)rangeLine
                                  heightReference:(CGFloat)heightReference
{
    NSInteger lengthWillShow = rangeLine.length + rangeLine.location;
    if (lengthWillShow <= 0 || lengthWillShow > self.modelMoreView.textContent.length) {
        return 0;
    }
    for (NSInteger i = 2; lengthWillShow > 0 && lengthWillShow <= self.modelMoreView.textContent.length; i++) {
        NSRange rangeWillShow = {0, lengthWillShow};
        NSString *stringWillShow = [self.modelMoreView.textContent substringWithRange:rangeWillShow];
        NSMutableAttributedString *mAttributedString = [self configAttributedTextWith:stringWillShow];
        CGSize textSize =
        [mAttributedString boundingRectWithSize:CGSizeMake(self.modelMoreView.preferredMaxLayoutWidth,MAXFLOAT)
                                        options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                        context:nil].size;
        if (fabs(textSize.height - heightReference) <= floatDeviationValue) {
            //精确找到指定行的折行字符
            break;
        } else if (textSize.height - heightReference > floatDeviationValue) {
            //向前校正
            if ((rangeLine.length + rangeLine.location) - i / 2 == lengthWillShow) {
                i++;
            }
            lengthWillShow = (rangeLine.length + rangeLine.location) - i / 2;
        } else if (textSize.height - heightReference < -floatDeviationValue) {
            if ((rangeLine.length + rangeLine.location) + i / 2 == lengthWillShow) {
                i++;
            }
            //向后校正
            lengthWillShow = (rangeLine.length + rangeLine.location) + i / 2;
        }
    }
    return lengthWillShow;
}

#pragma mark- 粗略计算指定折叠行的文本范围
//大概统计：获得指定行预展示文字和参考高度，有偏差，根据富文本可再精确计算实际展示文字
- (void)getSingleLineCanShowCharRange
{
    NSString *string = self.modelMoreView.textContent;
    UIFont *font = self.modelMoreView.font;
    NSInteger lineSerial = self.modelMoreView.lineSerial;
    CGFloat preferredMaxLayoutWidth = self.modelMoreView.preferredMaxLayoutWidth;
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:string];
    CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)([font fontName]), [font pointSize], NULL);
    [attStr addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)fontRef range:NSMakeRange(0, attStr.length)];
    CTParagraphStyleRef paragraphRef = [self getCTParagraphStyleRef];
    [attStr addAttribute:(NSString *)kCTParagraphStyleAttributeName value:(__bridge id)paragraphRef range:NSMakeRange(0, attStr.length)];
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attStr);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, preferredMaxLayoutWidth, MAXFLOAT));
    CTFrameRef ctFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0),path, NULL);
    CFArrayRef lines = CTFrameGetLines(ctFrame);
    NSRange rangeLineSerial = {0, 0};
    //按NSLineBreakByCharWrapping折行，每行实际显示会有1个字符左右的误差，实际行数小于指定行数的差值时，会有一行之内的误差,无需再做展开处理
    if (CFArrayGetCount(lines) < lineSerial) {
        self.rangeSerialLineShow = rangeLineSerial;
        return;
    }
    CGFloat heightFoldingReference = 0;
    CGFloat heightFoldingPreLineReference = 0;
    //标记出指定行数和预估高度
    for (NSInteger i = 0; i < CFArrayGetCount(lines); i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRange singleRange = CTLineGetStringRange(line);
        NSRange range = NSMakeRange(singleRange.location, singleRange.length);
        //                NSString *lineString = [string substringWithRange:range];
        //                NSLog(@"%ld,%ld  %@",singleRange.location,singleRange.length,lineString);
        //后续无需计算
        if (i >= lineSerial) {
            break;
        }
        //确认前一行
        if (i <= lineSerial - 2) {
            heightFoldingPreLineReference = heightFoldingPreLineReference + font.lineHeight + self.modelMoreView.lineSpaceing;
            if (lineSerial - 2 == i) {
                self.rangePreLineSerialLineShow = range;
            }
        }
        //确认指定行
        if (i <= lineSerial - 1) {
            heightFoldingReference = heightFoldingReference + font.lineHeight + self.modelMoreView.lineSpaceing;
            if (lineSerial - 1 == i) {
                self.rangeSerialLineShow = range;
            }
        }
    }
    //校正数据
    self.heightFoldingPreLineReference = heightFoldingPreLineReference - self.modelMoreView.lineSpaceing;
    self.heightFoldingReference = heightFoldingReference - self.modelMoreView.lineSpaceing;
    self.heightFoldingPreLineReference = MAX(self.heightFoldingPreLineReference, 0);
    self.heightFoldingReference = MAX(self.heightFoldingReference, 0);
    
    //释放内存
    CFRelease(ctFrame);
    CFRelease(path);
    CFRelease(frameSetter);
    CFRelease(paragraphRef);
    CFRelease(fontRef);
}

//配置CT类 的段落样式 需要与 NSMutableParagraphStyle 保持一致
- (CTParagraphStyleRef)getCTParagraphStyleRef
{
    CGFloat lineSpacing = self.modelMoreView.lineSpaceing;
    CTTextAlignment alignment = kCTTextAlignmentJustified;
    CTLineBreakMode lineBreakMode = kCTLineBreakByCharWrapping;
    CTParagraphStyleSetting paragraphSettings[] =
    {
    {kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment},
    {kCTParagraphStyleSpecifierLineBreakMode, sizeof(lineBreakMode), &lineBreakMode},
    {kCTParagraphStyleSpecifierLineSpacingAdjustment,sizeof(CGFloat),&lineSpacing},
    {kCTParagraphStyleSpecifierMaximumLineSpacing,sizeof(CGFloat),&lineSpacing},
    {kCTParagraphStyleSpecifierMinimumLineSpacing,sizeof(CGFloat),&lineSpacing}
    };
    return CTParagraphStyleCreate(paragraphSettings, 5);
}

#pragma mark- 配置富文本样式
- (NSMutableAttributedString *)configAttributedTextWith:(NSString *)textContent
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:textContent];
    NSRange range = {0, textContent.length};
    [attributedText addAttribute:NSFontAttributeName value:self.modelMoreView.font range:range];
    //调整行间距
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    paragraphStyle.alignment = NSTextAlignmentJustified;
    paragraphStyle.lineSpacing = self.modelMoreView.lineSpaceing;
    attributedText = [self setAttributedString:attributedText
                                paragraphStyle:paragraphStyle
                       preferredMaxLayoutWidth:self.modelMoreView.preferredMaxLayoutWidth
                                          font:self.modelMoreView.font];
    
    return attributedText;
}

//调整段落行间距
- (NSMutableAttributedString *)setAttributedString:(NSMutableAttributedString *)attributedString
                                    paragraphStyle:(NSMutableParagraphStyle *)paragraphStyle
                           preferredMaxLayoutWidth:(CGFloat)preferredMaxLayoutWidth
                                              font:(UIFont *)font
{
    //无需要计算和设置行间距
    if (paragraphStyle.lineSpacing <= 0) {
        return attributedString;
    }
    NSRange range = {0,attributedString.length};
    CGSize actualSize = [attributedString
                         boundingRectWithSize:CGSizeMake(preferredMaxLayoutWidth, MAXFLOAT)
                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                         context:nil].size;
    // 大于一行，可设置行间距
    if (actualSize.height > (font.lineHeight + paragraphStyle.lineSpacing) + floatDeviationValue) {
        [attributedString addAttribute:NSParagraphStyleAttributeName
                                 value:paragraphStyle
                                 range:range];
    } else {
        // 只有单行文本，清空行间距
        paragraphStyle.lineSpacing = 0;
        [attributedString addAttribute:NSParagraphStyleAttributeName
                                 value:paragraphStyle
                                 range:range];
    }
    return attributedString;
}

#pragma mark- 初始化属性数据、视图
- (void)initData
{
    self.modelMoreView = [[YKLabelMoreViewModel alloc] init];
    self.attributedUnfoldText = [[NSMutableAttributedString alloc] initWithString:@""];
    self.attributedFoldingText = [[NSMutableAttributedString alloc] initWithString:@""];
    self.rangePreLineSerialLineShow = NSMakeRange(0, 0);
    self.rangeSerialLineShow = NSMakeRange(0, 0);
    self.heightFoldingPreLineReference = 0;
    self.heightFoldingReference = 0;
    self.widthSerialLineShow = 0;
    self.heightAllUnfolding = 0;
    self.heightFolding = 0;
}

- (void)createSubViews
{
    //1._labelContent
    [self makelabelContent];
    [self addSubview:_labelContent];
    //--约束布局
    [_labelContent mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
        make.width.mas_equalTo(self.modelMoreView.preferredMaxLayoutWidth);
    }];
    
    //2._labelMore
    [self makeLabelMore];
    [self addSubview:_labelMore];
    //--约束布局
    [_labelMore mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self);
        make.bottom.equalTo(self);
    }];
}

- (void)makelabelContent
{
    _labelContent = [[UILabel alloc] initWithFrame:CGRectNull];
    _labelContent.numberOfLines = 0;
}

- (void)makeLabelMore
{
    _labelMore = [[UILabel alloc] initWithFrame:CGRectNull];
    //添加手势
    _labelMore.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapOpenMoreInside = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self
                                                 action:@selector(openOrFoldMoreView)];
    [_labelMore addGestureRecognizer:tapOpenMoreInside];
}

@end


@implementation YKLabelMoreViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferredMaxLayoutWidth = 0;
        self.lineSpaceing = 0;
        self.font = [UIFont systemFontOfSize:14];
        self.textContent = @"";
        self.textOpenMore = @"";
        self.colorTextContent = UIColor.grayColor;
        self.colorTextContent = UIColor.blackColor;
        self.spaceContentToMore = 0;
        self.lineSerial = 0;
        self.isFolding = YES;
    }
    return self;
}

@end


