#import "FKPAppListViewController.h"
#import <mach-o/dyld.h>

@implementation FKPAppListViewController {
    UITextView *_textView;
    NSString *_jbrootPath;
    NSString *_configPath;
}

- (void)appendPlist:(NSDictionary *)plist toResult:(NSMutableString *)result indent:(NSString *)indent {
    for (NSString *key in plist.allKeys) {
        id value = plist[key];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            [result appendFormat:@"%@%@:\n", indent, key];
            [self appendPlist:value toResult:result indent:[indent stringByAppendingString:@"  "]];
        } else if ([value isKindOfClass:[NSArray class]]) {
            [result appendFormat:@"%@%@: 数组 (%lu 项)\n", indent, key, (unsigned long)[(NSArray *)value count]];
        } else {
            [result appendFormat:@"%@%@: %@\n", indent, key, value];
        }
    }
}

- (NSString *)getJbrootPath {
    if (_jbrootPath) return _jbrootPath;
    
    char path[PATH_MAX];
    uint32_t size = sizeof(path);
    if (_NSGetExecutablePath(path, &size) == 0) {
        NSString *execPath = [NSString stringWithUTF8String:path];
        NSRange range = [execPath rangeOfString:@".jbroot-"];
        if (range.location != NSNotFound) {
            NSRange slashRange = [execPath rangeOfString:@"/" options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
            if (slashRange.location != NSNotFound) {
                NSRange endRange = [execPath rangeOfString:@"/" options:0 range:NSMakeRange(range.location + range.length, execPath.length - range.location - range.length)];
                if (endRange.location != NSNotFound) {
                    _jbrootPath = [execPath substringToIndex:endRange.location];
                }
            }
        }
    }
    return _jbrootPath;
}

- (void)refreshView {
    NSMutableString *result = [NSMutableString string];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *jbroot = [self getJbrootPath];
    NSString *myBundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    [result appendString:@"=== 实验：appconfig 隔离测试 ===\n\n"];
    
    [result appendFormat:@"当前 App Bundle ID: %@\n", myBundleID];
    [result appendFormat:@"jbroot 路径: %@\n\n", jbroot];
    
    // 测试：能不能看到 jbroot 下的关键文件
    [result appendString:@"--- 当前可见性测试 ---\n"];
    
    if (jbroot) {
        NSString *testFile = [jbroot stringByAppendingPathComponent:@"var/mobile/Library/RootHide/RootHideConfig.plist"];
        BOOL canSee = [fm fileExistsAtPath:testFile];
        [result appendFormat:@"能看到 RootHideConfig.plist: %@\n", canSee ? @"是" : @"否"];
        
        NSString *pluginDir = [jbroot stringByAppendingPathComponent:@"Library/MobileSubstrate/DynamicLibraries"];
        BOOL canSeePlugins = [fm fileExistsAtPath:pluginDir];
        [result appendFormat:@"能看到插件目录: %@\n", canSeePlugins ? @"是" : @"否"];
    } else {
        [result appendString:@"看不到 jbroot 路径（已被隔离）\n"];
    }
    
    // 读取 appconfig
    [result appendString:@"\n--- 当前 appconfig 列表 ---\n"];
    
    if (jbroot) {
        NSString *configPath = [jbroot stringByAppendingPathComponent:@"var/mobile/Library/RootHide/RootHideConfig.plist"];
        _configPath = configPath;
        
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:configPath];
        if (plist) {
            NSDictionary *appconfig = plist[@"appconfig"];
            if (appconfig) {
                [result appendFormat:@"共 %lu 个 App:\n", (unsigned long)appconfig.count];
                for (NSString *bundleID in appconfig.allKeys) {
                    BOOL isMe = [bundleID isEqualToString:myBundleID];
                    [result appendFormat:@"  - %@%@\n", bundleID, isMe ? @" ← 我自己" : @""];
                }
                
                BOOL isInList = appconfig[myBundleID] != nil;
                [result appendFormat:@"\n我在 appconfig 里: %@\n", isInList ? @"是" : @"否"];
            }
        }
    }
    
    [result appendString:@"\n--- 操作说明 ---\n"];
    [result appendString:@"点击下面按钮，然后重启 App，观察可见性变化\n"];
    
    _textView.text = result;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"App List 实验";
    self.view.backgroundColor = [UIColor blackColor];
    
    // 顶部按钮区
    UIView *buttonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
    buttonView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    buttonView.backgroundColor = [UIColor darkGrayColor];
    
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [addButton setTitle:@"加入 appconfig" forState:UIControlStateNormal];
    addButton.frame = CGRectMake(20, 20, 140, 40);
    addButton.titleLabel.font = [UIFont systemFontOfSize:14];
    addButton.backgroundColor = [UIColor systemBlueColor];
    [addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    addButton.layer.cornerRadius = 8;
    [addButton addTarget:self action:@selector(addToAppConfig) forControlEvents:UIControlEventTouchUpInside];
    [buttonView addSubview:addButton];
    
    UIButton *removeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [removeButton setTitle:@"从 appconfig 移除" forState:UIControlStateNormal];
    removeButton.frame = CGRectMake(180, 20, 160, 40);
    removeButton.titleLabel.font = [UIFont systemFontOfSize:14];
    removeButton.backgroundColor = [UIColor systemRedColor];
    [removeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    removeButton.layer.cornerRadius = 8;
    [removeButton addTarget:self action:@selector(removeFromAppConfig) forControlEvents:UIControlEventTouchUpInside];
    [buttonView addSubview:removeButton];
    
    [self.view addSubview:buttonView];
    
    // 文本区
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, self.view.bounds.size.height - 100)];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _textView.backgroundColor = [UIColor blackColor];
    _textView.textColor = [UIColor whiteColor];
    _textView.font = [UIFont systemFontOfSize:11];
    _textView.editable = NO;
    [self.view addSubview:_textView];
    
    [self refreshView];
}

