#import "FKPAppListViewController.h"
#import <mach-o/dyld.h>

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
    
    // 先反推 jbroot 根目录
    [result appendString:@"=== 反推 jbroot 根目录 ===\n\n"];
    
    char path[PATH_MAX];
    uint32_t size = sizeof(path);
    NSString *jbrootPath = nil;
    
    if (_NSGetExecutablePath(path, &size) == 0) {
        NSString *execPath = [NSString stringWithUTF8String:path];
        NSRange range = [execPath rangeOfString:@".jbroot-"];
        if (range.location != NSNotFound) {
            NSRange slashRange = [execPath rangeOfString:@"/" options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
            if (slashRange.location != NSNotFound) {
                NSRange endRange = [execPath rangeOfString:@"/" options:0 range:NSMakeRange(range.location + range.length, execPath.length - range.location - range.length)];
                if (endRange.location != NSNotFound) {
                    jbrootPath = [execPath substringToIndex:endRange.location];
                    [result appendFormat:@"jbroot 根: %@\n\n", jbrootPath];
                }
            }
        }
    }
    
    // 基于 jbroot 搜索配置文件
    [result appendString:@"=== 基于 jbroot 的配置文件搜索 ===\n\n"];
    
    if (jbrootPath) {
        NSArray *candidatePaths = @[
            @"var/mobile/Library/RootHide",
            @"var/mobile/Library/Preferences/com.roothide.bootstrap.plist",
            @"var/mobile/Library/Preferences/roothide.plist",
            @"Library/Preferences/com.roothide.bootstrap.plist",
            @"Library/RootHide",
            @"var/mobile/Library/Preferences/com.opa334.roothide.plist",
            @"var/mobile/Library/Preferences/com.ellekit.plist"
        ];
        
        for (NSString *relativePath in candidatePaths) {
            NSString *fullPath = [jbrootPath stringByAppendingPathComponent:relativePath];
            BOOL exists = [fm fileExistsAtPath:fullPath];
            
            [result appendFormat:@"路径: %@\n", relativePath];
            [result appendFormat:@"  存在: %@\n", exists ? @"是" : @"否"];
            
            if (exists) {
                BOOL isDir;
                [fm fileExistsAtPath:fullPath isDirectory:&isDir];
                [result appendFormat:@"  是目录: %@\n", isDir ? @"是" : @"否"];
                
                if (!isDir) {
                    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:fullPath];
                    if (plist) {
                        [result appendFormat:@"  plist keys: %@\n", plist.allKeys];
                        
                        for (NSString *key in plist.allKeys) {
                            id value = plist[key];
                            if ([value isKindOfClass:[NSArray class]]) {
                                [result appendFormat:@"    %@: 数组 (%lu 项)\n", key, (unsigned long)[(NSArray *)value count]];
                            } else if ([value isKindOfClass:[NSDictionary class]]) {
                                [result appendFormat:@"    %@: 字典 (%lu 键)\n", key, (unsigned long)[(NSDictionary *)value count]];
                            } else {
                                [result appendFormat:@"    %@: %@\n", key, value];
                            }
                        }
                    }
                } else {
                    NSArray *contents = [fm contentsOfDirectoryAtPath:fullPath error:nil];
                    [result appendFormat:@"  目录内容: %lu 项\n", (unsigned long)contents.count];
                    for (NSString *file in contents) {
                        [result appendFormat:@"    - %@\n", file];
                    }
                }
            }
            
            [result appendString:@"\n"];
        }
        
        // 搜索整个 Preferences 目录
        [result appendString:@"=== 搜索 Preferences 目录 ===\n\n"];
        NSString *prefsDir = [jbrootPath stringByAppendingPathComponent:@"var/mobile/Library/Preferences"];
        BOOL prefsExists = [fm fileExistsAtPath:prefsDir];
        [result appendFormat:@"Preferences 目录存在: %@\n\n", prefsExists ? @"是" : @"否"];
        
        if (prefsExists) {
            NSArray *prefs = [fm contentsOfDirectoryAtPath:prefsDir error:nil];
            [result appendFormat:@"共 %lu 个文件:\n", (unsigned long)prefs.count];
            for (NSString *pref in prefs) {
                [result appendFormat:@"  - %@\n", pref];
            }
        }
    }
    
    // 标准路径测试
    [result appendString:@"\n=== 标准路径测试 ===\n\n"];
    NSArray *standardPaths = @[
        @"/var/mobile/Library/Preferences",
        @"/var/mobile/Library/RootHide"
    ];
    
    for (NSString *path in standardPaths) {
        BOOL exists = [fm fileExistsAtPath:path];
        [result appendFormat:@"%@: %@\n", path, exists ? @"存在" : @"不存在"];
    }
    
    textView.text = result;
    [self.view addSubview:textView];
}

@end
