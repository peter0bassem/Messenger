//
//  LocationPickerViewController.swift
//  Messenger
//
//  Created by Peter Bassem on 7/22/20.
//  Copyright © 2020 Peter Bassem. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

final class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    
    private lazy var mapView: MKMapView = {
       let mapView = MKMapView()
        if self.isPickable {
            mapView.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            mapView.addGestureRecognizer(gesture)
        } else {
            // just showing location
            // drop my pin on location
            if let coordinates = self.coordinates {
                let pin = MKPointAnnotation()
                pin.coordinate = coordinates
                mapView.removeAnnotations(mapView.annotations)
                mapView.addAnnotation(pin)
            }
        }
        return mapView
    }()
    
    private var coordinates: CLLocationCoordinate2D?
    private var isPickable = true
    
    init(coordinates: CLLocationCoordinate2D?) {
        self.coordinates = coordinates
        self.isPickable = coordinates == nil
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = isPickable ? "Pick Location" : "Location"
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(didTapSendBarButton(_:)))
        }
        view.addSubview(mapView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.frame = view.bounds
    }
    
    @objc private func didTapSendBarButton(_ sender: UIBarButtonItem) {
        guard let coordinates = self.coordinates else { return }
        completion?(coordinates)
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didTapMap(_ sender: UITapGestureRecognizer) {
        let locationInView = sender.location(in: mapView)
        let coordinates = mapView.convert(locationInView, toCoordinateFrom: mapView)
        self.coordinates = coordinates
        // drop my pin on location
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(pin)
    }
}
