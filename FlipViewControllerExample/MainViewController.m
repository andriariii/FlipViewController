//
//  MainViewController.m
//  FlipViewControllerExample
//
//  Created by Hesham Abd-Elmegid on 4/7/13.
//  Copyright (c) 2013 Hesham Abd-Elmegid. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@property (nonatomic, strong) FlipViewController *flipViewController;

@end

@implementation MainViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.flipViewController = [[FlipViewController alloc] initWithFrame:self.view.bounds];
    self.flipViewController = [[FlipViewController alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    self.flipViewController.delegate = self;
    [self.view addSubview:self.flipViewController];
}

#pragma mark - FlipViewControllerDelegate

- (UIImage *)imageForViewAtIndex:(NSInteger)index inFlipViewController:(FlipViewController *)flipViewController {
    switch (index) {
        case 0:
            return [UIImage imageNamed:@"1"];
            break;
        case 1:
            return [UIImage imageNamed:@"2"];
            break;
        case 2:
            return [UIImage imageNamed:@"3"];
            break;
        case 3:
            return [UIImage imageNamed:@"4"];
            break;
        
        default:
            break;
    }
    
    return nil;
}

- (NSInteger)numberOfViewsInFlipViewController:(FlipViewController *)flipViewController {
    return 4;
}

@end