- (void)addToAppConfig {
    NSString *jbroot = [self getJbrootPath];
    if (!jbroot) return;
    
    NSString *configPath = [jbroot stringByAppendingPathComponent:@"var/mobile/Library/RootHide/RootHideConfig.plist"];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:configPath];
    if (!plist) return;
    
    NSMutableDictionary *mutablePlist = [plist mutableCopy];
    NSMutableDictionary *appconfig = [mutablePlist[@"appconfig"] mutableCopy];
    if (!appconfig) {
        appconfig = [NSMutableDictionary dictionary];
    }
    
    NSString *myBundleID = [[NSBundle mainBundle] bundleIdentifier];
    appconfig[myBundleID] = @1;
    mutablePlist[@"appconfig"] = appconfig;
    
    BOOL success = [mutablePlist writeToFile:configPath atomically:YES];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"操作结果"
                                                                   message:success ? @"已加入 appconfig，请重启 App 观察效果" : @"写入失败"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        (void)action;
        [self refreshView];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)removeFromAppConfig {
    NSString *jbroot = [self getJbrootPath];
    if (!jbroot) return;
    
    NSString *configPath = [jbroot stringByAppendingPathComponent:@"var/mobile/Library/RootHide/RootHideConfig.plist"];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:configPath];
    if (!plist) return;
    
    NSMutableDictionary *mutablePlist = [plist mutableCopy];
    NSMutableDictionary *appconfig = [mutablePlist[@"appconfig"] mutableCopy];
    
    NSString *myBundleID = [[NSBundle mainBundle] bundleIdentifier];
    [appconfig removeObjectForKey:myBundleID];
    mutablePlist[@"appconfig"] = appconfig;
    
    BOOL success = [mutablePlist writeToFile:configPath atomically:YES];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"操作结果"
                                                                   message:success ? @"已从 appconfig 移除，请重启 App 观察效果" : @"写入失败"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        (void)action;
        [self refreshView];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
