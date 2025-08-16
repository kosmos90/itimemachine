#import <Foundation/Foundation.h>
@class ITMAppItem;

@interface CatalogService : NSObject
+ (NSArray *)loadBundledCatalogItems; // loads app/iTimeMachine/catalog.json
@end
