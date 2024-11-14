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
#import "KcObjcMethodMenu.h"

@interface KcDashboardAttributeGetPropertyInfoView () <NSMenuDelegate>

@property(nonatomic, strong) KcMenuContainerButton *propertyInfoBtn;

@property(nonatomic, strong) NSTextView *propertyInfoTextView;
@property(nonatomic, strong) NSScrollView *propertyInfoScrollView;

@end

@implementation KcDashboardAttributeGetPropertyInfoView

- (instancetype)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
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
    
    NSMenuItem *item = KcCallObjcMethodAttributeManager.sharedManager.noParamMethodMenu.menu.itemArray.firstObject;
    [self updateTitleWithMenuItem:item];
    
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

    if ([menuItem.title isEqualToString:self.propertyInfoBtn.title]) {
        // if 中后面的 == 是用来判断二者都是 nil 的情况
        menuItem.state = NSControlStateValueOn;
    } else {
        menuItem.state = NSControlStateValueOff;
    }
}

- (void)_handlePresetMenuItem:(NSMenuItem *)item {
    [self updateTitleWithMenuItem:item];
    
    @weakify(self);
    [[KcCallObjcMethodAttributeManager.sharedManager evalObjcMethodWithItem:item targetDisplayItem:self.attribute.targetDisplayItem] subscribeNext:^(NSString *  _Nullable message) {
        @strongify(self);
        
        self.propertyInfoTextView.string = message;
    }];
}

#pragma mark - Private

- (void)_executeGetPropertyList:(NSEvent *)event {
    NSMenu *menu = KcCallObjcMethodAttributeManager.sharedManager.noParamMethodMenu.menu;
    menu.delegate = self;
    
    [NSMenu popUpContextMenu:menu withEvent:event forView:self.propertyInfoBtn];
}

- (void)updateTitleWithMenuItem:(NSMenuItem *)menuItem {
    [self.propertyInfoBtn setAttributedTitle:$(menuItem.title).textColor([NSColor colorNamed:@"DashboardCardValueColor"]).attrString];
}

#pragma mark - 懒加载

- (KcMenuContainerButton *)propertyInfoBtn {
    if (!_propertyInfoBtn) {
        _propertyInfoBtn = [KcMenuContainerButton new];
        _propertyInfoBtn.ignoresMultiClick = YES;
        _propertyInfoBtn.clickTarget = self;
        _propertyInfoBtn.clickAction = @selector(_executeGetPropertyList:);
        _propertyInfoBtn.font = NSFontMake(13);
        [_propertyInfoBtn setAttributedTitle:$(@"获取属性列表").textColor([NSColor colorNamed:@"DashboardCardValueColor"]).attrString];
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

@end
