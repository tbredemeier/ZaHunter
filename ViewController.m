//
//  ViewController.m
//  ZaHunter
//
//  Created by tbredemeier on 5/29/14.
//  Copyright (c) 2014 Mobile Makers Academy. All rights reserved.
//

#import "ViewController.h"
#import "Pizzaria.h"
#import "MapViewController.h"

@interface ViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *myTableView;
@property (strong, nonatomic) IBOutlet UILabel *currentLocationLabel;
@property MapViewController *mapViewController;
@property NSMutableArray *pizzarias;
@property NSTimeInterval elapsedTime;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapViewController = [[self.tabBarController viewControllers] objectAtIndex:1];
    self.pizzarias = [[NSMutableArray alloc]init];
    self.elapsedTime = 0;
    self.currentLocationLabel.text = @"finding current location";
    self.title = @"ETA";
    self.mapViewController.title = @"Map";
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];

}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    for(CLLocation *location in locations)
    {
        if(location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000)
        {
            self.currentLocationLabel.text = @"location found";
            [self reverseGeoCode: location];
            [self.locationManager stopUpdatingLocation];
            break;
        }
    }
}

- (void)reverseGeoCode:(CLLocation *)location
{
    CLGeocoder *geoCoder = [[CLGeocoder alloc]init];
    [geoCoder reverseGeocodeLocation:location
                   completionHandler:^(NSArray *placemarks,
                                       NSError *error)
     {
         CLPlacemark *placemark = placemarks.firstObject;
         NSString *address = [NSString stringWithFormat:@"%@ %@",
                              placemark.subThoroughfare,
                              placemark.thoroughfare];
         self.currentLocationLabel.text = [NSString stringWithFormat:@"Current location: %@", address];
         [self findPizzaNear:location];
     }];
}

- (void)findPizzaNear:(CLLocation *)location
{
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc]init];
    request.naturalLanguageQuery = @"pizza";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(.05, .05));

    MKLocalSearch *search = [[MKLocalSearch alloc]initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response,
                                         NSError *error)
    {
        for (MKMapItem *mapItem in response.mapItems)
        {
            Pizzaria *pizzaria = [[Pizzaria alloc]init];
            pizzaria.mapItem = mapItem;
            pizzaria.distance = [self distanceTo:pizzaria.mapItem.placemark.location];
            [self.pizzarias addObject:pizzaria];
        }
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES];
        [self.pizzarias sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        while(self.pizzarias.count > 4)
            [self.pizzarias removeLastObject];

        self.mapViewController.pizzarias = self.pizzarias;

        MKMapItem *startMapItem = [MKMapItem mapItemForCurrentLocation];
        MKMapItem *endMapItem = nil;
        for(Pizzaria *pizzaria in self.pizzarias)
        {
            if(endMapItem)
                self.elapsedTime += 50 * 60;
            endMapItem = pizzaria.mapItem;
            [self getWalkingTime:startMapItem endMapItem:endMapItem];
            startMapItem = endMapItem;
        }
    }];
}

- (CLLocationDistance)distanceTo:(CLLocation *)location
{
    CLLocation *originLocation = self.locationManager.location;
    CLLocation *destinationLocation = location;
    return [originLocation distanceFromLocation:destinationLocation] / 1609.34;
}

- (void)getWalkingTime:(MKMapItem *)startMapItem
            endMapItem:(MKMapItem *)endMapItem
{
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc]init];
    request.source = startMapItem;
    request.destination = endMapItem;
    request.transportType = 1;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateETAWithCompletionHandler:^(MKETAResponse *response,
                                                    NSError *error)
    {
        self.elapsedTime += response.expectedTravelTime;
        [self.myTableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.pizzarias.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Pizzaria *pizzaria = [self.pizzarias objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MapItemCellID"];
    cell.textLabel.text = pizzaria.mapItem.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2g miles", pizzaria.distance];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView
titleForFooterInSection:(NSInteger)section
{
    if(self.elapsedTime > 0)
        return [NSString stringWithFormat:@"Total elapsed time: %d minutes", ((int)self.elapsedTime) / 60];
    else
        return @"";
}







@end
