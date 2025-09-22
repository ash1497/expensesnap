import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_application/view_models/bottomnav_view_model.dart';
import 'package:receipt_application/views/history_view.dart';
import 'package:receipt_application/views/home_view.dart';
import 'package:receipt_application/views/account_view.dart';

class BottomNavView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavViewModel>(
      builder: (context, bottomNavViewModel, child) {
        return Scaffold(
          body: IndexedStack(
            index: bottomNavViewModel.selectedIndex,
            children: [
              HomeView(), // Home
              const HistoryView(), // History
              AccountView(), // Account
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.white, // Keep the background color white
            currentIndex: bottomNavViewModel.selectedIndex,
            onTap: bottomNavViewModel.setSelectedIndex,
            type: BottomNavigationBarType
                .fixed, // Ensures equal spacing for icons
            selectedFontSize: 12, // Smaller font for labels
            unselectedFontSize: 10, // Smaller font for unselected labels
            selectedItemColor:
                const Color.fromARGB(255, 11, 61, 68), // Active icon color
            unselectedItemColor:
                const Color.fromARGB(255, 0, 0, 0), // Inactive icon color
            iconSize: 20, // Reduced icon size
            elevation: 8, // Subtle shadow for the navbar
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                activeIcon: _buildHighlightedIcon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history),
                activeIcon: _buildHighlightedIcon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                activeIcon: _buildHighlightedIcon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        );
      },
    );
  }

  // Add a subtle highlight indicator for active icons
  Widget _buildHighlightedIcon(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color.fromARGB(255, 11, 61, 68)
            .withOpacity(0.1), // Subtle highlight
      ),
      padding: const EdgeInsets.all(
          6.0), // Smaller padding for the circular highlight
      child: Icon(
        icon,
        size: 22, // Slightly larger size for active icons
        color: const Color.fromARGB(255, 11, 61, 68), // Match the active color
      ),
    );
  }
}
