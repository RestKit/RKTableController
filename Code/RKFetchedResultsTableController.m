//
//  RKFetchedResultsTableController.m
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

#import "RKFetchedResultsTableController.h"
#import "RKAbstractTableController_Internals.h"
#import "RKManagedObjectStore.h"
#import "RKMappingOperation.h"
#import "RKEntityMapping.h"
#import "RKLog.h"
#import "RKManagedObjectRequestOperation.h"
#import "NSEntityDescription+RKAdditions.h"
#import "RKObjectManager.h"

// Define logging component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitUI

@interface RKFetchedResultsTableController ()

@property (nonatomic, assign) BOOL isEmptyBeforeAnimation;
@property (nonatomic, strong, readwrite) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSArray *arraySortedFetchedObjects;
@property (nonatomic, assign, getter = hasRequestChanged) BOOL requestChanged;

- (BOOL)performFetch:(NSError **)error;
- (void)updateSortedArray;
@end

@implementation RKFetchedResultsTableController

@dynamic delegate;

- (void)dealloc
{
    self.fetchedResultsController.delegate = nil;
}

- (void)setRequest:(NSURLRequest *)request
{
    if (request != self.request) self.requestChanged = YES;
    [super setRequest:request];
}

#pragma mark - Helpers

- (BOOL)performFetch:(NSError **)error
{
    NSAssert(self.fetchedResultsController, @"Cannot perform a fetch: self.fetchedResultsController is nil.");
    
    [NSFetchedResultsController deleteCacheWithName:self.fetchedResultsController.cacheName];    
    BOOL success = [self.fetchedResultsController performFetch:error];
    if (!success) {
        RKLogError(@"performFetch failed with error: %@", [*error localizedDescription]);
        return NO;
    } else {
        RKLogTrace(@"performFetch completed successfully");
        for (NSUInteger index = 0; index < [self sectionCount]; index++) {
            if ([self.delegate respondsToSelector:@selector(tableController:didInsertSectionAtIndex:)]) {
                [self.delegate tableController:self didInsertSectionAtIndex:index];
            }

            if ([self.delegate respondsToSelector:@selector(tableController:didInsertObject:atIndexPath:)]) {
                for (NSUInteger row = 0; row < [self numberOfRowsInSection:index]; row++) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:index];
                    id object = [self objectForRowAtIndexPath:indexPath];
                    [self.delegate tableController:self didInsertObject:object atIndexPath:indexPath];
                }
            }
        }
    }

    return YES;
}

- (void)updateSortedArray
{
    self.arraySortedFetchedObjects = nil;

    if (self.sortSelector || self.sortComparator) {
        if (self.sortSelector) {
            self.arraySortedFetchedObjects = [self.fetchedResultsController.fetchedObjects sortedArrayUsingSelector:self.sortSelector];
        } else if (self.sortComparator) {
            self.arraySortedFetchedObjects = [self.fetchedResultsController.fetchedObjects sortedArrayUsingComparator:self.sortComparator];
        }

        NSAssert(self.arraySortedFetchedObjects.count == self.fetchedResultsController.fetchedObjects.count,
                 @"sortSelector or sortComparator sort resulted in fewer objects than expected");
    }
}

- (NSUInteger)headerSectionIndex
{
    return 0;
}

- (BOOL)isHeaderSection:(NSUInteger)section
{
    return (section == [self headerSectionIndex]);
}

- (BOOL)isHeaderRow:(NSUInteger)row
{
    BOOL isHeaderRow = NO;
    NSUInteger headerItemCount = [self.headerItems count];
    if ([self isEmpty] && self.emptyItem) {
        isHeaderRow = (row > 0 && row <= headerItemCount);
    } else {
        isHeaderRow = (row < headerItemCount);
    }
    return isHeaderRow;
}

- (NSUInteger)footerSectionIndex
{
    return ([self sectionCount] - 1);
}

- (BOOL)isFooterSection:(NSUInteger)section
{
    return (section == [self footerSectionIndex]);
}

- (BOOL)isFooterRow:(NSUInteger)row
{
    NSUInteger sectionIndex = ([self sectionCount] - 1);
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:sectionIndex];
    NSUInteger firstFooterIndex = [sectionInfo numberOfObjects];
    if (sectionIndex == 0) {
        firstFooterIndex += (![self isEmpty] || self.showsHeaderRowsWhenEmpty) ? [self.headerItems count] : 0;
        firstFooterIndex += ([self isEmpty] && self.emptyItem) ? 1 : 0;
    }
    
    return row >= firstFooterIndex;
}

