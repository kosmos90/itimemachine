#import "CatalogViewController.h"
 #import "CatalogService.h"
 #import "ITMAppItem.h"
 #import "DetailViewController.h"

@interface CatalogViewController ()
@property (nonatomic, strong) NSArray *items;      // of ITMAppItem*
@property (nonatomic, strong) NSArray *filtered;   // of ITMAppItem*
@property (nonatomic, strong) UISearchBar *searchBar;
@end

@implementation CatalogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"iTimeMachine";

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    self.searchBar.delegate = self;
    [self.searchBar sizeToFit]; // ensure proper height on iOS 6
    self.tableView.tableHeaderView = self.searchBar;

    // Load bundled first (instant UI), then try remote
    self.items = [CatalogService loadBundledCatalogItems];
    self.filtered = self.items ?: @[];
    [self.tableView reloadData];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *remote = [CatalogService loadRemoteCatalogItems];
        if (remote.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.items = remote;
                self.filtered = remote;
                [self.tableView reloadData];
            });
        }
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
        self.filtered = [self.items filteredArrayUsingPredicate:p];
    }
    [self.tableView reloadData];
}

@end
