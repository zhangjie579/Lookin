//
//  LKDisplayItemNode.h
//  Lookin
//
//  Created by Li Kai on 2019/8/17.
//  https://lookin.work
//

#import <SceneKit/SceneKit.h>

@class LookinDisplayItem, LKPreferenceManager, LKHierarchyDataSource;

@interface LKDisplayItemNode : SCNNode

- (instancetype)initWithDataSource:(LKHierarchyDataSource *)dataSource;

/// 在全部 displayItems 里的 idx
@property(nonatomic, assign) NSUInteger index;

@property(nonatomic, assign) CGSize screenSize;

@property(nonatomic, weak) LKPreferenceManager *preferenceManager;

@property(nonatomic, strong) LookinDisplayItem *displayItem;

@property(nonatomic, assign) BOOL isDarkMode;

/// 隐藏view
- (void)hiddenView;

/// 重置隐藏状态
- (void)resetHiddenViewStatus;

@end
