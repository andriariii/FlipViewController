//
//  FlipViewController.m
//  FlipViewController
//
//  Created by Hesham Abd-Elmegid on 4/7/13.
//  Copyright (c) 2013 Hesham Abd-Elmegid. All rights reserved.
//

#import "FlipViewController.h"

#define kDepth 2000
#define kGravity 2
#define kSensitivity 40

@implementation FlipView

@end

@interface FlipViewController ()

@property (nonatomic, unsafe_unretained) BOOL animationEnded;
@property (nonatomic, unsafe_unretained) CGFloat sublayerCornerRadius;
@property (nonatomic, unsafe_unretained) BOOL animationLock;
@property (nonatomic, unsafe_unretained) CGFloat currentAnimationProgress;
@property (nonatomic, unsafe_unretained) FlipDirection currentDirection;
@property (nonatomic, unsafe_unretained) CGImageRef transitionImageBackup;
@property (nonatomic, strong) NSMutableArray *flipViews;

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

- (void)setAnimationProgressWithValue:(CGFloat)aValue {
    int frameCount = [self.flipViews count];
    FlipView* currentFrame = [self.flipViews lastObject];
    CALayer *targetLayer;
    FlipView* nextFrame = [self.flipViews objectAtIndex:frameCount-2];
    FlipView* previousFrame = [self.flipViews objectAtIndex:0];
    
    CGFloat rotationAfterDirection;
    
    if (aValue - self.currentAnimationProgress >= 0.0f) {
        self.currentDirection = FlipDirectionForward;
        targetLayer = [currentFrame.animationLayers lastObject];
    } else if (aValue - self.currentAnimationProgress < 0.0f) {
        self.currentDirection = FlipDirectionBackward;
        [self sortLayersForDirection:self.currentDirection step:1];
        targetLayer = [currentFrame.animationLayers objectAtIndex:0];
    }
    
    targetLayer.zPosition = 1;
    
    if (self.currentDirection == FlipDirectionForward) {
        rotationAfterDirection = - M_PI;
        targetLayer = [currentFrame.animationLayers lastObject];
    } else if (self.currentDirection == FlipDirectionBackward) {
        rotationAfterDirection = M_PI;
        targetLayer = [currentFrame.animationLayers objectAtIndex:0];
    }
    
    CGFloat adjustedAnimationProgress;
    adjustedAnimationProgress = fabs(aValue * (kSensitivity / 1000.0));
    adjustedAnimationProgress = MAX(0.0, adjustedAnimationProgress);
    adjustedAnimationProgress = MIN(10.0, adjustedAnimationProgress);
    
    CALayer *targetFrontLayer = [targetLayer.sublayers objectAtIndex:1];
    CALayer *nextLayer;
    
    if (self.currentDirection == FlipDirectionForward)
        nextLayer = [nextFrame.animationLayers objectAtIndex:0];
    else
        nextLayer = [previousFrame.animationLayers objectAtIndex:1];
    
    CALayer *targetBackLayer = [nextLayer.sublayers objectAtIndex:0];
    
    if (adjustedAnimationProgress != self.currentAnimationProgress) {
        CATransform3D aTransform = CATransform3DIdentity;
        aTransform.m34 = 1.0 / - kDepth;
        targetLayer.sublayerTransform = aTransform;
        
        if (self.transitionImageBackup == nil) {
            CGImageRef tempImageRef = (__bridge CGImageRef)targetBackLayer.contents;
            self.transitionImageBackup = (__bridge CGImageRef)targetFrontLayer.contents;
            targetFrontLayer.contents = (__bridge id)tempImageRef;
        }
        
        [self setTransformForLayer:targetLayer
                        startValue:(rotationAfterDirection/10.0 * self.currentAnimationProgress)
                          endValue:(rotationAfterDirection/10.0 * adjustedAnimationProgress)
                          duration:0.6
                       setDelegate:NO];
        
        self.currentAnimationProgress = adjustedAnimationProgress;
    }
}

- (void)setTransformForLayer:(CALayer *)layer
                  startValue:(CGFloat)startValue
                    endValue:(CGFloat)endValue
                    duration:(CGFloat)duration
                 setDelegate:(BOOL)setDelegate {
    CATransform3D aTransform = CATransform3DIdentity;
    aTransform.m34 = 1.0 / - kDepth;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.duration = duration;
    animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, startValue, 1, 0, 0)];
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, endValue, 1, 0, 0)];
    
    if (setDelegate) animation.delegate = self;
    
    animation.removedOnCompletion = NO;
    [animation setFillMode:kCAFillModeForwards];
    
    [layer addAnimation:animation forKey:@"transformAnimation"];
}

