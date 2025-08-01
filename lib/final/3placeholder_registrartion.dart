import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../bloc/placeholder_registration_bloc/placeholder_registration_bloc.dart';
import '../bloc/placeholder_registration_bloc/placeholder_registration_event.dart';
import '../bloc/placeholder_registration_bloc/placeholder_registration_state.dart';


class PlaceholderRegistrartion extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
  create: (context) => TimerBloc(ref)..add(StartTimerp()),
  child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PlaceholderRegistrationPage(),
    ),
);
  }
}

class PlaceholderRegistrationPage extends StatelessWidget {
  const PlaceholderRegistrationPage({Key? key}) : super(key: key);

  void _showTimerCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing on tap outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Session Expired"),
          content: const Text("The email verification time has expired. Please try again."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close AlertDialog
               context.go("/login"); // Navigate to login page
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TimerBloc, TimerState>(
      listener: (context, state) {
        if (state is TimerNavigation) {
          Future.microtask(() =>context.goNamed("registrationQR"));
        }

        if (state is TimerEnded) {
          print("🚀 Showing Timer Dialog box...");
          Future.microtask(() {
            _showTimerCompletedDialog(context);
          });
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xFFDC143C),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "SPIDROX",
                style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Check the email and click on the link which is been provided there.",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                "You will receive the email in a few minutes.",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 20),

              // Timer Countdown Display
              BlocBuilder<TimerBloc, TimerState>(
                builder: (context, state) {
                  if (state is TimerRunning) {
                    final minutes = state.remainingTime ~/ 60;
                    final seconds = state.remainingTime % 60;
                    final formattedTime =
                        '$minutes:${seconds.toString().padLeft(2,'0')}';
                    return Text("Redirecting in: ${formattedTime} ",
                        style: const TextStyle(fontSize: 16, color: Colors.white));
                  } else if (state is TimerEnded) {
                    return Text("⏳ Timer Ended! Redirecting...",
                        style: const TextStyle(fontSize: 16, color: Colors.white));
                  }
                  return const SizedBox();
                },
              ),

            ],
          ),
        ),
      ),
    );
  }
}
