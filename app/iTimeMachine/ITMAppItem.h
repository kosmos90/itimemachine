#import <Foundation/Foundation.h>

@interface ITMAppItem : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *bundleID;
@property (nonatomic, copy) NSString *minIOS;
@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, copy) NSString *iconPath;

+ (NSArray *)itemsFromCatalogDictionary:(NSDictionary *)catalog;
@end
