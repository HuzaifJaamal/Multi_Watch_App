package com.example.multi_watch_app.utils;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Handler;
import android.content.Intent;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.example.multi_watch_app.adapter.CustomLogAdapter;
import com.inuker.bluetooth.library.Code;
import com.inuker.bluetooth.library.Constants;
import com.inuker.bluetooth.library.search.SearchResult;
import com.inuker.bluetooth.library.search.response.SearchResponse;
import com.inuker.bluetooth.library.utils.BluetoothUtils;


import com.veepoo.protocol.VPOperateManager;
import com.veepoo.protocol.listener.base.IABleConnectStatusListener;
import com.veepoo.protocol.listener.base.IABluetoothStateListener;
import com.veepoo.protocol.listener.base.IConnectResponse;
import com.veepoo.protocol.listener.base.INotifyResponse;
import com.veepoo.protocol.util.VPLogger;
import com.inuker.bluetooth.library.log.VPLocalLogger;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

import com.orhanobut.logger.LogLevel;
import com.orhanobut.logger.Logger;

import io.flutter.plugin.common.EventChannel;

public class BluetoothScanHelper {

    private final Activity activity;
    private final Handler handler = new Handler();
    private BluetoothAdapter mBAdapter;
    private boolean mIsOadModel;
    private EventChannel.EventSink eventSink;

    private final List<SearchResult> deviceList = new ArrayList<>();
    private final List<String> deviceAddressList = new ArrayList<>();


    private void initLog() {
        Logger.init("example")
                .methodCount(0)
                .methodOffset(0)
                .hideThreadInfo()
                .logLevel(LogLevel.FULL)
                .logAdapter(new CustomLogAdapter());
    }

    public BluetoothScanHelper(Activity activity) {
        this.activity = activity;
        // Initialize logger
        com.jieli.jl_rcsp.util.JL_Log.setTagPrefix("HBand-JLFace");
        com.jieli.jl_rcsp.util.JL_Log.configureLog((Activity) activity, true, true);
        initLog();

        // Initialize VPLogger and BLE manager
        VPLogger.setDebug(true);
        VPOperateManager.getInstance().init(activity);
        VPLocalLogger.startMonitor(activity);
        checkPermissions();
        registerBluetoothStateListener();
    }


    // Set Flutter EventSink to stream scan results
    public void setEventSink(EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
    }

    // Check and request runtime permissions (Android 12+)
    public boolean checkPermissions() {

        List<String> requestList = new ArrayList<>();

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {  // Android 12+
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_SCAN)
                    != PackageManager.PERMISSION_GRANTED) {
                requestList.add(Manifest.permission.BLUETOOTH_SCAN);
            }
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_CONNECT)
                    != PackageManager.PERMISSION_GRANTED) {
                requestList.add(Manifest.permission.BLUETOOTH_CONNECT);
            }
        } else {  // Android 11 and below
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION)
                    != PackageManager.PERMISSION_GRANTED) {
                requestList.add(Manifest.permission.ACCESS_FINE_LOCATION);
            }
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_COARSE_LOCATION)
                    != PackageManager.PERMISSION_GRANTED) {
                requestList.add(Manifest.permission.ACCESS_COARSE_LOCATION);
            }
        }

        if (!requestList.isEmpty()) {
            ActivityCompat.requestPermissions(activity,
                    requestList.toArray(new String[0]),
                    0x55);
            return false;
        }

        initBLE();
        return true;
    }



    // Initialize BLE Adapter
    private void initBLE() {
        BluetoothManager manager = (BluetoothManager) activity.getSystemService(Context.BLUETOOTH_SERVICE);
        if (manager != null) {
            mBAdapter = manager.getAdapter();
        }
    }

    // Start scanning devices (auto-enable Bluetooth if needed)
    public void startScan() {
        if (!BluetoothUtils.isBluetoothEnabled()) {
            enableBluetooth();
            return;
        }

        scanDevices();
    }

    // Enable Bluetooth and start scan after delay
    private void enableBluetooth() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Cannot auto-enable Bluetooth on Android 13+
            // Must ask user manually
            // Open system dialog
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            activity.startActivity(enableBtIntent);
        } else {
            mBAdapter.enable();
        }

        // Wait 1.5s for Bluetooth to enable
        handler.postDelayed(this::scanDevices, 1500);
    }

    // Perform actual device scan
    private void scanDevices() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_SCAN)
                        != PackageManager.PERMISSION_GRANTED) {

            if (eventSink != null) {
                eventSink.error("no_permission", "Missing BLUETOOTH_SCAN", null);
            }
            return;
        }
        deviceList.clear();
        deviceAddressList.clear();

        VPOperateManager.getInstance().startScanDevice(searchResponse);

        // Auto-stop scan after 3 seconds
        handler.postDelayed(() -> VPOperateManager.getInstance().stopScanDevice(), 3000);
    }

    // Connect to a BLE device
    public void connectDevice(final String mac, final String name) {

        VPOperateManager.getInstance().registerConnectStatusListener(mac, mBleConnectStatusListener);

        VPOperateManager.getInstance().connectDevice(mac, name, new IConnectResponse() {
            @Override
            public void connectState(int code, com.inuker.bluetooth.library.model.BleGattProfile profile, boolean isOadMode) {

                mIsOadModel = isOadMode;

            }

        }, new INotifyResponse() {
            @Override
            public void notifyState(int state) {
                if (state == Code.REQUEST_SUCCESS) {
                    if (eventSink != null) {
                        eventSink.success(Map.of("mac", mac, "status", "connected"));
                        OperatorHelper.startVerificationAndSync(activity, mac);
                    }
                }
            }
        });
    }

    // Scan callback
    private final SearchResponse searchResponse = new SearchResponse() {
        @Override
        public void onSearchStarted() { }

        @Override
        public void onDeviceFounded(SearchResult device) {
            if (!deviceAddressList.contains(device.getAddress())) {
                deviceList.add(device);
                deviceAddressList.add(device.getAddress());
                if (eventSink != null) {
                    eventSink.success(Map.of(
                            "name", device.getName(),
                            "mac", device.getAddress(),
                            "rssi", device.rssi
                    ));
                }
            }
        }

        @Override
        public void onSearchStopped() { }

        @Override
        public void onSearchCanceled() { }
    };

    // Connect status listener
    private final IABleConnectStatusListener mBleConnectStatusListener = new IABleConnectStatusListener() {
        @Override
        public void onConnectStatusChanged(String mac, int status) {
            if (eventSink != null) {
                Map<String, Object> map = new HashMap<>();
                map.put("mac", mac);
                map.put("status", status == Constants.STATUS_CONNECTED ? "connected" : "disconnected");
                eventSink.success(map);
            }
        }
    };
    private void registerBluetoothStateListener() {

        VPOperateManager.getInstance().registerBluetoothStateListener(new IABluetoothStateListener() {
            @Override
            public void onBluetoothStateChanged(boolean openOrClosed) {
                if (eventSink != null) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("bluetoothState", openOrClosed ? "on" : "off");
                    eventSink.success(map);
                }
            }
        });
    }

    public void dispose() {
        eventSink = null;

        try {
            VPOperateManager.getInstance().stopScanDevice();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }



}


