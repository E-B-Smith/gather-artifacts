/**
 @file          GAJUnit.h
 @package       gather-artifacts
 @brief         Create JUnit xml from Xcode build result plist.

 @author        Edward Smith
 @date          September 22, 2019
 @copyright     -©-  Copyright © 2019 Edward Smith. All rights reserved. -©-
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Creates a junit xml file.
 @param input   Name of the input directory to find the result plist.
 @param output  Name of the output xml file to create. A full pathname is expected.
 @return        Returns a sysexit code indicating success or failure.
*/
NSError*_Nullable GAJUnitWithInput(NSString*input, NSString*output);

NS_ASSUME_NONNULL_END
