//
//  LKWindowToolbarHelper.h
//  Lookin
//
//  Created by Li Kai on 2019/5/8.
//  https://lookin.work
//

#import <Foundation/Foundation.h>

extern NSToolbarItemIdentifier const LKToolBarIdentifier_Dimension;
extern NSToolbarItemIdentifier const LKToolBarIdentifier_Scale;
extern NSToolbarItemIdentifier const LKToolBarIdentifier_Rotation;
extern NSToolbarItemIdentifier const LKToolBarIdentifier_Setting;
extern NSToolbarItemIdentifier const LKToolBarIdentifier_Reload;
extern NSToolbarItemIdentifier const LKToolBarIdentifier_App;
extern NSToolbarItemIdentifier const LKToolBarIdentifier_AppInReadMode;
extern NSToolbarItemIdentifier const LKToolBarIdentifier_Console;
extern NSToolbarItemIdentifier const LKToolBarIdentifier_Add;
extern NSToolbarItemIdentifier const LKToolBarIdentifier_Remove;
extern NSToolbarItemIdentifier const LKToolBarIdentifier_Measure;
extern NSToolbarItemIdentifier const LKToolBarIdentifier_Message;
extern NSToolbarItemIdentifier const LKToolBarIdentifier_FastMode;

/// 隐藏view, 调整可视化view视图
extern NSToolbarItemIdentifier const LKToolBarIdentifier_AdjustVisableOfViews;
/// 只显示选中的view
extern NSToolbarItemIdentifier const LKToolBarIdentifier_focusOnSelectedView;

@class LKPreferenceManager, LookinAppInfo;

@interface LKWindowToolbarHelper : NSObject

+ (instancetype)sharedInstance;

/**
 通过以下 identifier 创建的 toolBarItem 需要业务自己设置点击 action:
 - Reload
 - App
 - Expansion
 - DynamicMode
 - StaticMode
 - RemoteSelect
 - Add
 - Remove
 - Setting
 - Change
 */
- (NSToolbarItem *)makeToolBarItemWithIdentifier:(NSToolbarItemIdentifier)identifier preferenceManager:(LKPreferenceManager *)manager;

/// 请使用该方法初始化 AppInReadMode 这个 item
- (NSToolbarItem *)makeAppInReadModeItemWithAppInfo:(LookinAppInfo *)appInfo;

@end
