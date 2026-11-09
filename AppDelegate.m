#import "AppDelegate.h"
#import "FKPEntitlementsViewController.h"
#import "FKPElleKitScannerViewController.h"
#import "FKPPListParserViewController.h"
#import "FKPAppListViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    FKPEntitlementsViewController *entitlementsVC = [[FKPEntitlementsViewController alloc] init];
    UINavigationController *nav1 = [[UINavigationController alloc] initWithRootViewController:entitlementsVC];
    nav1.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Entitlements" image:nil tag:0];
    
    FKPElleKitScannerViewController *ellekitVC = [[FKPElleKitScannerViewController alloc] init];
    UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:ellekitVC];
    nav2.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"ElleKit" image:nil tag:1];
    
    FKPPListParserViewController *plistVC = [[FKPPListParserViewController alloc] init];
    UINavigationController *nav3 = [[UINavigationController alloc] initWithRootViewController:plistVC];
    nav3.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Plist" image:nil tag:2];
    
    FKPAppListViewController *appListVC = [[FKPAppListViewController alloc] init];
    UINavigationController *nav4 = [[UINavigationController alloc] initWithRootViewController:appListVC];
    nav4.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"AppList" image:nil tag:3];
    
    tabBarController.viewControllers = @[nav1, nav2, nav3, nav4];
    
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
