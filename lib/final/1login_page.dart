import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../bloc/login_bloc/login_bloc.dart';
import '../bloc/login_bloc/minui.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold( // ✅ Removed MaterialApp, keeping it inside the app structure
      backgroundColor: const Color(0xFFDC143C),
      body: BlocProvider(
        create: (context) => QRLoginBloc(ref),
        child: LoginPageScreen(),
      ),
    );
  }
}


class LoginPageScreen extends StatelessWidget {
  const LoginPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final bool isMobile = width < 600 ;
    final bool isTablet = width >= 600 && width < 1300;


    // If the screen is too small, show an error message.
    if (width < 720 || height < 500) {
      return Scaffold(
            backgroundColor: const Color(0xFFDC143C),
            body: Center(
              child: Text(
                'Error: Screen size is too small for this layout.\nPlease use a larger device.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
    }

    return Scaffold(
        backgroundColor: const Color(0xFFDC143C),
      body: SizedBox(
        height: height + (isMobile ? 200 : 0),
        child: Stack(
          children: [
            // Parabolic Clipper on top
            ClipPath(
              clipper: ParabolicClipper(),
              child: Container(
                height: size.height / 1.8,
                width: size.width,
                color: Colors.black,
              ),
            ),
            // Top-left text (logo)
            const Positioned(
              top: 5,
              left: 25,
              child: Text(
                'SpidrOx',
                style: TextStyle(
                  fontSize: 32,
                  fontFamily: 'Fenix',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC143C), // Red for contrast
                ),
              ),
            ),
            // Main content: left instructions and right QR code
            Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 20 : isTablet ? 30 : 50,
                right: isMobile ? 20 : isTablet ? 30 : 50,
                top: isMobile ? 60 : 20,
              ),
              child: isMobile
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  InstructionText(isTablet: isTablet,),
                  const SizedBox(height: 50),
                  LeftInstructionBox(width: width, height: height,isMobile: isMobile,isTablet: isTablet),
                  const SizedBox(height: 40),
                  QRBox(size: size, height: height, width: width,),
                ],
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: instructions and text
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InstructionText(isTablet: isTablet,),
                        const SizedBox(height: 50),
                        LeftInstructionBox(width: width, height: height,isMobile: isMobile,isTablet:isTablet),
                      ],
                    ),
                  ),
                  // Right side: QR code box
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding:  EdgeInsets.symmetric(horizontal: width * 0.05),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          QRBox(size: size, height: height, width: width,),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for the instructional text above the white box.
class InstructionText extends StatelessWidget {
  final bool isTablet;
  const InstructionText({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Text(
      '''
  Log in to access your profile, 
interact with fellow students, 
and explore exciting opportunities.
''',
      style: TextStyle(
        fontSize: isTablet?22:28,
        fontFamily: 'Fenix',
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Widget for the left white box that contains step-by-step instructions.
class LeftInstructionBox extends StatelessWidget {
  final double width;
  final double height;
  final bool isMobile;
  final bool isTablet;
  const LeftInstructionBox({super.key, required this.width, required this.height,required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      width: width * 0.5, // Adjust based on screen width
      height: height * 0.5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row of instructions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StepBox(
                  imagePath: 'images/laptop-screen.png',
                  stepNumber: 'Step 1: ',
                  description: 'Login or register',
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
                SizedBox(width: width*0.03),
                StepBox(
                  imagePath: 'images/user.png',
                  stepNumber: 'Step 2:',
                  description: 'Open SpidrOx\nMobile Application',
                  isMobile: isMobile,
                  isTablet: isTablet,

                ),
              ],
            ),
            SizedBox(height: height*0.05),
            // Second row of instructions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StepBox(
                  imagePath: 'images/qr-code.png',
                  stepNumber: 'Step 3: ',
                  description: 'Navigate to the QR Code',
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
                SizedBox(width: width*0.03),
                StepBox(
                  imagePath: 'images/phone.png',
                  stepNumber: 'Step 4: ',
                  description: 'Scan the QR Code',
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A reusable widget for each step/instruction box.
class StepBox extends StatelessWidget {
  final String imagePath;
  final String stepNumber;
  final String description;
  final bool isMobile;
  final bool isTablet;
  const StepBox({
    super.key,
    required this.imagePath,
    required this.stepNumber,
    required this.description,
    required this.isMobile,
    required this.isTablet,

  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.18,
      width: size.width * 0.18,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size.width * 0.10,
            height: size.height * 0.10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(imagePath, fit: BoxFit.scaleDown),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: stepNumber,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: isMobile?10:isTablet?14:18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: description,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: isMobile?10:isTablet?14:18,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget for the right-side white box with the QR code.
class QRBox extends StatelessWidget {
  final Size size;
  final double height;
  final double width;
  const QRBox({super.key, required this.size,required this.height,required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // White rectangular box for QR code
        Container(
          width: size.width * 0.25,
          height: size.height * 0.5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(5, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Center(
            child: QRLoginWidget(height: height, width: width,),
          ),
        ),
        const SizedBox(height: 15),
        // Text below the QR code box
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: '''  
Scan QR Code to Login 
''',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const WidgetSpan(
                child: SizedBox(height: 50),
              ),
              const TextSpan(
                text: '''
Need an account ? 
''',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: 'Click here to Register',

                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                  decorationThickness: 2,
                  decorationStyle: TextDecorationStyle.solid,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    print("🔴 Disposing QRLoginBloc before navigating...");
                    context.read<QRLoginBloc>().close(); // ✅ Dispose before navigating
                    context.pushNamed('registerPage'); // Navigate to registration page
                  },
              ),

            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Custom Clipper for Parabolic Shape
class ParabolicClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double width = size.width;
    double height = size.height;
    double curveMultiplier = width > 1000 ? 0.6 : width > 600 ? 0.45 : 0.3;
    double controlPointY = height * curveMultiplier;

    final Path path = Path();
    path.lineTo(0, height);
    path.quadraticBezierTo(
      width / 2,
      controlPointY,
      width,
      height,
    );
    path.lineTo(width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
