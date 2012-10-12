//
//  RKFetchedResultsTableController.h
//  RestKit
//
//  Created by Blake Watters on 8/2/11.
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

#import <CoreData/CoreData.h>
#import "RKAbstractTableController.h"
#import "RKManagedObjectCaching.h"

typedef UIView *(^RKFetchedResultsTableViewViewForHeaderInSectionBlock)(NSUInteger sectionIndex, NSString *sectionTitle);
typedef void (^RKFetchedResultsTableViewScrollViewBlock)(UIScrollView *scrollView);

@class RKFetchedResultsTableController;
@protocol RKFetchedResultsTableControllerDelegate <RKAbstractTableControllerDelegate>

@optional

// Sections
- (void)tableController:(RKFetchedResultsTableController *)tableController didInsertSectionAtIndex:(NSUInteger)sectionIndex;
- (void)tableController:(RKFetchedResultsTableController *)tableController didDeleteSectionAtIndex:(NSUInteger)sectionIndex;

@end

/**
 Instances of RKFetchedResultsTableController provide an interface for driving a UITableView
 */
@interface RKFetchedResultsTableController : RKAbstractTableController <NSFetchedResultsControllerDelegate>

// Delegate
@property (nonatomic, weak) id<RKFetchedResultsTableControllerDelegate> delegate;

// Fetched Results Controller
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) id<RKManagedObjectCaching> managedObjectCache;
@property (nonatomic, strong) NSArray *fetchRequestBlocks; // An array of blocks for determining the fetch request for a URL
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSFetchRequest *fetchRequest;
@property (nonatomic, strong) NSPredicate *predicate;
@property (nonatomic, strong) NSArray *sortDescriptors;
@property (nonatomic, copy) NSString *sectionNameKeyPath;
@property (nonatomic, copy) NSString *cacheName;
@property (nonatomic, strong, readonly) NSFetchedResultsController *fetchedResultsController;

// Configuring Headers and Sections
@property (nonatomic, assign) CGFloat heightForHeaderInSection;
@property (nonatomic, assign) BOOL showsSectionIndexTitles;

// Sorting
@property (nonatomic, assign) SEL sortSelector;
@property (nonatomic, copy) NSComparator sortComparator;

// UIScrollViewDelegate blocks
@property (nonatomic, copy) RKFetchedResultsTableViewScrollViewBlock onScrollViewDidScroll;
@property (nonatomic, copy) RKFetchedResultsTableViewScrollViewBlock onScrollViewWillBeginDragging;
@property (nonatomic, copy) RKFetchedResultsTableViewScrollViewBlock onScrollViewDidScrollToTop;
@property (nonatomic, copy) RKFetchedResultsTableViewScrollViewBlock onScrollViewWillBeginDecelerating;
@property (nonatomic, copy) RKFetchedResultsTableViewScrollViewBlock onScrollViewDidEndDecelerating;

//- (void)setObjectMappingForClass:(Class)objectClass; // TODO: Kill this API... mapping descriptors will cover use case.
- (void)loadTable;
//- (void)loadTableWithFetchRequest:(NSFetchRequest *)fetchRequest;
@end
