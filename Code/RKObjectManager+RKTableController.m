//
//  RKObjectManager+RKTableController.m
//  RestKit
//
//  Created by Blake Watters on 2/23/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKObjectManager+RKTableController.h"

#if TARGET_OS_IPHONE

#import "RKTableController.h"
#import "RKFetchedResultsTableController.h"
#import "RKManagedObjectStore.h"

@implementation RKObjectManager (RKTableController)

- (RKTableController *)tableControllerForTableViewController:(UITableViewController *)tableViewController
{
    RKTableController *tableController = [RKTableController tableControllerForTableViewController:tableViewController];
    tableController.responseDescriptors = self.responseDescriptors;
    tableController.operationQueue = self.operationQueue;
    return tableController;
}

- (RKTableController *)tableControllerWithTableView:(UITableView *)tableView forViewController:(UIViewController *)viewController
{
    RKTableController *tableController = [RKTableController tableControllerWithTableView:tableView forViewController:viewController];
    tableController.responseDescriptors = self.responseDescriptors;
    tableController.operationQueue = self.operationQueue;
    return tableController;
}

- (RKFetchedResultsTableController *)fetchedResultsTableControllerForTableViewController:(UITableViewController *)tableViewController
{
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerForTableViewController:tableViewController];
    tableController.responseDescriptors = self.responseDescriptors;
    tableController.managedObjectContext = self.managedObjectStore.persistentStoreManagedObjectContext;
    tableController.managedObjectCache = self.managedObjectStore.managedObjectCache;
    tableController.operationQueue = self.operationQueue;
    tableController.fetchRequestBlocks = self.fetchRequestBlocks;
    return tableController;
}

- (RKFetchedResultsTableController *)fetchedResultsTableControllerWithTableView:(UITableView *)tableView forViewController:(UIViewController *)viewController
{
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerWithTableView:tableView forViewController:viewController];
    tableController.responseDescriptors = self.responseDescriptors;
    tableController.managedObjectContext = self.managedObjectStore.persistentStoreManagedObjectContext;
    tableController.managedObjectCache = self.managedObjectStore.managedObjectCache;
    tableController.operationQueue = self.operationQueue;
    tableController.fetchRequestBlocks = self.fetchRequestBlocks;
    return tableController;
}

@end

#endif
