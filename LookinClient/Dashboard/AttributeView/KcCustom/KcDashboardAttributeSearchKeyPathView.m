//
//  KcDashboardAttributeSearchKeyPathView.m
//  LookinClient
//
//  Created by 张杰 on 2024/11/10.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import "KcDashboardAttributeSearchKeyPathView.h"
#import "KcCallObjcMethodAttributeManager.h"
#import "KcObjcMethodMenu.h"
#import "KcMenuContainerButton.h"

@interface KcDashboardAttributeSearchKeyPathView () <NSTextFieldDelegate, NSMenuDelegate>

@property(nonatomic, strong) KcMenuContainerButton *btn;

@property(nonatomic, strong) NSTextField *textField;

@property(nonatomic, strong) NSTextView *textView;
@property(nonatomic, strong) NSScrollView *scrollView;

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
    
    NSMenuItem *item = KcCallObjcMethodAttributeManager.sharedManager.keyPathMenu.menu.itemArray.firstObject;
    [self updateTitleWithMenuItem:item];
    
    [self setNeedsLayout:YES];
}

- (NSSize)sizeThatFits:(NSSize)limitedSize {
    return NSMakeSize(limitedSize.width, 245);
}

- (NSUInteger)numberOfColumnsOccupied {
    return 1;
}

#pragma mark - <NSTextViewDelegate>

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    NSTextField *editingTextField = notification.object;
    
    if (editingTextField.stringValue.length <= 0) {
        return;
    }
    
    KcCallObjcMethodAttributeManager *manager = KcCallObjcMethodAttributeManager.sharedManager;
    KcKeyPathObjcMethodMenu *keyPathMenu = manager.keyPathMenu;
    
    NSDictionary<NSString *, id> *method = [keyPathMenu evalMethodStringWithItem:[keyPathMenu itemWithTitle:self.btn.title] keyPath:editingTextField.stringValue];
    
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

    if ([menuItem.title isEqualToString:self.btn.title]) {
        // if 中后面的 == 是用来判断二者都是 nil 的情况
        menuItem.state = NSControlStateValueOn;
    } else {
        menuItem.state = NSControlStateValueOff;
    }
}

- (void)_handlePresetMenuItem:(NSMenuItem *)item {
    [self updateTitleWithMenuItem:item];
    
    if (self.textField.stringValue.length) {
        KcCallObjcMethodAttributeManager *manager = KcCallObjcMethodAttributeManager.sharedManager;
        
        NSDictionary<NSString *, id> *method = [manager.keyPathMenu evalMethodStringWithItem:item keyPath:self.textField.stringValue];
        
        @weakify(self);
        [[KcCallObjcMethodAttributeManager evalObjcMethod:method targetDisplayItem:self.attribute.targetDisplayItem] subscribeNext:^(NSString * _Nullable message) {
            @strongify(self);
            
            self.textView.string = message ?: @"";
        }];
    }
}

#pragma mark - Private

- (void)_selectItem:(NSEvent *)event {
    NSMenu *menu = KcCallObjcMethodAttributeManager.sharedManager.keyPathMenu.menu;
    menu.delegate = self;
    
    [NSMenu popUpContextMenu:menu withEvent:event forView:self.btn];
}

- (void)updateTitleWithMenuItem:(NSMenuItem *)menuItem {
    [self.btn setAttributedTitle:$(menuItem.title).textColor([NSColor colorNamed:@"DashboardCardValueColor"]).attrString];
}

#pragma mark - 懒加载

- (NSTextField *)textField {
    if (!_textField) {
        _textField = [[NSTextField alloc] init];
        _textField.font = NSFontMake(13);
        _textField.backgroundColor = [NSColor colorNamed:@"DashboardCardValueBGColor"];
        _textField.placeholderString = @"输入keyPath";
        _textField.delegate = self;
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

@end
