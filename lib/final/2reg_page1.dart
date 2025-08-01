import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth/reg_bloc.dart';
import '../bloc/auth/reg_event.dart';
import '../bloc/auth/reg_state.dart';
import '3placeholder_registrartion.dart';

class ParabolicEdgePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
      create: (context) => AuthBloc(ref),
      child: RegistrationPage(),
    );
  }
}


class RegistrationPage extends StatefulWidget {

  RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  String? selectedCollege;
  List<String> collegeNames = [
    'JSS Academy',
    'Dayananda Sagar College',
    'RV College',
    'BMS College',
    'PES University',
    'NITK Surathkal',
  ];

@override
void initState(){
  super.initState();
  context.read<AuthBloc>().add(FetchCollegeNames());
}




  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 1300;

    return Scaffold(
        backgroundColor: const Color(0xFFDC143C),
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registration Successful!')),
              );
              context.read<AuthBloc>().close();
              print("registration bloc closed");
              Future.delayed(Duration(milliseconds: 1300), () =>
                  context.go("/placeholder"));
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            } else if (state is CollegeNamesLoaded) {
              // Update the local college names list when loaded
              setState(() {
                collegeNames = state.collegeNames;
              });
            } else if (state is CollegeNamesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
          child: SingleChildScrollView(
            child: SizedBox(
              height: height + (isMobile ? 200 : 0),
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
                  Padding(
                    padding: EdgeInsets.only(
                      left: isMobile ? 20 : isTablet ? 30 : 50,
                      right: isMobile ? 20 : isTablet ? 30 : 50,
                      top: isMobile ? 60 : 20,
                    ),
                    child: isMobile
                        ? Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            _buildTextContent(isMobile, isTablet,height),
                            const SizedBox(height: 50),
                            _buildRegistrationForm(
                              context,
                              width * 0.9,
                              height * 0.8,
                              isMobile,
                              isTablet,
                            ),
                          ],
                        ),
                      ),
                    )
                        : SizedBox(
                      height: height,
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(30.0),
                              child: _buildTextContent(isMobile, isTablet,height),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: _buildRegistrationForm(
                                context,
                                width * (isTablet ? 0.5 : 0.35),
                                height * 0.7,
                                isMobile,
                                isTablet,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildCollegeDropdown() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is CollegeNamesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Use the college names from the state if available
        List<String> dropdownItems = (state is CollegeNamesLoaded)
            ? state.collegeNames
            : collegeNames;

        return DropdownButtonFormField<String>(
          value: selectedCollege,
          hint: const Text("Select College Name", style: TextStyle(color: Colors.black)),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: dropdownItems.map((String college) {
            return DropdownMenuItem<String>(
              value: college,
              child: Text(college),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedCollege = newValue;
            });
          },
        );
      },
    );
  }
  Widget _buildTextContent(bool isMobile, bool isTablet,double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Text(
          '''
   Connect, collaborate, and stay 
    updated with everything 
     happening on campus.''',
          style: TextStyle(color: Colors.white, fontSize: 28, fontFamily: 'Fenix'),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isMobile?height * 0.05:isTablet?height * 0.06:0),
        const Text(
          '''
            Register here to 
            get started!''',
          style: TextStyle(color: Colors.white, fontSize: 28, fontFamily: 'Fenix'),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(BuildContext context, double width, double height, bool isMobile, bool isTablet) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white60.withOpacity(0.88),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: EdgeInsets.all(isMobile ? 15 : 30),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: isMobile ? 5 : 20),
            Text(
              'Welcome to SpidrOx\nYour Campus, Your Network!',
              style: TextStyle(
                fontSize: isMobile ? 22 : isTablet ? 26 : 30,
                color: Colors.black,
                fontFamily: 'Fenix',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: height * 0.06),
            _buildTextField('Enter user name', usernameController),
            SizedBox(height: height * 0.06),
            _buildTextField('Enter email id', emailController),
            SizedBox(height: height * 0.06),
            _buildCollegeDropdown(),
            SizedBox(height: height * 0.1),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    context.read<AuthBloc>().add(RegisterUser(
                      emailController.text.trim(),
                      usernameController.text.trim(),
                      selectedCollege!, // ✅ Pass selected college name
                    ));
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 10),
                    child: state is AuthLoading
                        ? const CircularProgressIndicator()
                        : const Text('  Register Now  ', style: TextStyle(color: Colors.black)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class ParabolicClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double width = size.width;
    double height = size.height;
    double curveMultiplier = width > 1000 ? 0.5 : width > 600 ? 0.6 : 0.8;
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
