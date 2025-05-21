//
//  KcDashboardAttributeSearchKeyPathView.m
//  LookinClient
//
//  Created by 张杰 on 2024/11/10.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import "KcDashboardAttributeSearchKeyPathView.h"
#import "KcCallObjcMethodAttributeManager.h"
#import "KcMenuContainerButton.h"
#import "LKHierarchyDataSource.h"
#import "LKDashboardViewController.h"
#import "LookinHierarchyInfo.h"
#import "LKNavigationManager.h"
#import "LKStaticWindowController.h"

@interface KcDashboardAttributeSearchKeyPathView () <NSTextFieldDelegate, NSMenuDelegate>

@property(nonatomic, strong) KcMenuContainerButton *btn;

@property(nonatomic, strong) NSTextField *textField;

@property(nonatomic, strong) NSTextView *textView;
@property(nonatomic, strong) NSScrollView *scrollView;

@property(nonatomic, strong) NSMutableArray<NSDictionary<NSString *, id> *> *evalMethods;

@property(nonatomic, strong) NSMenu *methodMenu;

@end

@implementation KcDashboardAttributeSearchKeyPathView

- (instancetype)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.btn];
        [self addSubview:self.textField];
        [self.textView class];
        [self addSubview:self.scrollView];
    }
    return self;
}

- (void)layout {
    [super layout];
    CGFloat itemWidth = self.frame.size.width;
    
    CGFloat x = 0;
    CGFloat y = 5;
    self.textField.frame = CGRectMake(x, y, itemWidth, 25);
//    self.btn.frame = CGRectMake(CGRectGetMaxX(self.textField.frame) + 5, y, itemWidth - (CGRectGetMaxX(self.textField.frame) + 5), self.textField.frame.size.height);
    y = CGRectGetMaxY(self.textField.frame);
    
    self.btn.frame = CGRectMake(x, y + 5, itemWidth, 25);
    y = CGRectGetMaxY(self.btn.frame);
    
    self.scrollView.frame = CGRectMake(0, y + 5, itemWidth, 180);
}

- (void)renderWithAttribute {
    // 清空、初始化
    self.textView.string = @"";
    self.textField.stringValue = @"";
    [self.methodMenu removeAllItems];
    [self.evalMethods removeAllObjects];
    [self.evalMethods addObjectsFromArray:[KcDashboardAttributeSearchKeyPathView defaultMethods]];
    
    LKHierarchyDataSource *dataSource = self.dashboardViewController.currentDataSource;
    NSArray<NSDictionary<NSString *, id> *> *_Nullable injectMethods = dataSource.rawHierarchyInfo.kc_injectKeyPathMethods;
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
    return NSMakeSize(limitedSize.width, 245);
}

- (NSUInteger)numberOfColumnsOccupied {
    return 1;
}

#pragma mark - <NSTextFieldDelegate>

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    // 点击刷新的时候可能会走这里, 这种情况下应该过滤掉
    LKStaticWindowController *staticWc = [LKNavigationManager sharedInstance].staticWindowController;
    
    bool isReloading = [staticWc isReloading];
    
    if (isReloading) {
        return;
    }
    
    NSTextField *editingTextField = notification.object;
    
    if (editingTextField.stringValue.length <= 0) {
        return;
    }
    
    NSMenuItem *item = self.methodMenu.itemArray[self.btn.tag];
    NSDictionary<NSString *, id> *method = [self evalMethodStringWithItem:item keyPath:self.textField.stringValue];
    
    @weakify(self);
    [[KcCallObjcMethodAttributeManager evalObjcMethod:method targetDisplayItem:self.attribute.targetDisplayItem] subscribeNext:^(NSString * _Nullable message) {
        @strongify(self);
        
        self.textView.string = message ?: @"";
    }];
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
    
    menuItem.state = menuItem.tag == self.btn.tag ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)_handlePresetMenuItem:(NSMenuItem *)item {
    [self updateTitleWithMenuItem:item];
    
    if (self.textField.stringValue.length) {
        NSDictionary<NSString *, id> *method = [self evalMethodStringWithItem:item keyPath:self.textField.stringValue];
        
        @weakify(self);
        [[KcCallObjcMethodAttributeManager evalObjcMethod:method targetDisplayItem:self.attribute.targetDisplayItem] subscribeNext:^(NSString * _Nullable message) {
            @strongify(self);
            
            self.textView.string = message ?: @"";
        }];
    }
}