- (BOOL)isHeaderIndexPath:(NSIndexPath *)indexPath
{
    return ((! [self isEmpty] || self.showsHeaderRowsWhenEmpty) &&
            [self.headerItems count] > 0 &&
            [self isHeaderSection:indexPath.section] &&
            [self isHeaderRow:indexPath.row]);
}

- (BOOL)isFooterIndexPath:(NSIndexPath *)indexPath
{
    return ((! [self isEmpty] || self.showsFooterRowsWhenEmpty) &&
            [self.footerItems count] > 0 &&
            [self isFooterSection:indexPath.section] &&
            [self isFooterRow:indexPath.row]);
}

- (BOOL)isEmptySection:(NSUInteger)section
{
    return (section == 0);
}

- (BOOL)isEmptyRow:(NSUInteger)row
{
    return (row == 0);
}

- (BOOL)isEmptyItemIndexPath:(NSIndexPath *)indexPath
{
    return ([self isEmpty] && self.emptyItem &&
            [self isEmptySection:indexPath.section] &&
            [self isEmptyRow:indexPath.row]);
}

- (NSIndexPath *)emptyItemIndexPath
{
    return [NSIndexPath indexPathForRow:0 inSection:0];
}

- (NSIndexPath *)fetchedResultsIndexPathForIndexPath:(NSIndexPath *)indexPath
{
    if (([self isEmpty] && self.emptyItem &&
         [self isEmptySection:indexPath.section] &&
         ! [self isEmptyRow:indexPath.row]) ||
        ((! [self isEmpty] || self.showsHeaderRowsWhenEmpty) &&
         [self.headerItems count] > 0 &&
        [self isHeaderSection:indexPath.section] &&
        ! [self isHeaderRow:indexPath.row])) {
            NSUInteger adjustedRowIndex = indexPath.row;
            if (![self isEmpty] || self.showsHeaderRowsWhenEmpty) {
                adjustedRowIndex -= [self.headerItems count];
            }
            adjustedRowIndex -= ([self isEmpty] && self.emptyItem) ? 1 : 0;
            return [NSIndexPath indexPathForRow:adjustedRowIndex
                                  inSection:indexPath.section];
    }
    return indexPath;
}

- (NSIndexPath *)indexPathForFetchedResultsIndexPath:(NSIndexPath *)indexPath
{
    if (([self isEmpty] && self.emptyItem &&
         [self isEmptySection:indexPath.section] &&
         ! [self isEmptyRow:indexPath.row]) ||
        ((! [self isEmpty] || self.showsHeaderRowsWhenEmpty) &&
         [self.headerItems count] > 0 &&
         [self isHeaderSection:indexPath.section])) {
            NSUInteger adjustedRowIndex = indexPath.row;
            if (![self isEmpty] || self.showsHeaderRowsWhenEmpty) {
                adjustedRowIndex += [self.headerItems count];
            }
            adjustedRowIndex += ([self isEmpty] && self.emptyItem) ? 1 : 0;
            return [NSIndexPath indexPathForRow:adjustedRowIndex
                                      inSection:indexPath.section];
    }
    return indexPath;
}

#pragma mark - Public

- (NSFetchRequest *)fetchRequest
{
    return _fetchRequest ? _fetchRequest : self.fetchedResultsController.fetchRequest;
}

- (id)objectRequestOperationWithRequest:(NSURLRequest *)request
{
    RKManagedObjectRequestOperation *operation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.responseDescriptors];
    operation.managedObjectContext = self.managedObjectContext;
    operation.fetchRequestBlocks = self.fetchRequestBlocks;
    operation.managedObjectCache = self.managedObjectCache;
    return operation;
}

- (void)loadTable
{
    NSAssert(self.fetchRequest || self.request, @"Cannot load a fetch results table without a request or a fetch request");
    NSFetchRequest *fetchRequest = self.fetchRequest;
    if (!self.fetchRequest) {
        RKLogInfo(@"Determining fetch request from blocks for URL: '%@'", self.request.URL);
        for (RKFetchRequestBlock fetchRequestBlock in self.fetchRequestBlocks) {
            fetchRequest = fetchRequestBlock(self.request.URL);
            if (fetchRequest) break;
        }
    }
    
    NSAssert(fetchRequest, @"Failed to find a fetchRequest for URL: %@", self.request.URL);
    self.fetchRequest = fetchRequest;

    if (self.predicate) {
        [fetchRequest setPredicate:self.predicate];
    }
    if (self.sortDescriptors) {
        [fetchRequest setSortDescriptors:self.sortDescriptors];
    }
    
    RKLogTrace(@"Loading fetched results table view from managed object context %@ with fetch request: %@", self.managedObjectContext, fetchRequest);
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:self.managedObjectContext
                                                                                                 sectionNameKeyPath:self.sectionNameKeyPath
                                                                                                          cacheName:self.cacheName];
    self.fetchedResultsController = fetchedResultsController;
    self.fetchedResultsController.delegate = self;

    // Perform the load
    NSError *error;
    [self didStartLoad];
    BOOL success = [self performFetch:&error];
    if (! success) {
        [self didFailLoadWithError:error];
    }
    [self updateSortedArray];
    [self didFinishLoad];
    
    // Load the table view after we have finished the load to ensure the state
    // is accurate when computing the table view data source responses
    [self.tableView reloadData];

    if (!self.objectRequestOperation && self.request && self.hasRequestChanged) {
        self.requestChanged = NO;
        [self loadTableWithRequest:self.request];
    }
}

