//
//  TableViewController.m
//  EverouSample
//
//  Created by Baintex S.L on 2/6/21.
//

#import "TableViewController.h"

// Frameworks
@import EverouSDK;
@import CoreBluetooth;
@import CoreLocation;

// Views
#import "EverouDeviceCell.h"

NSString* const kEverouUserPrivateAPIKey = @"testing-everou-user-apikey";
NSString* const kAppSharedGroupIdentifier = nil;

@interface TableViewController ()
<CBCentralManagerDelegate, CLLocationManagerDelegate, AutomaticDetectionDelegate>

@property (nonatomic) EverouUser *loggedUser;
@property (nonatomic) NSArray<EverouDevice*> *devices;

@property (nonatomic) CBCentralManager *centralManager;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) id<AutomaticDetectionDelegate> delegate;

@end

@implementation TableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureView];
    
    [self loadData];
}

- (void)configureView
{
    self.title = @"Everou Sample";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadDevices) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.refreshControl;
}

- (void)loadData
{
    [EverouSDK initializeWithAPIKey:kEverouUserPrivateAPIKey
                        sharedGroup:kAppSharedGroupIdentifier
                         completion:^(EverouUser *user, NSError *error)
     {
        if (!error)
        {
            self.loggedUser = user;
            
            [self loadDevices];
        }
    }];
}

- (void)loadDevices
{
    [EverouSDK getDevices:^(NSArray<EverouDevice*> *devices, NSError *error)
     {
        if (!error) {
            self.devices = devices;
        }
        else {
            NSLog(@"Error fetching devices %@", error);
        }
        
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
        
        [self startAutomaticDetection];
    }];
}

- (void)startAutomaticDetection
{
    [EverouSDK startAutomaticDeviceDetection:self
                                  completion:^(NSError* _Nullable error)
     {
        if (error)
        {
            NSLog(@"Error starting automatic detection: %@", error);
            
            switch (error.code) {
                // APIErrorCodeBLEPermissions = 6001,
                case 6001:
                    [self askBluetoothPermissions];
                    break;
                // APIErrorCodeLocatingPermissions = 6002,
                case 6002:
                    [self askLocationPermissions];
                    break;
                default:
                    break;
            }
        }
        else {
            NSLog(@"Started automatic detection!");
        }
    }];
}

#pragma mark - Table view helpers

- (IBAction)toggleDevice:(id)sender
{
    UIButton *button = (UIButton*)sender;
    EverouDevice *device = self.devices[button.tag];
    
    [EverouSDK toggleDevice:device completion:^(NSError *error)
     {
        if (!error)
        {
            NSLog(@"Toggled device %@", device.name);
        }
        else
        {
            NSLog(@"Error toggling device %@", error);
            
            // APIErrorCodeBLEPermissions = 6001,
            if (error.code == 6001)
            {
                [self askBluetoothPermissions];
            }
        }
    }];
}

- (void)askBluetoothPermissions
{
    NSLog(@"Requesting BLE permissions");
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:dispatch_get_main_queue()
                                                             options:@{CBCentralManagerOptionShowPowerAlertKey:@(NO)}];
}

- (void)askLocationPermissions
{
    NSLog(@"Requesting location permissions");
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.activityType = CLActivityTypeOther;
    self.locationManager.delegate = self;
    self.locationManager.allowsBackgroundLocationUpdates = NO;
    
    [self.locationManager requestAlwaysAuthorization];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.loggedUser) {
        return [NSString stringWithFormat:@"%@ - %@", self.loggedUser.name, self.loggedUser.email];
    }
    else return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EverouDevice *device = self.devices[indexPath.row];
    
    EverouDeviceCell *cell = (EverouDeviceCell*)[tableView dequeueReusableCellWithIdentifier:@"EverouDeviceCell" forIndexPath:indexPath];
    cell.nameLabel.text = device.name;
    cell.roomLabel.text = device.uid;
    cell.toggleButton.tag = indexPath.row;
    
    return cell;
}

#pragma mark - Automatic Detection delegate

- (void)didDetectDevice:(NSString*)deviceUid error:(NSError* _Nullable)error
{
    NSLog(@"Detected device %@ error: %@", deviceUid, error);
}

- (void)didToggleDevice:(NSString*)deviceUid
{
    NSLog(@"Toggled device %@", deviceUid);
}

#pragma mark - CBCentral Manager

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBManagerStateUnauthorized:
            switch (CBManager.authorization) {
                case CBManagerAuthorizationAllowedAlways:
                    NSLog(@"BLE authorized");
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

@end