- (void)sortLayersForDirection:(FlipDirection)flipDirection step:(NSInteger)step {
    if ([self.flipViews count] > 1) {
        FlipView *currentFrame = [self.flipViews lastObject];
        FlipView *previousFrame = [self.flipViews objectAtIndex:0];
        FlipView *previousPreviousFrame = [self.flipViews objectAtIndex:1];
        FlipView *nextFrame = [self.flipViews objectAtIndex:[self.flipViews count]-2];
        
        if (flipDirection == FlipDirectionForward) {
            
            if (step == 3) {
                [currentFrame removeFromSuperlayer];
                
                [self.layer insertSublayer:currentFrame below:previousFrame];
                
                [self.flipViews removeLastObject];
                
                [self.flipViews insertObject:currentFrame atIndex:0];
            }
            
        } else if (flipDirection == FlipDirectionBackward) {
            if (step == 1) {
                if ([self.flipViews count] > 2) {
                    [previousFrame removeFromSuperlayer];
                    [self.layer insertSublayer:previousFrame above:nextFrame];
                }
            } else if (step == 2) {
                if ([self.flipViews count] > 2) {
                    [previousFrame removeFromSuperlayer];
                    [self.layer insertSublayer:previousFrame below:previousPreviousFrame];
                }
            } else if (step == 3) {
                [previousFrame removeFromSuperlayer];
                [self.layer insertSublayer:previousFrame above:currentFrame];
                [self.flipViews removeObjectAtIndex:0];
                [self.flipViews addObject:previousFrame];
            }
        }
    }
}

- (void)endAnimationWithVelocity:(CGFloat)velocity {
    if (self.currentAnimationProgress == 0.0f || self.currentAnimationProgress == 10.0f) {
        [self resetTransformValues];
    } else {
        FlipView *currentFrame = [self.flipViews lastObject];
        CALayer *targetLayer;
        CGFloat rotationAfterDirection;
        
        if (self.currentDirection == FlipDirectionForward) {
            rotationAfterDirection = - M_PI;
            targetLayer = [currentFrame.animationLayers lastObject];
        } else {
            rotationAfterDirection = M_PI;
            targetLayer = [currentFrame.animationLayers objectAtIndex:0];
        }
        
        CATransform3D aTransform = CATransform3DIdentity;
        aTransform.m34 = 1.0 / - kDepth;
        [targetLayer setValue:[NSValue valueWithCATransform3D:CATransform3DRotate(aTransform,rotationAfterDirection/10.0 * self.currentAnimationProgress, 1, 0, 0)] forKeyPath:@"transform"];
        for (CALayer *layer in targetLayer.sublayers) {
            [layer removeAllAnimations];
        }
        [targetLayer removeAllAnimations];
        
        if (self.currentAnimationProgress + velocity <= 5.0f) {
            [self setTransformForLayer:targetLayer
                            startValue:rotationAfterDirection / 10.0 * self.currentAnimationProgress
                              endValue:0.0f
                              duration:1.0f / (kGravity + velocity)
                           setDelegate:YES];
            
            self.currentAnimationProgress = 0.0f;
        } else {
            [self setTransformForLayer:targetLayer
                            startValue:rotationAfterDirection / 10.0 * self.currentAnimationProgress
                              endValue:rotationAfterDirection
                              duration:1.0f / (kGravity + velocity)
                           setDelegate:YES];
            
            self.currentAnimationProgress = 10.0f;
        }
    }
}

- (void)resetTransformValues {
    FlipView *currentFrame = [self.flipViews lastObject];
    
    CALayer *targetLayer;
    
    if (self.currentDirection == FlipDirectionForward) {
        targetLayer = [currentFrame.animationLayers lastObject];
    } else if (self.currentDirection == FlipDirectionBackward) {
        targetLayer = [currentFrame.animationLayers objectAtIndex:0];
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [targetLayer setValue:[NSValue valueWithCATransform3D:CATransform3DIdentity] forKeyPath:@"transform"];
    
    for (CALayer *layer in targetLayer.sublayers) {
        [layer removeAllAnimations];
    }
    [targetLayer removeAllAnimations];
    
    targetLayer.zPosition = 0;

    
    CATransform3D aTransform = CATransform3DIdentity;
    targetLayer.sublayerTransform = aTransform;
    
    if (self.currentAnimationProgress == 10.0f) {
        [self sortLayersForDirection:self.currentDirection step:3];
    } else {
        [self sortLayersForDirection:self.currentDirection step:2];
    }
    
    [CATransaction commit];
    
    self.animationEnded = NO;
    self.animationLock = NO;
    self.transitionImageBackup = nil;
    self.currentAnimationProgress = 0.0f;
}

#pragma mark - UIPanGestureRecognizer

- (void)didPan:(UIPanGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            if (self.animationEnded == NO) {
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                self.animationLock = YES;
            }
        }
            break;
        case UIGestureRecognizerStateChanged: {
            if (self.animationLock && self.animationEnded == NO) {
                CGFloat value = [recognizer translationInView:self].y;
                [self setAnimationProgressWithValue:value];
            }
        }
            break;
        case UIGestureRecognizerStateEnded: {
            if (self.animationLock) {
                self.animationEnded = YES;
                CGFloat value = sqrtf(fabsf([recognizer velocityInView:self].x))/10.0f;
                [self endAnimationWithVelocity:value];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CABasicAnimation *)animation finished:(BOOL)finished {
    if (finished)
        [self resetTransformValues];
}

@end
