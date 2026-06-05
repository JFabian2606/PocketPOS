import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushReplacementNamed('login');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundBg = Color(0xFFF9F5F1);
    const Color accentColor = Color(0xFFA66E38);
    const Color textColor = Color(0xFF2D2926);
    const Color secondaryTextColor = Color(0xFF717171);

    const PageDecoration pageDecoration = PageDecoration(
      pageColor: backgroundBg,
      titleTextStyle: TextStyle(
        fontSize: 26.0,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      bodyTextStyle: TextStyle(
        fontSize: 16.0,
        color: secondaryTextColor,
        height: 1.5,
      ),
      imagePadding: EdgeInsets.only(top: 80.0, bottom: 20.0),
      titlePadding: EdgeInsets.only(top: 20.0, bottom: 12.0),
      bodyPadding: EdgeInsets.symmetric(horizontal: 24.0),
    );

    return Scaffold(
      backgroundColor: backgroundBg,
      body: SafeArea(
        child: IntroductionScreen(
          globalBackgroundColor: backgroundBg,
          pages: [
            PageViewModel(
              title: 'Bienvenido a PocketPOS',
              body: 'Tu negocio, en tu bolsillo',
              image: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/icon_app.png',
                      height: 180,
                      width: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              decoration: pageDecoration,
            ),
            PageViewModel(
              title: 'Gestiona tu inventario',
              body: 'Controla tu stock en tiempo real y recibe alertas de stock bajo',
              image: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 90,
                    color: accentColor,
                  ),
                ),
              ),
              decoration: pageDecoration,
            ),
            PageViewModel(
              title: 'Genera tickets al instante',
              body: 'Crea recibos en PDF para cada venta en segundos',
              image: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 90,
                    color: accentColor,
                  ),
                ),
              ),
              decoration: pageDecoration,
            ),
          ],
          onDone: () => _completeOnboarding(context),
          onSkip: () => _completeOnboarding(context),
          showSkipButton: true,
          skip: const Text(
            'Saltar',
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          next: const Icon(
            Icons.arrow_forward,
            color: accentColor,
          ),
          done: const Text(
            'Comenzar',
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          dotsDecorator: DotsDecorator(
            size: const Size.square(10.0),
            activeSize: const Size(22.0, 10.0),
            activeColor: accentColor,
            color: accentColor.withOpacity(0.3),
            spacing: const EdgeInsets.symmetric(horizontal: 4.0),
            activeShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
          dotsContainerDecorator: const ShapeDecoration(
            color: backgroundBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          ),
        ),
      ),
    );
  }
}
