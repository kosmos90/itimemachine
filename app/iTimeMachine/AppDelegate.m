#import "AppDelegate.h"
#import "CatalogViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
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
