//
//  RKTableViewCellMapping.m
//  RestKit
//
//  Created by Blake Watters on 8/4/11.
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

#import "RKTableViewCellMapping.h"
#import "RKLog.h"

// Define logging component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitUI

@interface RKTableViewCellMapping ()
@property (nonatomic, strong) NSMutableArray *mutablePrepareCellBlocks;
@end

@implementation RKTableViewCellMapping

@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize style = _style;
@synthesize accessoryType = _accessoryType;
@synthesize selectionStyle = _selectionStyle;
@synthesize onSelectCellForObjectAtIndexPath = _onSelectCellForObjectAtIndexPath;
@synthesize onSelectCell = _onSelectCell;
@synthesize onCellWillAppearForObjectAtIndexPath = _onCellWillAppearForObjectAtIndexPath;
@synthesize heightOfCellForObjectAtIndexPath = _heightOfCellForObjectAtIndexPath;
@synthesize onTapAccessoryButtonForObjectAtIndexPath = _onTapAccessoryButtonForObjectAtIndexPath;
@synthesize titleForDeleteButtonForObjectAtIndexPath = _titleForDeleteButtonForObjectAtIndexPath;
@synthesize editingStyleForObjectAtIndexPath = _editingStyleForObjectAtIndexPath;
@synthesize targetIndexPathForMove = _targetIndexPathForMove;
@synthesize rowHeight = _rowHeight;
@synthesize deselectsRowOnSelection = _deselectsRowOnSelection;
@synthesize managesCellAttributes = _managesCellAttributes;
@synthesize mutablePrepareCellBlocks = _mutablePrepareCellBlocks;

+ (id)cellMapping
{
    return [self mappingForClass:[UITableViewCell class]];
}

+ (id)cellMappingForReuseIdentifier:(NSString *)reuseIdentifier
{
    RKTableViewCellMapping *cellMapping = [self cellMapping];
    cellMapping.reuseIdentifier = reuseIdentifier;
    return cellMapping;
}

+ (id)defaultCellMapping
{
    RKTableViewCellMapping *cellMapping = [self cellMapping];
    [cellMapping addDefaultMappings];
    return cellMapping;
}

+ (id)cellMappingUsingBlock:(void (^)(RKTableViewCellMapping *))block
{
    RKTableViewCellMapping *cellMapping = [self cellMapping];
    block(cellMapping);
    return cellMapping;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.cellClass = [UITableViewCell class];
        self.style = UITableViewCellStyleDefault;
        self.managesCellAttributes = NO;
        _accessoryType = UITableViewCellAccessoryNone;
        _selectionStyle = UITableViewCellSelectionStyleBlue;
        self.rowHeight = 44;
        self.deselectsRowOnSelection = YES;
        self.mutablePrepareCellBlocks = [NSMutableArray array];
    }

    return self;
}

- (void)addDefaultMappings
{
    [self addAttributeMappingsFromDictionary:@{
     @"text":       @"textLabel.text",
     @"detailText": @"detailTextLabel.text",
     @"image":      @"imageView.image",
     }];
}


- (id)copyWithZone:(NSZone *)zone
{
    RKTableViewCellMapping *copy = [super copyWithZone:zone];
    copy.reuseIdentifier = self.reuseIdentifier;
    copy.style = self.style;
    copy.accessoryType = self.accessoryType;
    copy.selectionStyle = self.selectionStyle;
    copy.onSelectCellForObjectAtIndexPath = self.onSelectCellForObjectAtIndexPath;
    copy.onSelectCell = self.onSelectCell;
    copy.onCellWillAppearForObjectAtIndexPath = self.onCellWillAppearForObjectAtIndexPath;
    copy.heightOfCellForObjectAtIndexPath = self.heightOfCellForObjectAtIndexPath;
    copy.onTapAccessoryButtonForObjectAtIndexPath = self.onTapAccessoryButtonForObjectAtIndexPath;
    copy.titleForDeleteButtonForObjectAtIndexPath = self.titleForDeleteButtonForObjectAtIndexPath;
    copy.editingStyleForObjectAtIndexPath = self.editingStyleForObjectAtIndexPath;
    copy.targetIndexPathForMove = self.targetIndexPathForMove;
    copy.rowHeight = self.rowHeight;

    @synchronized(_mutablePrepareCellBlocks) {
        for (void (^block)(UITableViewCell *) in _mutablePrepareCellBlocks) {
            void (^blockCopy)(UITableViewCell *cell) = [block copy];
            [copy addPrepareCellBlock:blockCopy];
        }
    }

    return copy;
}

- (void)setSelectionStyle:(UITableViewCellSelectionStyle)selectionStyle
{
    self.managesCellAttributes = YES;
    _selectionStyle = selectionStyle;
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType
{
    self.managesCellAttributes = YES;
    _accessoryType = accessoryType;
}

//- (void)setObjectClass:(Class)objectClass
//{
//    NSAssert([objectClass isSubclassOfClass:[UITableViewCell class]], @"Cell mappings can only target classes that inherit from UITableViewCell");
//    [super setObjectClass:objectClass];
//}

//- (void)setCellClass:(Class)cellClass
//{
//    [self setObjectClass:cellClass];
//}

- (NSString *)cellClassName
{
    return NSStringFromClass(self.cellClass);
}

- (void)setCellClassName:(NSString *)cellClassName
{
    self.cellClass = NSClassFromString(cellClassName);
}

- (Class)cellClass
{
    return [self objectClass];
}

- (NSString *)reuseIdentifier
{
    return _reuseIdentifier ? _reuseIdentifier : NSStringFromClass(self.objectClass);
}

#pragma mark - Control Action Helpers

- (void)addPrepareCellBlock:(void (^)(UITableViewCell *cell))block
{
    void (^blockCopy)(UITableViewCell *cell) = [block copy];
    [self.mutablePrepareCellBlocks addObject:blockCopy];
}

- (NSArray *)prepareCellBlocks
{
    return [NSArray arrayWithArray:self.mutablePrepareCellBlocks];
}

@end