- (void)setSortSelector:(SEL)sortSelector
{
    NSAssert(self.sectionNameKeyPath == nil, @"Attempted to sort fetchedObjects across multiple sections");
    NSAssert(self.sortComparator == nil, @"Attempted to sort fetchedObjects with a sortSelector when a sortComparator already exists");
    _sortSelector = sortSelector;
}

- (void)setSortComparator:(NSComparator)sortComparator
{
    NSAssert(self.sectionNameKeyPath == nil, @"Attempted to sort fetchedObjects across multiple sections");
    NSAssert(self.sortSelector == nil, @"Attempted to sort fetchedObjects with a sortComparator when a sortSelector already exists");
    _sortComparator = sortComparator;
}

- (void)setSectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    NSAssert(self.sortSelector == nil, @"Attempted to create a sectioned fetchedResultsController when a sortSelector is present");
    NSAssert(self.sortComparator == nil, @"Attempted to create a sectioned fetchedResultsController when a sortComparator is present");
    _sectionNameKeyPath = sectionNameKeyPath;
}

#pragma mark - Managing Sections

- (NSUInteger)sectionCount
{
    return [[self.fetchedResultsController sections] count];
}

- (NSUInteger)rowCount
{
    NSUInteger fetchedItemCount = [[self.fetchedResultsController fetchedObjects] count];
    NSUInteger nonFetchedItemCount = 0;
    if (fetchedItemCount == 0) {
        nonFetchedItemCount += self.emptyItem ? 1 : 0;
        nonFetchedItemCount += self.showsHeaderRowsWhenEmpty ? [self.headerItems count] : 0;
        nonFetchedItemCount += self.showsFooterRowsWhenEmpty ? [self.footerItems count] : 0;
    } else {
        nonFetchedItemCount += [self.headerItems count];
        nonFetchedItemCount += [self.footerItems count];
    }
    return (fetchedItemCount + nonFetchedItemCount);
}

- (NSIndexPath *)indexPathForObject:(id)object
{
    if ([object isKindOfClass:[NSManagedObject class]]) {
        return [self indexPathForFetchedResultsIndexPath:[self.fetchedResultsController indexPathForObject:object]];
    } else if ([object isKindOfClass:[RKTableItem class]]) {
        if ([object isEqual:self.emptyItem]) {
            return ([self isEmpty]) ? [self emptyItemIndexPath] : nil;
        } else if ([self.headerItems containsObject:object]) {
            // Figure out the row number for the object
            NSUInteger objectIndex = [self.headerItems indexOfObject:object];
            NSUInteger row = ([self isEmpty] && self.emptyItem) ? (objectIndex + 1) : objectIndex;
            return [NSIndexPath indexPathForRow:row inSection:[self headerSectionIndex]];
        } else if ([self.footerItems containsObject:object]) {
            NSUInteger footerSectionIndex = [self sectionCount] - 1;
            id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:footerSectionIndex];
            NSUInteger numberOfFetchedResults = sectionInfo.numberOfObjects;
            NSUInteger objectIndex = [self.footerItems indexOfObject:object];
            NSUInteger row = numberOfFetchedResults + objectIndex;
            row += ([self isEmpty] && self.emptyItem) ? 1 : 0;
            if ([self isHeaderSection:footerSectionIndex]) {
                row += [self.headerItems count];
            }

            return [NSIndexPath indexPathForRow:row inSection:footerSectionIndex];
        }
    } else {
        RKLogWarning(@"Asked for indexPath of unsupported object type '%@': %@", [object class], object);
    }
    return nil;
}

