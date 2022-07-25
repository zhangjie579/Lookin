//
//  KcDoubleSlide.m
//  LookinClient
//
//  Created by 张杰 on 2022/5/1.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import "KcDoubleSlide.h"

@interface KcDoubleSlide ()

/// 总滑块的layer
@property (nonatomic) CALayer *totalSlideLayer;
/// 选中的view
@property (nonatomic) NSView *selectedView;
/// 左边滑块
@property (nonatomic) NSView *leftSlideView;
/// 右边滑块
@property (nonatomic) NSView *rightSlideView;

/// 滑块的总长度份数
@property (nonatomic) double totalLength;
@property (nonatomic) double leftValue;
@property (nonatomic) double rightValue;

/// 每一份的width
@property (nonatomic) CGFloat widthPer;

/// 是否滑动左边的
@property (nonatomic) BOOL isSlideLeft;
/// 是否滑动右边的
@property (nonatomic) BOOL isSlideRight;

/// 上一次拖拽的位置x, 用于计算相对滑动
@property (nonatomic) CGFloat preDragLocationX;

@property (nonatomic) CGFloat preLeftDragLocationX;
@property (nonatomic) CGFloat preRightDragLocationX;

@end

@implementation KcDoubleSlide

#pragma mark - lifeCycle

- (nullable instancetype)initWithFrame:(NSRect)frameRect leftValue:(double)leftValue rightValue:(double)rightValue totalLength:(double)totalLength {
    // 不能超过totalLength
    if ((rightValue - leftValue) > totalLength) {
        return nil;
    }
    
    if (self = [super initWithFrame:frameRect]) {
        self.totalLength = totalLength;
        self.leftValue = leftValue;
        self.rightValue = rightValue;
        self.widthPer = 0;
        
        [self setup];
    }
    return self;
}

- (void)setup {
    self.wantsLayer = true;
    
    [self.layer addSublayer:self.totalSlideLayer];
    [self addSubview:self.selectedView];
    [self addSubview:self.leftSlideView];
    [self addSubview:self.rightSlideView];
}

#pragma mark - public

/// 重置
- (void)reset {
    self.leftValue = 0;
    self.rightValue = self.totalLength;
    
    [self setNeedsLayout:true];
}

#pragma mark - event

// 返回YES的话，View会接收mouseDown消息。
- (BOOL)acceptsFirstMouse:(NSEvent *)event{
    return YES;
}

//鼠标按下时，执行此方法。
- (void)mouseDown:(NSEvent *)event {
    NSPoint clickedLocationPoint = [event locationInWindow];
    NSPoint localPoint = [self convertPoint:clickedLocationPoint fromView:nil];

    self.preDragLocationX = localPoint.x;

    if (NSPointInRect(localPoint, self.leftSlideView.frame)) {
        self.isSlideLeft = true;
        self.isSlideRight = false;
    } else if (NSPointInRect(localPoint, self.rightSlideView.frame)) {
        self.isSlideRight = true;
        self.isSlideLeft = false;
    }
}

//鼠标松开时，执行此方法。
- (void)mouseUp:(NSEvent *)event {
    self.isSlideLeft = false;
    self.isSlideRight = false;
}

/// 鼠标拖拽时执行此方法。
- (void)mouseDragged:(NSEvent *)event {
    NSPoint clickLocationPoint = event.locationInWindow;
    NSPoint localPoint = [self convertPoint:clickLocationPoint fromView:nil];

    CGFloat changeX = self.preDragLocationX - localPoint.x;
    self.preDragLocationX = localPoint.x;

    // 因为滑块有size, 当点击滑块中心位置时, 右边滑块往左边滑动, 滑块中心x > 右边滑块minX, so就会先往右边抖动下再到左边⚠️
    if (self.isSlideLeft) {
        [self leftSlideChange:-changeX];
    } else if (self.isSlideRight) {
        [self rightSlideChange:-changeX];
    }
}

//- (void)panLeftSlideWithGesture:(NSPanGestureRecognizer *)panGestureRecognizer {
//    CGFloat translationX = [panGestureRecognizer translationInView:self.leftSlideView].x;
//    [panGestureRecognizer setTranslation:NSZeroPoint inView:self.leftSlideView];
//
//    switch (panGestureRecognizer.state) {
//        case NSGestureRecognizerStateBegan:
//            self.preLeftDragLocationX = translationX;
//            break;
//        default: {
//            [self leftSlideChange:translationX - self.preLeftDragLocationX];
//            translationX = self.preLeftDragLocationX;
//        }
//            break;
//    }
//}
//
//- (void)panRightSlideWithGesture:(NSPanGestureRecognizer *)panGestureRecognizer {
//    CGFloat translationX = [panGestureRecognizer translationInView:self.rightSlideView].x;
//    [panGestureRecognizer setTranslation:NSZeroPoint inView:self.rightSlideView];
//
//    switch (panGestureRecognizer.state) {
//        case NSGestureRecognizerStateBegan:
//            self.preRightDragLocationX = translationX;
//            break;
//        default: {
//            [self rightSlideChange:translationX - self.preRightDragLocationX];
//            translationX = self.preRightDragLocationX;
//        }
//            break;
//    }
//}

