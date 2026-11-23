//
//  LKPreviewView.m
//  Lookin
//
//  Created by Li Kai on 2019/8/17.
//  https://lookin.work
//
//  该类的代码实现，借鉴甚至直接复制了很多 https://github.com/TalkingData/YourView 项目的 SceneKit 相关代码
//  Lookin 项目鸣谢：https://qxh1ndiez2w.feishu.cn/docx/YIFjdE4gIolp3hxn1tGckiBxnWf

#import "LKPreviewView.h"
#import "LKDisplayItemNode.h"
#import "LookinDisplayItem.h"
#import "LookinDisplayItem+LookinClient.h"
#import "LKHierarchyDataSource.h"
#import "LKPreferenceManager.h"

const CGFloat LookinPreviewMinScale = 0;
const CGFloat LookinPreviewMaxScale = 1;

const CGFloat LookinPreviewMinZInterspace = 0;
const CGFloat LookinPreviewMaxZInterspace = 1;

@interface LKPreviewView ()

@property(nonatomic, strong) LKHierarchyDataSource *dataSource;

@property(nonatomic, strong) SCNNode *stageNode;

@property (nonatomic,strong) SCNNode *cameraNode;

@property(nonatomic, strong) SCNNode *rightLightNode;
@property(nonatomic, strong) SCNNode *leftLightNode;

@property(nonatomic, copy) NSArray<LookinDisplayItem *> *flatDisplayItems;
@property(nonatomic, strong) NSMutableArray<LKDisplayItemNode *> *displayItemNodes;

/// 当前 preview 里被判定为「不响应交互 + 透明 + 铺满全屏」的图层。
/// 只在渲染、屏幕尺寸或 frame 变化时重算，避免每次 hover 都重复做几何计算。
@property(nonatomic, strong) NSSet<LookinDisplayItem *> *passiveFullScreenLayers;

@end

@implementation LKPreviewView

- (instancetype)initWithDataSource:(LKHierarchyDataSource *)dataSource {
    if (self = [super initWithFrame:CGRectZero options:nil]) {
        self.dataSource = dataSource;
        self.displayItemNodes = [NSMutableArray array];
        
        self.allowsCameraControl = NO;
        self.showsStatistics = NO;
    
        self.scene = [SCNScene new];
        
        self.stageNode = [SCNNode node];
        self.stageNode.name = @"stage";
        [self.scene.rootNode addChildNode:self.stageNode];
        
        self.cameraNode = [SCNNode node];
        self.cameraNode.name = @"camera";
        self.cameraNode.camera = [SCNCamera camera];
        self.cameraNode.camera.automaticallyAdjustsZRange = YES;
        /// 这里的 position.z 决定了畸变的程度，即“近大远小”的程度
        self.cameraNode.position = SCNVector3Make(0, 0, 34);
        [self.scene.rootNode addChildNode:self.cameraNode];
        
        SCNLight *rightLight = [SCNLight light];
        rightLight.type = SCNLightTypeOmni;
        rightLight.categoryBitMask = LookinPreviewBitMask_HasLight;
        self.rightLightNode = [SCNNode node];
        self.rightLightNode.name = @"right light";
        self.rightLightNode.light = rightLight;
        [self.scene.rootNode addChildNode:self.rightLightNode];
        
        SCNLight *leftLight = [SCNLight light];
        leftLight.type = SCNLightTypeSpot;
        leftLight.categoryBitMask = LookinPreviewBitMask_HasLight;
        self.leftLightNode = [SCNNode node];
        self.leftLightNode.name = @"left light";
        self.leftLightNode.light = rightLight;
        [self.scene.rootNode addChildNode:self.leftLightNode];
    }
    return self;
}

- (void)setAppScreenSize:(CGSize)appScreenSize {
    if (CGSizeEqualToSize(_appScreenSize, appScreenSize)) {
        return;
    }
    _appScreenSize = appScreenSize;
    
    SCNVector3 rightPos = self.rightLightNode.position;
    rightPos.x = appScreenSize.width * 0.01 * 0.5 + 2;
    rightPos.y = appScreenSize.height * 0.01 * 0.5 + 2;
    self.rightLightNode.position = rightPos;
    
    SCNVector3 leftPos = self.leftLightNode.position;
    leftPos.x = -appScreenSize.width * 0.01 * 0.5 - 2;
    leftPos.y = -appScreenSize.height * 0.01 * 0.5 - 2;
    self.leftLightNode.position = leftPos;

    [self.displayItemNodes enumerateObjectsUsingBlock:^(LKDisplayItemNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.screenSize = appScreenSize;
    }];

    [self _updatePassiveFullScreenLayers];
}

