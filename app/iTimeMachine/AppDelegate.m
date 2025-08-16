#import "AppDelegate.h"
#import "CatalogViewController.h"

static void ITMUncaughtExceptionHandler(NSException *exception) {
    NSLog(@"[UncaughtException] %@: %@\nStack:\n%@", exception.name, exception.reason, [exception.callStackSymbols componentsJoinedByString:@"\n"]);
}

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSSetUncaughtExceptionHandler(&ITMUncaughtExceptionHandler);
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    CatalogViewController *rootVC = [[CatalogViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];

    // Basic iOS 6-style nav bar appearance (minimal)
    nav.navigationBar.barStyle = UIBarStyleDefault;

    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
