/**
 @file          GACommon.h
 @package       gather-artifacts
 @brief         Common functions.

 @author        Edward Smith
 @date          September 23, 2019
 @copyright     -©-  Copyright © 2019 Edward Smith. All rights reserved. -©-
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSError*_Nullable NSErrorWithCodeFileLine(NSInteger code, NSString*filename, NSInteger linenumber);

#define NSErrorWithCode(code) \
    NSErrorWithCodeFileLine(code, @__FILE__, __LINE__)

FOUNDATION_EXPORT NSError*_Nullable GAWritef(NSFileHandle*file, NSString*format, ...) NS_FORMAT_FUNCTION(2,3);

FOUNDATION_EXPORT NSString* GAProjectFilename(NSString*filename);

NS_ASSUME_NONNULL_END
