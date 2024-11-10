//
//  KcDashboardAttributeSearchKeyPathView.m
//  LookinClient
//
//  Created by 张杰 on 2024/11/10.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import "KcDashboardAttributeSearchKeyPathView.h"
#import "LKAppsManager.h"

@interface KcDashboardAttributeSearchKeyPathView () <NSTextFieldDelegate>

//@property(nonatomic, strong) NSButton *btn;

@property(nonatomic, strong) NSTextField *textField;

@property(nonatomic, strong) NSTextView *textView;
@property(nonatomic, strong) NSScrollView *scrollView;

@end

@implementation KcDashboardAttributeSearchKeyPathView

- (instancetype)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.textField];
        [self.textView class];
        [self addSubview:self.scrollView];
    }
    return self;
}

- (void)layout {
    [super layout];
    CGFloat itemWidth = self.frame.size.width;
    
    CGFloat x = 5;
    CGFloat y = 5;
    self.textField.frame = CGRectMake(x, y, itemWidth - 2 * x, 25);
    y = CGRectGetMaxY(self.textField.frame);
    
    self.scrollView.frame = CGRectMake(0, y + 5, itemWidth, 180);
}

- (void)renderWithAttribute {
    // 清空、初始化
    self.textView.string = @"";
    self.textField.stringValue = @"";
    
    [self setNeedsLayout:YES];
}

- (NSSize)sizeThatFits:(NSSize)limitedSize {
    return NSMakeSize(limitedSize.width, 215);
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
    
    LookinObject *searchObjc = nil;
    
    LookinObject *viewObject = self.attribute.targetDisplayItem.viewObject;
    searchObjc = viewObject;
    
    LookinObject *_Nullable hostViewControllerObject = self.attribute.targetDisplayItem.hostViewControllerObject;
    
    // 有vc的用vc
    if (hostViewControllerObject) {
        searchObjc = hostViewControllerObject;
    }
    
    @weakify(self);
    [[LKAppsManager.sharedInstance.inspectingApp performSelectorWithText:[NSString stringWithFormat:@"[KcFindPropertyTooler searchPropertyWithValue:self keyPath: %@]", editingTextField.stringValue] oid:searchObjc.oid] subscribeNext:^(NSDictionary *dict) {
        NSString *_Nullable returnDescription = dict[@"description"];
        NSString *_Nullable errorLog = dict[@"errorLog"];

        @strongify(self);
        
        if (returnDescription.length) {
            self.textView.string = returnDescription;
        } else if (errorLog.length) {
            self.textView.string = [NSString stringWithFormat:@"%@\n%@", errorLog, @"pod 'KcDebugSwift' 并且版本 >= 0.1.5"];
        } else {
            self.textView.string = @"";
        }
    }];
}

#pragma mark - Private

#pragma mark - 懒加载

- (NSTextField *)textField {
    if (!_textField) {
        _textField = [[NSTextField alloc] init];
        _textField.font = NSFontMake(12);
        _textField.backgroundColor = [NSColor colorNamed:@"DashboardCardValueBGColor"];
        _textField.placeholderString = @"请输入查询的keyPath";
        _textField.delegate = self;
    }
    return _textField;
}

//- (NSButton *)btn {
//    if (!_btn) {
//        _btn = [NSButton new];
//        _btn.ignoresMultiClick = YES;
//        _btn.target = self;
//        _btn.action = @selector(_executeGetPropertyList);
//        _btn.font = NSFontMake(13);
////        [_propertyInfoBtn setTitle:@"获取当前对象的属性列表"];
//        [_btn setAttributedTitle:$(@"获取属性列表").textColor([NSColor colorNamed:@"DashboardCardValueColor"]).attrString];
//    }
//    return _btn;
//}

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

