import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flowlink_mobile/services/db_service.dart';

class NotificationEntry {
  final dynamic key;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  NotificationEntry({this.key, required this.title, required this.body, required this.createdAt, required this.read});

  factory NotificationEntry.fromMap(dynamic key, Map map) {
    return NotificationEntry(
      key: key,
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      read: (map['read'] ?? 0) == 1 || map['read'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'created_at': createdAt.millisecondsSinceEpoch,
        'read': read ? 1 : 0,
      };
}

class FaqEntry {
  final dynamic key;
  final String question;
  final String answer;
  FaqEntry({this.key, required this.question, required this.answer});

  factory FaqEntry.fromMap(dynamic key, Map map) {
    return FaqEntry(
      key: key,
      question: (map['q'] ?? '').toString(),
      answer: (map['a'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'q': question,
        'a': answer,
      };
}

class ContentService {
  ContentService._();
  static final ContentService instance = ContentService._();

  final ValueNotifier<List<NotificationEntry>> notifications = ValueNotifier<List<NotificationEntry>>(<NotificationEntry>[]);
  final ValueNotifier<List<FaqEntry>> faqs = ValueNotifier<List<FaqEntry>>(<FaqEntry>[]);

  StreamSubscription? _notiSub;
  StreamSubscription? _faqsSub;

  Future<void> init() async {
    // Ensure DbService initialized
    await DbService.instance.init();
    _reloadNotifications();
    await seedFaqsIfEmpty();
    _reloadFaqs();
    _notiSub?.cancel();
    _faqsSub?.cancel();
    _notiSub = DbService.instance.notifications.watch().listen((_) => _reloadNotifications());
    _faqsSub = DbService.instance.faqs.watch().listen((_) => _reloadFaqs());
  }

  void _reloadNotifications() {
    final box = DbService.instance.notifications;
    final list = <NotificationEntry>[];
    for (final k in box.keys) {
      final v = box.get(k);
      if (v is Map) list.add(NotificationEntry.fromMap(k, Map<String, dynamic>.from(v)));
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifications.value = list;
  }

  void _reloadFaqs() {
    final box = DbService.instance.faqs;
    final list = <FaqEntry>[];
    for (final k in box.keys) {
      final v = box.get(k);
      if (v is Map) list.add(FaqEntry.fromMap(k, Map<String, dynamic>.from(v)));
    }
    faqs.value = list;
  }

  Future<void> addNotification(String title, String body) async {
    final box = DbService.instance.notifications;
    await box.add({'title': title, 'body': body, 'created_at': DateTime.now().millisecondsSinceEpoch, 'read': 0});
  }

  Future<void> markNotificationRead(dynamic key, {bool read = true}) async {
    final box = DbService.instance.notifications;
    final raw = box.get(key);
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      m['read'] = read ? 1 : 0;
      await box.put(key, m);
    }
  }

  Future<void> saveContact({required String subject, required String email, required String message}) async {
    final box = DbService.instance.contacts;
    await box.add({
      'subject': subject,
      'email': email,
      'message': message,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> addFaq({required String question, required String answer}) async {
    final box = DbService.instance.faqs;
    await box.add({'q': question, 'a': answer});
  }

  Future<void> seedFaqsIfEmpty() async {
    final box = DbService.instance.faqs;
    final baseFaqs = <Map<String, String>>[
      {
        'q': 'How do I order grocery from this app?',
        'a': 'Browse categories or search for items. Tap Add to add products to your cart. When you are ready, go to My Cart, review items, select or add a delivery address, choose a payment method, and place the order. You can track the order status from the Orders tab.'
      },
      {
        'q': 'Are the prices different than at the shop?',
        'a': 'We work with multiple partners and run periodic offers. Prices can vary from in-store prices due to partner pricing, surge, packaging, or delivery fees. The final price is always shown at checkout before you pay.'
      },
      {
        'q': 'What happens if a product price changes after I order?',
        'a': 'Your order is locked at the price shown at checkout. If a partner changes the price before fulfillment, we will either honor the original price or notify you to approve the change. If you do not approve, the item will be removed and you will not be charged for it.'
      },
      {
        'q': 'How can I put special requests on my online order?',
        'a': 'Open the product and add a note (e.g., “Ripe bananas”, “No plastic bag”). For general delivery instructions (gate, block, or call-on-arrival), add a note in the address details at checkout.'
      },
      {
        'q': 'Who do I contact if there is a mistake with my order?',
        'a': 'Open the Orders tab, select the order, and tap Help or Contact Us to report an issue such as missing or damaged items. Our team will investigate and offer a replacement or refund as per policy.'
      },
      {
        'q': 'When are you getting more shops as partners?',
        'a': 'We are continuously onboarding stores. Follow our updates in Notifications and check the Home banner for newly added partners in your area.'
      },
      {
        'q': 'Which payment methods do you support?',
        'a': 'We support major credit/debit cards, UPI, and popular wallets (region dependent). Saved cards are tokenized and processed securely by our payment provider.'
      },
      {
        'q': 'How do refunds work?',
        'a': 'For canceled items or verified issues, refunds are initiated immediately after resolution. Card/UPI refunds usually reflect within 3–7 business days depending on your bank. You will receive a notification when a refund is processed.'
      },
      {
        'q': 'How do I track my order?',
        'a': 'Go to the Orders tab to view live status such as Packed, Shipped, or Out for Delivery. You will also see the expected delivery time and receive push notifications for important updates.'
      },
      {
        'q': 'Can I cancel or modify an order after placing it?',
        'a': 'You can cancel or edit items until the order moves to Packed. After that, cancellations may not be possible. Open the order in Orders and tap Modify or Cancel (if available). For urgent mistakes, contact support from the same screen.'
      },
      {
        'q': 'Is there a minimum order value or delivery fee?',
        'a': 'Some areas have a small order fee if your cart is below a threshold. Delivery fees depend on distance, time, and partner policies. All fees are transparently shown at checkout.'
      },
      {
        'q': 'How do promo codes and discounts work?',
        'a': 'Enter a valid promo code during checkout. If the code applies to your cart, the discount will be shown instantly. Some promotions auto-apply when eligible—no code needed.'
      },
      {
        'q': 'How is my data kept private?',
        'a': 'We collect only the data necessary to fulfill your orders and improve the service. Sensitive data (like payments) is processed by certified providers. You can request account/data deletion via Contact Us. See Privacy for full details.'
      },
      {
        'q': 'Which areas and times do you deliver?',
        'a': 'Delivery coverage depends on partner stores in your locality. Typical delivery hours are 8 AM–10 PM, with variations per store and peak periods. Check your address to see estimated times and availability.'
      },
    ];

    final existingQuestions = <String>{};
    for (final k in box.keys) {
      final v = box.get(k);
      if (v is Map && v['q'] is String) existingQuestions.add(v['q'] as String);
    }

    for (final m in baseFaqs) {
      if (!existingQuestions.contains(m['q'])) {
        await box.add(m);
      }
    }
  }
}
