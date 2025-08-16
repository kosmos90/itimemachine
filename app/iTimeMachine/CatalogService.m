#import "CatalogService.h"
#import "ITMAppItem.h"

@implementation CatalogService

+ (NSArray *)loadBundledCatalogItems {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"catalog" ofType:@"json"];
    if (!path) { return @[]; }
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) { return @[]; }
    NSError *err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err || ![obj isKindOfClass:[NSDictionary class]]) { return @[]; }
    return [ITMAppItem itemsFromCatalogDictionary:(NSDictionary *)obj];
}

@end
