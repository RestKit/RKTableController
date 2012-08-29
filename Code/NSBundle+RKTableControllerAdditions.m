//
//  NSBundle+RKTableControllerAdditions.m
//  RestKit
//
//  Created by Blake Watters on 8/28/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "NSBundle+RKTableControllerAdditions.h"
#import "UIImage+RKAdditions.h"
#import "RKLog.h"

@implementation NSBundle (RKTableControllerAdditions)

+ (NSBundle *)restKitResourcesBundle
{
    static BOOL searchedForBundle = NO;

    if (! searchedForBundle) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"RestKitResources" ofType:@"bundle"];
        searchedForBundle = YES;
        NSBundle *resourcesBundle = [NSBundle bundleWithPath:path];
        if (! resourcesBundle) RKLogWarning(@"Unable to find RestKitResources.bundle in your project. Did you forget to add it?");
        return resourcesBundle;
    }

    return [NSBundle bundleWithIdentifier:@"org.restkit.RestKitResources"];
}

- (UIImage *)imageWithContentsOfResource:(NSString *)name withExtension:(NSString *)extension
{
    NSString *resourcePath = [self pathForResource:name ofType:extension];
    if (! resourcePath) {
        RKLogWarning(@"%@ Failed to locate Resource with name '%@' and extension '%@': File Not Found.", self, resourcePath, extension);
        return nil;
    }

    return [UIImage imageWithContentsOfResolutionIndependentFile:resourcePath];
}

@end
