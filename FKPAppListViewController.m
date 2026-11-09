#import "FKPAppListViewController.h"

@implementation FKPAppListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"RootHide App List";
    self.view.backgroundColor = [UIColor blackColor];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont systemFontOfSize:11];
    textView.editable = NO;
    
    NSMutableString *result = [NSMutableString string];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    [result appendString:@"=== 搜索 RootHide 配置文件 ===\n\n"];
    
    // 候选配置文件路径
    NSMutableArray *candidatePaths = [NSMutableArray array];
    
    // 标准 RootHide 路径
    NSArray *standardPaths = @[
        @"/var/mobile/Library/RootHide",
        @"/var/mobile/Library/Preferences/com.roothide.bootstrap.plist",
        @"/var/mobile/Library/Preferences/roothide.plist",
        @"/Library/Preferences/com.roothide.bootstrap.plist"
    ];
    [candidatePaths addObjectsFromArray:standardPaths];
    
    // 搜索 .jbroot 目录
    NSString *appDir = @"/var/containers/Bundle/Application";
    NSArray *appContents = [fm contentsOfDirectoryAtPath:appDir error:nil];
    
    for (NSString *item in appContents) {
        if ([item hasPrefix:@".jbroot-"]) {
            NSString *jbrootPath = [appDir stringByAppendingPathComponent:item];
            
            NSArray *jbrootCandidates = @[
                [jbrootPath stringByAppendingPathComponent:@"/var/mobile/Library/RootHide"],
                [jbrootPath stringByAppendingPathComponent:@"/var/mobile/Library/Preferences/com.roothide.bootstrap.plist"],
                [jbrootPath stringByAppendingPathComponent:@"/var/mobile/Library/Preferences/roothide.plist"],
                [jbrootPath stringByAppendingPathComponent:@"/Library/Preferences/com.roothide.bootstrap.plist"],
                [jbrootPath stringByAppendingPathComponent:@"/Library/RootHide"],
                [jbrootPath stringByAppendingPathComponent:@"/private/var/mobile/Library/Preferences/com.roothide.bootstrap.plist"]
            ];
            [candidatePaths addObjectsFromArray:jbrootCandidates];
        }
    }
    
    // 检查每个候选路径
    for (NSString *path in candidatePaths) {
        BOOL exists = [fm fileExistsAtPath:path];
        [result appendFormat:@"路径: %@\n", path];
        [result appendFormat:@"  存在: %@\n", exists ? @"是" : @"否"];
        
        if (exists) {
            BOOL isDir;
            [fm fileExistsAtPath:path isDirectory:&isDir];
            [result appendFormat:@"  是目录: %@\n", isDir ? @"是" : @"否"];
            
            if (!isDir) {
                // 尝试解析 plist
                NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
                if (plist) {
                    [result appendFormat:@"  plist keys: %@\n", plist.allKeys];
                    
                    // 搜索 App List 相关的 key
                    for (NSString *key in plist.allKeys) {
                        id value = plist[key];
                        if ([value isKindOfClass:[NSArray class]]) {
                            [result appendFormat:@"    %@: 数组 (%lu 项)\n", key, (unsigned long)[(NSArray *)value count]];
                        } else if ([value isKindOfClass:[NSDictionary class]]) {
                            [result appendFormat:@"    %@: 字典 (%lu 键)\n", key, (unsigned long)[(NSDictionary *)value count]];
                        } else if ([value isKindOfClass:[NSString class]]) {
                            [result appendFormat:@"    %@: %@\n", key, value];
                        } else {
                            [result appendFormat:@"    %@: %@\n", key, [value class]];
                        }
                    }
                } else {
                    [result appendString:@"  不是 plist 或解析失败\n"];
                }
            } else {
                // 列出目录内容
                NSArray *contents = [fm contentsOfDirectoryAtPath:path error:nil];
                [result appendFormat:@"  目录内容: %lu 项\n", (unsigned long)contents.count];
                for (NSString *file in contents) {
                    [result appendFormat:@"    - %@\n", file];
                }
            }
        }
        
        [result appendString:@"\n"];
    }
    
    // 搜索所有 plist 文件
    [result appendString:@"=== 搜索所有可能的 RootHide 配置 ===\n\n"];
    
    for (NSString *item in appContents) {
        if ([item hasPrefix:@".jbroot-"]) {
            NSString *jbrootPath = [appDir stringByAppendingPathComponent:item];
            
            // 搜索 Preferences 目录
            NSString *prefsDir = [jbrootPath stringByAppendingPathComponent:@"/var/mobile/Library/Preferences"];
            if ([fm fileExistsAtPath:prefsDir]) {
                NSArray *prefs = [fm contentsOfDirectoryAtPath:prefsDir error:nil];
                for (NSString *pref in prefs) {
                    if ([pref containsString:@"roothide"] || [pref containsString:@"ellekit"]) {
                        [result appendFormat:@"找到: %@\n", [prefsDir stringByAppendingPathComponent:pref]];
                    }
                }
            }
        }
    }
    
    textView.text = result;
    [self.view addSubview:textView];
}

@end