- (void)leftSlideChange:(CGFloat)changeX {
    CGFloat leftSlideToX = CGRectGetMinX(self.leftSlideView.frame) + changeX;

    if (leftSlideToX <= 0) { // 不能 < 0
        self.leftValue = 0;
        [self setNeedsLayout:true];
        return;
    }

    CGFloat leftSlideMaxX = CGRectGetMinX(self.rightSlideView.frame) - self.class.sliderKnobWidth;

    if (leftSlideToX >= leftSlideMaxX) { // 不能超过右边滑块
        self.leftValue = self.rightValue;
        [self setNeedsLayout:true];
//        [self updateLeftSlideLayout:leftSlideMaxX];
    } else {
        self.leftValue = leftSlideToX / self.widthPer;
        [self setNeedsLayout:true];
//        [self updateLeftSlideLayout:leftSlideToX];
    }
}

- (void)rightSlideChange:(CGFloat)changeX {
    CGFloat rightSlideToX = CGRectGetMinX(self.rightSlideView.frame) + changeX;

    if (rightSlideToX >= CGRectGetWidth(self.frame) - self.class.sliderKnobWidth) { // 最右边了不能滑过了
        self.rightValue = self.totalLength;
        [self setNeedsLayout:true];
//        [self updateRightSlideLayout:CGRectGetWidth(self.frame) - self.class.sliderKnobWidth];
        return;
    }

    CGFloat rightSlideMinX = CGRectGetMaxX(self.leftSlideView.frame);

    if (rightSlideToX <= rightSlideMinX) { // 不能 < 左边的slide
        self.rightValue = self.leftValue;
        [self setNeedsLayout:true];
//        [self updateRightSlideLayout:rightSlideMinX];
    } else {
        self.rightValue = (rightSlideToX - self.class.sliderKnobWidth) / self.widthPer;
        [self setNeedsLayout:true];
//        [self updateRightSlideLayout:rightSlideToX];
    }
}

#pragma mark - 当2个滑块中间没空隙时, 还可以继续滑

//- (void)leftSlideChange:(CGFloat)changeX {
//    CGFloat leftSlideToX = CGRectGetMinX(self.leftSlideView.frame) - changeX;
//
//    if (leftSlideToX <= 0) { // 不能 < 0
//        self.minValue = 0;
//        [self setNeedsLayout:true];
//        return;
//    } else if (leftSlideToX >= CGRectGetWidth(self.frame) - 2 * self.class.sliderKnobWidth) { // 不能 > width - 2个滑块宽
//        self.minValue = self.totalLength;
//        self.maxValue = self.maxValue;
//        [self setNeedsLayout:true];
//        return;
//    }
//
//    CGFloat leftSlideMaxX = CGRectGetMinX(self.rightSlideView.frame) - self.class.sliderKnobWidth;
//
//    self.minValue = leftSlideToX / self.widthPer;
//    if (leftSlideToX >= leftSlideMaxX) { // 不能超过右边滑块
//        self.maxValue = self.minValue;
//    }
//
//    [self setNeedsLayout:true];
//}
//
//- (void)rightSlideChange:(CGFloat)changeX {
//    CGFloat rightSlideToX = CGRectGetMinX(self.rightSlideView.frame) - changeX;
//
//    if (rightSlideToX <= 2 * self.class.sliderKnobWidth) { // 最左边了
//        self.maxValue = 0;
//        self.minValue = 0;
//        [self setNeedsLayout:true];
//        return;
//    } else if (rightSlideToX >= CGRectGetWidth(self.frame) - self.class.sliderKnobWidth) { // 最右边了不能滑过了
//        self.maxValue = self.totalLength;
//        [self setNeedsLayout:true];
//        return;
//    }
//
//    CGFloat rightSlideMinX = CGRectGetMaxX(self.leftSlideView.frame);
//    self.maxValue = (rightSlideToX - self.class.sliderKnobWidth) / self.widthPer;
//
//    if (rightSlideToX <= rightSlideMinX) { // 不能 < 左边的slide
//        self.minValue = self.maxValue;
//    }
//
//    [self setNeedsLayout:true];
//}

