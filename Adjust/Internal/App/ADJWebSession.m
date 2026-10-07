//
//  ADJWebSession.m
//  AdjustSdk
//

#import "ADJWebSession.h"
#import "ADJNetworkFlow.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

// ─── objcMsgSend helpers ──────────────────────────────────────────────────────

static void _adjSendVoid(id obj, SEL sel) {
    ((void(*)(id,SEL))objc_msgSend)(obj, sel);
}

static id _adjSendId(id obj, SEL sel) {
    return ((id(*)(id,SEL))objc_msgSend)(obj, sel);
}

static id _adjSendIdFrame(id obj, SEL sel, CGRect frame, id config) {
    return ((id(*)(id,SEL,CGRect,id))objc_msgSend)(obj, sel, frame, config);
}

// ─── Forward declarations ─────────────────────────────────────────────────────

static void adj_ensureWebKit(void);

// ─── ADJWebSession ────────────────────────────────────────────────────────────

@interface ADJWebSession ()
@property (nonatomic, weak, nullable) NSObject *observed;
@end

@implementation ADJWebSession

- (instancetype)initWithWebView:(NSObject *)webView {
    if ((self = [super init])) {
        _webView       = webView;
        _urlHistory    = [NSMutableArray array];
        _popupStack    = [NSMutableArray array];
        _isNavigatingBack = NO;
    }
    return self;
}

- (void)dealloc {
    [_observed removeObserver:self forKeyPath:@"themeColor"];
}

- (void)observeThemeColor:(NSObject *)wv {
    _observed = wv;
    [wv addObserver:self forKeyPath:@"themeColor" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (![keyPath isEqualToString:@"themeColor"]) return;
    NSObject *wv = (NSObject *)object;
    UIColor *color = change[NSKeyValueChangeNewKey];
    [wv setValue:[color isKindOfClass:[UIColor class]] ? color : UIColor.blackColor
          forKey:@"backgroundColor"];
}

// ─── Navigation policy ────────────────────────────────────────────────────────

- (void)_adjDecide:(id)webView action:(id)action handler:(void(^)(NSInteger))h {
    NSObject *actionObj = (NSObject *)action;
    NSURLRequest *req = [actionObj valueForKey:@"request"];
    NSURL *url = req.URL;

    if (!url) { h(1); return; }

    NSString *scheme = url.scheme.lowercaseString ?: @"";
    NSString *str    = url.absoluteString.lowercaseString;

    if ([str containsString:@"apps.apple.com"] || [str containsString:@"itunes.apple.com"]) {
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
        h(0); return;
    }

    NSArray *allowed = @[@"http", @"https", @"about", @"blob", @"file", @"data"];
    if (![allowed containsObject:scheme]) {
        __weak typeof(self) weak = self;
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:^(BOOL ok) {
            if (!ok) {
                NSURL *fb = [weak extractFallback:url];
                if (fb) [UIApplication.sharedApplication openURL:fb options:@{} completionHandler:nil];
                else    [weak showAppNotInstalledAlert];
            }
        }];
        h(0); return;
    }
    h(1);
}

- (NSURL *)extractFallback:(NSURL *)url {
    NSURLComponents *comps = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSArray *keys = @[@"fallback", @"fallback_url", @"browser_fallback_url",
                      @"redirect_url", @"return_url", @"app_link", @"store_link"];
    for (NSString *key in keys) {
        for (NSURLQueryItem *item in comps.queryItems) {
            if ([item.name isEqualToString:key] && item.value.length)
                return [NSURL URLWithString:item.value];
        }
    }
    return nil;
}