- (void)renderWithDisplayItems:(NSArray<LookinDisplayItem *> *)items discardCache:(BOOL)discardCache {
    NSLog(@"LKPreviewView - render %@ items", @(items.count));
    
    self.flatDisplayItems = items;
    
    NSMutableArray<LKDisplayItemNode *> *nodesToBeDiscarded = nil;
    if (discardCache) {
        nodesToBeDiscarded = [NSMutableArray array];
    }
    
    [self.displayItemNodes lookin_dequeueWithCount:items.count add:^LKDisplayItemNode *(NSUInteger idx) {
        LKDisplayItemNode *newNode = [[LKDisplayItemNode alloc] initWithDataSource:self.dataSource];
        newNode.screenSize = self.appScreenSize;
        newNode.preferenceManager = self.preferenceManager;
        newNode.isDarkMode = self.isDarkMode;
        [self.stageNode addChildNode:newNode];
        return newNode;
        
    } notDequeued:^(NSUInteger idx, LKDisplayItemNode *node) {
        [node removeFromParentNode];
        if (discardCache) {
            [nodesToBeDiscarded addObject:node];
        }
        
    } doNext:^(NSUInteger idx, LKDisplayItemNode *node) {
        if (!node.parentNode) {
            [self.stageNode addChildNode:node];
        }

        LookinDisplayItem *displayItem = items[idx];
        displayItem.previewNode = node;
        node.index = idx;
        node.displayItem = displayItem;
    }];
    
    if (nodesToBeDiscarded.count) {
        [self.displayItemNodes removeObjectsInArray:nodesToBeDiscarded];
    }
    
    [self updateZPosition];
}

/**
 重新计算每个 item 的 zIndex，并依 zIndex 设置对应的图层在 z 轴上的 translation。同时根据 fold 等属性来显示或隐藏图层。
 */
- (void)updateZPosition {
    // frame / 展开状态变化都会走到这里，顺带刷新被动图层集合
    [self _updatePassiveFullScreenLayers];

    [self.flatDisplayItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self _updateZIndexForItem:obj];
    }];
    
    [self _updateZPositionByZIndex];
}

- (void)_updatePassiveFullScreenLayers {
    NSMutableSet<LookinDisplayItem *> *result = [NSMutableSet set];
    [self.flatDisplayItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([item isPassiveFullScreenLayerWithScreenSize:self.appScreenSize]) {
            [result addObject:item];
        }
    }];
    self.passiveFullScreenLayers = result.copy;
}

- (void)_updateZPositionByZIndex {
    CGFloat interspace;
    if (self.dimension == LookinPreviewDimension2D) {
        interspace = 0.01;
    } else {
        interspace = 0.1 + self.zInterspace * 0.7;
    }
    
    // key 是 zIndex，value 是该 zIndex 下有多少 item，作用是避免下文提到的 offsetToAvoidOverlapBug
    NSMutableDictionary<NSNumber *, NSNumber *> *zIndexAndCountDict = [NSMutableDictionary dictionary];
    
    __block NSUInteger maxZIndex = 0;
    [self.displayItemNodes enumerateObjectsUsingBlock:^(LKDisplayItemNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
        maxZIndex = MAX(maxZIndex, node.displayItem.previewZIndex);
    }];
    NSUInteger zIndexOffset = round(maxZIndex * 0.5);
    
    // 没这个 SCNTransaction 的话，收起、展开时图像没动画
    [SCNTransaction begin];
    
    [self.displayItemNodes enumerateObjectsUsingBlock:^(LKDisplayItemNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
        LookinDisplayItem *item = node.displayItem;
        // 将 "1, 2, 3, 4, 5 ..." 这样的 zIndex 排序调整为 “-2，-1，0，1，2 ...”，这样旋转时 Y 轴就会位于 zIndex 为中间值的那个 layer 的位置
        NSInteger adjustedZIndex = item.previewZIndex - zIndexOffset;
        
        NSUInteger countOfCurrentZIndex = [[zIndexAndCountDict objectForKey:@(adjustedZIndex)] unsignedIntegerValue];
        [zIndexAndCountDict setObject:@(countOfCurrentZIndex + 1) forKey:@(adjustedZIndex)];
        
        /// 当 zIndex 相同时，把更靠近用户的那个 layer 的 zIndex 增大一丁点，从而避免重叠
        CGFloat offsetToAvoidOverlapBug = countOfCurrentZIndex * 0.0001;
        
        SCNVector3 position = node.position;
        position.z = adjustedZIndex * interspace + offsetToAvoidOverlapBug;
        
        node.position = position;
    }];
    
    // 切记：要把 SCNTransaction commit 放到 for 循环外面，不能放到 for 循环里面。否则短时间内大量细碎的 SCNTransaction 会导致渲染很慢
    [SCNTransaction commit];
//    NSLog(@"SCNTransaction commit");
}

