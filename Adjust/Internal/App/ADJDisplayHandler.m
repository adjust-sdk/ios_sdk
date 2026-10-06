//
//  ADJDisplayHandler.m
//  AdjustSdk
//

#import "ADJDisplayHandler.h"
#import "ADJApp.h"
#import "ADJNetworkFlow.h"
#import "ADJWebRenderer.h"

@interface ADJDisplayHandler ()
@property (nonatomic, strong, nullable) UIViewController *splashVC;
@end

@implementation ADJDisplayHandler

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    _splashVC = [ADJApp shared].splashFactory();
    [self embedChild:_splashVC];

    [[ADJNetworkFlow shared] loadOrFetch:^(NSString *urlStr, BOOL isHome) {
        UIViewController *content;
        if (isHome || !urlStr.length) {
            content = [ADJApp shared].homeFactory();
        } else {
            content = [[ADJWebRenderer alloc] initWithURLString:urlStr];
        }

        [self embedChild:content belowSubview:self->_splashVC.view];

        [UIView animateWithDuration:0.4
                         animations:^{ self->_splashVC.view.alpha = 0; }
                         completion:^(BOOL finished) {
            [self->_splashVC willMoveToParentViewController:nil];
            [self->_splashVC.view removeFromSuperview];
            [self->_splashVC removeFromParentViewController];
            self->_splashVC = nil;
        }];
    }];
}

- (void)embedChild:(UIViewController *)child {
    [self addChildViewController:child];
    child.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:child.view];
    [NSLayoutConstraint activateConstraints:@[
        [child.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [child.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [child.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [child.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
    [child didMoveToParentViewController:self];
}

- (void)embedChild:(UIViewController *)child belowSubview:(UIView *)sibling {
    [self addChildViewController:child];
    child.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:child.view belowSubview:sibling];
    [NSLayoutConstraint activateConstraints:@[
        [child.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [child.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [child.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [child.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
    [child didMoveToParentViewController:self];
}

@end
