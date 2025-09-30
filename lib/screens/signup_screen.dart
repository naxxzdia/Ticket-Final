import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController rePasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRePassword = true;
  bool _acceptTerms = false;
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.red;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Listen to password changes
    passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _animationController.dispose();
    passwordController.removeListener(_checkPasswordStrength);
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = passwordController.text;
    double strength = 0;

    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;

    setState(() {
      _passwordStrength = strength;
      if (strength <= 0.25) {
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = Colors.red;
      } else if (strength <= 0.5) {
        _passwordStrengthText = 'Fair';
        _passwordStrengthColor = Colors.orange;
      } else if (strength <= 0.75) {
        _passwordStrengthText = 'Good';
        _passwordStrengthColor = Colors.yellow[700]!;
      } else {
        _passwordStrengthText = 'Strong';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showSnackBar('Please accept Terms of Service', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      setState(() => _isLoading = false);
      _showSnackBar('Account created successfully!', isError: false);
      // Navigator.pushReplacement(...); // ไปหน้า sign in หรือ home
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'email-already-in-use') {
        _showSnackBar('Email already in use.', isError: true);
      } else if (e.code == 'weak-password') {
        _showSnackBar('Password is too weak.', isError: true);
      } else {
        _showSnackBar('Error: {e.message}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFD1DC),
            Color(0xFFE75480),
            Color(0xFF673AB7),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: SafeArea( // <<== เพิ่ม SafeArea ตรงนี้
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Hero Section
                _buildHeroSection(),
                
                // Form Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      
                      _buildTitle(),
                      const SizedBox(height: 24),
                      
                      _buildSocialButtons(),
                      const SizedBox(height: 28),
                      
                      _buildDivider(),
                      const SizedBox(height: 28),
                      
                      _buildForm(),
                      const SizedBox(height: 10),
                      
                      _buildTermsCheckbox(),
                      const SizedBox(height: 8),

                      _buildSignUpButton(),
                      const SizedBox(height: 16),
                      
                      _buildSignInLink(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Poster.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Live the music. Live the moment",
                    style: TextStyle(
                      color: Color(0xFFFFFFCC),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Events",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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

  Widget _buildTitle() {
    return const Text(
      "Create Account",
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFFFFFF),
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(child: _buildSocialButton(
          'assets/images/google_logo.png',
          "Continue with Google",
          const Color(0xFFF8C8DC),
          Color(0xFF212121),
          () {},
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildSocialButton(
          'assets/images/apple_logo.png',
          "Continue with Apple",
          const Color(0xFFF3F1FA),
          Colors.black87,
          () {},
        )),
      ],
    );
  }

  Widget _buildSocialButton(String iconPath, String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Image.asset(iconPath, width: 20, height: 20),
        label: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Color(0xFF616161), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "OR",
            style: TextStyle(
              color: Color(0xFF616161),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFF616161), thickness: 1)),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            label: "Full Name",
            hint: "Enter your full name",
            controller: nameController,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            label: "Email",
            hint: "Enter your email",
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            label: "Password",
            hint: "Create a strong password",
            controller: passwordController,
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          
          // Password Strength Indicator
          if (passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPasswordStrengthIndicator(),
          ],
          
          const SizedBox(height: 16),
          
          _buildTextField(
            label: "Confirm Password",
            hint: "Re-enter your password",
            controller: rePasswordController,
            obscureText: _obscureRePassword,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(_obscureRePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscureRePassword = !_obscureRePassword),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Password Strength:",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              _passwordStrengthText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _passwordStrengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: _passwordStrength,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(_passwordStrengthColor),
        ),
      ],
    );
  }

 Widget _buildTermsCheckbox() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center, // ปรับให้ checkbox กับข้อความอยู่ตรงกลางแถว
    children: [
      Checkbox(
        value: _acceptTerms,
        onChanged: (value) => setState(() => _acceptTerms = value ?? false),
        activeColor: const Color(0xFFFF4081),
      ),
      Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _acceptTerms = !_acceptTerms),
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Color(0xFFFFFFB3), fontSize: 13),
              children: const [
                TextSpan(text: "I agree to the "),
                TextSpan(
                  text: "Terms of Service",
                  style: TextStyle(
                    color: Color(0xFFF4A6B6),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: " and "),
                TextSpan(
                  text: "Privacy Policy",
                  style: TextStyle(
                    color: Color(0xFFF4A6B6),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildSignUpButton() {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFFFFB3).withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      gradient: const LinearGradient(
        colors: [
          Color(0xFFFF4081),
          Color(0xFFFF9AA2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, // ให้พื้นหลังโปร่งใสเพื่อโชว์ gradient
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: _isLoading ? null : _signUp,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFFFFFB3),
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  );
}
  Widget _buildSignInLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
          );
        },
        child: RichText(
          text: const TextSpan(
            style: TextStyle(color: Color(0xFFFFFFB3), fontSize: 14),
            children: [
              TextSpan(text: "Already have an account? "),
              TextSpan(
                text: "Sign In",
                style: TextStyle(
                  color: Color(0xFFF4A6B6),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter ${label.toLowerCase()}';
          }
          if (label == "Email" && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
          if (label == "Password" && value.length < 8) {
            return 'Password must be at least 8 characters';
          }
          if (label == "Confirm Password" && value != passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[600]) : null,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1), // กรอบบางๆสีแดง
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1), // กรอบบางๆสีแดง
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0),width: 2), // กรอบแดงตอน focus
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}