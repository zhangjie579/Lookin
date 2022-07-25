//
//  KcDoubleSlide.h
//  LookinClient
//
//  Created by 张杰 on 2022/5/1.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// 双向滑块
// 注意⚠️: 因为滑块有size, 当点击滑块中心位置时, 右边滑块往左边滑动, 滑块中心x > 右边滑块minX, so就会先往右边抖动下再到左边⚠️, so不能用绝对距离, 而是用相对滑动了距离
// 这里不继承自NSControl, 在tabbar位置上会拖动整个页面, slide交互有冲突
@interface KcDoubleSlide : NSControl

/// 初始化
/// @param frameRect 布局
/// @param leftValue 左边滑块的value
/// @param rightValue 右边滑块的value
/// @param totalLength 可滑动的总长度value
- (nullable instancetype)initWithFrame:(NSRect)frameRect
                              leftValue:(double)leftValue
                              rightValue:(double)rightValue
                           totalLength:(double)totalLength;

/// 滑块的总长度份数
@property (nonatomic, readonly) double totalLength;
@property (nonatomic, readonly) double leftValue;
@property (nonatomic, readonly) double rightValue;

/// 改变滑块的value
@property (nonatomic, copy) void (^updateSlideValue)(KcDoubleSlide *slide, double leftValue, double rightValue);

/// 重置
- (void)reset;

@end

NS_ASSUME_NONNULL_END