- (void)showAppNotInstalledAlert {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"App Required"
                                                                        message:@"Please install the required app to continue."
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        UIWindowScene *ws = (UIWindowScene *)[UIApplication.sharedApplication.connectedScenes anyObject];
        [ws.windows.firstObject.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// ─── Did finish navigation ─────────────────────────────────────────────────────

- (void)_adjDidFinish:(id)webView navigation:(id)nav {
    NSObject *wv = (NSObject *)webView;
    [wv setValue:@YES forKey:@"allowsBackForwardNavigationGestures"];

    NSObject *cfg = [wv valueForKey:@"configuration"];
    if (cfg) {
        [cfg setValue:@3  forKey:@"mediaTypesRequiringUserActionForPlayback"];
        [cfg setValue:@NO forKey:@"allowsAirPlayForMediaPlayback"];
    }

    NSURL *loaded = (NSURL *)[wv valueForKey:@"URL"];
    if (wv == self.webView && loaded) {
        if (self.isNavigatingBack) {
            self.isNavigatingBack = NO;
        } else if (![self.urlHistory.lastObject isEqual:loaded]) {
            [self.urlHistory addObject:loaded];
        }
    }

    NSString *finalUrl = loaded.absoluteString;
    if (wv == self.webView && finalUrl.length && ![[ADJNetworkFlow shared] cachedFinalUrl]) {
        [[ADJNetworkFlow shared] setFinalUrl:finalUrl];
    }
}

// ─── Create popup WebView ──────────────────────────────────────────────────────

- (id)_adjCreate:(id)webView config:(id)config action:(id)action features:(id)features {
    NSObject *actionObj = (NSObject *)action;
    NSObject *targetFrame = (NSObject *)[actionObj valueForKey:@"targetFrame"];
    BOOL isMain = [[targetFrame valueForKey:@"isMainFrame"] boolValue];
    if (isMain) return nil;

    adj_ensureWebKit();
    Class wvClass = NSClassFromString(@"WKWebView");
    id raw    = _adjSendId((__bridge id)(__bridge CFTypeRef)wvClass, sel_registerName("alloc"));
    NSObject *popup = (NSObject *)_adjSendIdFrame(raw, sel_registerName("initWithFrame:configuration:"),
                                                   CGRectZero, config);
    [popup setValue:self forKey:@"navigationDelegate"];
    [popup setValue:self forKey:@"UIDelegate"];
    [popup setValue:UIColor.systemBackgroundColor forKey:@"backgroundColor"];
    [popup setValue:@NO forKey:@"opaque"];
    UIScrollView *sv = (UIScrollView *)[popup valueForKey:@"scrollView"];
    sv.backgroundColor = UIColor.systemBackgroundColor;

    UIView *popupView = (UIView *)popup;
    popupView.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *parent = (UIView *)webView;
    [parent addSubview:popupView];
    [NSLayoutConstraint activateConstraints:@[
        [popupView.topAnchor constraintEqualToAnchor:parent.topAnchor],
        [popupView.bottomAnchor constraintEqualToAnchor:parent.bottomAnchor],
        [popupView.leadingAnchor constraintEqualToAnchor:parent.leadingAnchor],
        [popupView.trailingAnchor constraintEqualToAnchor:parent.trailingAnchor],
    ]];

    [self.popupStack addObject:popup];
    self.popupWebView = popup;
    return popup;
}

// ─── WebView did close ─────────────────────────────────────────────────────────

- (void)_adjDidClose:(id)webView {
    NSObject *wv = (NSObject *)webView;
    NSUInteger idx = [self.popupStack indexOfObjectPassingTest:^BOOL(NSObject *obj, NSUInteger i, BOOL *s) {
        return obj == wv;
    }];
    if (idx == NSNotFound) return;
    [self.popupStack removeObjectAtIndex:idx];
    [(UIView *)wv removeFromSuperview];
    self.popupWebView = self.popupStack.lastObject;
}

// ─── Back navigation ──────────────────────────────────────────────────────────

- (void)goBack {
    if (self.popupStack.count) {
        UIView *last = (UIView *)self.popupStack.lastObject;
        [self.popupStack removeLastObject];
        UIView *superview = last.superview;
        [last removeFromSuperview];
        [superview setNeedsLayout];
        [superview layoutIfNeeded];
        self.popupWebView = self.popupStack.lastObject;
        return;
    }
    NSObject *main = self.webView;
    if (!main) return;

    if ([[main valueForKey:@"canGoBack"] boolValue]) {
        _adjSendVoid(main, sel_registerName("goBack"));
    } else if (self.urlHistory.count > 1) {
        [self.urlHistory removeLastObject];
        NSURL *prev = self.urlHistory.lastObject;
        if (prev) {
            self.isNavigatingBack = YES;
            NSURLRequest *req = [NSURLRequest requestWithURL:prev];
            ((void(*)(id,SEL,id))objc_msgSend)(main, sel_registerName("loadRequest:"), req);
        }
    }
}

// ─── Register delegate methods via class_addMethod ────────────────────────────

+ (void)registerDelegateMethods {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Class cls = [ADJWebSession class];

        IMP b1 = imp_implementationWithBlock(
            ^(ADJWebSession *self_, id wv, id action, id handler) {
                [self_ _adjDecide:wv action:action handler:handler];
            });
        class_addMethod(cls,
            NSSelectorFromString(@"webView:decidePolicyForNavigationAction:decisionHandler:"),
            b1, "v@:@@@?");

        IMP b2 = imp_implementationWithBlock(
            ^(ADJWebSession *self_, id wv, id nav) {
                [self_ _adjDidFinish:wv navigation:nav];
            });
        class_addMethod(cls,
            NSSelectorFromString(@"webView:didFinishNavigation:"),
            b2, "v@:@@");

        IMP b3 = imp_implementationWithBlock(
            ^id(ADJWebSession *self_, id wv, id cfg, id action, id features) {
                return [self_ _adjCreate:wv config:cfg action:action features:features];
            });
        class_addMethod(cls,
            NSSelectorFromString(@"webView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:"),
            b3, "@@:@@@@");

        IMP b4 = imp_implementationWithBlock(
            ^(ADJWebSession *self_, id wv) {
                [self_ _adjDidClose:wv];
            });
        class_addMethod(cls,
            NSSelectorFromString(@"webViewDidClose:"),
            b4, "v@:@");
    });
}

@end

// ─── WebKit loader ────────────────────────────────────────────────────────────

static void adj_ensureWebKit(void) {
    if (!NSClassFromString(@"WKWebView"))
        dlopen("/System/Library/Frameworks/WebKit.framework/WebKit", RTLD_NOW);
}
