//
//  FlipViewController.m
//  FlipViewController
//
//  Created by Hesham Abd-Elmegid on 4/7/13.
//  Copyright (c) 2013 Hesham Abd-Elmegid. All rights reserved.
//

#import "FlipViewController.h"

#define kDepth 1000
#define kGravity 2
#define kSensitivity 40

@interface FlipViewController ()

@property (nonatomic, unsafe_unretained) CGFloat currentAnimationProgress;
@property (nonatomic, unsafe_unretained) NSInteger currentIndex;
@property (nonatomic, strong) NSMutableArray *flipViews;
@property (nonatomic, unsafe_unretained) FlipDirection currentDirection;
@property (nonatomic, getter = isAnimating) BOOL animating;

@end

@implementation FlipView

@end

@implementation FlipViewController

#pragma mark - UIView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.flipViews = [[NSMutableArray alloc] init];
        self.currentDirection = FlipDirectionForward;
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
        panGestureRecognizer.delegate = self;
        [self addGestureRecognizer:panGestureRecognizer];
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [self reloadData];
}

#pragma mark -

- (void)reloadData {
    for (CALayer *layer in self.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
    
    [self.flipViews removeAllObjects];
    
    NSInteger numberOfViews = [self.delegate numberOfViewsInFlipViewController:self];
    
    for (int i = 0; i < numberOfViews; i++) {
        [self addFlipViewWithImage:[self.delegate imageForViewAtIndex:i inFlipViewController:self]];
    }
}

- (BOOL)addFlipViewWithImage:(UIImage *)image {
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    if (image) {
        CGRect layerRect = CGRectMake(0,
                                      0,
                                      self.frame.size.width,
                                      self.frame.size.height / 2);
        
        // Upper layer
        CALayer *upperFlipLayer = [CATransformLayer layer];
        upperFlipLayer.frame = CGRectMake(0,
                                          self.frame.size.height / 4,
                                          self.frame.size.width,
                                          self.frame.size.height / 2);
        upperFlipLayer.anchorPoint = CGPointMake(0.5, 1.0);
        
        
        CALayer *upperBackLayer = [self layerWithFrame:layerRect];
        [upperFlipLayer addSublayer:upperBackLayer];
        
        CALayer *upperFrontLayer = [self layerWithFrame:layerRect];
        upperFrontLayer.transform = CATransform3DMakeRotation(M_PI, 1.0, 0, 0);
        [upperFlipLayer addSublayer:upperFrontLayer];
        
        // Lower layer
        CALayer *lowerFlipLayer = [CATransformLayer layer];
        lowerFlipLayer.frame = CGRectMake(0,
                                          self.frame.size.height / 4,
                                          self.frame.size.width,
                                          self.frame.size.height / 2);
        lowerFlipLayer.anchorPoint = CGPointMake(0.5, 0.0);
        
        CALayer *lowerBackLayer = [self layerWithFrame:layerRect];
        [lowerFlipLayer addSublayer:lowerBackLayer];
        
        CALayer *lowerFrontLayer = [self layerWithFrame:layerRect];
        lowerFrontLayer.transform = CATransform3DMakeRotation(M_PI, 1.0, 0, 0);
        [lowerFlipLayer addSublayer:lowerFrontLayer];
        
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, 0, self.frame.size.width * scale, self.frame.size.height * scale / 2));
        
        CGImageRef imageRef2 = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, self.frame.size.height * scale / 2, self.frame.size.width * scale, self.frame.size.height * scale / 2));
        
        [upperBackLayer setContents:(__bridge id)imageRef];
        [lowerBackLayer setContents:(__bridge id)imageRef2];
        
        FlipView *flipView = [[FlipView alloc] init];
        [self.layer addSublayer:flipView];
        [flipView addSublayer:upperFlipLayer];
        [flipView addSublayer:lowerFlipLayer];
        flipView.animationLayers = @[lowerFlipLayer, upperFlipLayer];
        
        [self.flipViews addObject:flipView];
        
        self.currentIndex = self.flipViews.count - 1;
        
        return YES;
    }
    
    return NO;
}

