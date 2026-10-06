//
//  ADJWebRenderer.m
//  AdjustSdk
//

#import "ADJWebRenderer.h"
#import "ADJWebSession.h"
#import <objc/runtime.h>
#import <dlfcn.h>

// ─── Helpers ──────────────────────────────────────────────────────────────────

static void adj_loadWebKit(void) {
    if (!NSClassFromString(@"WKWebView"))
        dlopen("/System/Library/Frameworks/WebKit.framework/WebKit", RTLD_NOW);
}

static id adj_wkClass(NSString *name) {
    adj_loadWebKit();
    return NSClassFromString(name);
}

static id adj_msgId(id obj, SEL sel) {
    return ((id(*)(id,SEL))objc_msgSend)(obj, sel);
}

static id adj_msgIdFrame(id obj, SEL sel, CGRect frame, id config) {
    return ((id(*)(id,SEL,CGRect,id))objc_msgSend)(obj, sel, frame, config);
}

static id adj_msgIdBool(id obj, SEL sel, BOOL b) {
    return ((id(*)(id,SEL,BOOL))objc_msgSend)(obj, sel, b);
}

static id adj_msgIdNSString(id obj, SEL sel, NSString *s) {
    return ((id(*)(id,SEL,NSString *))objc_msgSend)(obj, sel, s);
}

// ─── ADJWebRenderer ───────────────────────────────────────────────────────────

@interface ADJWebRenderer ()
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, strong) NSObject *webView;
@property (nonatomic, strong) ADJWebSession *session;
@property (nonatomic, strong) UIView *backButton;
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
    root.backgroundColor = UIColor.systemBackgroundColor;
    self.view = root;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildWebView];
    [self buildBackButton];
    [self loadURL];
}

// ─── Build WKWebView ──────────────────────────────────────────────────────────

- (void)buildWebView {
    id wkPrefs   = adj_msgId(adj_msgId(adj_wkClass(@"WKPreferences"), sel_registerName("alloc")),
                              sel_registerName("init"));
    ((void(*)(id,SEL,BOOL))objc_msgSend)(wkPrefs, sel_registerName("setJavaScriptEnabled:"), YES);
    ((void(*)(id,SEL,BOOL))objc_msgSend)(wkPrefs, sel_registerName("setJavaScriptCanOpenWindowsAutomatically:"), YES);

    id wkCfg = adj_msgId(adj_msgId(adj_wkClass(@"WKWebViewConfiguration"), sel_registerName("alloc")),
                          sel_registerName("init"));
    ((void(*)(id,SEL,id))objc_msgSend)(wkCfg, sel_registerName("setPreferences:"), wkPrefs);

    id processPool = adj_msgId(adj_msgId(adj_wkClass(@"WKProcessPool"), sel_registerName("alloc")),
                                sel_registerName("init"));
    ((void(*)(id,SEL,id))objc_msgSend)(wkCfg, sel_registerName("setProcessPool:"), processPool);

    id raw = adj_msgId(adj_wkClass(@"WKWebView"), sel_registerName("alloc"));
    NSObject *wv = (NSObject *)adj_msgIdFrame(raw, sel_registerName("initWithFrame:configuration:"),
                                               self.view.bounds, wkCfg);

    self.session = [[ADJWebSession alloc] initWithWebView:wv];
    [wv setValue:self.session forKey:@"navigationDelegate"];
    [wv setValue:self.session forKey:@"UIDelegate"];
    [self.session observeThemeColor:wv];

    [wv setValue:UIColor.systemBackgroundColor forKey:@"backgroundColor"];
    [wv setValue:@NO forKey:@"opaque"];
    adj_msgIdBool(wv, sel_registerName("setAllowsBackForwardNavigationGestures:"), YES);

    UIScrollView *sv = (UIScrollView *)[wv valueForKey:@"scrollView"];
    sv.backgroundColor = UIColor.systemBackgroundColor;
    sv.showsHorizontalScrollIndicator = NO;

    UIView *wvView = (UIView *)wv;
    wvView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:wvView];
    [NSLayoutConstraint activateConstraints:@[
        [wvView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [wvView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [wvView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [wvView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];

    self.webView = wv;
}

// ─── Build back-navigation button ─────────────────────────────────────────────

- (void)buildBackButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    btn.tintColor = UIColor.labelColor;
    btn.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.18];
    btn.layer.cornerRadius = 20;
    btn.clipsToBounds = YES;
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addTarget:self action:@selector(onBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    [NSLayoutConstraint activateConstraints:@[
        [btn.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:12],
        [btn.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [btn.widthAnchor constraintEqualToConstant:40],
        [btn.heightAnchor constraintEqualToConstant:40],
    ]];
    self.backButton = btn;
}

- (void)onBack:(id)sender {
    [self.session goBack];
}

// ─── Load initial URL ─────────────────────────────────────────────────────────

- (void)loadURL {
    NSURL *url = [NSURL URLWithString:self.urlString];
    if (!url) return;
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    ((void(*)(id,SEL,id))objc_msgSend)(self.webView, sel_registerName("loadRequest:"), req);
}

@end
