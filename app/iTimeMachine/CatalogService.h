#import <Foundation/Foundation.h>
@class ITMAppItem;

@interface CatalogService : NSObject
+ (NSArray *)loadBundledCatalogItems; // loads app/iTimeMachine/catalog.json
// Remote loading
 + (NSArray *)loadRemoteCatalogItems; // synchronous fetch from GitHub raw URL
 + (NSURL *)remoteCatalogURL;
@end
