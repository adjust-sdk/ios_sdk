//
//  ADJApp.m
//  AdjustSdk
//

#import "ADJApp.h"
#import "ADJDisplayHandler.h"
#import <AdjustSdk/Adjust.h>
#import <AdjustSdk/ADJConfig.h>
#import <AdjustSdk/ADJLogger.h>

@interface ADJApp ()
@property (nonatomic, copy) NSString *adjustToken;
@property (nonatomic, copy) NSString *configUrl;
@property (nonatomic, copy) NSString *configKey;
@property (nonatomic, copy) NSString *configKeyValue;
@property (nonatomic, copy) ADJViewFactory splashFactory;
@property (nonatomic, copy) ADJViewFactory homeFactory;
@property (nonatomic, copy, nullable) ADJLaunchBlock onLaunch;
@property (nonatomic, copy, nullable) ADJPushDataBlock onPushData;
@end

@implementation ADJApp

static ADJApp *_shared = nil;

+ (ADJApp *)shared {
    return _shared;
}

+ (void)configureWithAdjustToken:(NSString *)adjustToken
                       configUrl:(NSString *)configUrl
                       configKey:(NSString *)configKey
                      configKeyValue:(NSString *)configKeyValue
                   splashFactory:(ADJViewFactory)splashFactory
                     homeFactory:(ADJViewFactory)homeFactory
                        onLaunch:(nullable ADJLaunchBlock)onLaunch
                      onPushData:(nullable ADJPushDataBlock)onPushData {
    ADJApp *instance = [[ADJApp alloc] init];
    instance.adjustToken  = adjustToken;
    instance.configUrl    = configUrl;
    instance.configKey    = configKey;
    instance.configKeyValue = configKeyValue;
    instance.splashFactory = splashFactory;
    instance.homeFactory   = homeFactory;
    instance.onLaunch      = onLaunch;
    instance.onPushData    = onPushData;
    _shared = instance;

    if (onLaunch) {
        onLaunch(UIApplication.sharedApplication, nil);
    }

    ADJConfig *config = [[ADJConfig alloc] initWithAppToken:adjustToken
                                                environment:ADJEnvironmentProduction];
    if (config) {
        config.logLevel = ADJLogLevelVerbose;
        config.attConsentWaitingInterval = 20;
        [Adjust initSdk:config];
    }
}

+ (UIViewController *)makeRootViewController {
    return [ADJDisplayHandler new];
}

@end
