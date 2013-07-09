//
//  FlipViewController.h
//  FlipViewController
//
//  Created by Hesham Abd-Elmegid on 4/7/13.
//  Copyright (c) 2013 Hesham Abd-Elmegid. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class FlipViewController;

@protocol FlipViewControllerDelegate <NSObject>

@required
- (UIImage *)imageForViewAtIndex:(NSInteger)index inFlipViewController:(FlipViewController *)flipViewController;
- (NSInteger)numberOfViewsInFlipViewController:(FlipViewController *)flipViewController;

@end

typedef enum {
    FlipDirectionForward,
    FlipDirectionBackward,
} FlipDirection;

@interface FlipViewController : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, unsafe_unretained) id<FlipViewControllerDelegate> delegate;

- (void)reloadData;

@end

@interface FlipView : CALayer

@property (nonatomic, strong) NSArray *animationLayers;

@end