- (UITableViewCell *)cellForObject:(id)object
{
    NSIndexPath *indexPath = [self indexPathForObject:object];
    NSAssert(indexPath, @"Failed to find indexPath for object: %@", object);
    return [self.tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSAssert(tableView == self.tableView, @"numberOfSectionsInTableView: invoked with inappropriate tableView: %@", tableView);
    RKLogTrace(@"numberOfSectionsInTableView: %d (%@)", [[self.fetchedResultsController sections] count], [[self.fetchedResultsController sections] valueForKey:@"name"]);
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSAssert(tableView == self.tableView, @"tableView:numberOfRowsInSection: invoked with inappropriate tableView: %@", tableView);
    RKLogTrace(@"%@ numberOfRowsInSection:%d = %d", self, section, self.sectionCount);
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    NSUInteger numberOfRows = [sectionInfo numberOfObjects];

    if ([self isHeaderSection:section]) {
        numberOfRows += (![self isEmpty] || self.showsHeaderRowsWhenEmpty) ? [self.headerItems count] : 0;
        numberOfRows += ([self isEmpty] && self.emptyItem) ? 1 : 0;
    }

    if ([self isFooterSection:section]) {
        numberOfRows += (![self isEmpty] || self.showsFooterRowsWhenEmpty) ? [self.footerItems count] : 0;
    }
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSAssert(tableView == self.tableView, @"tableView:titleForFooterInSection: invoked with inappropriate tableView: %@", tableView);
    return nil;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (tableView.style == UITableViewStylePlain && self.showsSectionIndexTitles) {
        return [_fetchedResultsController sectionIndexTitles];
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (tableView.style == UITableViewStylePlain && self.showsSectionIndexTitles) {
        return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(tableView == self.tableView, @"tableView:commitEditingStyle:forRowAtIndexPath: invoked with inappropriate tableView: %@", tableView);
    if (self.canEditRows && editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObject *managedObject = [self objectForRowAtIndexPath:indexPath];

        NSString *primaryKeyAttributeName = managedObject.entity.primaryKeyAttributeName;
        if ([managedObject valueForKeyPath:primaryKeyAttributeName]) {
            // TODO: This should probably be done via delegation. We are coupled to the shared manager.
            RKLogTrace(@"About to fire a delete request for managedObject: %@", managedObject);
            [[RKObjectManager sharedManager] deleteObject:managedObject path:nil parameters:nil success:nil failure:^(RKObjectRequestOperation *operation, NSError *error) {
                RKLogError(@"Failed to delete managed object deleted by table controller. Error: %@", error);
            }];
        } else {
            RKLogTrace(@"About to locally delete managedObject: %@", managedObject);
            NSManagedObjectContext *managedObjectContext = managedObject.managedObjectContext;
            [managedObjectContext performBlock:^{
                [managedObjectContext deleteObject:managedObject];
                
                NSError *error = nil;
                [managedObjectContext save:&error];
                if (error) {
                    RKLogError(@"Failed to save managedObjectContext after a delete with error: %@", error);
                }
            }];
        }
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destIndexPath
{
    NSAssert(tableView == self.tableView, @"tableView:moveRowAtIndexPath:toIndexPath: invoked with inappropriate tableView: %@", tableView);
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(tableView == self.tableView, @"tableView:canEditRowAtIndexPath: invoked with inappropriate tableView: %@", tableView);
    return self.canEditRows && [self isOnline] && !([self isHeaderIndexPath:indexPath] || [self isFooterIndexPath:indexPath] || [self isEmptyItemIndexPath:indexPath]);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(tableView == self.tableView, @"tableView:canMoveRowAtIndexPath: invoked with inappropriate tableView: %@", tableView);
    return self.canMoveRows && !([self isHeaderIndexPath:indexPath] || [self isFooterIndexPath:indexPath] || [self isEmptyItemIndexPath:indexPath]);
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSAssert(tableView == self.tableView, @"heightForHeaderInSection: invoked with inappropriate tableView: %@", tableView);
    return self.heightForHeaderInSection;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)sectionIndex
{
    NSAssert(tableView == self.tableView, @"heightForFooterInSection: invoked with inappropriate tableView: %@", tableView);
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSAssert(tableView == self.tableView, @"viewForHeaderInSection: invoked with inappropriate tableView: %@", tableView);
    if (self.onViewForHeaderInSection) {
        NSString *sectionTitle = [self tableView:self.tableView titleForHeaderInSection:section];
        if (sectionTitle) {
            return self.onViewForHeaderInSection(section, sectionTitle);
        }
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)sectionIndex
{
    NSAssert(tableView == self.tableView, @"viewForFooterInSection: invoked with inappropriate tableView: %@", tableView);
    return nil;
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.onScrollViewDidScroll) self.onScrollViewDidScroll(scrollView);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.onScrollViewWillBeginDragging) self.onScrollViewWillBeginDragging(scrollView);
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    if (self.onScrollViewShouldScrollToTop) self.onScrollViewShouldScrollToTop(scrollView);
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    if (self.onScrollViewDidScrollToTop) self.onScrollViewDidScrollToTop(scrollView);
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if (self.onScrollViewWillBeginDecelerating) self.onScrollViewWillBeginDecelerating(scrollView);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.onScrollViewDidEndDecelerating) self.onScrollViewDidEndDecelerating(scrollView);
}

#pragma mark - Cell Mappings

- (id)objectForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isEmptyItemIndexPath:indexPath]) {
        return self.emptyItem;
    } else if ([self isHeaderIndexPath:indexPath]) {
        NSUInteger row = ([self isEmpty] && self.emptyItem) ? (indexPath.row - 1) : indexPath.row;
        return [self.headerItems objectAtIndex:row];
    } else if ([self isFooterIndexPath:indexPath]) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:indexPath.section];
        NSUInteger footerRow = (indexPath.row - sectionInfo.numberOfObjects);
        if (indexPath.section == 0) {
            footerRow -= (![self isEmpty] || self.showsHeaderRowsWhenEmpty) ? [self.headerItems count] : 0;
            footerRow -= ([self isEmpty] && self.emptyItem) ? 1 : 0;
        }
        return [self.footerItems objectAtIndex:footerRow];

    } else if (self.sortSelector || self.sortComparator) {
        return [self.arraySortedFetchedObjects objectAtIndex:[self fetchedResultsIndexPathForIndexPath:indexPath].row];
    }
    
    NSIndexPath *fetchedResultsIndexPath = [self fetchedResultsIndexPathForIndexPath:indexPath];
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:fetchedResultsIndexPath.section];
    if (fetchedResultsIndexPath.row < [sectionInfo numberOfObjects]) {
        return [self.fetchedResultsController objectAtIndexPath:fetchedResultsIndexPath];
    } else {
        return nil;
    }
}