//- (void)updateLeftSlideLayout:(CGFloat)x {
//    CGRect leftFrame = self.leftSlideView.frame;
//    leftFrame.origin.x = x;
//    self.leftSlideView.frame = leftFrame;
//
//    CGRect selectFrame = self.selectedView.frame;
//    selectFrame.origin.x = CGRectGetMaxX(self.leftSlideView.frame);
//    selectFrame.size.width = CGRectGetMinX(self.rightSlideView.frame) - CGRectGetMaxX(self.leftSlideView.frame);
//    self.selectedView.frame = selectFrame;
//}
//
//- (void)updateRightSlideLayout:(CGFloat)x {
//    CGRect rightFrame = self.rightSlideView.frame;
//    rightFrame.origin.x = x;
//    self.rightSlideView.frame = rightFrame;
//
//    CGRect selectFrame = self.selectedView.frame;
////    selectFrame.origin.x = CGRectGetMaxX(self.leftSlideView.frame);
//    selectFrame.size.width = CGRectGetMinX(self.rightSlideView.frame) - CGRectGetMaxX(self.leftSlideView.frame);
//    self.selectedView.frame = selectFrame;
//}

- (void)layout {
    [super layout];
    
    CGFloat slideHeight = 4;
    CGFloat sliderKnobWidth = self.class.sliderKnobWidth;
    CGFloat sliderKnobHeight = 20;
    
    CGFloat width = self.frame.size.width - 2 * sliderKnobWidth;
    CGFloat height = self.frame.size.height;
    
    // 每一份的width
    CGFloat widthPer = self.widthPer <= 0 ? width / self.totalLength : self.widthPer;
    if (self.widthPer <= 0) {
        self.widthPer = widthPer;
    }
    
    self.totalSlideLayer.frame = CGRectMake(0, (height - slideHeight) / 2, CGRectGetWidth(self.frame), slideHeight);
    
    self.leftSlideView.frame = NSMakeRect(widthPer * self.leftValue,
                                          (height - sliderKnobHeight) / 2,
                                          sliderKnobWidth,
                                          sliderKnobHeight);
    
    CGFloat selectedViewWidth = (self.rightValue - self.leftValue) * widthPer;
    self.selectedView.frame = NSMakeRect(CGRectGetMaxX(self.leftSlideView.frame),
                                         (height - slideHeight) / 2,
                                         selectedViewWidth,
                                         slideHeight);
    
    CGFloat rightSlideViewX = CGRectGetMaxX(self.selectedView.frame);
    if (CGRectGetMaxX(self.selectedView.frame) + sliderKnobWidth > CGRectGetWidth(self.frame)) {
        rightSlideViewX = CGRectGetWidth(self.frame) - sliderKnobWidth;
    }

    self.rightSlideView.frame = NSMakeRect(rightSlideViewX,
                                           CGRectGetMinY(self.leftSlideView.frame),
                                           sliderKnobWidth,
                                           CGRectGetHeight(self.leftSlideView.frame));
    
    if (self.updateSlideValue) {
        self.updateSlideValue(self, self.leftValue, self.rightValue);
    }
}

/// 滑块的宽度
+ (CGFloat)sliderKnobWidth {
    return 20;
}

#pragma mark - 懒加载

- (NSView *)selectedView {
    if (!_selectedView) {
        _selectedView = [[NSView alloc] init];
        _selectedView.wantsLayer = true;
        _selectedView.layer.backgroundColor = [NSColor.blackColor colorWithAlphaComponent:0.5].CGColor;
    }
    return _selectedView;
}

- (CALayer *)totalSlideLayer {
    if (!_totalSlideLayer) {
        _totalSlideLayer = [[CALayer alloc] init];
        _totalSlideLayer.backgroundColor = [NSColor.blackColor colorWithAlphaComponent:0.3].CGColor;
    }
    return _totalSlideLayer;
}

- (NSView *)leftSlideView {
    if (!_leftSlideView) {
        _leftSlideView = [[NSView alloc] init];
        _leftSlideView.wantsLayer = true;
        _leftSlideView.layer.backgroundColor = NSColor.whiteColor.CGColor;
        _leftSlideView.layer.borderColor = NSColor.lightGrayColor.CGColor;
        _leftSlideView.layer.borderWidth = 1;
        _leftSlideView.layer.cornerRadius = 10;
//        [_leftSlideView addGestureRecognizer:[[NSPanGestureRecognizer alloc] initWithTarget:self action:@selector(panLeftSlideWithGesture:)]];
    }
    return _leftSlideView;
}

- (NSView *)rightSlideView {
    if (!_rightSlideView) {
        _rightSlideView = [[NSView alloc] init];
        _rightSlideView.wantsLayer = true;
        _rightSlideView.layer.backgroundColor = NSColor.whiteColor.CGColor;
        _rightSlideView.layer.borderColor = NSColor.lightGrayColor.CGColor;
        _rightSlideView.layer.borderWidth = 1;
        _rightSlideView.layer.cornerRadius = 10;
//        [_rightSlideView addGestureRecognizer:[[NSPanGestureRecognizer alloc] initWithTarget:self action:@selector(panRightSlideWithGesture:)]];
    }
    return _rightSlideView;
}

@end
