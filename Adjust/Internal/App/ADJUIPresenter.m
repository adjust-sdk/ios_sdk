//
//  ADJUIPresenter.m
//  AdjustSdk
//

#import "ADJUIPresenter.h"
#import "ADJApp.h"

@implementation ADJUIPresenter

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;

    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController = [ADJApp makeRootViewController];
    [self.window makeKeyAndVisible];
}

@end
