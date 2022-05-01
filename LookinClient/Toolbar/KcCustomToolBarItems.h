//
//  KcCustomToolBarItems.h
//  LookinClient
//
//  Created by 张杰 on 2022/5/1.
//  Copyright © 2022 hughkli. All rights reserved.
//  自定义ToolBarItems

#import <Foundation/Foundation.h>
@class KcDoubleSlide;

NS_ASSUME_NONNULL_BEGIN

/// 自定义ToolBarItems
@interface KcCustomToolBarItems : NSObject

/// 调整可视view的范围
- (void)adjustTheRangeOfVisableOfViewsWithSlide:(KcDoubleSlide *)slider;

/// 聚焦选中的view
- (void)focusOnSelectedView:(NSButton *)btn;

@end

NS_ASSUME_NONNULL_END
