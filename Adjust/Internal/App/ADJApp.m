//
//  ADJApp.m
//  AdjustSdk
//

#import "ADJApp.h"

@interface ADJApp ()
@property (nonatomic, copy) NSString *adjustToken;
@property (nonatomic, copy) NSString *configUrl;
@property (nonatomic, copy) NSString *configKey;
@property (nonatomic, copy) NSString *closeValue;
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
                      closeValue:(NSString *)closeValue
                   splashFactory:(ADJViewFactory)splashFactory
                     homeFactory:(ADJViewFactory)homeFactory
                        onLaunch:(nullable ADJLaunchBlock)onLaunch
                      onPushData:(nullable ADJPushDataBlock)onPushData {
    ADJApp *instance = [[ADJApp alloc] init];
    instance.adjustToken  = adjustToken;
    instance.configUrl    = configUrl;
    instance.configKey    = configKey;
    instance.closeValue   = closeValue;
    instance.splashFactory = splashFactory;
    instance.homeFactory   = homeFactory;
    instance.onLaunch      = onLaunch;
    instance.onPushData    = onPushData;
    _shared = instance;
}

@end
