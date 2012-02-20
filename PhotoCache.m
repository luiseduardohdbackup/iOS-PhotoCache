//
//  PhotoCache.m
//
//  Created by Nicholas Hughes on 2/20/12.
//  Copyright 2012. All rights reserved.
//

#import "PhotoCache.h"
#define MAX_CACHE_SIZE_IN_BYTES 10000000
#define FILE_EXTENSION @"jpg"

@implementation PhotoCache

+ (NSArray *)sortDirectoryContentsByDateAtPath:(NSString *)documentsPath 
{   
    NSError* error = nil;
    NSArray* filesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsPath error:&error];
    if(error != nil) {
        NSLog(@"Error in reading files: %@", [error localizedDescription]);
    }
    
    // sort by creation date
    NSMutableArray* filesAndProperties = [NSMutableArray arrayWithCapacity:[filesArray count]];
    for(NSString* file in filesArray) {
        NSString* filePath = [documentsPath stringByAppendingPathComponent:file];
        NSDictionary* properties = [[NSFileManager defaultManager]
                                    attributesOfItemAtPath:filePath
                                    error:&error];
        NSDate* modDate = [properties objectForKey:NSFileModificationDate];
        
        if(error == nil)
        {
            [filesAndProperties addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                           file, @"path",
                                           modDate, @"lastModDate",
                                           nil]];                 
        }
    }
    
    // sort with a block by modified date desc
    NSArray* sortedFiles = [filesAndProperties sortedArrayUsingComparator:
                            ^(id path1, id path2)
                            {                               
                                NSComparisonResult comp = [[path2 objectForKey:@"lastModDate"] compare:
                                                           [path1 objectForKey:@"lastModDate"]];
                                return comp;                
                            }];
    
    return sortedFiles;
}


+ (BOOL)removeOldestCachedPhotoAtPath:(NSString *)path
{
    NSArray *photos = [self sortDirectoryContentsByDateAtPath:path];
    NSError *error = nil;
    NSString *filePath = [path stringByAppendingPathComponent:[[photos lastObject] objectForKey:@"path"]];
    return [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
}

+ (unsigned long long int)folderSize:(NSString *)folderPath {
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long int fileSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDictionary fileSize];
    }
    return fileSize;
}

+ (NSData *)fetchPhotoFromCache:(NSString *)fileName 
                        fromUrl:(NSURL *)url
{
    // set the file path
    NSFileManager *fileManager = [NSFileManager defaultManager];
    fileName = [fileName stringByAppendingPathExtension:[url pathExtension]];
    NSError *error = nil;
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *folderPath = [documentsDirectory stringByAppendingPathComponent:@"photos"];
    if (![fileManager fileExistsAtPath:folderPath]) {
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
    
    // check if photo is already in the cache
    NSData *cachedImageData = [fileManager contentsAtPath:filePath];
    return cachedImageData;
}

+ (void)cachePhoto:(NSString *)fileName 
          withData:(NSData *)imageData 
           fromUrl:(NSURL *)url
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    fileName = [fileName stringByAppendingPathExtension:[url pathExtension]];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *folderPath = [documentsDirectory stringByAppendingPathComponent:@"photos"];
    
    dispatch_queue_t photoCacheQueue = dispatch_queue_create("photo caching", NULL);
    dispatch_async(photoCacheQueue, ^{
        // set the file path
        NSError *error = nil;
        if (![fileManager fileExistsAtPath:folderPath]) {
            [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:&error];
        }
        NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
        
        // check if photo is already in the cache
        NSData *cachedImageData = [fileManager contentsAtPath:filePath];
        if (![cachedImageData isEqualToData:imageData]){
            // it's not so we'll try to save it
            unsigned long long int size = [self folderSize:folderPath];
            size += [imageData length];
            
            BOOL deleteSuccessful = YES;
            while (!(size < MAX_CACHE_SIZE_IN_BYTES)) {
                deleteSuccessful = [self removeOldestCachedPhotoAtPath:folderPath];
                size = [self folderSize:folderPath];
                size += [imageData length];
                
                // debug
                if (deleteSuccessful) {
                    // NSLog(@"delete photo result was successful");
                } else {
                    NSLog(@"delete photo result was unsuccessful");
                }
            }
            
            if (deleteSuccessful) {
                BOOL result = [[NSFileManager defaultManager] createFileAtPath:filePath contents:imageData attributes:nil];
                if (!result) NSLog(@"file create result: %@", result ? @"YES" : @"NO");
            }
        }
    });
    dispatch_release(photoCacheQueue);
}

@end
