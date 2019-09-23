/**
 @file          GACommandOptions.h
 @package       gather-artifacts
 @brief         Parse command line arguments.

 @author        Edward Smith
 @date          September 22, 2019
 @copyright     -©-  Copyright © 2019 Edward Smith. All rights reserved. -©-
*/

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface GACommandOptions : NSObject
@property (assign) BOOL showHelp;
@property (assign) NSInteger verbosity;
@property (assign) BOOL showVersion;
@property (assign) BOOL badOptionsError;
@property (copy) NSString*_Nonnull inputDirectory;
@property (copy) NSString*_Nonnull outputDirectory;

+ (instancetype _Nonnull) commandLineOptionsWithArgc:(int)argc
    argv:(char*const _Nullable[_Nullable])argv;
+ (NSString*) helpString;
@end

NS_ASSUME_NONNULL_END
