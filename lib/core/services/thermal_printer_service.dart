/// ─── CampusEats — Thermal Printer Service (Phase 11) ────────────────────────
///
/// Wraps unified_esc_pos_printer v3.2.0 for direct BT/Network ESC/POS printing.
///
/// Real API surface used (verified from package source):
///   `PrinterManager` (not a singleton — create per session)
///     `.scanPrinters({types, timeout})` → `Future<List<PrinterDevice>>`
///     `.connect(PrinterDevice)` → `Future<void>`
///     `.printTicket(Ticket)` → `Future<void>`
///     `.disconnect()` → `Future<void>`
///     `.dispose()` → `Future<void>`
///
///   Device types: `BluetoothPrinterDevice`, `NetworkPrinterDevice`, `UsbPrinterDevice`
///   `Ticket`: high-level builder that accumulates bytes
///   `CapabilityProfile.load()` → `CapabilityProfile` (async, loads from assets)
///
/// Pairing is persisted as:
///   shared_preferences keys: thermal_printer_address, thermal_printer_name,
///                            thermal_printer_type (bluetooth|network)
///
/// Print semantics:
///   - Returns ThermalPrintResult enum (success/noPrinter/failed) — never throws
///   - Caller decides whether to: commit printedAt, show fallback, or warn
///   - Failed print does NOT implicitly commit printedAt on the backend

library;

import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

// ─── Persisted Printer State ─────────────────────────────────────────────────

class PairedPrinterInfo {
  final String address; // BT MAC or IP
  final String name;
  final SavedPrinterType type;

  const PairedPrinterInfo({
    required this.address,
    required this.name,
    required this.type,
  });

  /// Reconstructs a PrinterDevice for use with PrinterManager.
  PrinterDevice toPrinterDevice() {
    switch (type) {
      case SavedPrinterType.bluetooth:
        return BluetoothPrinterDevice(name: name, address: address);
      case SavedPrinterType.network:
        final parts = address.split(':');
        final host = parts.first;
        final port = parts.length > 1 ? int.tryParse(parts[1]) ?? 9100 : 9100;
        return NetworkPrinterDevice(name: name, host: host, port: port);
    }
  }
}

enum SavedPrinterType { bluetooth, network }

// ─── Result ──────────────────────────────────────────────────────────────────

enum ThermalPrintResult { success, noPrinter, failed }

// ─── Discovered Printer ───────────────────────────────────────────────────────

class DiscoveredPrinter {
  final String name;
  final String address;
  final PrinterConnectionType connectionType;

  const DiscoveredPrinter({
    required this.name,
    required this.address,
    required this.connectionType,
  });

  SavedPrinterType get savedType => connectionType == PrinterConnectionType.network
      ? SavedPrinterType.network
      : SavedPrinterType.bluetooth;
}

// ─── Thermal Printer Service ─────────────────────────────────────────────────

class ThermalPrinterService {
  ThermalPrinterService._();
  static final instance = ThermalPrinterService._();

  static const _prefAddress = 'thermal_printer_address';
  static const _prefName    = 'thermal_printer_name';
  static const _prefType    = 'thermal_printer_type';

  PairedPrinterInfo? _paired;
  PairedPrinterInfo? get pairedPrinter => _paired;
  bool get hasPrinter => _paired != null;

  // ── Persistence ──────────────────────────────────────────────────────────

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final address = prefs.getString(_prefAddress);
      final name    = prefs.getString(_prefName) ?? 'Thermal Printer';
      final typeStr = prefs.getString(_prefType) ?? 'bluetooth';
      if (address != null && address.isNotEmpty) {
        _paired = PairedPrinterInfo(
          address: address,
          name:    name,
          type:    _parseType(typeStr),
        );
        dev.log('[THERMAL] Loaded paired: $name ($address)', name: 'ThermalPrinter');
      }
    } catch (e) {
      dev.log('[THERMAL] Load error: $e', name: 'ThermalPrinter');
    }
  }

  Future<void> savePaired(PairedPrinterInfo info) async {
    _paired = info;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefAddress, info.address);
      await prefs.setString(_prefName, info.name);
      await prefs.setString(_prefType, info.type.name);
      dev.log('[THERMAL] Saved: ${info.name} (${info.address})', name: 'ThermalPrinter');
    } catch (e) {
      dev.log('[THERMAL] Save error: $e', name: 'ThermalPrinter');
    }
  }

  Future<void> clearPaired() async {
    _paired = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefAddress);
      await prefs.remove(_prefName);
      await prefs.remove(_prefType);
    } catch (e) {
      dev.log('[THERMAL] Clear error: $e', name: 'ThermalPrinter');
    }
  }

  // ── Discovery ─────────────────────────────────────────────────────────────

  /// Returns all discoverable Bluetooth (Classic) printers.
  /// Scan timeout is 5 s — suitable for canteen-side tablet use.
  Future<List<DiscoveredPrinter>> scanBluetooth({Duration timeout = const Duration(seconds: 5)}) async {
    final manager = PrinterManager();
    try {
      final devices = await manager.scanPrinters(
        timeout: timeout,
        types: {PrinterConnectionType.bluetooth},
      );
      return devices
          .whereType<BluetoothPrinterDevice>()
          .map((d) => DiscoveredPrinter(
                name:           d.name,
                address:        d.address,
                connectionType: d.connectionType,
              ))
          .toList();
    } catch (e) {
      dev.log('[THERMAL] Scan failed: $e', name: 'ThermalPrinter');
      return [];
    } finally {
      await manager.dispose();
    }
  }

  // ── Direct Print ───────────────────────────────────────────────────────────

  /// Connects, prints [ticket], disconnects.
  /// Returns typed result — NEVER throws.
  Future<ThermalPrintResult> printTicket(Ticket ticket) async {
    if (_paired == null) return ThermalPrintResult.noPrinter;

    final manager = PrinterManager();
    try {
      final device = _paired!.toPrinterDevice();
      dev.log('[THERMAL] Connecting to ${_paired!.name}', name: 'ThermalPrinter');
      await manager.connect(device, timeout: const Duration(seconds: 8));

      dev.log('[THERMAL] Printing…', name: 'ThermalPrinter');
      await manager.printTicket(ticket);
      dev.log('[THERMAL] Print OK', name: 'ThermalPrinter');
      return ThermalPrintResult.success;
    } catch (e) {
      dev.log('[THERMAL] Print failed: $e', name: 'ThermalPrinter');
      return ThermalPrintResult.failed;
    } finally {
      try { await manager.disconnect(); } catch (_) {}
      await manager.dispose();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  SavedPrinterType _parseType(String s) {
    return s == 'network' ? SavedPrinterType.network : SavedPrinterType.bluetooth;
  }
}

// ─── Riverpod Provider ───────────────────────────────────────────────────────

final thermalPrinterProvider = Provider<ThermalPrinterService>((ref) {
  return ThermalPrinterService.instance;
});
