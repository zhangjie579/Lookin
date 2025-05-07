//
//  KcDashboardAttributeGetPropertyInfoView.m
//  LookinClient
//
//  Created by 张杰 on 2024/11/10.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import "KcDashboardAttributeGetPropertyInfoView.h"
#import "LKAppsManager.h"
#import "KcMenuContainerButton.h"
#import "KcCallObjcMethodAttributeManager.h"
#import "LKHierarchyDataSource.h"
#import "LKDashboardViewController.h"
#import "LookinHierarchyInfo.h"

@interface KcDashboardAttributeGetPropertyInfoView () <NSMenuDelegate>

@property(nonatomic, strong) KcMenuContainerButton *propertyInfoBtn;

@property(nonatomic, strong) NSTextView *propertyInfoTextView;
@property(nonatomic, strong) NSScrollView *propertyInfoScrollView;

@property(nonatomic, strong) NSMutableArray<NSDictionary<NSString *, id> *> *evalMethods;

@property(nonatomic, strong) NSMenu *methodMenu;

@end

@implementation KcDashboardAttributeGetPropertyInfoView

- (instancetype)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 在这里拿不到dashboardViewController⚠️
        [self addSubview:self.propertyInfoBtn];
        [self.propertyInfoTextView class];
        [self addSubview:self.propertyInfoScrollView];
    }
    return self;
}

- (void)layout {
    [super layout];
    CGFloat itemWidth = self.frame.size.width;
    
    CGFloat x = 0;
    CGFloat y = 5;
    self.propertyInfoBtn.frame = CGRectMake(x, y, itemWidth - 2 * x, 40);
    y = CGRectGetMaxY(self.propertyInfoBtn.frame);

    self.propertyInfoScrollView.frame = CGRectMake(0, y + 5, itemWidth, 180);
}

- (void)renderWithAttribute {
    // 清空、初始化
    self.propertyInfoTextView.string = @"";
    [self.methodMenu removeAllItems];
    [self.evalMethods removeAllObjects];
    [self.evalMethods addObjectsFromArray:[KcDashboardAttributeGetPropertyInfoView defaultMethods]];
    
    LKHierarchyDataSource *dataSource = self.dashboardViewController.currentDataSource;
    NSArray<NSDictionary<NSString *, id> *> *_Nullable injectMethods = dataSource.rawHierarchyInfo.kc_injectMethods;
    if (injectMethods) {
        [self.evalMethods addObjectsFromArray:injectMethods];
    }
    
    [self.evalMethods enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.methodMenu addItem:({
            NSMenuItem *menuItem = [NSMenuItem new];
            menuItem.image = [[NSImage alloc] initWithSize:NSMakeSize(1, 22)];
            menuItem.title = dict[@"title"];
            menuItem.tag = idx;
            menuItem.representedObject = @{
                @"method": dict,
            };
            
            menuItem;
        })];
    }];
    
    NSMenuItem *item = self.methodMenu.itemArray.firstObject;
    if (item) {
        [self updateTitleWithMenuItem:item];
    }
    
    [self setNeedsLayout:YES];
}

- (NSSize)sizeThatFits:(NSSize)limitedSize {
    return NSMakeSize(limitedSize.width, 230);
}

#pragma mark - <NSMenuDelegate>

- (void)menuNeedsUpdate:(NSMenu *)menu {
    [menu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull menuItem, NSUInteger idx, BOOL * _Nonnull stop) {
        if (menuItem.hasSubmenu) {
            [menuItem.submenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull subMenuItem, NSUInteger idx, BOOL * _Nonnull stop) {
                [self _updateMenuItem:subMenuItem];
            }];
        } else {
            [self _updateMenuItem:menuItem];
        }
    }];
}

- (void)_updateMenuItem:(NSMenuItem *)menuItem {
    menuItem.target = self;
    menuItem.action = @selector(_handlePresetMenuItem:);
    
    menuItem.state = menuItem.tag == self.propertyInfoBtn.tag ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)_handlePresetMenuItem:(NSMenuItem *)item {
    [self updateTitleWithMenuItem:item];
    
    NSDictionary<NSString *, id> *objcMethod = item.representedObject[@"method"];
    
    @weakify(self);
    [[KcCallObjcMethodAttributeManager evalObjcMethod:objcMethod targetDisplayItem:self.attribute.targetDisplayItem] subscribeNext:^(NSString *  _Nullable message) {
        @strongify(self);
        
        self.propertyInfoTextView.string = message;
    }];
}

#pragma mark - Private

- (void)_executeGetPropertyList:(NSEvent *)event {
    [NSMenu popUpContextMenu:self.methodMenu withEvent:event forView:self.propertyInfoBtn];
}

