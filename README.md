Summary
============

**PhotoCache** is an NSObject intended to supply photo-based iOS applications with basic
file caching. It has been extracted from a personal learning project built for iOS 5 with XCode 4.2.

Contribute
=================

Fork, revise, and issue a pull request.

Installation
===========================

Git clone and copy PhotoCache.h and PhotoCache.m into your existing project.

Alternatively, you may want to install PhotoCache as a submodule within your project: 

    git submodule add repoUrl

Include the header file in any class from which you wish to use the cache:

    #import PhotoCache.h

Example Usage
===========================

Cache a photo:

    NSDictionary *photo = *your photo object*
    NSURL *photoUrl = *your photo's url*
    NSData *photoData = [NSData dataWithContentsOfURL:photoUrl];
    [PhotoCache cachePhoto:photo withData:photoData fromUrl:photoUrl];

Fetch a photo from the cache:

    NSDictionary *photo = *your photo object*
    NSURL *photoUrl = *your photo's url*
    NSData *photoData = [PhotoCache fetchPhotoFromCache:photo fromUrl:photoUrl];
    UIImage *image = [UIImage imageWithData:photoData];
