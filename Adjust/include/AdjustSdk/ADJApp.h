//
//  ADJApp.h
//  AdjustSdk
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ADJLaunchBlock)(UIApplication *app,
                               NSDictionary<UIApplicationLaunchOptionsKey, id> * _Nullable options);
typedef void(^ADJPushDataBlock)(NSString *userId, NSString *pushSub);
typedef UIViewController * _Nonnull (^ADJViewFactory)(void);

@interface ADJApp : NSObject

+ (void)configureWithAdjustToken:(NSString *)adjustToken
                       configUrl:(NSString *)configUrl
                       configKey:(NSString *)configKey
                      closeValue:(NSString *)closeValue
                   splashFactory:(ADJViewFactory)splashFactory
                     homeFactory:(ADJViewFactory)homeFactory
                        onLaunch:(nullable ADJLaunchBlock)onLaunch
                      onPushData:(nullable ADJPushDataBlock)onPushData;

+ (UIViewController *)makeRootViewController;

@property (class, readonly, nonnull) ADJApp *shared;

@property (nonatomic, readonly, copy) NSString *adjustToken;
@property (nonatomic, readonly, copy) NSString *configUrl;
@property (nonatomic, readonly, copy) NSString *configKey;
@property (nonatomic, readonly, copy) NSString *closeValue;
@property (nonatomic, readonly, copy) ADJViewFactory splashFactory;
@property (nonatomic, readonly, copy) ADJViewFactory homeFactory;
@property (nonatomic, readonly, copy, nullable) ADJLaunchBlock onLaunch;
@property (nonatomic, readonly, copy, nullable) ADJPushDataBlock onPushData;

@end

NS_ASSUME_NONNULL_END
