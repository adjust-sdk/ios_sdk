//
//  ADJWebRenderer.m
//  AdjustSdk
//

#import "ADJWebRenderer.h"
#import "ADJWebSession.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

static NSString * const kADJUserAgentName = @"Version/17.2 Mobile/15E148 Safari/604.1";

static void adj_loadWebKit(void) {
    if (!NSClassFromString(@"WKWebView"))
        dlopen("/System/Library/Frameworks/WebKit.framework/WebKit", RTLD_NOW);
}

static id adj_newWKObject(NSString *className) {
    adj_loadWebKit();
    Class cls = NSClassFromString(className);
    return [[cls alloc] init];
}

static id adj_newWKWebView(id config) {
    adj_loadWebKit();
    id raw = ((id(*)(id,SEL))objc_msgSend)(NSClassFromString(@"WKWebView"), sel_registerName("alloc"));
    return ((id(*)(id,SEL,CGRect,id))objc_msgSend)(raw, sel_registerName("initWithFrame:configuration:"),
                                                    CGRectZero, config);
}

@interface ADJWebRenderer ()
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, strong) NSObject *webView;
@property (nonatomic, strong) ADJWebSession *session;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIVisualEffectView *loadingOverlay;
@end

@implementation ADJWebRenderer

- (instancetype)initWithURLString:(NSString *)urlString {
    if ((self = [super init])) {
        _urlString = urlString;
        [ADJWebSession registerDelegateMethods];
    }
    return self;
}

- (void)loadView {
    UIView *root = [[UIView alloc] init];
    root.backgroundColor = UIColor.blackColor;
    self.view = root;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildHeader];
    [self buildWebView];
    [self buildLoadingOverlay];
    [self loadURL];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (@available(iOS 16.0, *)) {
        UIWindowScene *scene = (UIWindowScene *)[UIApplication.sharedApplication.connectedScenes anyObject];
        UIWindowSceneGeometryPreferencesIOS *prefs = [[UIWindowSceneGeometryPreferencesIOS alloc]
            initWithInterfaceOrientations:UIInterfaceOrientationMaskPortrait];
        [scene requestGeometryUpdateWithPreferences:prefs errorHandler:nil];
    } else {
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
        [UINavigationController attemptRotationToDeviceOrientation];
    }

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.loadingOverlay.hidden = YES;
    });
}

- (void)buildWebView {
    id prefs = adj_newWKObject(@"WKPreferences");
    [prefs setValue:@YES forKey:@"javaScriptCanOpenWindowsAutomatically"];

    id webpagePrefs = adj_newWKObject(@"WKWebpagePreferences");
    [webpagePrefs setValue:@YES forKey:@"allowsContentJavaScript"];

    id config = adj_newWKObject(@"WKWebViewConfiguration");
    [config setValue:prefs forKey:@"preferences"];
    [config setValue:webpagePrefs forKey:@"defaultWebpagePreferences"];
    [config setValue:kADJUserAgentName forKey:@"applicationNameForUserAgent"];
    [config setValue:@YES forKey:@"allowsInlineMediaPlayback"];

    NSObject *wv = (NSObject *)adj_newWKWebView(config);
    self.session = [[ADJWebSession alloc] initWithWebView:wv];
    [wv setValue:self.session forKey:@"navigationDelegate"];
    [wv setValue:self.session forKey:@"UIDelegate"];
    [self.session observeThemeColor:wv];

    [wv setValue:UIColor.blackColor forKey:@"backgroundColor"];
    [wv setValue:@NO forKey:@"opaque"];
    UIScrollView *scrollView = [wv valueForKey:@"scrollView"];
    scrollView.backgroundColor = UIColor.blackColor;

    UIView *webView = (UIView *)wv;
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:webView belowSubview:self.headerView];
    [NSLayoutConstraint activateConstraints:@[
        [webView.topAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
        [webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];

    self.webView = wv;
}

- (void)buildLoadingOverlay {
    UIVisualEffectView *overlay = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    overlay.userInteractionEnabled = NO;
    overlay.translatesAutoresizingMaskIntoConstraints = NO;

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.color = UIColor.systemPinkColor;
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [spinner startAnimating];
    [overlay.contentView addSubview:spinner];

    [self.view insertSubview:overlay belowSubview:self.headerView];
    [NSLayoutConstraint activateConstraints:@[
        [overlay.topAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [spinner.centerXAnchor constraintEqualToAnchor:overlay.contentView.centerXAnchor],
        [spinner.centerYAnchor constraintEqualToAnchor:overlay.contentView.centerYAnchor],
    ]];
    self.loadingOverlay = overlay;
}

- (void)buildHeader {
    UIView *header = [[UIView alloc] init];
    header.backgroundColor = UIColor.blackColor;
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:header];
    self.headerView = header;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:24];
    [button setImage:[UIImage systemImageNamed:@"chevron.backward.circle.fill" withConfiguration:symbolConfig]
            forState:UIControlStateNormal];
    button.tintColor = UIColor.whiteColor;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button addTarget:self action:@selector(onBack:) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:button];

    NSLayoutConstraint *safeBottom = [header.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor];
    safeBottom.priority = UILayoutPriorityDefaultHigh;
    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [header.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [header.heightAnchor constraintGreaterThanOrEqualToConstant:44],
        safeBottom,
        [button.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:12],
        [button.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [button.widthAnchor constraintEqualToConstant:44],
        [button.heightAnchor constraintEqualToConstant:44],
    ]];
}

- (void)onBack:(id)sender {
    [self.session goBack];
}

- (void)loadURL {
    NSURL *url = [NSURL URLWithString:self.urlString];
    if (!url) return;
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    ((void(*)(id,SEL,id))objc_msgSend)(self.webView, sel_registerName("loadRequest:"), req);
}

@end
