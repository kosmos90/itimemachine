#import "CatalogViewController.h"
 #import "CatalogService.h"
 #import "ITMAppItem.h"
 #import "DetailViewController.h"

@interface CatalogViewController ()
@property (nonatomic, strong) NSArray *items;      // of ITMAppItem*
@property (nonatomic, strong) NSArray *filtered;   // of ITMAppItem*
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, assign) NSInteger sortMode; // 0=name, 1=bundle, 2=size
@end

@implementation CatalogViewController

- (NSArray *)sanitizeItems:(NSArray *)items {
    // Keep entries with non-numeric names and non-empty bundle IDs
    NSPredicate *keep = [NSPredicate predicateWithBlock:^BOOL(ITMAppItem *obj, NSDictionary *bindings) {
        NSString *name = obj.name ?: @"";
        NSString *bid = obj.bundleID ?: @"";
        if (bid.length == 0) return NO;
        // digits-only name?
        NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        BOOL digitsOnly = ([name rangeOfCharacterFromSet:nonDigits].location == NSNotFound);
        return !digitsOnly && name.length > 0;
    }];
    NSArray *filtered = [items filteredArrayUsingPredicate:keep];
    // Cap to avoid UI overload on iOS 6
    NSUInteger cap = 800;
    if (filtered.count > cap) {
        filtered = [filtered subarrayWithRange:NSMakeRange(0, cap)];
    }
    return filtered;
}

- (NSArray *)sortedArrayFrom:(NSArray *)array {
    // sort according to sortMode
    switch (self.sortMode) {
        case 1: { // bundle
            return [array sortedArrayUsingComparator:^NSComparisonResult(ITMAppItem *a, ITMAppItem *b) {
                NSString *la = a.bundleID ?: @"";
                NSString *lb = b.bundleID ?: @"";
                return [la caseInsensitiveCompare:lb];
            }];
        }
        case 2: { // size (descending), nil sizes last
            return [array sortedArrayUsingComparator:^NSComparisonResult(ITMAppItem *a, ITMAppItem *b) {
                NSNumber *sa = a.size; NSNumber *sb = b.size;
                if (sa == nil && sb == nil) return NSOrderedSame;
                if (sa == nil) return NSOrderedDescending; // a after b
                if (sb == nil) return NSOrderedAscending;  // a before b
                // larger first
                return [sb compare:sa];
            }];
        }
        default: { // name
            return [array sortedArrayUsingComparator:^NSComparisonResult(ITMAppItem *a, ITMAppItem *b) {
                NSString *la = a.name ?: @"";
                NSString *lb = b.name ?: @"";
                return [la caseInsensitiveCompare:lb];
            }];
        }
    }
}

- (void)sortAndReload {
    self.items = [self sortedArrayFrom:self.items ?: @[]];
    self.filtered = [self sortedArrayFrom:self.filtered ?: @[]];
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"iTimeMachine";
    self.sortMode = 0;

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    self.searchBar.delegate = self;
    [self.searchBar sizeToFit]; // ensure proper height on iOS 6
    self.tableView.tableHeaderView = self.searchBar;

    // Sorting segmented control in titleView
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Name", @"Bundle", @"Size"]];
    seg.selectedSegmentIndex = self.sortMode;
    [seg addTarget:self action:@selector(sortSegmentChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = seg;

    // Random button
    UIBarButtonItem *randBtn = [[UIBarButtonItem alloc] initWithTitle:@"Random" style:UIBarButtonItemStyleBordered target:self action:@selector(randomTapped:)];
    self.navigationItem.rightBarButtonItem = randBtn;

    // Load bundled first (instant UI), then try remote
    self.items = [self sortedArrayFrom:[self sanitizeItems:[CatalogService loadBundledCatalogItems]]];
    self.filtered = self.items ?: @[];
    [self.tableView reloadData];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *remote = [self sortedArrayFrom:[self sanitizeItems:[CatalogService loadRemoteCatalogItems]]];
        if (remote.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.items = remote;
                self.filtered = remote;
                [self.tableView reloadData];
            });
        }
    });
}

- (void)sortSegmentChanged:(UISegmentedControl *)seg {
    self.sortMode = seg.selectedSegmentIndex;
    [self sortAndReload];
}

- (void)randomTapped:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Random"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Random (Loaded)", @"Random (All)", nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"Random (Loaded)"]) {
        NSArray *source = self.filtered.count ? self.filtered : self.items;
        if (source.count == 0) return;
        uint32_t idx = arc4random_uniform((uint32_t)source.count);
        ITMAppItem *item = [source objectAtIndex:idx];
        DetailViewController *d = [DetailViewController new];
        d.item = item;
        [self.navigationController pushViewController:d animated:YES];
    } else if ([title isEqualToString:@"Random (All)"]) {
        [self performRandomAll];
    }
}

