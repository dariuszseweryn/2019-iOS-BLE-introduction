# Introduction app for BLE on iOS

This application is an introduction to BLE on iOS using RxBluetoothKit library. It aims to show how little is needed to successfully scan, 
connect and get some data from a BLE peripheral. In this situation the peripheral is a Texas Instruments SensorTag CC2541.

This application was successfully build using XCode 10.1 — as for this moment it is not compatible with XCode 10.2 which assumes usage of
Swift 5. RxBluetoothKit is not yet compatible with Swift 5.

All connection code is in `BluetoothDemo/ViewController.swift`