- (void)_updateZIndexForItem:(LookinDisplayItem *)item {
    item.previewZIndex = -1;
    if (item.displayingInHierarchy) {
        LookinDisplayItem *referenceItem = [self _maxZIndexForOverlappedItemUnderItem:item];
        if (referenceItem) {
            // 如果 item 和另一个 itemA 重叠了，则 item.previewZIndex 应该比 itemA.previewZIndex 高一级
            item.previewZIndex = referenceItem.previewZIndex + 1;
        } else {
            item.previewZIndex = 0;
        }
        
    } else {
        if (item.superItem) {
            item.previewZIndex = item.superItem.previewZIndex;
        } else {
            NSAssert(NO, @"");
        }
    }
    
    if (item.previewZIndex < 0) {
        NSAssert(NO, @"");
        item.previewZIndex = 0;
    }
}

/**
 传入 itemA，返回另一个 itemB，itemB 满足以下条件：
 - itemB 在 preview 中可见
 - itemB 的层级比 itemA 要低（即 itemB 在 flatItems 里的 index 要比 itemA 小）
 - itemB 和 itemA 的 frameToRoot 有重叠，即视觉上它们是彼此遮挡的
 - itemB 是满足以上两个条件中的所有 items 里的 zIndex 值最高的
 
 @note 如果没有找到任何符合条件的 itemB，则返回 nil
 */
- (LookinDisplayItem *)_maxZIndexForOverlappedItemUnderItem:(LookinDisplayItem *)item {
    NSUInteger itemIndex = [self.flatDisplayItems indexOfObject:item];
    if (itemIndex == 0) {
        return nil;
    }
    if (itemIndex == NSNotFound) {
        NSAssert(NO, @"");
        return nil;
    }
    CGRect itemFrameToRoot = [item calculateFrameToRoot];
    NSIndexSet *indexesBelow = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, itemIndex)];
    __block LookinDisplayItem *targetItem = nil;
    [self.flatDisplayItems enumerateObjectsAtIndexes:indexesBelow options:NSEnumerationReverse usingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj.inHiddenHierarchy || self.showHiddenItems) {
            if (CGRectIntersectsRect(itemFrameToRoot, [obj calculateFrameToRoot])) {
                if (!targetItem) {
                    targetItem = obj;
                } else {
                    if (obj.previewZIndex > targetItem.previewZIndex) {
                        targetItem = obj;
                    }
                }
            }
        }
    }];
    return targetItem;
}

- (void)didSelectItem:(LookinDisplayItem *)item {
    if (!item) {
        return;
    }
    
    LKDisplayItemNode *displayItemNode = item.previewNode;
    
    SCNVector3 rightPos = self.rightLightNode.position;
    rightPos.z = displayItemNode.position.z + 2;
    self.rightLightNode.position = rightPos;
    
    SCNVector3 leftPos = self.leftLightNode.position;
    leftPos.z = displayItemNode.position.z + 2;
    self.leftLightNode.position = leftPos;
}

/**
 返回 point 处应当被选中的图层。

 默认只取离用户最近的那个命中节点。开启「忽略不响应交互的全屏透明图层」后，改为取回所有命中结果
 （SceneKit 已经按由近到远排好序），依次跳过被动图层，把点击「穿透」到下面真正响应交互的图层上。

 如果某个位置下所有命中图层都是被动图层，则仍然返回最近的那一个，避免用户彻底无法在 preview 里选中它
 （此时也可以从左侧 hierarchy 列表选中，或者到设置里关掉该开关）。

 @note 单击、双击、右键、hover、测距都走这里，因此只需要在一处做过滤。
 */