- (void)performRandomAll {
    // Fetch git tree (recursive) and choose a random .plist under data/
    NSURL *url = [NSURL URLWithString:@"https://api.github.com/repos/stuffed18/ipa-archive-updated/git/trees/main?recursive=1"];
    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *err = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:NULL error:&err];
        if (err || !data) { [self showRandomAllError:@"Network error"]; return; }
        id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        if (err || ![obj isKindOfClass:[NSDictionary class]]) { [self showRandomAllError:@"Bad response"]; return; }
        NSArray *tree = obj[@"tree"]; if (![tree isKindOfClass:[NSArray class]]) { [self showRandomAllError:@"No tree"]; return; }
        NSMutableArray *plists = [NSMutableArray array];
        for (NSDictionary *n in tree) {
            if (![n isKindOfClass:[NSDictionary class]]) continue;
            if (![[n objectForKey:@"type"] isEqual:@"blob"]) continue;
            NSString *path = [n objectForKey:@"path"];
            if ([path hasPrefix:@"data/"] && [path hasSuffix:@".plist"]) {
                [plists addObject:path];
            }
        }
        if (plists.count == 0) { [self showRandomAllError:@"No entries"]; return; }
        uint32_t idx = arc4random_uniform((uint32_t)plists.count);
        NSString *path = [plists objectAtIndex:idx];
        NSString *raw = [NSString stringWithFormat:@"https://raw.githubusercontent.com/stuffed18/ipa-archive-updated/main/%@", path];

        NSURLRequest *plistReq = [NSURLRequest requestWithURL:[NSURL URLWithString:raw]
                                                   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                               timeoutInterval:20.0];
        NSData *plistData = [NSURLConnection sendSynchronousRequest:plistReq returningResponse:NULL error:&err];
        if (err || !plistData) { [self showRandomAllError:@"Failed to load plist"]; return; }
        NSPropertyListFormat fmt = NSPropertyListXMLFormat_v1_0;
        id plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:&fmt error:&err];
        if (err || ![plist isKindOfClass:[NSDictionary class]]) { [self showRandomAllError:@"Bad plist"]; return; }
        NSDictionary *pl = (NSDictionary *)plist;
        ITMAppItem *item = [ITMAppItem new];
        NSString *name = pl[@"CFBundleDisplayName"] ?: pl[@"CFBundleName"] ?: pl[@"name"] ?: [path lastPathComponent];
        item.name = name ?: @"Unknown";
        NSString *bid = pl[@"CFBundleIdentifier"] ?: pl[@"bundle_id"] ?: pl[@"bundleId"];
        item.bundleID = bid ?: @"";
        NSString *min = pl[@"MinimumOSVersion"] ?: pl[@"min_ios"];
        item.minIOS = min ?: @"";
        item.downloadURL = raw; // fallback; real IPA URL may differ
        item.iconPath = nil;
        item.size = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            DetailViewController *d = [DetailViewController new];
            d.item = item;
            [self.navigationController pushViewController:d animated:YES];
        });
    });
}

- (void)showRandomAllError:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Random (All) Failed"
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
        [a show];
    });
}

#pragma mark - Table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filtered.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    ITMAppItem *item = [self.filtered objectAtIndex:indexPath.row];
    cell.textLabel.text = item.name;
    NSString *min = item.minIOS.length ? [NSString stringWithFormat:@" • iOS %@+", item.minIOS] : @"";
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@", item.bundleID ?: @"", min];
    return cell;
}

#pragma mark - Selection

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ITMAppItem *item = [self.filtered objectAtIndex:indexPath.row];
    DetailViewController *d = [DetailViewController new];
    d.item = item;
    [self.navigationController pushViewController:d animated:YES];
}

#pragma mark - Search

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        self.filtered = self.items;
    } else {
        NSPredicate *p = [NSPredicate predicateWithBlock:^BOOL(ITMAppItem *obj, NSDictionary *bindings) {
            NSString *name = obj.name ?: @"";
            NSString *bundle = obj.bundleID ?: @"";
            return ([name rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) ||
                   ([bundle rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound);
        }];
        self.filtered = [self sortedArrayFrom:[self.items filteredArrayUsingPredicate:p]];
    }
    [self.tableView reloadData];
}

@end
