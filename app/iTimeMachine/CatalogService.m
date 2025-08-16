#import "CatalogService.h"
#import "ITMAppItem.h"

@implementation CatalogService

+ (NSArray *)itemsFromCatalogData:(NSData *)data {
    if (!data) { return @[]; }
    NSError *err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err || ![obj isKindOfClass:[NSDictionary class]]) {
        NSLog(@"[CatalogService] JSON parse failed or not a dict: %@", err);
        return @[];
    }
    NSArray *items = [ITMAppItem itemsFromCatalogDictionary:(NSDictionary *)obj];
    NSLog(@"[CatalogService] Parsed %lu items", (unsigned long)items.count);
    return items;
}

+ (NSArray *)loadBundledCatalogItems {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"catalog" ofType:@"json"];
    if (!path) { return @[]; }
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSArray *items = [self itemsFromCatalogData:data];
    NSLog(@"[CatalogService] Loaded bundled catalog: %lu items", (unsigned long)items.count);
    return items;
}

// Remote source preferred by user
+ (NSURL *)remoteCatalogURL {
    return [NSURL URLWithString:@"https://raw.githubusercontent.com/stuffed18/ipa-archive-updated/main/catalog.json"];
}

+ (NSArray *)loadRemoteCatalogItems {
    NSURL *url = [self remoteCatalogURL];
    if (!url) { return @[]; }
    NSURLRequest *req = [NSURLRequest requestWithURL:url
                                          cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                      timeoutInterval:20.0];
    NSURLResponse *resp = nil;
    NSError *err = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    if (err || !data) {
        NSLog(@"[CatalogService] Remote fetch failed: %@", err);
        return @[];
    }
    NSArray *items = [self itemsFromCatalogData:data];
    NSLog(@"[CatalogService] Loaded remote catalog: %lu items", (unsigned long)items.count);
    return items;
}

@end
