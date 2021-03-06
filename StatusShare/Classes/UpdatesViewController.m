//
//  UpdatesViewController.m
//  StatusShare
//
//  Copyright 2013 Kinvey, Inc.
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


#import "UpdatesViewController.h"
#import <KinveyKit/KinveyKit.h>

#import "StatusShareUpdate.h"
#import "UpdateCell.h"

#import "AuthorViewController.h"

#import "GravatarStore.h"
#import "UIColor+KinveyHelpers.h"

@implementation UpdatesCell
@end

@interface UpdatesViewController ()
@property (nonatomic, retain) NSArray* updates;
@property (nonatomic, retain) KCSCachedStore* updateStore;
@property (nonatomic, retain) UILabel* noItemsLabel;

- (void) updateList;
@end

@implementation UpdatesViewController
@synthesize updates;
@synthesize updateStore;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundColor = [UIColor colorWithIntRed:220 green:220 blue:220];
    
    KCSCollection* collection = [KCSCollection collectionFromString:@"Updates" ofClass:[StatusShareUpdate class]];
    self.updateStore = [KCSLinkedAppdataStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection, KCSStoreKeyResource, [NSNumber numberWithInt:KCSCachePolicyBoth], KCSStoreKeyCachePolicy, nil]];
    
    self.noItemsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0., 0., 1., 1.)];
    self.noItemsLabel.textColor = [UIColor darkGrayColor];
    self.noItemsLabel.shadowColor = [UIColor whiteColor];
    self.noItemsLabel.shadowOffset = CGSizeMake(0., 1.);
    self.noItemsLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.noItemsLabel];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(startCompose:)];
    UIBarButtonItem* logoutButton = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Logout", @"Logout button") style:UIBarButtonItemStylePlain target:self action:@selector(logout)];
    self.navigationItem.leftBarButtonItem = logoutButton;
    
    [self updateList];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (StatusShareUpdate*) updateAtIndex:(NSUInteger)index
{
    return [self.updates objectAtIndex:index];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[AuthorViewController class]]) {
        NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];
        StatusShareUpdate* update = [self updateAtIndex:indexPath.row];
        
        [segue.destinationViewController setAuthor:[update.meta creatorId]];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.updates == nil ? 0 : [self.updates count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 48. + 16. + ([[self.updates objectAtIndex:indexPath.row] attachment] != nil ? 250. : 0.);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UpdateCell *thisCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!thisCell) {
        
        thisCell = [[UpdateCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    StatusShareUpdate* update = [self updateAtIndex:indexPath.row];
    [thisCell setUpdate:update];
    
   
    return thisCell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"segueToAuthor" sender:tableView];
}

#pragma mark - Text Field
- (BOOL) textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)refresh
{
    [self updateList];
}

#pragma mark - Compose
- (void) startCompose:(id)sender
{
    [self performSegueWithIdentifier:@"coverWithWrite" sender:sender];
}

#pragma mark - Kinvey Methods

- (void) updateList
{
    KCSQuery* query = [KCSQuery query];
    KCSQuerySortModifier* sortByDate = [[KCSQuerySortModifier alloc] initWithField:@"userDate" inDirection:kKCSDescending];
    [query addSortModifier:sortByDate]; //sort the return by the date field
    [query setLimitModifer:[[KCSQueryLimitModifier alloc] initWithLimit:10]]; //just get back 10 results
    [updateStore queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        //        [self performSelector:@selector(stopLoading) withObject:nil afterDelay:1.0]; //too fast transition feels weird
        [self.refreshControl endRefreshing];
        if (objectsOrNil) {
            self.updates = objectsOrNil;
            [self.tableView reloadData];
            if (objectsOrNil.count == 0) {
                self.noItemsLabel.text = NSLocalizedString(@"No Status Updates Found.", nil);
                [self.noItemsLabel sizeToFit];
                self.noItemsLabel.center = self.view.center;
                self.noItemsLabel.hidden = NO;
            } else {
                self.noItemsLabel.hidden = YES;
            }
        }
    } withProgressBlock:nil];
}

- (void) logout
{
    self.updates = [NSArray array]; //clear array so that the previous user's data is cached if a different user logins in immediately
    [[KCSUser activeUser] logout];
    [self.navigationController popToRootViewControllerAnimated:YES];
}


@end
