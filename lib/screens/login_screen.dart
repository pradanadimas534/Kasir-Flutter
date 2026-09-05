import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:provider/provider.dart';
import '../providers/kasir_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    final ok = await context.read<KasirProvider>().login();
    if (!mounted) return;
    if (!ok) {
      setState(() => _loading = false);
      final detail = context.read<KasirProvider>().loginError;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(detail.isEmpty ? 'Login gagal, coba lagi' : detail),
        backgroundColor: AppColors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.loginGradient),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Kasir Toko',
                      style: TextStyle(
                        fontFamily: 'Lobster',
                        fontSize: 50,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kasir & Operasional',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: .92),
                      ),
                    ),
                    const Spacer(flex: 3),
                    Image.asset(
                      'assets/images/basket.png',
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(flex: 3),
                    const Text(
                      'Selamat datang!',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login untuk melanjutkan ke aplikasi kasir',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: .92),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _GoogleButton(onPressed: _loading ? null : _login),
                    const Spacer(flex: 3),
                    Text(
                      'Dengan login, Anda setuju dengan',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Syarat & Ketentuan dan Kebijakan Privasi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),

            // Overlay loading (desain "Login2")
            if (_loading)
              Container(
                color: Colors.black.withValues(alpha: .35),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 54,
                  height: 54,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 4,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        color: const Color(0xFFFBECEC),
        borderRadius: BorderRadius.circular(30),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _GoogleG(),
              const SizedBox(width: 12),
              Text(
                'Login dengan Google',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: onPressed == null
                      ? const Color(0xFF9A9A9A)
                      : const Color(0xFF141417),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "G" ala Google — pendekatan sederhana tanpa aset SVG.
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration:
          const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: const Text(
        'G',
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: Color(0xFF4285F4),
          height: 1.0,
        ),
      ),
    );
  }
}
