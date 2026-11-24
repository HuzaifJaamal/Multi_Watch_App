import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/app_color.dart';
import '../../viewmodels/bluetooth_scan_viewmodel.dart';

class BluetoothScanAnimatedScreen extends StatefulWidget {
  const BluetoothScanAnimatedScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothScanAnimatedScreen> createState() =>
      _BluetoothScanAnimatedScreenState();
}

class _BluetoothScanAnimatedScreenState
    extends State<BluetoothScanAnimatedScreen>
    with SingleTickerProviderStateMixin {


  late final AnimationController _controller;
  late final Animation<double> _pulseAnim;

  late final BluetoothScanViewModel scanVM;


  @override
  void initState() {
    super.initState();

    scanVM = Get.find<BluetoothScanViewModel>();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _pulseAnim = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(_controller);

    _controller.repeat(reverse: true);

    scanVM.startScan();
  }

  @override
  void dispose() {

    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            centerTitle: true,
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                scanVM.isScanning.value ? "Searching for devices..." : "Select your device",
                key: ValueKey<bool>(scanVM.isScanning.value),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              const SizedBox(height: 24),

              /// Bluetooth icon with pulse animation
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bluetooth,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sub text
              Text(
                "Make sure your device is unlocked\nand Bluetooth is enabled",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: scanVM.isScanning.value
                      ? const LinearProgressIndicator(
                    minHeight: 3,
                    key: ValueKey("progress"),
                  )
                      : const SizedBox(
                    key: ValueKey("no_progress"),
                    height: 3,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // "History" label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Text(
                      "History",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Obx(() {
                return Expanded(
                  child: scanVM.devices.isEmpty
                      ? Center(
                        child: Text(
                          scanVM.isScanning.value
                              ? "Scanning for nearby devices..."
                              : "No devices found",
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      )
                      : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: scanVM.devices.length,
                        itemBuilder: (context, index) {
                          final device = scanVM.devices[index];

                          return TweenAnimationBuilder<double>(
                            tween:
                            Tween<double>(begin: 30.0, end: 0.0), // slide up
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, value),
                                child: Opacity(
                                  opacity:
                                  (30.0 - value) / 30.0, // fade in as it moves
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.usb, size: 26),
                                  title: Text(device["name"] ?? "Unknown device"),
                                  subtitle: Text(
                                    device["mac"] ?? "",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onTap: () {
                                  scanVM.connect(
                                    device["mac"],
                                    device["name"],
                                  );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),

              const SizedBox(height: 8),
              Obx(() {
                return FloatingActionButton.extended(
                  onPressed: scanVM.isScanning.value
                      ? null
                      : scanVM.startScan,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Rescan"),
                );
              }),
              const SizedBox(height: 4),
            ],
          ),
        ),
        // Loading overlay

        /// 🔹 FULL SCREEN LOADER
        Obx(() {
          if (!scanVM.isConnecting.value) return const SizedBox();

          return Positioned.fill(
            child: ColoredBox(
              color: AppColors.black.withOpacity(0.35),
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 140,
                        child: Lottie.asset(
                          "assets/lottie/loading.json",
                          repeat: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        "Connecting to ${scanVM.connectingDeviceName.value}",
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "Please wait...",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontStyle: FontStyle.normal
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
