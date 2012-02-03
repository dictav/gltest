//
//  SAAppDelegate.h
//  glgltest
//
//  Created by 阿部 慎太郎 on 12/01/01.
//  Copyright (c) 2012年 dictav. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EAGLViewController;
@interface SAAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) EAGLViewController *viewController;
@end