- (CALayer *)layerWithFrame:(CGRect)aFrame {
    CALayer *layer = [CALayer layer];
    layer.frame = aFrame;
    layer.masksToBounds = YES;
    layer.doubleSided = NO;
    layer.contentsGravity = kCAGravityResizeAspect;
    
    return layer;
}

- (void)setAnimationProgressWithValue:(CGFloat)animationProgress {
    NSInteger flipViewsCount = self.flipViews.count;
    FlipView *currentFrame = [self.flipViews objectAtIndex:self.currentIndex];
    FlipView *nextFrame = [self.flipViews objectAtIndex:abs((self.currentIndex - 1)) % flipViewsCount];
    FlipView *previousFrame = [self.flipViews objectAtIndex:abs(((self.currentIndex + 1) - flipViewsCount)) % flipViewsCount];
    
    CALayer *targetLayer;
    CGFloat rotationAfterDirection;
    
    if (animationProgress - self.currentAnimationProgress >= 0.0f) {
        self.currentDirection = FlipDirectionForward;
        targetLayer = [currentFrame.animationLayers lastObject];
    } else if (animationProgress - self.currentAnimationProgress < 0.0f) {
        self.currentDirection = FlipDirectionBackward;
        
        // Reorder layers
        [previousFrame removeFromSuperlayer];
        [self.layer insertSublayer:previousFrame above:nextFrame];
        
        targetLayer = [currentFrame.animationLayers objectAtIndex:0];
    }
    
    targetLayer.zPosition = 1;
    
    if (self.currentDirection == FlipDirectionForward) {
        rotationAfterDirection = - M_PI;
        targetLayer = [currentFrame.animationLayers lastObject];
    } else {
        rotationAfterDirection = M_PI;
        targetLayer = [currentFrame.animationLayers objectAtIndex:0];
    }
    
    CGFloat adjustedAnimationProgress  = fabs(animationProgress * (kSensitivity / 1000.0));
    // Make sure the adjusted value is between 0.0 and 10.0
    adjustedAnimationProgress = MAX(0.0, adjustedAnimationProgress);
    adjustedAnimationProgress = MIN(10.0, adjustedAnimationProgress);
    
    CALayer *targetFrontLayer;
    CALayer *targetBackLayer;
    
    switch (self.currentDirection) {
        case FlipDirectionForward: {
            targetFrontLayer = [targetLayer.sublayers objectAtIndex:1];
            CALayer *nextLayer = [nextFrame.animationLayers objectAtIndex:0];
            targetBackLayer = [nextLayer.sublayers objectAtIndex:0];
        }
            break;
        case FlipDirectionBackward: {
            targetFrontLayer = [targetLayer.sublayers objectAtIndex:1]; // upper front layer
            CALayer *previousLayer = [previousFrame.animationLayers objectAtIndex:1];
            targetBackLayer = [previousLayer.sublayers objectAtIndex:0];
        }
            break;
        default:
            break;
    }
    
    [CATransaction begin];
    
    CATransform3D aTransform = CATransform3DIdentity;
    aTransform.m34 = 1.0 / - kDepth;
    [targetLayer setValue:[NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, rotationAfterDirection/10.0 * self.currentAnimationProgress, 1, 0, 0)] forKeyPath:@"transform"];
    
    [self removeAnimationsFromLayer:targetLayer];
    
    [CATransaction commit];
    
    if (adjustedAnimationProgress != self.currentAnimationProgress) {
        CATransform3D aTransform = CATransform3DIdentity;
        aTransform.m34 = 1.0 / - kDepth;
        targetLayer.sublayerTransform = aTransform;
        
        CGImageRef tempImageRef = (__bridge CGImageRef)targetBackLayer.contents;
        targetFrontLayer.contents = (__bridge id)tempImageRef;
        
        self.currentAnimationProgress = adjustedAnimationProgress;
    }
}

