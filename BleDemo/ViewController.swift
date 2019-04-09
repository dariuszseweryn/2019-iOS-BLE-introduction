//
//  ViewController.swift
//  BleDemo
//
//  Created by Dariusz Seweryn on 08/04/2019.
//  Copyright © 2019 Polidea. All rights reserved.
//

import UIKit
import RxSwift
import RxBluetoothKit
import CoreBluetooth

class ViewController: UIViewController {
    
    let bleManager = CentralManager(queue: .main)
    let cbuuidAccService = CBUUID(string: "F000AA10-0451-4000-B000-000000000000")
    let cbuuidAccData = CBUUID(string: "F000AA11-0451-4000-B000-000000000000")
    let cbuuidAccConfig = CBUUID(string: "F000AA12-0451-4000-B000-000000000000")
    var disposable: Disposable? = nil
    
    enum DeviceCharacteristic: String, CharacteristicIdentifier { // the description of Bluetooth Service and Bluetooth Characteristics that will be used in this application
        
        // Monitoring
        case accData = "F000AA11-0451-4000-B000-000000000000" // uuid of characteristic containing accelerometer data
        case accConfig = "F000AA12-0451-4000-B000-000000000000" // uuid of characteristic configuring accelerometer
        
        var uuid: CBUUID {
            return CBUUID(string: self.rawValue)
        }
        
        //Service to which characteristic belongs
        var service: ServiceIdentifier {
            switch self {
            case .accData, .accConfig:
                return DeviceService.accService
            }
        }
        
        enum DeviceService: String, ServiceIdentifier {
            case accService = "F000AA10-0451-4000-B000-000000000000" // uuid of service containing above characteristics
            
            var uuid: CBUUID {
                return CBUUID(string: self.rawValue)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.disposable = self.bleManager.observeState() // start with observing ble manager state changes
            .startWith(self.bleManager.state) // at the beginning emit the current state
            .filter { $0 == .poweredOn } // wait for the bluetooth to be ready
            .take(1) // when it will be ready this app stops listening for changes from the above
            .flatMap { _ in self.bleManager.scanForPeripherals(withServices: nil) } // on ready start scanning for all devices
            .filter { (sp: ScannedPeripheral) -> Bool in // we are interested only in devices that match our expectation
                print("scanned: \(sp.peripheral.name)")
                return sp.peripheral.name == "TI BLE Sensor Tag" } // the peripheral has to be named appropriately
            .take(1) // when first such device is scanned the above flow gets unsubscribed — scanning is turned off
            .flatMap { $0.peripheral.establishConnection() } // with the scanned peripheral establish a connection
            .flatMap { (cPeripheral: Peripheral) -> Observable<Characteristic> in // when connection is established
                return cPeripheral.writeValue(Data([0x01]), for: DeviceCharacteristic.accConfig, type: .withResponse).asObservable() // turn on the accelerometer on SensorTag one needs to send an appropriate value to the configuration characteristic (the value can be found in the specification of SensorTag site)
                    .flatMap { (_: Characteristic) -> Observable<Characteristic> in // after writing the configuration
                        return cPeripheral.observeValueUpdateAndSetNotification(for: DeviceCharacteristic.accData) // subscribe to updates of the accelerometer data characteristic
                }
            }
            .subscribe(onNext: { (c: Characteristic) in
                let value = c.value as! Data // with each notification print the results
                print("Data \(value[0]) \(value[1]) \(value[2])") // to get an appropriate accelerometer value one would need to apply a transformation according to SensorTag specification which is outside of this demo
                
            }, onError: { print("Whoops! \($0)") }, onCompleted: nil, onDisposed: nil) // in case of any error print it
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.disposable?.dispose() // when the application is sent to background the whole above flow is canceled
    }
}

