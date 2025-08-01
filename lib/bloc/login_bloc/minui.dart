import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'login_bloc.dart';
import 'login_state.dart';

class QRLoginWidget extends StatefulWidget {
  final double height;
  final double width;

  const QRLoginWidget({super.key, required this.height, required this.width});

  @override
  State<QRLoginWidget> createState() => _QRLoginWidgetState();
}

class _QRLoginWidgetState extends State<QRLoginWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<QRLoginBloc, QRLoginState>(
      listener: (context, state) {
        if (state.status == QRLoginStatus.navigating) {
          context.read<QRLoginBloc>().close();
          print("QRLoginBloc closed");
            context.goNamed("profilePage");
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BlocBuilder<QRLoginBloc, QRLoginState>(
            builder: (context, state) {
              if (state.status == QRLoginStatus.loading || state.jwt == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final qrData = jsonEncode({"jwt": state.jwt, "url": state.url,"action":"login"});

              return QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: widget.width * 0.2,
              );
            },
          ),
          BlocBuilder<QRLoginBloc, QRLoginState>(
            builder: (context, state) {
              final minutes = state.remainingTime ~/ 60;
              final seconds = state.remainingTime % 60;
              final formattedTime =
                  '$minutes:${seconds.toString().padLeft(2,'0')}';
              return Text(
                'Refresh in: ${formattedTime} minutes',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              );
            },
          ),
        ],
      ),
    );
  }
}
