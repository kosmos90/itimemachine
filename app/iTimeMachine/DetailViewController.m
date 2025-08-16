#import "DetailViewController.h"
#import "ITMAppItem.h"
 #import <Foundation/Foundation.h>
 #include <spawn.h>
 #include <sys/wait.h>
 extern char **environ;

@interface DetailViewController ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bundleLabel;
@property (nonatomic, strong) UIButton *installButton;
@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.title = @"Details";

    CGFloat pad = 12.0;
    CGRect b = self.view.bounds;

    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(pad, 100, b.size.width - pad*2, 28)];
    t.font = [UIFont boldSystemFontOfSize:20];
    [self.view addSubview:t];
    self.titleLabel = t;

    UILabel *bd = [[UILabel alloc] initWithFrame:CGRectMake(pad, 140, b.size.width - pad*2, 20)];
    bd.font = [UIFont systemFontOfSize:14];
    bd.textColor = [UIColor darkGrayColor];
    [self.view addSubview:bd];
    self.bundleLabel = bd;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = CGRectMake(pad, 190, 160, 36);
    [btn setTitle:@"Install (WIP)" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onInstall) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    self.installButton = btn;

    [self refresh];
}

- (void)setItem:(ITMAppItem *)item {
    _item = item;
    if (self.isViewLoaded) {
        [self refresh];
    }
}

- (void)refresh {
    self.titleLabel.text = self.item.name ?: @"";
    NSString *min = self.item.minIOS.length ? [NSString stringWithFormat:@" • iOS %@+", self.item.minIOS] : @"";
    self.bundleLabel.text = [NSString stringWithFormat:@"%@%@", self.item.bundleID ?: @"", min];
}

- (void)onInstall {
    // Jailbreak-only path: download IPA and call /usr/bin/ipainstaller <path>
    ITMAppItem *item = self.item;
    if (!item.downloadURL.length) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Download URL"
                                                        message:@"This catalog entry lacks a download URL."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }

    // Destination path
    NSString *downloadsDir = @"/var/mobile/Media/iTimeMachine/Downloads";
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *dirErr = nil;
    [fm createDirectoryAtPath:downloadsDir withIntermediateDirectories:YES attributes:nil error:&dirErr];

    NSString *filename = item.name.length ? [item.name stringByReplacingOccurrencesOfString:@" " withString:@"_"] : @"download";
    if (![filename hasSuffix:@".ipa"]) {
        filename = [filename stringByAppendingString:@".ipa"];
    }
    NSString *destPath = [downloadsDir stringByAppendingPathComponent:filename];

    // Simple download on background queue (iOS 6 compatible via NSURLConnection)
    self.installButton.enabled = NO;
    self.installButton.alpha = 0.5;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:item.downloadURL]
                                                 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                             timeoutInterval:120];
            NSError *err = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:NULL error:&err];
            if (err || !data) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Download Failed"
                                                                  message:[err localizedDescription] ?: @"No data"
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
                    [a show];
                    self.installButton.enabled = YES;
                    self.installButton.alpha = 1.0;
                });
                return;
            }
            if (![data writeToFile:destPath atomically:YES]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Save Failed"
                                                                  message:@"Could not write IPA to destination."
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
                    [a show];
                    self.installButton.enabled = YES;
                    self.installButton.alpha = 1.0;
                });
                return;
            }

            // Spawn ipainstaller
            pid_t pid;
            int status = 0; // initialize to satisfy older compilers and -Wsometimes-uninitialized
            const char *tool = "/usr/bin/ipainstaller";
            const char *ipaPath = [destPath fileSystemRepresentation];
            char *const argv[] = { (char *)tool, (char *)ipaPath, NULL };
            int spawnErr = posix_spawn(&pid, tool, NULL, NULL, argv, environ);
            if (spawnErr == 0) {
                waitpid(pid, &status, 0);
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                self.installButton.enabled = YES;
                self.installButton.alpha = 1.0;
                NSString *msg;
                if (spawnErr == 0) {
                    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
                        msg = @"ipainstaller finished successfully (check device).";
                    } else {
                        int code = WIFEXITED(status) ? WEXITSTATUS(status) : -1;
                        msg = [NSString stringWithFormat:@"ipainstaller exited with status %d", code];
                    }
                } else {
                    msg = [NSString stringWithFormat:@"Failed to spawn ipainstaller (err=%d)", spawnErr];
                }
                UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Install Result"
                                                          message:msg
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
                [a show];
            });
        }
    });
}

@end
