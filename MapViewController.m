//
//  MapViewController.m
//  ZaHunter
//
//  Created by tbredemeier on 5/29/14.
//  Copyright (c) 2014 Mobile Makers Academy. All rights reserved.
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>
#import "Pizzaria.h"

@interface MapViewController () <MKMapViewDelegate>
@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self makePins];
}

- (void)makePins
{
    NSMutableArray *pins = [[NSMutableArray alloc]init];
    for(Pizzaria *pizzaria in self.pizzarias)
    {
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
        annotation.coordinate = pizzaria.mapItem.placemark.location.coordinate;
        annotation.title = pizzaria.mapItem.name;
        [pins addObject:annotation];
        [self.mapView addAnnotation:annotation];
    }
//    MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
//    annotation.coordinate = self.mapView.userLocation.coordinate;
//    [pins addObject:annotation];
    [self.mapView showAnnotations:pins animated:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:nil];
    pin.canShowCallout = YES;
    pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    UIImage *image = [UIImage imageNamed:@"pizzaslice"];
    image = [UIImage imageWithCGImage:[image CGImage] scale:20 orientation:UIImageOrientationUp];
    pin.image = image;
    return pin;
}



@end
