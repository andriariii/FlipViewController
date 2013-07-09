//
//  AppDelegate.m
//  FlipViewControllerExample
//
//  Created by Hesham Abd-Elmegid on 9/7/13.
//  Copyright (c) 2013 Hesham Abd-Elmegid. All rights reserved.
//

#import "AppDelegate.h"

#import "MainViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    MainViewController *mainViewController = [[MainViewController alloc] init];
    self.window.rootViewController = mainViewController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

@end
