//
//  ISMapFilterViewController.m
//  iNSite
//
//  Created by Chris Karr on 8/6/16.
//  Copyright © 2016 iNSite AEC Hackathon Team. All rights reserved.
//

#import "ISMapFilterViewController.h"

@interface ISMapFilterViewController ()

@property UITableView * filtersTable;

@property NSArray * pinTypes;
@end

@implementation ISMapFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSPropertyListFormat format;
    self.pinTypes = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pinTypes"
                                                                                                                                     ofType:@"plist"]
                                                                                             options:0
                                                                                               error:NULL]
                                                              options:NSPropertyListImmutable
                                                               format:&format
                                                                error:NULL];

    NSLog(@"PING TYPES: %@", self.pinTypes);
    
    self.filtersTable = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.filtersTable.delegate = self;
    self.filtersTable.dataSource = self;
    self.filtersTable.alwaysBounceVertical = NO;
    
    [self.view addSubview:self.filtersTable];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FilterCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSDictionary * pinType = self.pinTypes[indexPath.row];
    
    cell.textLabel.text = pinType[@"Name"];
    cell.imageView.image = [UIImage imageNamed:pinType[@"Icon Name"]];
    cell.accessoryView = [[UISwitch alloc] init];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.pinTypes.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView * headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 66)];
    
    headerView.backgroundColor = [UIColor colorWithRed:(0xff/255.0) green:(0xa0/255.0) blue:(0x00/255.0) alpha:1.0];

    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(16, 40, tableView.frame.size.width - 32, 14)];
    label.text = NSLocalizedString(@"title_filter_view_controller", nil).uppercaseString;
    label.font = [UIFont boldSystemFontOfSize:14];
    label.textColor = [UIColor whiteColor];

    [headerView addSubview:label];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 66;
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.filtersTable.frame = self.view.bounds;
}


@end
