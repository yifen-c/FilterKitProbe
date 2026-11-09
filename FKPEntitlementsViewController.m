#import "FKPEntitlementsViewController.h"
#import <sys/sysctl.h>
#import <unistd.h>
#import <mach-o/dyld.h>

@implementation FKPEntitlementsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Entitlements 验证";
    self.view.backgroundColor = [UIColor blackColor];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont systemFontOfSize:12];
    textView.editable = NO;
    
    NSMutableString *result = [NSMutableString string];
    
    // 基本进程信息
    [result appendString:@"=== 进程基本信息 ===\n"];
    [result appendFormat:@"PID: %d\n", getpid()];
    [result appendFormat:@"UID: %d\n", getuid()];
    [result appendFormat:@"EUID: %d\n", geteuid()];
    [result appendFormat:@"GID: %d\n", getgid()];
    [result appendFormat:@"EGID: %d\n", getegid()];
    
    // 可执行文件路径
    [result appendString:@"\n=== 可执行文件路径 ===\n"];
    char path[PATH_MAX];
    uint32_t size = sizeof(path);
    if (_NSGetExecutablePath(path, &size) == 0) {
        [result appendFormat:@"路径: %s\n", path];
    }
    
    // 测试关键目录访问权限
    [result appendString:@"\n=== 目录访问测试 ===\n"];
    NSArray *testPaths = @[
        @"/var/mobile",
        @"/var/containers/Bundle/Application",
        @"/Library/MobileSubstrate/DynamicLibraries",
        @"/var/jb/Library/MobileSubstrate/DynamicLibraries",
        @"/var/run",
        @"/private/var/run"
    ];
    
    for (NSString *testPath in testPaths) {
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDir;
        BOOL exists = [fm fileExistsAtPath:testPath isDirectory:&isDir];
        NSDictionary *attrs = [fm attributesOfItemAtPath:testPath error:nil];
        NSNumber *perms = [attrs objectForKey:NSFilePosixPermissions];
        
        [result appendFormat:@"路径: %@\n", testPath];
        [result appendFormat:@"  存在: %@\n", exists ? @"是" : @"否"];
        if (exists) {
            [result appendFormat:@"  是目录: %@\n", isDir ? @"是" : @"否"];
            [result appendFormat:@"  权限: %o\n", [perms intValue]];
            [result appendFormat:@"  可读: %@\n", [fm isReadableFileAtPath:testPath] ? @"是" : @"否"];
            [result appendFormat:@"  可写: %@\n", [fm isWritableFileAtPath:testPath] ? @"是" : @"否"];
            [result appendFormat:@"  可执行: %@\n", [fm isExecutableFileAtPath:testPath] ? @"是" : @"否"];
        }
        [result appendString:@"\n"];
    }
    
    // 搜索 .jbroot 目录
    [result appendString:@"=== 搜索 .jbroot 目录 ===\n"];
    NSString *appDir = @"/var/containers/Bundle/Application";
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *contents = [fm contentsOfDirectoryAtPath:appDir error:nil];
    int count = 0;
    for (NSString *item in contents) {
        if ([item hasPrefix:@".jbroot-"]) {
            count++;
            NSString *fullPath = [appDir stringByAppendingPathComponent:item];
            [result appendFormat:@"找到: %@\n", fullPath];
            
            // 测试这个目录下的子目录
            NSArray *subPaths = @[@"Library", @"usr", @"var"];
            for (NSString *sub in subPaths) {
                NSString *subPath = [fullPath stringByAppendingPathComponent:sub];
                BOOL exists = [fm fileExistsAtPath:subPath];
                [result appendFormat:@"  %@: %@\n", sub, exists ? @"存在" : @"不存在"];
            }
        }
    }
    [result appendFormat:@"共找到 %d 个 .jbroot 目录\n", count];
    
    textView.text = result;
    [self.view addSubview:textView];
}

@end
