import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/home_screen.dart';
import 'package:flowlink_mobile/ui/cart_screen.dart';
import 'package:flowlink_mobile/ui/orders_list_screen.dart';
import 'package:flowlink_mobile/ui/more_screen.dart';
import 'package:flowlink_mobile/services/assistant_notifier.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';

class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final GlobalKey<NavigatorState> _homeKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _ordersKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _cartKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _moreKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      Navigator(
        key: _homeKey,
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => HomeScreen(
            showBottomNav: false,
            onOpenCartTab: () => setState(() => _currentIndex = 2),
          ),
        ),
      ),
      Navigator(
        key: _ordersKey,
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const OrdersListScreen()),
      ),
      Navigator(
        key: _cartKey,
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const CartScreen()),
      ),
      Navigator(
        key: _moreKey,
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const MoreScreen()),
      ),
    ];
  }

  Future<bool> _onWillPop() async {
    final currentKey = [_homeKey, _ordersKey, _cartKey, _moreKey][_currentIndex];
    final nav = currentKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: _TabNavScope(
        currentNavigatorKey: () => [_homeKey, _ordersKey, _cartKey, _moreKey][_currentIndex],
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: ValueListenableBuilder<bool>(
            valueListenable: AssistantNotifier.instance.isOpen,
            builder: (_, isOpen, __) {
              if (isOpen) return const SizedBox.shrink();
              return _BottomNavPersistent(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabNavScope extends InheritedWidget {
  const _TabNavScope({required this.currentNavigatorKey, required super.child});
  final GlobalKey<NavigatorState> Function() currentNavigatorKey;

  static _TabNavScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_TabNavScope>();
    assert(scope != null, 'No _TabNavScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant _TabNavScope oldWidget) => false;
}

class _BottomNavPersistent extends StatelessWidget {
  const _BottomNavPersistent({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          if (theme.brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.greenPrimary,
          unselectedItemColor: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black45,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          iconSize: 24,
          onTap: onTap,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: _ActiveNavIcon(icon: Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: _ActiveNavIcon(icon: Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: _ActiveNavIcon(icon: Icons.shopping_cart),
              label: 'My Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: _ActiveNavIcon(icon: Icons.grid_view),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveNavIcon extends StatelessWidget {
  const _ActiveNavIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.greenPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.greenPrimary),
    );
  }
}
