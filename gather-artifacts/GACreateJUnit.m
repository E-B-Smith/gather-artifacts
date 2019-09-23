/**
 @file          GACreateJUnit.m
 @package       gather-artifacts
 @brief         Create JUnit xml from Xcode build result plist.

 @author        Edward Smith
 @date          September 22, 2019
 @copyright     -©-  Copyright © 2019 Edward Smith. All rights reserved. -©-
*/

#import "GACreateJUnit.h"
#import <sysexits.h>
#import "BNCLog.h"

NSError*_Nullable GACreateJUnitWithInputDirectory(
    NSString*_Nonnull input,
    NSString*_Nonnull output
) {
    NSError*error = nil;
    __auto_type filename = [input stringByAppendingPathComponent:@"Result.plist"];
    __auto_type data = [NSData dataWithContentsOfFile:filename options:0 error:&error];
    if (error) return error;

    NSDictionary*plist =
        [NSPropertyListSerialization propertyListWithData:data
            options:NSPropertyListImmutable
            format:nil
            error:&error];
    if (error) return error;

    return nil;
}
