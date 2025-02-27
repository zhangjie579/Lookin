//
//  KcCustomAttributesGroup.m
//  LookinClient
//
//  Created by 张杰 on 2022/4/14.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import "KcCustomAttributesGroup.h"
#import "LookinAttributesGroup.h"
#import "LookinAttributesSection.h"
#import "LookinAttribute.h"

@implementation KcCustomAttributesGroup

/// 添加自定义的attributesGroup
+ (NSArray<LookinAttributesGroup *> *)addCustomAttributesGroupWithTargetDisplayItem:(nullable LookinDisplayItem *)targetDisplayItem {
    NSMutableArray<LookinAttributesGroup *> *attributesGroup = [[NSMutableArray alloc] init];
    
    { // debugMethodAttribute
        LookinAttributesGroup *debugMethodGroup = [[LookinAttributesGroup alloc] init];
        debugMethodGroup.identifier = LookinAttrGroup_KcDebugMethod;
        
        LookinAttributesSection *debugMethodSection = [[LookinAttributesSection alloc] init];
        debugMethodSection.identifier = LookinAttrSec_KcDebugMethod_Class;
        
        LookinAttribute *debugMethodAttribute = [[LookinAttribute alloc] init];
        debugMethodAttribute.identifier = LookinAttr_Kc_Debug_methodDesc;
        debugMethodAttribute.attrType = LookinAttrTypeCustomObj;
        debugMethodAttribute.targetDisplayItem = targetDisplayItem;
        debugMethodAttribute.value = @[
            @"😄😄关于动态执行方法说明\n * 格式oc方法 [0x12434534/类名 方法名:参数value]\n * 支持参数: self/this, int...基本数据类型, string, 16进制address, 传递class用类名, @id(类名) -> 内部会创建对应对象, @id(地址) -> 内存会转objc对象 (string不用写\"\", 否则会出错⚠️)",
            @"dump功能: 查看KcDebugSwift库 NSObject+KcObjcDump",
            
            @"查找属性name: kc_debug_findUIPropertyName",
            @"通过keyPath查找值为value的所有祖先: [self kc_log_findAncestorViewValue:(id)value keyPath:clipsToBounds]",
            @"查找图层树下设置了对应属性(背景色: 0, 圆角: 1, 边框: 2)的所有subviews: [0x12434534(view的地址) matchSubviewsWithPropertyType:0]",
            @"dump对象: kc_dumpSwift",
            @"获取所有成员变量: kc_dump_allIvarDescription",
            @"获取imageView的image信息: kc_debug_imageInfo",
            @"获取imageView的origin url信息: kc_debug_imageOriginURLString",
            @"view层级: kc_dump_viewHierarchy",
            @"ViewController的层级: kc_dump_viewControllerHierarchy",
            @"自动布局层级: kc_dump_autoLayoutHierarchy",
        ];
        
        debugMethodSection.attributes = @[
            debugMethodAttribute,
        ];
        
        debugMethodGroup.attrSections = @[debugMethodSection];
        
        [attributesGroup addObject:debugMethodGroup];
    }
    
    { // 调用oc的方法
        LookinAttributesGroup *debugMethodGroup = [[LookinAttributesGroup alloc] init];
        debugMethodGroup.identifier = LookinAttrGroup_KcDebugCallObjcMethod;
        
        LookinAttributesSection *debugMethodSection = [[LookinAttributesSection alloc] init];
        debugMethodSection.identifier = LookinAttrGroup_KcDebugCallObjcMethod_Class;
        
        LookinAttribute *debugMethodAttribute0 = [[LookinAttribute alloc] init];
        debugMethodAttribute0.identifier = LookinAttr_Kc_Debug_getPropertyInfo;
        debugMethodAttribute0.attrType = LookinAttrTypeCustomObj;
        debugMethodAttribute0.value = @""; // 获取属性name
        debugMethodAttribute0.targetDisplayItem = targetDisplayItem;
        
        LookinAttribute *debugMethodAttribute1 = [[LookinAttribute alloc] init];
        debugMethodAttribute1.identifier = LookinAttr_Kc_Debug_searchKeyPath;
        debugMethodAttribute1.attrType = LookinAttrTypeCustomObj;
        debugMethodAttribute1.value = @"通过keyPath查询属性值";
        debugMethodAttribute1.targetDisplayItem = targetDisplayItem;
        
        debugMethodSection.attributes = @[
            debugMethodAttribute0,
            debugMethodAttribute1,
        ];
        
        debugMethodGroup.attrSections = @[debugMethodSection];
        
        [attributesGroup addObject:debugMethodGroup];
    }
    
    return attributesGroup.copy;
}

+ (NSArray<NSString *> *)kcCustomIdentity {
    return @[
        LookinAttrSec_KcDebugMethod_Class,
        LookinAttrGroup_KcDebugCallObjcMethod_Class
    ];
}

@end
