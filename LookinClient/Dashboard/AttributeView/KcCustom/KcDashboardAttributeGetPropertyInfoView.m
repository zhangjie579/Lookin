//
//  KcDashboardAttributeGetPropertyInfoView.m
//  LookinClient
//
//  Created by 张杰 on 2024/11/10.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import "KcDashboardAttributeGetPropertyInfoView.h"
#import "LKAppsManager.h"

typedef enum : NSUInteger {
    KcPropertyInfoTypeGet,
    KcPropertyInfoTypeIvarName,
} KcPropertyInfoType;

@interface KcDashboardAttributeGetPropertyInfoView ()

@property(nonatomic, strong) NSButton *propertyInfoBtn;

@property(nonatomic, strong) NSTextView *propertyInfoTextView;
@property(nonatomic, strong) NSScrollView *propertyInfoScrollView;

@property(nonatomic, assign) KcPropertyInfoType propertyInfoType;

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
    
    CGFloat propertyInfoScrollViewH = 80;
    if (self.propertyInfoType == KcPropertyInfoTypeGet) {
        propertyInfoScrollViewH = 180;
    } else if (self.propertyInfoType == KcPropertyInfoTypeIvarName) {
        propertyInfoScrollViewH = 80;
    } else {
        NSAssert(NO, @"要实现类型");
    }
    
    self.propertyInfoScrollView.frame = CGRectMake(0, y + 5, itemWidth, propertyInfoScrollViewH);
}

- (void)renderWithAttribute {
    // 清空、初始化
    self.propertyInfoTextView.string = @"";
    
    if ([self.attribute.value isEqualToString:@"1"]) {
        self.propertyInfoType = KcPropertyInfoTypeGet;
        [self.propertyInfoBtn setAttributedTitle:$(@"获取属性列表").textColor([NSColor colorNamed:@"DashboardCardValueColor"]).attrString];
    } else if ([self.attribute.value isEqualToString:@"2"]) {
        self.propertyInfoType = KcPropertyInfoTypeIvarName;
        [self.propertyInfoBtn setAttributedTitle:$(@"查询当前对象属性名").textColor([NSColor colorNamed:@"DashboardCardValueColor"]).attrString];
    } else {
        NSAssert(NO, @"要实现类型");
        self.propertyInfoType = KcPropertyInfoTypeGet;
        [self.propertyInfoBtn setAttributedTitle:$(@"获取属性列表").textColor([NSColor colorNamed:@"DashboardCardValueColor"]).attrString];
    }
    
    [self setNeedsLayout:YES];
}

- (NSSize)sizeThatFits:(NSSize)limitedSize {

    if (self.propertyInfoType == KcPropertyInfoTypeGet) {
        return NSMakeSize(limitedSize.width, 230);
    } else if (self.propertyInfoType == KcPropertyInfoTypeIvarName) {
        return NSMakeSize(limitedSize.width, 130);
    } else {
        NSAssert(NO, @"要实现类型");
        return NSMakeSize(limitedSize.width, 230);
    }
}

#pragma mark - Private

/// 执行获取对象属性的方法
- (void)_executeGetPropertyList {
    LookinObject *searchObjc = nil;
    
    LookinObject *viewObject = self.attribute.targetDisplayItem.viewObject;
    searchObjc = viewObject;
    
    LookinObject *_Nullable hostViewControllerObject = self.attribute.targetDisplayItem.hostViewControllerObject;
    
    // 有vc的用vc
    if (hostViewControllerObject) {
        searchObjc = hostViewControllerObject;
    }
    
    NSString *objcMethod = nil;
    
    if (self.propertyInfoType == KcPropertyInfoTypeGet) {
        objcMethod = @"[KcFindPropertyTooler propertyListWithValue:self]";
    } else if (self.propertyInfoType == KcPropertyInfoTypeIvarName) {
        objcMethod = @"[self kc_debug_findUIPropertyName]";
    } else {
        NSAssert(NO, @"要实现");
    }
    
    @weakify(self);
    [[LKAppsManager.sharedInstance.inspectingApp performSelectorWithText:objcMethod oid:searchObjc.oid] subscribeNext:^(NSDictionary *dict) {
        NSString *_Nullable returnDescription = dict[@"description"];
        NSString *_Nullable errorLog = dict[@"errorLog"];

        @strongify(self);
        
        if (returnDescription.length) {
            self.propertyInfoTextView.string = returnDescription;
        } else if (errorLog.length) {
            self.propertyInfoTextView.string = [NSString stringWithFormat:@"%@\n%@", errorLog, @"pod 'KcDebugSwift' 并且版本 >= 0.1.5"];
        } else {
            self.propertyInfoTextView.string = @"";
        }
    }];
}

#pragma mark - 懒加载

- (NSButton *)propertyInfoBtn {
    if (!_propertyInfoBtn) {
        _propertyInfoBtn = [NSButton new];
        _propertyInfoBtn.ignoresMultiClick = YES;
        _propertyInfoBtn.target = self;
        _propertyInfoBtn.action = @selector(_executeGetPropertyList);
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
        _propertyInfoTextView.font = NSFontMake(12);
        _propertyInfoTextView.backgroundColor = [NSColor colorNamed:@"DashboardCardValueBGColor"];
        _propertyInfoTextView.textContainerInset = NSMakeSize(2, 4);
        _propertyInfoTextView.editable = false;
    }
    return _propertyInfoTextView;
}

@end
