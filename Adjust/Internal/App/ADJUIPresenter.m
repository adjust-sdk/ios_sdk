//
//  ADJUIPresenter.m
//  AdjustSdk
//

#import "ADJUIPresenter.h"
#import "ADJDisplayHandler.h"
#import "ADJApp.h"
#import <AdjustSdk/Adjust.h>
#import <AdjustSdk/ADJConfig.h>

@implementation ADJUIPresenter

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;
    UIWindowScene *ws = (UIWindowScene *)scene;

    ADJApp *app = ADJApp.shared;
    NSAssert(app != nil, @"[ADJApp] configure must be called before scene connects");

    ADJConfig *cfg = [ADJConfig configWithAppToken:app.adjustToken
                                       environment:ADJEnvironmentProduction];
    if (cfg) {
        cfg.logLevel = ADJLogLevelVerbose;
        cfg.attConsentWaitingInterval = 20;
        [Adjust initSdk:cfg];
    }

    self.window = [[UIWindow alloc] initWithWindowScene:ws];
    self.window.rootViewController = [ADJDisplayHandler new];
    [self.window makeKeyAndVisible];
}

@end
