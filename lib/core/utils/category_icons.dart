import 'package:flutter/material.dart';

class CategoryIcons {
  static IconData getIcon(String iconName) {
    switch (iconName) {
      // Expenses
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_basket':
        return Icons.shopping_basket;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'receipt':
        return Icons.receipt_long;
      case 'home':
        return Icons.home;
      case 'medical_services':
        return Icons.medical_services;
      case 'movie':
        return Icons.movie;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'spa':
        return Icons.spa;
      case 'more_horiz':
        return Icons.more_horiz;
      // Income
      case 'work':
        return Icons.work;
      case 'monetization_on':
        return Icons.monetization_on;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'trending_up':
        return Icons.trending_up;
      case 'autorenew':
        return Icons.autorenew;
      case 'attach_money':
        return Icons.attach_money;
      // Custom generic defaults
      case 'account_balance':
        return Icons.account_balance;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'phone_android':
        return Icons.phone_android;
      case 'pets':
        return Icons.pets;
      case 'fitness_center':
        return Icons.fitness_center;
      default:
        return Icons.category;
    }
  }

  static List<String> getAvailableIcons() {
    return [
      'restaurant',
      'shopping_basket',
      'directions_car',
      'shopping_bag',
      'receipt',
      'home',
      'medical_services',
      'movie',
      'school',
      'flight',
      'spa',
      'work',
      'monetization_on',
      'card_giftcard',
      'trending_up',
      'autorenew',
      'attach_money',
      'account_balance',
      'local_gas_station',
      'phone_android',
      'pets',
      'fitness_center',
    ];
  }
}