#pragma mark - Private

- (void)_selectItem:(NSEvent *)event {
    [NSMenu popUpContextMenu:self.methodMenu withEvent:event forView:self.btn];
}

- (void)updateTitleWithMenuItem:(NSMenuItem *)menuItem {
    [self.btn setAttributedTitle:$(menuItem.title).textColor([NSColor colorNamed:@"DashboardCardValueColor"]).attrString];
    
    self.btn.tag = menuItem.tag;
}

/* 替换keyPath
 @{
     @"methodName": @"[self matchSuperviewsWithPropertyName: %@]",
     @"isUIViewMethod": @YES,
     @"title": @"superview属性",
 },
 */
- (NSDictionary<NSString *, id> *)evalMethodStringWithItem:(NSMenuItem *)item keyPath:(NSString *)keyPath {
    NSMutableDictionary<NSString *, id> *methodInfo = [NSMutableDictionary dictionaryWithDictionary:item.representedObject[@"method"]];
    
    NSString *name = [methodInfo[@"methodName"] stringByReplacingOccurrencesOfString:@"%@" withString:keyPath];
    methodInfo[@"methodName"] = name;

    return methodInfo;
}

#pragma mark - 懒加载

- (NSTextField *)textField {
    if (!_textField) {
        _textField = [[NSTextField alloc] init];
        _textField.font = NSFontMake(13);
        _textField.backgroundColor = [NSColor colorNamed:@"DashboardCardValueBGColor"];
        _textField.placeholderString = @"输入keyPath";
        _textField.delegate = self;
        _textField.tag = 0;
    }
    return _textField;
}

- (KcMenuContainerButton *)btn {
    if (!_btn) {
        _btn = [KcMenuContainerButton new];
        _btn.ignoresMultiClick = YES;
        _btn.clickTarget = self;
        _btn.clickAction = @selector(_selectItem:);
        _btn.font = NSFontMake(13);
    }
    return _btn;
}

- (NSScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [LKHelper scrollableTextView];
        _scrollView.wantsLayer = YES;
        _scrollView.layer.cornerRadius = DashboardCardControlCornerRadius;
    }
    return _scrollView;
}

- (NSTextView *)textView {
    if (!_textView) {
        _textView = self.scrollView.documentView;
        _textView.font = NSFontMake(12);
        _textView.backgroundColor = [NSColor colorNamed:@"DashboardCardValueBGColor"];
        _textView.textContainerInset = NSMakeSize(2, 4);
        _textView.editable = false;
    }
    return _textView;
}

- (NSMutableArray<NSDictionary<NSString *,id> *> *)evalMethods {
    if (!_evalMethods) {
        _evalMethods = [NSMutableArray arrayWithArray:[KcDashboardAttributeSearchKeyPathView defaultMethods]];
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
            @"methodName": @"[KcFindPropertyTooler searchPropertyWithValue:self keyPath: %@]",
            @"isUIViewMethod": @NO,
            @"title": @"查询keyPath",
        },
        @{
            @"methodName": @"[self matchSubviewsWithPropertyName: %@]",
            @"isUIViewMethod": @YES,
            @"title": @"all子树keyPath",
        },
        @{
            @"methodName": @"[self matchSuperviewsWithPropertyName: %@]",
            @"isUIViewMethod": @YES,
            @"title": @"superview族簇keyPath",
        },
    ];
}

@end
