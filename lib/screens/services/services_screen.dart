import 'package:flutter/material.dart';

import '../../data/catalog.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'service_detail_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String _category = 'All';
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final list = serviceCatalog.where((s) {
      final catOk = _category == 'All' || s.category == _category;
      final qOk = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.provider.toLowerCase().contains(q) ||
          s.location.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search services or clinics',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          }),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in serviceCategories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _category == c ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                  icon: Icons.search_off,
                  title: 'No services found',
                  message: 'Try another keyword or category.'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ServiceTile(service: list[i]),
                  childCount: list.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ServiceTile extends StatelessWidget {
  const ServiceTile({super.key, required this.service});
  final PetService service;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Hero(
                tag: 'svc_${service.id}',
                child: Image.asset(service.image, fit: BoxFit.cover),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(service.provider,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    const Spacer(),
                    Text(service.priceLabel,
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text('${service.rating} · ${service.duration}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
