//
//  KcCustomToolBarItems.m
//  LookinClient
//
//  Created by 张杰 on 2022/5/1.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import "KcCustomToolBarItems.h"
#import "KcDoubleSlide.h"
#import "LKStaticHierarchyDataSource.h"
#import "LookinDisplayItem.h"
#import "LookinDisplayItemNode.h"
#import "LKUserActionManager.h"

@interface KcCustomToolBarItems ()

/// 聚焦btn
@property (nonatomic, weak) NSButton *focusBtn;

@end

@implementation KcCustomToolBarItems

// MARK: - 隐藏视图

/// 调整可视view的范围
//- (void)adjustTheRangeOfVisableOfViewsWithSlide:(NSSlider *)slider {
//    LKStaticHierarchyDataSource *dataSource = [LKStaticHierarchyDataSource sharedInstance];
//
//    // 所有可见的view的count (本想把displayingFlatItems count赋值给slider的maxValue, 发现那一刻值不准确)⚠️
//    NSArray<LookinDisplayItem *> *displayingFlatItems = dataSource.displayingFlatItems;
//    NSInteger value = floor(slider.doubleValue * displayingFlatItems.count / slider.maxValue);
//
//    for (NSInteger i = displayingFlatItems.count - 1; i >= 0; i--) {
//        if (i > (value - 1)) {
//            [displayingFlatItems[i] hiddenViewAndSaveCurrentHiddenStatus];
//        } else {
//            [displayingFlatItems[i] resetHiddenViewStatus];
//        }
//    }
//}

/// 调整可视view的范围
- (void)adjustTheRangeOfVisableOfViewsWithSlide:(KcDoubleSlide *)slider {
    LKStaticHierarchyDataSource *dataSource = [LKStaticHierarchyDataSource sharedInstance];

    // 所有可见的view的count (本想把displayingFlatItems count赋值给slider的maxValue, 发现那一刻值不准确)⚠️
    NSArray<LookinDisplayItem *> *displayingFlatItems = dataSource.displayingFlatItems;
    NSInteger rightValue = floor(slider.rightValue * displayingFlatItems.count / slider.totalLength);
    NSInteger leftValue = floor(slider.leftValue * displayingFlatItems.count / slider.totalLength);

    for (NSInteger i = displayingFlatItems.count - 1; i >= 0; i--) {
        if (i >= rightValue || i <= leftValue) {
            [displayingFlatItems[i].previewNode hiddenView];
        } else {
            [displayingFlatItems[i].previewNode resetHiddenViewStatus];
        }
    }
}

#pragma mark - 聚焦

/// 聚焦选中的view
- (void)focusOnSelectedView:(NSButton *)btn {
    BOOL isFocus = true;
    if (btn.tag == 0) { // 聚焦 - 只显示选中的
        btn.title = @"取消聚焦";
        btn.tag = 1;
    } else { // 还原
        btn.title = @"聚焦";
        btn.tag = 0;
        isFocus = false;
    }
    
    if (!self.focusBtn) {
        self.focusBtn = btn;
    }
    
    NSArray<LookinDisplayItem *> *displayingFlatItems = LKStaticHierarchyDataSource.sharedInstance.displayingFlatItems;
    
    if (isFocus) {
        // 当前选中的
        LookinDisplayItem *selectedItem = LKStaticHierarchyDataSource.sharedInstance.selectedItem;
        NSSet<LookinDisplayItem *> *visableSelectedItems = [self displayingFlatItemsWithItem:selectedItem];
        
        for (LookinDisplayItem *item in displayingFlatItems) {
            if (![visableSelectedItems containsObject:item]) {
                if (isFocus) {
                    [item.previewNode hiddenView];
                } else {
                    [item.previewNode resetHiddenViewStatus];
                }
            }
        }
    } else { // 取消聚焦, 因为selectedItem可能变了, 只要把displayingFlatItems全部重置即可
        for (LookinDisplayItem *item in displayingFlatItems) {
            [item.previewNode resetHiddenViewStatus];
        }
    }
    
//    [self recursionHiddenDisplayItemWithSuperItem:selectedItem.superItem
//                                       filterItem:selectedItem
//                                          isFocus:isFocus];
}

/// 只包括在 hierarchy item自身及其子树中因为未被折叠而可见的 displayItems
- (nullable NSSet<LookinDisplayItem *> *)displayingFlatItemsWithItem:(LookinDisplayItem *)item {
    if (!item) {
        return nil;
    }

    NSMutableSet<LookinDisplayItem *> *set = [[NSMutableSet alloc] initWithObjects:item, nil];

    for (LookinDisplayItem *subitem in item.subitems) {
        if (!subitem.displayingInHierarchy) {
            continue;
        }

        NSSet<LookinDisplayItem *> *childItems = [self displayingFlatItemsWithItem:subitem];
        if (childItems) {
            [set unionSet:childItems];
        }
    }

    return set;
}

///// 递归隐藏item, 除了filterItem
//- (void)recursionHiddenDisplayItemWithSuperItem:(nullable LookinDisplayItem *)superItem filterItem:(nullable LookinDisplayItem *)filterItem isFocus:(BOOL)isFocus {
//    if (!superItem || superItem.subitems.count <= 0) {
//        return;
//    }
//
//    for (LookinDisplayItem *subitem in superItem.subitems) {
//        if (filterItem && [subitem isEqual:filterItem]) { // 过滤的不用处理
//            continue;
//        }
//
//        if (isFocus) {
//            [subitem hiddenViewAndSaveCurrentHiddenStatus];
//        } else {
//            [subitem resetHiddenViewStatus];
//        }
//    }
//
//    // 再继续往上找
//    [self recursionHiddenDisplayItemWithSuperItem:superItem.superItem
//                                       filterItem:superItem
//                                          isFocus:isFocus];
//}
//
//#pragma mark - LKUserActionManagerDelegate
//
///// 当 sendAction 被业务调用时，该 delegate 方法也会被调用
//- (void)LKUserActionManager:(LKUserActionManager *)manager didAct:(LKUserActionType)type {
//    // 当前选中的 item改变
//    if (type != LKUserActionType_SelectedItemChange) {
//        return;
//    }
//
//    if (!self.focusBtn || self.focusBtn.tag == 0) {
//        return;
//    }
//
//    self.focusBtn.title = @"聚焦";
//    self.focusBtn.tag = 0;
//    self.focusBtn = nil;
//
//    NSArray<LookinDisplayItem *> *displayingFlatItems = LKStaticHierarchyDataSource.sharedInstance.displayingFlatItems;
//    for (LookinDisplayItem *displayItem in displayingFlatItems) {
////        [displayItem resetHiddenViewStatus];
//        [displayItem.previewNode resetHiddenViewStatus];
//    }
//}


@end
