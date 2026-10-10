import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../booking/booking_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.service});
  final PetService service;

  Future<void> _call(BuildContext context) async {
    final digits = service.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final ok = await launchUrl(Uri(scheme: 'tel', path: digits));
    if (!ok && context.mounted) showSnack(context, 'Could not open the dialer', error: true);
  }

  Future<void> _map(BuildContext context) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${service.provider}, ${service.location}',
    });
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showSnack(context, 'Could not open maps', error: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'svc_${service.id}',
                child: Image.asset(service.image, fit: BoxFit.cover),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(service.name,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('${service.provider} · ${service.location}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 15)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(icon: Icons.star_rounded, text: '${service.rating} (${service.reviews})'),
                    _Pill(icon: Icons.timer_outlined, text: service.duration),
                    _Pill(text: service.priceLabel, dark: true),
                  ],
                ),
                const SectionHeader('About this service'),
                Text(service.description,
                    style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.ink)),
                const SectionHeader('Includes'),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    for (final i in service.includes)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(i),
                        ],
                      ),
                  ],
                ),
                const SectionHeader('Location & hours'),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _map(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 96,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, color: AppColors.primary, size: 30),
                            Text('Open map',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.hours, style: const TextStyle(color: AppColors.muted)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _call(context),
                            child: Row(
                              children: [
                                const Icon(Icons.phone, size: 18, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(service.phone,
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BookingScreen(initialServiceId: service.id)),
                  ),
                  child: const Text('Book This Service'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({this.icon, required this.text, this.dark = false});
  final IconData? icon;
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: icon == Icons.star_rounded ? const Color(0xFFF59E0B) : AppColors.muted),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  color: dark ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
