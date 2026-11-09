#import "FKPElleKitScannerViewController.h"
#import <sys/stat.h>
#import <sys/syslimits.h>

@implementation FKPElleKitScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ElleKit 插件目录扫描";
    self.view.backgroundColor = [UIColor blackColor];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont systemFontOfSize:12];
    textView.editable = NO;
    
    NSMutableString *result = [NSMutableString string];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 候选插件目录列表
    NSArray *candidateDirs = @[
        @"/Library/MobileSubstrate/DynamicLibraries",
        @"/var/jb/Library/MobileSubstrate/DynamicLibraries",
        @"/usr/lib/TweakInject",
        @"/var/jb/usr/lib/TweakInject"
    ];
    
    [result appendString:@"=== 候选插件目录检查 ===\n\n"];
    
    for (NSString *dir in candidateDirs) {
        struct stat st;
        BOOL exists = (stat([dir UTF8String], &st) == 0);
        
        [result appendFormat:@"路径: %@\n", dir];
        [result appendFormat:@"  存在: %@\n", exists ? @"是" : @"否"];
        
        if (exists) {
            // 检查是否是符号链接
            BOOL isSymlink = (S_ISLNK(st.st_mode));
            [result appendFormat:@"  是符号链接: %@\n", isSymlink ? @"是" : @"否"];
            
            if (isSymlink) {
                char resolvedPath[PATH_MAX];
                if (realpath([dir UTF8String], resolvedPath) != NULL) {
                    [result appendFormat:@"  实际指向: %s\n", resolvedPath];
                }
            }
            
            [result appendFormat:@"  权限: %o\n", st.st_mode & 0777];
            [result appendFormat:@"  UID: %d\n", st.st_uid];
            [result appendFormat:@"  GID: %d\n", st.st_gid];
            
            // 列出目录内容
            NSArray *contents = [fm contentsOfDirectoryAtPath:dir error:nil];
            [result appendFormat:@"  文件数量: %lu\n", (unsigned long)contents.count];
            
            // 统计 dylib 和 plist 数量
            int dylibCount = 0;
            int plistCount = 0;
            NSMutableArray *dylibNames = [NSMutableArray array];
            
            for (NSString *file in contents) {
                if ([[file pathExtension] isEqualToString:@"dylib"]) {
                    dylibCount++;
                    [dylibNames addObject:file];
                } else if ([[file pathExtension] isEqualToString:@"plist"]) {
                    plistCount++;
                }
            }
            
            [result appendFormat:@"  dylib 数量: %d\n", dylibCount];
            [result appendFormat:@"  plist 数量: %d\n", plistCount];
            
            if (dylibCount > 0 && dylibCount <= 20) {
                [result appendString:@"  dylib 列表:\n"];
                for (NSString *name in dylibNames) {
                    [result appendFormat:@"    - %@\n", name];
                }
            }
        }
        
        [result appendString:@"\n"];
    }
    
    // 搜索所有 .jbroot 目录下的插件目录
    [result appendString:@"=== 搜索 .jbroot 下的插件目录 ===\n\n"];
    
    NSString *appDir = @"/var/containers/Bundle/Application";
    NSArray *appContents = [fm contentsOfDirectoryAtPath:appDir error:nil];
    
    for (NSString *item in appContents) {
        if ([item hasPrefix:@".jbroot-"]) {
            NSString *jbrootPath = [appDir stringByAppendingPathComponent:item];
            
            NSArray *pluginDirCandidates = @[
                [jbrootPath stringByAppendingPathComponent:@"/Library/MobileSubstrate/DynamicLibraries"],
                [jbrootPath stringByAppendingPathComponent:@"/usr/lib/TweakInject"]
            ];
            
            for (NSString *pluginDir in pluginDirCandidates) {
                BOOL exists = [fm fileExistsAtPath:pluginDir];
                [result appendFormat:@"路径: %@\n", pluginDir];
                [result appendFormat:@"  存在: %@\n", exists ? @"是" : @"否"];
                
                if (exists) {
                    NSArray *contents = [fm contentsOfDirectoryAtPath:pluginDir error:nil];
                    [result appendFormat:@"  文件数量: %lu\n", (unsigned long)contents.count];
                }
                [result appendString:@"\n"];
            }
        }
    }
    
    textView.text = result;
    [self.view addSubview:textView];
}

@end