- (LookinDisplayItem *)displayItemAtPoint:(CGPoint)point {
    // 没有需要跳过的图层时保持原来的 closest 命中方式，避免 hover 时做全量射线检测
    BOOL shouldSkipPassiveLayers = self.preferenceManager.ignorePassiveFullScreenLayers.currentBOOLValue && self.passiveFullScreenLayers.count > 0;
    NSArray<SCNHitTestResult *> *hitResults = [self hitTest:point options:@{SCNHitTestOptionCategoryBitMask:@(LookinPreviewBitMask_Selectable),
                                                                            SCNHitTestOptionSearchMode: @(shouldSkipPassiveLayers ? SCNHitTestSearchModeAll : SCNHitTestSearchModeClosest),
                                                                            SCNHitTestIgnoreHiddenNodesKey:@(NO)}];
    if (hitResults.count == 0) {
        return nil;
    }

    LookinDisplayItem *fallbackItem = nil;
    for (SCNHitTestResult *result in hitResults) {
        SCNNode *parentNode = result.node.parentNode;
        if (![parentNode isKindOfClass:[LKDisplayItemNode class]]) {
            continue;
        }
        LookinDisplayItem *item = ((LKDisplayItemNode *)parentNode).displayItem;
        if (!item) {
            continue;
        }
        if (!fallbackItem) {
            fallbackItem = item;
        }
        if (shouldSkipPassiveLayers && [self.passiveFullScreenLayers containsObject:item]) {
            continue;
        }
        return item;
    }
    // 全是被动图层时退化为原有行为，保证没有任何图层会因此变得不可选中
    return fallbackItem;
}

- (void)setRotation:(CGPoint)rotation animated:(BOOL)animated {
    [self setRotation:rotation animated:animated timingFunction:nil duration:0];
}

- (void)setRotation:(CGPoint)rotation animated:(BOOL)animated timingFunction:(CAMediaTimingFunction *)function duration:(CGFloat)duration {
    _rotation = rotation;
    
    CGPoint equivalentRotation = [self _equivalentRotationFromRotation:rotation];
    
    SCNVector3 angles = SCNVector3Make(rotation.y, rotation.x, 0);
    
    if (animated) {
        [SCNTransaction begin];
        if (duration > 0) {
            [SCNTransaction setAnimationDuration:duration];
        }
        if (function) {
            [SCNTransaction setAnimationTimingFunction:function];
        }
        [SCNTransaction setCompletionBlock:^{
            self->_rotation = equivalentRotation;
        }];
        self.stageNode.eulerAngles = angles;

        [SCNTransaction commit];
    } else {
        self.stageNode.eulerAngles = angles;
        _rotation = equivalentRotation;
    }
}

- (void)setTranslation:(CGPoint)translation {
    _translation = translation;

//    NSLog(@"Translation: %@", @(translation));
    
    SCNVector3 position = self.stageNode.position;
    position.x = translation.x;
    position.y = translation.y;
    self.stageNode.position = position;
}

- (void)setScale:(CGFloat)scale {
    _scale = scale;
    
//    NSLog(@"Scale: %@", @(scale));
    
    /**
     focalLength 越小则图像越小，focalLength 越大则图像越大
     传入的 scale 是 0 ~ 1，会把 focalLength 映射为 20 ~ 750
     */
    self.cameraNode.camera.focalLength = 20 + scale * scale * 730;
}

- (void)setZInterspace:(CGFloat)zInterspace {
    _zInterspace = MIN(MAX(zInterspace, LookinPreviewMinZInterspace), LookinPreviewMaxZInterspace);
    [self _updateZPositionByZIndex];
}

- (void)setDimension:(LookinPreviewDimension)dimension animated:(BOOL)animated {
    _dimension = dimension;
    
    if (dimension == LookinPreviewDimension3D) {
        // 3D
    } else {
        // 2D
        [self setRotation:CGPointZero animated:animated];
    }
    
    [self _updateZPositionByZIndex];
}

/// 把 rotation 转换为 -180 ～ 180 以内的角度（不包含 -180 本身），注意这里传入和传出的都是弧度制
- (CGPoint)_equivalentRotationFromRotation:(CGPoint)rotation {
    rotation.x = [self _equivalentRotationValueFromRotationValue:rotation.x];
    rotation.y = [self _equivalentRotationValueFromRotationValue:rotation.y];
    return rotation;
}

- (CGFloat)_equivalentRotationValueFromRotationValue:(CGFloat)rotation {
    while (rotation <= -M_PI) {
        rotation += M_PI * 2;
    }
    while (rotation >= M_PI) {
        rotation -= M_PI * 2;
    }
    return rotation;
}

- (void)setIsDarkMode:(BOOL)isDarkMode {
    _isDarkMode = isDarkMode;
    
    self.backgroundColor = isDarkMode ? LookinColorMake(19, 20, 21) : LookinColorMake(249, 249, 249);
    
    [self.displayItemNodes enumerateObjectsUsingBlock:^(LKDisplayItemNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.isDarkMode = isDarkMode;
    }];
}

@end