- (void)updateTitleWithMenuItem:(NSMenuItem *)menuItem {
    [self.propertyInfoBtn setAttributedTitle:$(menuItem.title).textColor([NSColor colorNamed:@"DashboardCardValueColor"]).attrString];
    
    self.propertyInfoBtn.tag = menuItem.tag;
}

#pragma mark - 懒加载

- (KcMenuContainerButton *)propertyInfoBtn {
    if (!_propertyInfoBtn) {
        _propertyInfoBtn = [KcMenuContainerButton new];
        _propertyInfoBtn.ignoresMultiClick = YES;
        _propertyInfoBtn.clickTarget = self;
        _propertyInfoBtn.clickAction = @selector(_executeGetPropertyList:);
        _propertyInfoBtn.font = NSFontMake(13);
        
        NSString *title = self.evalMethods[0][@"title"];
        [_propertyInfoBtn setAttributedTitle:$(title).textColor([NSColor colorNamed:@"DashboardCardValueColor"]).attrString];
    }
    return _propertyInfoBtn;
}

- (NSScrollView *)propertyInfoScrollView {
    if (!_propertyInfoScrollView) {
        _propertyInfoScrollView = [LKHelper scrollableTextView];
        _propertyInfoScrollView.wantsLayer = YES;
        _propertyInfoScrollView.layer.cornerRadius = DashboardCardControlCornerRadius;
    }
    return _propertyInfoScrollView;
}

- (NSTextView *)propertyInfoTextView {
    if (!_propertyInfoTextView) {
        _propertyInfoTextView = self.propertyInfoScrollView.documentView;
        _propertyInfoTextView.font = NSFontMake(13);
        _propertyInfoTextView.backgroundColor = [NSColor colorNamed:@"DashboardCardValueBGColor"];
        _propertyInfoTextView.textContainerInset = NSMakeSize(2, 4);
        _propertyInfoTextView.editable = false;
    }
    return _propertyInfoTextView;
}

- (NSMutableArray<NSDictionary<NSString *,id> *> *)evalMethods {
    if (!_evalMethods) {
        _evalMethods = [NSMutableArray arrayWithArray:[KcDashboardAttributeGetPropertyInfoView defaultMethods]];
    }
    return _evalMethods;
}

- (NSMenu *)methodMenu {
    if (!_methodMenu) {
        _methodMenu = [NSMenu new];
        _methodMenu.delegate = self;
    }
    return _methodMenu;
}

+ (NSArray<NSDictionary<NSString *, id> *> *)defaultMethods {
    return @[
        @{
            @"methodName": @"[KcFindPropertyTooler propertyListWithValue:self]",
            @"isUIViewMethod": @NO,
            @"title": @"获取属性列表",
        },
        @{
            @"methodName":  @"[self kc_debug_findUIPropertyName]",
            @"isUIViewMethod": @NO,
            @"title": @"查询对象属性名",
        },
        @{
            @"methodName": @"[self kc_dump_allIvarDescription]",
            @"isUIViewMethod": @NO,
            @"title": @"所有成员变量",
        },
        @{
            @"methodName": @"[self kc_dumpSwift]",
            @"isUIViewMethod": @NO,
            @"title": @"dumpSwift",
        },
        @{
            @"methodName": @"[@Class kc_dump_allMethodDescription]",
            @"isUIViewMethod": @NO,
            @"title": @"dump所有方法",
        },
        @{
            @"methodName": @"[@Class kc_dump_allCustomMethodDescription]",
            @"isUIViewMethod": @NO,
            @"title": @"dump所有自定义方法",
        },
        @{
            @"methodName": @"[@Class kc_dump_allPropertyDescription]",
            @"isUIViewMethod": @NO,
            @"title": @"dump所有属性",
        },
        @{
            @"methodName": @"[NSObject kc_dump_propertyDescriptionForClass:@Class]",
            @"isUIViewMethod": @NO,
            @"title": @"dump当前class属性",
        },
        @{
            @"methodName": @"[self kc_dump_autoLayoutHierarchy]",
            @"isUIViewMethod": @YES,
            @"title": @"自动布局",
        },
        @{
            @"methodName": @"[self kc_dump_viewControllerHierarchy]",
            @"isUIViewMethod": @NO,
            @"title": @"ViewController的层级"
        },
        @{
            @"methodName": @"[self matchSubviewsWithPropertyName:backgroundColor]",
            @"isUIViewMethod": @YES,
            @"title": @"查询all子树背景色",
        },
        @{
            @"methodName": @"[self matchSubviewsWithPropertyName:cornerRadius]",
            @"isUIViewMethod": @YES,
            @"title": @"查询all子树圆角",
        },
        @{
            @"methodName": @"[self matchSubviewsWithPropertyName:borderColor]",
            @"isUIViewMethod": @YES,
            @"title": @"查询all子树边框",
        },
    ];
}

@end
