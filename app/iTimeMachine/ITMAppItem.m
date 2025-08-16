#import "ITMAppItem.h"

@implementation ITMAppItem

+ (NSArray *)itemsFromCatalogDictionary:(NSDictionary *)catalog {
    NSArray *raw = catalog[@"items"];
    if (![raw isKindOfClass:[NSArray class]]) return @[];
    NSMutableArray *out = [NSMutableArray arrayWithCapacity:raw.count];
    for (NSDictionary *d in raw) {
        if (![d isKindOfClass:[NSDictionary class]]) continue;
        ITMAppItem *item = [ITMAppItem new];
        id name = d[@"name"]; item.name = [name isKindOfClass:[NSString class]] ? name : [name description] ?: @"Unknown";
        id bid = d[@"bundle_id"]; item.bundleID = [bid isKindOfClass:[NSString class]] ? bid : (bid ? [bid description] : @"");
        id min = d[@"min_ios"]; item.minIOS = [min isKindOfClass:[NSString class]] ? min : (min ? [min description] : @"");
        id dl = d[@"download_url"]; item.downloadURL = [dl isKindOfClass:[NSString class]] ? dl : (dl ? [dl description] : @"");
        id ic = d[@"icon"]; item.iconPath = [ic isKindOfClass:[NSString class]] ? ic : (ic ? [ic description] : @"");
        id desc = d[@"description"]; item.desc = [desc isKindOfClass:[NSString class]] ? desc : (desc ? [desc description] : @"");
        [out addObject:item];
    }
    return out;
}

@end
