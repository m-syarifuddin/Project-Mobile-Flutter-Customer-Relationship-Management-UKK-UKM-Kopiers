library kopiers;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'services/api_client.dart';
import 'services/member_card_printer.dart';

part 'admin/auth.dart';
part 'admin/shell.dart';
part 'admin/products.dart';
part 'admin/transactions.dart';
part 'admin/data.dart';
part 'admin/dashboard.dart';
part 'admin/customers.dart';
part 'admin/segments.dart';
part 'admin/complaints.dart';
part 'admin/loyalty.dart';
part 'admin/campaigns.dart';
part 'admin/profile.dart';
part 'customer/shell.dart';
part 'customer/data.dart';
part 'customer/home.dart';
part 'customer/transactions.dart';
part 'customer/loyalty.dart';
part 'customer/promos.dart';
part 'customer/account.dart';
part 'customer/complaints.dart';

// Warna utama Kopiers
const coffee = Color(0xFFE00404);
const cream = Color(0xFFFFF5F5);
const darkCoffee = Color(0xFFB80000);
const ink = Color(0xFF282323);
const borderColor = Color(0xFFFFD6D6);
const softRed = Color(0xFFFFE0E0);

class KopiersApp extends StatelessWidget {
  const KopiersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kopiers',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(seedColor: coffee, surface: cream)
            .copyWith(
              primary: coffee,
              onPrimary: Colors.white,
              secondary: darkCoffee,
              onSecondary: Colors.white,
              surface: Colors.white,
              onSurface: ink,
              outline: borderColor,
              error: const Color(0xFFB00020),
              onError: Colors.white,
            ),

        scaffoldBackgroundColor: cream,

        appBarTheme: const AppBarTheme(
          backgroundColor: coffee,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: borderColor),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: coffee, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB00020)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB00020), width: 1.5),
          ),
          labelStyle: const TextStyle(color: ink),
          prefixIconColor: coffee,
          suffixIconColor: coffee,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: coffee,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFFFB3B3),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: coffee,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFFFB3B3),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: coffee,
            side: const BorderSide(color: coffee),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: coffee,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        iconTheme: const IconThemeData(color: coffee),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: softRed,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
            (states) => TextStyle(
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? coffee
                  : Colors.grey.shade600,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? coffee
                  : Colors.grey.shade600,
            ),
          ),
        ),

        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Colors.white,
          selectedIconTheme: IconThemeData(color: coffee),
          unselectedIconTheme: IconThemeData(color: Colors.grey),
          indicatorColor: softRed,
        ),

        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: coffee,
          foregroundColor: Colors.white,
          elevation: 2,
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(color: coffee),

        chipTheme: ChipThemeData(
          backgroundColor: softRed,
          selectedColor: coffee,
          side: const BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: const TextStyle(color: ink),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
        ),

        dividerTheme: const DividerThemeData(color: borderColor, thickness: 1),

        listTileTheme: const ListTileThemeData(
          iconColor: coffee,
          textColor: ink,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),

        tabBarTheme: const TabBarThemeData(
          labelColor: coffee,
          unselectedLabelColor: Colors.grey,
          indicatorColor: coffee,
        ),

        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
            (states) =>
                states.contains(WidgetState.selected) ? Colors.white : null,
          ),
          trackColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.selected) ? coffee : null,
          ),
        ),

        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.selected) ? coffee : null,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),

        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color?>(
            (states) =>
                states.contains(WidgetState.selected) ? coffee : Colors.grey,
          ),
        ),

        snackBarTheme: SnackBarThemeData(
          backgroundColor: ink,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),

        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
        ),
      ),

      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      await ApiClient.instance.restore();

      if (ApiClient.instance.hasToken) {
        final result = await ApiClient.instance.get('/auth/me');
        _user = Map<String, dynamic>.from(result['user'] as Map);
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await ApiClient.instance.clearToken();
      }
    } catch (_) {
      // Pertahankan token lokal jika API sedang tidak tersedia.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _signedIn(Map<String, dynamic> user) {
    setState(() => _user = user);
  }

  void _userUpdated(Map<String, dynamic> user) {
    setState(() => _user = user);
  }

  Future<void> _signOut() async {
    try {
      await ApiClient.instance.post('/auth/logout');
    } catch (_) {
      // Hapus sesi lokal meskipun server tidak tersedia.
    }

    await ApiClient.instance.clearToken();

    if (mounted) {
      setState(() => _user = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return LoginPage(onSignedIn: _signedIn);
    }

    return switch (_user!['role']) {
      'admin' => AdminShell(
        user: _user!,
        onSignOut: _signOut,
        onUserUpdated: _userUpdated,
      ),
      'customer' => CustomerShell(user: _user!, onSignOut: _signOut),
      _ => LoginPage(onSignedIn: _signedIn),
    };
  }
}
