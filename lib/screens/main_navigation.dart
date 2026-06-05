import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:pocketpos/screens/screens.dart';
import 'package:pocketpos/theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        onJumpToCart: () {
          _controller.jumpToTab(2);
        },
      ),
      const ProductsScreen(),
      const CartScreen(),
      const SettingsScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.bar_chart_outlined),
        title: ("Ventas"),
        activeColorPrimary: AppTheme.terracotta,
        inactiveColorPrimary: AppTheme.gray,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.inventory_2_outlined),
        title: ("Catálogo"),
        activeColorPrimary: AppTheme.terracotta,
        inactiveColorPrimary: AppTheme.gray,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.shopping_cart_outlined),
        title: ("Carrito"),
        activeColorPrimary: AppTheme.terracotta,
        inactiveColorPrimary: AppTheme.gray,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.settings_outlined),
        title: ("Ajustes"),
        activeColorPrimary: AppTheme.terracotta,
        inactiveColorPrimary: AppTheme.gray,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineToSafeArea: true,
      backgroundColor: Colors.white, // Default is Colors.white.
      handleAndroidBackButtonPress: true, // Default is true.
      resizeToAvoidBottomInset: true, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
      stateManagement: true, // Default is true.
      hideNavigationBarWhenKeyboardAppears: true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
      popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,
      padding: const EdgeInsets.only(top: 8),
      navBarStyle: NavBarStyle.style1, // Choose the nav bar style with this property.
    );
  }
}
