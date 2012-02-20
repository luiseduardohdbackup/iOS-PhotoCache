//
//  PhotoCache.h
//
//  Created by Nicholas Hughes on 2/20/12.
//

#import <Foundation/Foundation.h>

@interface PhotoCache : NSObject
+ (NSArray *)sortDirectoryContentsByDateAtPath:(NSString *)documentsPath;
+ (BOOL)removeOldestCachedPhotoAtPath:(NSString *)path;
+ (unsigned long long int)folderSize:(NSString *)folderPath;
+ (NSData *)fetchPhotoFromCache:(NSString *)fileName 
                        fromUrl:(NSURL *)url;
+ (void)cachePhoto:(NSString *)fileName 
          withData:(NSData *)imageData 
           fromUrl:(NSURL *)url;
@end