#pragma mark - KVO & Model States

- (BOOL)isConsideredEmpty
{
    NSUInteger fetchedObjectsCount = [[_fetchedResultsController fetchedObjects] count];
    BOOL isEmpty = (fetchedObjectsCount == 0);
    RKLogTrace(@"Determined isEmpty = %@. fetchedObjects count = %d", isEmpty ? @"YES" : @"NO", fetchedObjectsCount);
    return isEmpty;
}

#pragma mark - NSFetchedResultsControllerDelegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    RKLogTrace(@"Beginning updates for fetchedResultsController (%@). Current section count = %d (URL: %@)", controller, [[controller sections] count], self.request.URL);

    if (self.sortSelector) return;

    [self.tableView beginUpdates];
    self.isEmptyBeforeAnimation = [self isEmpty];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{

    if (_sortSelector) return;

    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];

            if ([self.delegate respondsToSelector:@selector(tableController:didInsertSectionAtIndex:)]) {
                [self.delegate tableController:self didInsertSectionAtIndex:sectionIndex];
            }
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];

            if ([self.delegate respondsToSelector:@selector(tableController:didDeleteSectionAtIndex:)]) {
                [self.delegate tableController:self didDeleteSectionAtIndex:sectionIndex];
            }
            break;

        default:
            RKLogTrace(@"Encountered unexpected section changeType: %d", type);
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{

    if (_sortSelector) return;

    NSIndexPath *adjIndexPath = [self indexPathForFetchedResultsIndexPath:indexPath];
    NSIndexPath *adjNewIndexPath = [self indexPathForFetchedResultsIndexPath:newIndexPath];

    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:adjNewIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:adjIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:adjIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:adjIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:adjNewIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;

        default:
            RKLogTrace(@"Encountered unexpected object changeType: %d", type);
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    RKLogTrace(@"Ending updates for fetchedResultsController (%@). New section count = %d (URL: %@)",
               controller, [[controller sections] count], self.request.URL);
    if (self.emptyItem && ![self isEmpty] && _isEmptyBeforeAnimation) {
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[self emptyItemIndexPath]]
                              withRowAnimation:UITableViewRowAnimationFade];
    }

    [self updateSortedArray];

    if (self.sortSelector) {
        [self.tableView reloadData];
    } else {
        [self.tableView endUpdates];
    }

    [self didFinishLoad];
}

#pragma mark - UITableViewDataSource methods

- (NSUInteger)numberOfRowsInSection:(NSUInteger)index
{
    return [self tableView:self.tableView numberOfRowsInSection:index];
}

@end
