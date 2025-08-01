import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:spidrox_reg/bloc/Register_qr_bloc/register_qr_bloc.dart';
import 'package:spidrox_reg/bloc/Register_qr_bloc/register_qr_state.dart';
import '../../river_pod/data_provider.dart';

class RegisterQRWidget extends ConsumerWidget {
  final double width;
  final double height;

  const RegisterQRWidget({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authData = ref.watch(authProvider); // Fetch JWT & URL from Riverpod

    return BlocListener<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state.isNavigating) {
          Future.microtask(() => context.go("/login"));
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BlocBuilder<RegisterBloc, RegisterState>(
            builder: (context, state) {
              final jwt = authData.jwt;
              final url = authData.url;

              // ✅ Ensure JWT and URL are not null before showing QR
              if (jwt.isEmpty || url.isEmpty) {
                print("❌ Missing Data -> URL: $url, JWT: $jwt");
                return const Text("No QR data available. Please try again.");
              }

              // ✅ Create QR code only if both JWT and URL are valid
              final qrData = jsonEncode({
                "jwt": jwt,
                "url": url,
                "action": "register"
              });

              return QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: width * 0.15,
              );
            },
          ),
          BlocBuilder<RegisterBloc, RegisterState>(
            buildWhen: (previous, current) => previous.remainingTime != current.remainingTime,
            builder: (context, state) {
              return Text(
                'Redirecting in: ${state.remainingTime} sec',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              );
            },
          ),
        ],
      ),
    );
  }
}
