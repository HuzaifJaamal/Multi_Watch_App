package com.example.multi_watch_app.activity;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.example.multi_watch_app.utils.BluetoothScanHelper;
import com.example.multi_watch_app.utils.DataHelper;

import com.inuker.bluetooth.library.log.VPLocalLogger;
import com.veepoo.protocol.VPOperateManager;
import com.veepoo.protocol.listener.base.IBleWriteResponse;


import androidx.work.Data;
import androidx.work.OneTimeWorkRequest;
import androidx.work.WorkManager;

public class MainActivity extends FlutterActivity {

    /* ---------------- Channels ---------------- */

    private static final String METHOD_CHANNEL =
            "com.example.bluetooth/scan";

    private static final String EVENT_CHANNEL =
            "com.example.bluetooth/unified_events";

    private static final String ECG_PDF_CHANNEL = "ecg_pdf_worker";

    private static final String PDF_EVENT_CHANNEL =
            "ecg_pdf_worker/events";

    /* ---------------- Helpers ---------------- */

    private BluetoothScanHelper bluetoothHelper;
    private DataHelper dataHelper;


    /* ---------------- Event Sink ---------------- */

    private EventChannel.EventSink unifiedEventSink;

    private static EventChannel.EventSink pdfEventSink;

    /* ---------------- Flutter Engine ---------------- */

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        /* -------- Initialize Helpers -------- */

        bluetoothHelper = new BluetoothScanHelper(this);
        dataHelper = new DataHelper(this);

        /* -------- MethodChannel -------- */

        MethodChannel methodChannel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                METHOD_CHANNEL
        );

        methodChannel.setMethodCallHandler((call, result) -> {

            switch (call.method) {

                /* 🔍 Start BLE Scan */
                case "startScan":
                    if (bluetoothHelper.checkPermissions()) {
                        bluetoothHelper.startScan();
                        result.success(null);
                    } else {
                        result.error(
                                "PERMISSION",
                                "Bluetooth permission not granted",
                                null
                        );
                    }
                    break;

                /* 🔗 Connect Device */
                case "connectDevice":
                    String mac = call.argument("mac");
                    String name = call.argument("name");
                    bluetoothHelper.connectDevice(mac, name);
                    result.success(null);
                    break;

                /* ❤️ Start ECG */
                case "startECG":
                    new Thread(() -> {
//                        dataHelper.startEcgDetection();
                        dataHelper.startHeartDetection();
                        new Handler(Looper.getMainLooper())
                                .post(() -> result.success("ECG started"));
                    }).start();
                    break;

                /* 🛑 Stop ECG */
                case "stopECG":
                    dataHelper.stopEcg();
                    result.success("ECG stopped");
                    break;

                /* ❌ Disconnect Device */
                case "disconnect":
                    VPOperateManager.getInstance()
                            .disconnectWatch(new IBleWriteResponse() {
                                @Override
                                public void onResponse(int code) {
                                    Log.d(
                                            "MainActivity",
                                            "Disconnected, code: " + code
                                    );
                                }
                            });
                    result.success("Disconnected");
                    break;


                default:
                    result.notImplemented();
                    break;
            }
        });


        /* -------- Unified EventChannel -------- */

        new EventChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                EVENT_CHANNEL
        ).setStreamHandler(new EventChannel.StreamHandler() {

            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                unifiedEventSink = events;

                // Attach sink to helpers
                bluetoothHelper.setEventSink(events);
                dataHelper.setEcgEventSink(events);



                Log.d("MainActivity", "Unified EventChannel attached");
            }

            @Override
            public void onCancel(Object arguments) {
                unifiedEventSink = null;

                bluetoothHelper.setEventSink(null);
                dataHelper.setEcgEventSink(null);

                Log.d("MainActivity", "Unified EventChannel detached");
            }
        });

    }




    /* ---------------- Lifecycle ---------------- */

    @Override
    protected void onDestroy() {

        if (dataHelper != null) {
            dataHelper.dispose();
        }

        if (bluetoothHelper != null) {
            bluetoothHelper.dispose();
        }

        VPLocalLogger.stopMonitor();

        VPOperateManager.getInstance()
                .disconnectWatch(new IBleWriteResponse() {
                    @Override
                    public void onResponse(int code) {
                        Log.d(
                                "MainActivity",
                                "Watch disconnected, code: " + code
                        );
                    }
                });

        unifiedEventSink = null;

        super.onDestroy();
    }
}

