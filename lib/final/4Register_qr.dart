import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bloc/Register_qr_bloc/reg_qr_widget.dart';
import '../bloc/Register_qr_bloc/register_qr_bloc.dart';
import '../bloc/Register_qr_bloc/register_qr_event.dart'; // Import the qr_flutter package

void main() {
  runApp(const ParabolicBackgroundApp());
}

class ParabolicBackgroundApp extends ConsumerWidget {
  const ParabolicBackgroundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Parabolic Edge Example',
        theme: ThemeData(primarySwatch: Colors.blue),
        home:  BlocProvider(
  create: (context) => RegisterBloc(ref),
  child: ParabolicEdgeDemo(),
),
      );
  }
}

class ParabolicEdgeDemo extends StatefulWidget {
  const ParabolicEdgeDemo({super.key});

  @override
  _ParabolicEdgeDemoState createState() => _ParabolicEdgeDemoState();
}

class _ParabolicEdgeDemoState extends State<ParabolicEdgeDemo> {

 void initState() {
    super.initState();
    print("register_qr_page started");
    context.read<RegisterBloc>().add(StartTimer());
  }
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFDC143C),
      body: SizedBox(
        height: height + 200,
        child: Stack(
          children: [
            ClipPath(
              clipper: ParabolicClipper(),
              child: Container(
                height: height * 0.55,
                width: width,
                color: const Color(0xff000000),
              ),
            ),
            const Positioned(
              top: 25,
              left: 25,
              child: Text(
                'SpidrOx',
                style: TextStyle(
                  fontSize: 32,
                  fontFamily: 'Fenix',
                  color: Color(0xFFDC143C),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100, left: 100, right: 100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Left Column (Steps Container)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child:  Container(
                        width: width * 0.3,
                        height: height * 0.5,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '       Follow These Steps',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildStep(1, '''Scan the QR Code using your phone's mobile application.'''),
                              const SizedBox(height: 10),
                              _buildStep(2, 'A new tab will open to log-in.'),
                              const SizedBox(height: 10),
                              _buildStep(3, 'Follow the steps on log-in Screen.'),
                            ],
                          ),
                        ),
                      ),

                    ),
                    // Right Column (QR Code Container)
                    const SizedBox(width: 40),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Container(
                            width: width * 0.25,
                            height: height * 0.4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                color: Colors.white,
                                child: Center(
                                  child: //Text("wait")
                                  RegisterQRWidget(
                                    width: width,
                                    height: height,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int stepNumber, String stepDescription) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $stepNumber:',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            stepDescription,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class ParabolicClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double width = size.width;
    double height = size.height;

    double curveMultiplier = width > 800 ? 0.6 : (0.25 + (width / 900));
    double controlPointY = height * curveMultiplier;

    final Path path = Path();
    path.lineTo(0, height);
    path.quadraticBezierTo(
      width / 2, controlPointY,
      width, height,
    );
    path.lineTo(width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}




// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // Import the qr_flutter package
// import 'package:spidrox_reg/bloc/Register_qr_bloc/register_qr_bloc.dart';
// import 'dart:ui';
//
// import '../bloc/Register_qr_bloc/reg_qr_widget.dart';
// void main() {
//   runApp(const ParabolicBackgroundApp());
// }
//
// class ParabolicBackgroundApp extends ConsumerWidget {
//   const ParabolicBackgroundApp({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Parabolic Edge Example',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home:  BlocProvider(
//         create: (context) => RegisterBloc(ref),
//         child: ParabolicEdgeDemo(),
//       ),
//     );
//   }
// }
//
// class ParabolicEdgeDemo extends StatefulWidget {
//   const ParabolicEdgeDemo({super.key});
//
//   @override
//   _ParabolicEdgeDemoState createState() => _ParabolicEdgeDemoState();
// }
//
// class _ParabolicEdgeDemoState extends State<ParabolicEdgeDemo> {
//   int _secondsRemaining = 30; // Set initial timer value
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _startTimer();
//   }
//
//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_secondsRemaining > 0) {
//         setState(() {
//           _secondsRemaining--;
//         });
//       } else {
//         timer.cancel(); // Stop the timer when it reaches 0
//       }
//     });
//   }
//
//   double getResponsiveFontSize(double screenWidth, {double baseFontSize = 16}) {
//     if (screenWidth < 600) {
//       return baseFontSize; // Small screens
//     } else if (screenWidth < 900) {
//       return baseFontSize *1.5 ; // Medium screens
//     } else {
//       return baseFontSize * 2; // Large screens
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final height = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFDC143C),
//       body: SizedBox(
//         height: height + 200,
//         child: Stack(
//           children: [
//             ClipPath(
//               clipper: ParabolicClipper(),
//               child: Container(
//                 height: height * 0.55,
//                 width: width,
//                 color: const Color(0xff000000),
//               ),
//             ),
//             Positioned(
//               top: 25,
//               left: 25,
//               child: Text(
//                 'SpidrOx',
//                 style: TextStyle(
//                   fontSize: getResponsiveFontSize(width, baseFontSize: 20),
//                   fontFamily: 'Fenix',
//                   color: const Color(0xFFDC143C),
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             Center(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: width < 600 ? 10 : 100,
//                   vertical: width < 600 ? 20 : 100,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     // Fixed Size Steps Container
//                     Container(
//                       width: width*0.3, // Fixed width
//                       height: height*0.6, // Fixed height
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(10),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               '       Follow These Steps',
//                               style: TextStyle(
//                                 fontSize: getResponsiveFontSize(width, baseFontSize: 18),
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black,
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             _buildStep(1, 'Download the Mobile Application.'),
//                             const SizedBox(height: 10),
//                             _buildStep(2, '''Scan the QR Code using your phone's mobile application.'''),
//                             const SizedBox(height: 10),
//                             _buildStep(3, 'A new tab will open to log-in.'),
//                             const SizedBox(height: 10),
//                             _buildStep(4, 'Follow the steps on log-in Screen.'),
//                           ],
//                         ),
//                       ),
//                     ),
//
//                     // Fixed Size QR Code Container
//                     Container(
//                       width: 300, // Fixed width
//                       height: 300, // Fixed height
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: RegisterQRWidget(
//                         width: width,
//                         height: height,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//
//
//
//   void _showDownloadDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: true, // Allows closing by tapping outside
//       builder: (BuildContext context) {
//         return Stack(
//           children: [
//             // Blurred Background
//             BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Adjust blur strength
//               child: Container(
//                 color: Colors.black.withOpacity(0.2), // Darken the background slightly
//               ),
//             ),
//
//             // QR Code Dialog
//             Dialog(
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//               child: Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   color: Colors.white,
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text(
//                       "Scan to Download",
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     QrImageView(
//                       data: "https://lumiether.com/",
//                       version: QrVersions.auto,
//                       size: 200,
//                       backgroundColor: Colors.white,
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context); // Close the dialog
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text("Close", style: TextStyle(color: Colors.white)),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//
//
//
//   Widget _buildStep(int stepNumber, String stepDescription) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Step $stepNumber:',
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.red,
//           ),
//         ),
//         const SizedBox(width: 5),
//         Expanded(
//           child: stepNumber == 1
//               ? Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   stepDescription,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Container(
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.black, width: 1.5),
//                   borderRadius: BorderRadius.circular(8),
//                   color: Colors.white, // Background color
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.download, color: Colors.black, size: 24),
//                   onPressed: () {
//                     _showDownloadDialog(); // Call the dialog function
//                   },
//                 ),
//               ),
//             ],
//           )
//               : Text(
//             stepDescription,
//             style: const TextStyle(
//               fontSize: 18,
//               color: Colors.black,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
// }
//
// class ParabolicClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     double width = size.width;
//     double height = size.height;
//
//     double curveMultiplier = width > 800 ? 0.6 : (0.25 + (width / 900));
//     double controlPointY = height * curveMultiplier;
//
//     final Path path = Path();
//     path.lineTo(0, height);
//     path.quadraticBezierTo(
//       width / 2, controlPointY,
//       width, height,
//     );
//     path.lineTo(width, 0);
//     path.close();
//     return path;
//   }
//
//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => false;
// }