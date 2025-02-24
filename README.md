![Preview](https://cdn.lookin.work/public/style/images/independent/homepage/preview_en_1x.jpg "Preview")

# Introduction
You can inspect and modify views in iOS app via Lookin, just like UI Inspector in Xcode, or another app called Reveal.

Official Website：https://lookin.work/

# Integration Guide
To use Lookin macOS app, you need to integrate LookinServer (iOS Framework of Lookin) into your iOS project.

> **Warning**
Never integrate LookinServer in Release building configuration.

## via CocoaPods:
### Swift Project
`pod 'LookinServer', :subspecs => ['Swift'], :configurations => ['Debug']`
### Objective-C Project
`pod 'LookinServer', :configurations => ['Debug']`
## via Swift Package Manager:
`https://github.com/QMUI/LookinServer/`

# Repository
LookinServer: https://github.com/QMUI/LookinServer

macOS app: https://github.com/hughkli/Lookin/

# Tips
- How to display custom information in Lookin: https://bytedance.larkoffice.com/docx/TRridRXeUoErMTxs94bcnGchnlb
- How to display more member variables in Lookin: https://bytedance.larkoffice.com/docx/CKRndHqdeoub11xSqUZcMlFhnWe
- How to turn on Swift optimization for Lookin: https://bytedance.larkoffice.com/docx/GFRLdzpeKoakeyxvwgCcZ5XdnTb
- Documentation Collection: https://bytedance.larkoffice.com/docx/Yvv1d57XQoe5l0xZ0ZRc0ILfnWb

# Acknowledgements
https://qxh1ndiez2w.feishu.cn/docx/YIFjdE4gIolp3hxn1tGckiBxnWf

---
# 简介
Lookin 可以查看与修改 iOS App 里的 UI 对象，类似于 Xcode 自带的 UI Inspector 工具，或另一款叫做 Reveal 的软件。

官网：https://lookin.work/

# 安装 LookinServer Framework
如果这是你的 iOS 项目第一次使用 Lookin，则需要先把 LookinServer 这款 iOS Framework 集成到你的 iOS 项目中。

> **Warning**
记得不要在 AppStore 模式下集成 LookinServer。

## 通过 CocoaPods：

### Swift 项目
`pod 'LookinServer', :subspecs => ['Swift'], :configurations => ['Debug']`
### Objective-C 项目
`pod 'LookinServer', :configurations => ['Debug']`

## 通过 Swift Package Manager:
`https://github.com/QMUI/LookinServer/`

# 源代码仓库

iOS 端 LookinServer：https://github.com/QMUI/LookinServer

macOS 端软件：https://github.com/hughkli/Lookin/

# 技巧
- 如何在 Lookin 中展示自定义信息: https://bytedance.larkoffice.com/docx/TRridRXeUoErMTxs94bcnGchnlb
- 如何在 Lookin 中展示更多成员变量: https://bytedance.larkoffice.com/docx/CKRndHqdeoub11xSqUZcMlFhnWe
- 如何为 Lookin 开启 Swift 优化: https://bytedance.larkoffice.com/docx/GFRLdzpeKoakeyxvwgCcZ5XdnTb
- 文档汇总：https://bytedance.larkoffice.com/docx/Yvv1d57XQoe5l0xZ0ZRc0ILfnWb

# 工作机会
如果你也是 iOS/Android 客户端开发，并且有换工作的意向，那么诚挚邀请你加入我的部门：https://bytedance.feishu.cn/docx/SAcgdoQuAouyXAxAqy8cmrT2n4b


# 新增右侧工具栏调用执行app方法

`pod 'LookinServer', :git=>'https://github.com/zhangjie579/LookinServer.git', :branch => "personal/samzj", :subspecs => ['Swift'], :configurations => ['Debug']`
`pod 'KcDebugSwift', '0.1.6', :configurations => ['Debug']`

## 注入自定义的方法执行 - demo

```objc
@interface NSObject (KcLookinFeature1)

@end

@implementation NSObject (KcLookinFeature1)

/// JSON string
/// { title: xx, methodName: 方法名, isUIViewMethod: 是否uiview的方法 }
+ (NSString *)kc_injectedCustomFeature_0 {
    
    NSArray<NSDictionary<NSString *, id> *> *list = @[
        @{
            // @Class 会被替换成当前lookin item的类名
            @"methodName": @"[NSObject kc_dump_propertyDescriptionForClass:@Class]",
            @"isUIViewMethod": @NO,
            @"title": @"dump当前class属性",
        },
        @{
            // self 会替换成当前lookin item 对象那个view、viewController
            @"methodName": @"[self kc_dump_autoLayoutHierarchy]",
            @"isUIViewMethod": @YES,
            @"title": @"自动布局",
        },
    ];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:list options:0 error:nil];
    if (data.length) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

+ (NSString *)kc_injectedCustomKeyPathMethod {
    
    NSArray<NSDictionary<NSString *, id> *> *list = @[
        @{
            @"methodName": @"[KcFindPropertyTooler searchPropertyWithValue:self keyPath: %@]",
            @"isUIViewMethod": @NO,
            @"title": @"查询属性value",
        },
    ];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:list options:0 error:nil];
    if (data.length) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

@end
```

## 当前注入方法的几个方法名
```objc
// 可以传入keyPath参数的方法
@"[NSObject kc_injectedCustomKeyPathMethod]",
@"[NSObject kc_injectedCustomKeyPathMethod_0]",
@"[NSObject kc_injectedCustomKeyPathMethod_1]",
@"[NSObject kc_injectedCustomKeyPathMethod_2]",

// 不能传入参数的方法
@"[NSObject kc_injectedCustomFeature]",
@"[NSObject kc_injectedCustomFeature_0]",
@"[NSObject kc_injectedCustomFeature_1]",
@"[NSObject kc_injectedCustomFeature_2]",
```
