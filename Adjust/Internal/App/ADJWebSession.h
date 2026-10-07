//
//  ADJWebSession.h
//  AdjustSdk
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADJWebSession : NSObject

@property (nonatomic, weak, nullable) NSObject *webView;
@property (nonatomic, strong) NSMutableArray<NSURL *> *urlHistory;
@property (nonatomic, strong) NSMutableArray<NSObject *> *popupStack;
@property (nonatomic, weak, nullable) NSObject *popupWebView;
@property (nonatomic, assign) BOOL isNavigatingBack;

- (instancetype)initWithWebView:(NSObject *)webView;
- (void)observeThemeColor:(NSObject *)webView;
- (void)goBack;

// Registers WKNavigationDelegate + WKUIDelegate methods via class_addMethod.
// Must be called once before the coordinator is used as a delegate.
+ (void)registerDelegateMethods;

@end

NS_ASSUME_NONNULL_END
