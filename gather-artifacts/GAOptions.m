/**
 @file          GAOptions.m
 @package       gather-artifacts
 @brief         Command line arguments.

 @author        Edward Smith
 @date          September 22, 2019
 @copyright     -©-  Copyright © 2019 Edward Smith. All rights reserved. -©-
*/

#import "GAOptions.h"
#include <getopt.h>

@interface GAOptions ()
@end

@implementation GAOptions

- (instancetype _Nonnull) init {
    self = [super init];
    if (!self) return self;
    self.inputDirectory = @".";
    self.outputDirectory = @".";
    return self;
}

+ (instancetype _Nonnull) optionsWithArgc:(int)argc argv:(char*const _Nullable[_Nullable])argv {
    __auto_type options = [[GAOptions alloc] init];

    static struct option long_options[] = {
        {"help",        no_argument,        NULL, 'h'},
        {"input",       required_argument,  NULL, 'i'},
        {"output",      required_argument,  NULL, 'o'},
        {"verbose",     no_argument,        NULL, 'v'},
        {"version",     no_argument,        NULL, 'V'},
        {0, 0, 0, 0}
    };

    int c = 0;
    do {
        int option_index = 0;
        c = getopt_long(argc, argv, "hi:o:vV", long_options, &option_index);
        switch (c) {
        case -1:    break;
        case 'h':   options.showHelp = YES; break;
        case 'i':   options.inputDirectory = [self.class stringFromParameter]; break;
        case 'o':   options.outputDirectory = [self.class stringFromParameter]; break;
        case 'v':   options.verbosity++; break;
        case 'V':   options.showVersion = YES; break;
        default:    options.badOptionsError = YES; break;
        }
    } while (c != -1 && !options.badOptionsError);

    return options;
}

+ (NSString*) stringFromParameter {
    return [NSString stringWithCString:optarg encoding:NSUTF8StringEncoding];
}

+ (NSString*) helpString {
    return
@"usage: gather-artifacts [-hvV] [ -i <input-directory> ] [ -o <output-directory> ]\n"
"\n"
"    -h --help      Show help.\n"
"    -i --input     Input directory in which to search for Xcode artifacts.\n"
"    -o --output    Directory for the output files. Default is current directory.\n"
"    -v --verbose   Verbose.\n"
"    -V --version   Show version.\n"
"\n"
"Gathers Xcode test artifacts and create junit and coverage files.\n";
}

@end