- (void)endAnimationWithSpeed:(CGFloat)aVelocity {
    if (self.currentAnimationProgress == 0.0f || self.currentAnimationProgress == 10.0f) {
        [self resetTransformValues];
    } else {
        FlipView* currentFrame = [self.flipViews lastObject];
        CALayer *targetLayer;
        
        CGFloat rotationAfterDirection;
        
        if (self.currentDirection == FlipDirectionForward) {
            rotationAfterDirection = - M_PI;
            targetLayer = [currentFrame.animationLayers lastObject];
        } else {
            rotationAfterDirection = M_PI;
            targetLayer = [currentFrame.animationLayers objectAtIndex:0];
        }
        
        [self removeAnimationsFromLayer:targetLayer];
        self.animating = YES;
        
        CATransform3D aTransform = CATransform3DIdentity;
        aTransform.m34 = 1.0 / - kDepth;
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
        animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, rotationAfterDirection / 10.0 * self.currentAnimationProgress, 1, 0, 0)];
        animation.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, rotationAfterDirection, 1, 0, 0)];
        animation.removedOnCompletion = YES;
        animation.delegate = self;
        [animation setFillMode:kCAFillModeForwards];
        
        [targetLayer addAnimation:animation forKey:@"transformAnimation"];
        
        self.currentAnimationProgress = 10.0f;
    }
}

- (void)resetTransformValues {
    NSInteger flipViewsCount = self.flipViews.count;
    
    FlipView *currentFrame = [self.flipViews objectAtIndex:flipViewsCount - 1];
//    FlipView *currentFrame = [self.flipViews lastObject];
    FlipView *previousFrame = [self.flipViews objectAtIndex:0];
    
    CALayer *targetLayer;
    
    if (self.currentDirection == FlipDirectionForward) {
        targetLayer = [currentFrame.animationLayers lastObject];
    } else if (self.currentDirection == FlipDirectionBackward) {
        targetLayer = [currentFrame.animationLayers objectAtIndex:0];
    }
    
    [CATransaction begin];
    
    [targetLayer setValue:[NSValue valueWithCATransform3D:CATransform3DIdentity] forKeyPath:@"transform"];
    
    [self removeAnimationsFromLayer:targetLayer];
    
    targetLayer.zPosition = 0;
    targetLayer.sublayerTransform = CATransform3DIdentity;
    
    if (self.currentDirection == FlipDirectionForward) {
        [currentFrame removeFromSuperlayer];
        [self.layer insertSublayer:currentFrame below:previousFrame];
        [self.flipViews removeLastObject];
        [self.flipViews insertObject:currentFrame atIndex:0];
    } else if (self.currentDirection == FlipDirectionBackward) {
        [previousFrame removeFromSuperlayer];
        [self.layer insertSublayer:previousFrame above:currentFrame];
        [self.flipViews removeObjectAtIndex:0];
        [self.flipViews addObject:previousFrame];
    }
    
    [CATransaction commit];
    
    self.animating = NO;
    self.currentAnimationProgress = 0.0f;
}

- (void)removeAnimationsFromLayer:(CALayer *)layer {
    for (CALayer *sublayer in layer.sublayers) {
        [sublayer removeAllAnimations];
    }
    
    [layer removeAllAnimations];
}

#pragma mark - UIPanGestureRecognizer

- (void)didPan:(UIPanGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            self.animating = YES;
        }
            break;
        case UIGestureRecognizerStateChanged: {
            if (self.isAnimating) {
                CGPoint translationValue = [recognizer translationInView:self];
                [self setAnimationProgressWithValue:translationValue.y];
            }
        }
            break;
        case UIGestureRecognizerStateEnded: {
            if (self.isAnimating) {
                CGFloat speed = sqrtf(fabsf([recognizer velocityInView:self].x)) / 10.0f;
                [self endAnimationWithSpeed:speed];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CABasicAnimation *)theAnimation finished:(BOOL)finished {
    if (finished && self.animating) {
        [self resetTransformValues];
    }
}

@end
