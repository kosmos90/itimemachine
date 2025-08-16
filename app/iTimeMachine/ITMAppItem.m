#import "ITMAppItem.h"

@implementation ITMAppItem

+ (NSArray *)itemsFromCatalogDictionary:(NSDictionary *)catalog {
    NSArray *raw = catalog[@"items"];
    if (![raw isKindOfClass:[NSArray class]]) return @[];
    NSMutableArray *out = [NSMutableArray arrayWithCapacity:raw.count];
    for (NSDictionary *d in raw) {
        if (![d isKindOfClass:[NSDictionary class]]) continue;
        ITMAppItem *item = [ITMAppItem new];
        item.name = d[@"name"] ?: @"Unknown";
        item.bundleID = d[@"bundle_id"] ?: @"";
        item.minIOS = d[@"min_ios"] ?: @"";
        item.downloadURL = d[@"download_url"] ?: @"";
        item.iconPath = d[@"icon"] ?: @"";
        item.desc = d[@"description"] ?: @"";
        [out addObject:item];
    }
    return out;
}

@end
