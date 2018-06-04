// Copyright 2018 David Sansome
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "TKMTableModel.h"

@interface TKMTableModelSection : NSObject

@property(nonatomic) NSString *headerTitle;
@property(nonatomic) NSString *footerTitle;
@property(nonatomic) NSMutableArray<id<TKMModelItem> > *items;
@property(nonatomic) NSMutableIndexSet *hiddenItems;

@end

@implementation TKMTableModelSection

- (instancetype)init {
  self = [super init];
  if (self) {
    _items = [NSMutableArray array];
    _hiddenItems = [NSMutableIndexSet indexSet];
  }
  return self;
}

@end

@interface TKMTableModel ()

@property(nonatomic) NSMutableArray<TKMTableModelSection *> *sections;

@end

@implementation TKMTableModel {
  BOOL _isInitialised;
}

- (instancetype)initWithTableView:(UITableView *)tableView {
  self = [super init];
  if (self) {
    _tableView = tableView;
    _sections = [NSMutableArray array];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
  }
  return self;
}

#pragma mark - Hiding items

- (void)setIndexPath:(NSIndexPath *)index isHidden:(BOOL)hidden {
  if (hidden == [self isIndexPathHidden:index]) {
    return;
  }
  
  NSMutableIndexSet *indexSet = _sections[index.section].hiddenItems;
  if (hidden) {
    [indexSet addIndex:index.row];
  } else {
    [indexSet removeIndex:index.row];
  }
  
  if (_isInitialised) {
    if (hidden) {
      [_tableView deleteRowsAtIndexPaths:@[index]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
      [_tableView insertRowsAtIndexPaths:@[index]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
    }
  }
}

- (BOOL)isIndexPathHidden:(NSIndexPath *)index {
  return [_sections[index.section].hiddenItems containsIndex:index.row];
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView
                 cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
  TKMTableModelSection *section = _sections[indexPath.section];
  __block NSInteger row = indexPath.row;
  [section.hiddenItems enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
    if (idx <= row) {
      row ++;
    }
  }];
  
  return [self cellForItem:section.items[row]];
}

- (nonnull UITableViewCell *)cellForItem:(id<TKMModelItem>)item {
  Class cellClass = item.cellClass;
  
  NSString *reuseIdentifier;
  if ([item respondsToSelector:@selector(cellReuseIdentifier)]) {
    reuseIdentifier = [item cellReuseIdentifier];
  } else {
    reuseIdentifier = @(object_getClassName(cellClass));
  }
  
  TKMModelCell *cell = [_tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if (!cell) {
    if ([item respondsToSelector:@selector(createCell)]) {
      cell = [item createCell];
    } else {
      cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault
                              reuseIdentifier:reuseIdentifier];
    }
  }
  
  [cell updateWithItem:item];
  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return _sections[section].headerTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  return _sections[section].footerTitle;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  _isInitialised = YES;
  return _sections.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  TKMTableModelSection *s = _sections[section];
  return s.items.count - s.hiddenItems.count;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  TKMModelCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  [cell didSelectCell];
}

@end

@implementation TKMMutableTableModel

- (void)addSection {
  [self addSection:nil footer:nil];
}

- (void)addSection:(NSString *)title {
  [self addSection:title footer:nil];
}

- (void)addSection:(NSString *)title footer:(NSString *)footer {
  TKMTableModelSection *section = [[TKMTableModelSection alloc] init];
  section.headerTitle = title;
  section.footerTitle = footer;
  [self.sections addObject:section];
}

- (NSIndexPath *)addItem:(id<TKMModelItem>)item {
  [self.sections.lastObject.items addObject:item];
  return [NSIndexPath indexPathForRow:self.sections.lastObject.items.count - 1
                            inSection:self.sections.count - 1];
}

- (NSIndexPath *)addItem:(id<TKMModelItem>)item hidden:(bool)hidden {
  NSIndexPath *indexPath = [self addItem:item];
  if (hidden) {
    [self setIndexPath:indexPath isHidden:YES];
  }
  return indexPath;
}

- (void)reloadTable {
  [self.tableView reloadData];
}

@end