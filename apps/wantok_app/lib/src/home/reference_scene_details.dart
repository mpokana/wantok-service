import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'smoke_data.dart';
import 'wantok_category_ui.dart';

/// Additional preview-only layouts: no API clients, route dispatch or payments.
class ReferenceSceneDetails extends StatelessWidget {
  const ReferenceSceneDetails({super.key, required this.scene});
  final String scene;
  @override
  Widget build(BuildContext context) => switch (scene) {
    'foodListing' => const _FoodListing(),
    'taxi' => const _TaxiOptions(),
    'travel' => const _TravelForm(),
    'bookings' => const _BookingTabs(),
    'tracking' => const _DriverDetails(),
    'wallet' => const _WalletActions(),
    'account' => const _AccountMenu(),
    'home' => const _HomeQuickLinks(),
    _ => const SizedBox.shrink(),
  };
}

class _Heading extends StatelessWidget {
  const _Heading(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        const SmokeMarker(),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
        ),
      ],
    ),
  );
}

class _FoodListing extends StatelessWidget {
  const _FoodListing();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: WantokColors.primary,
            size: 18,
          ),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              'Waigani, Port Moresby · sample location',
              style: TextStyle(fontSize: 12),
            ),
          ),
          SmokeMarker(),
        ],
      ),
      const SizedBox(height: 9),
      const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Pill('Sort'),
            SizedBox(width: 6),
            _Pill('Open now'),
            SizedBox(width: 6),
            _Pill('Cuisine'),
            SizedBox(width: 6),
            _Pill('Price'),
          ],
        ),
      ),
      const _Heading('Sample restaurants'),
      for (var i = 0; i < SmokeCatalogue.food.length; i++)
        _RestaurantRow(record: SmokeCatalogue.food[i], index: i),
    ],
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE4E9F1)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        color: WantokColors.muted,
      ),
    ),
  );
}

class _RestaurantRow extends StatelessWidget {
  const _RestaurantRow({required this.record, required this.index});
  final SmokeRecord record;
  final int index;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0xFFE9EDF4)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset(
              record.asset,
              width: 79,
              height: 78,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SmokeMarker(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  index == 2
                      ? 'Coffee · Pastries'
                      : index == 3
                      ? 'Asian · Noodles'
                      : 'Seafood · PNG cuisine',
                  style: const TextStyle(
                    color: WantokColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFF6AE11),
                    ),
                    Text(
                      ' ${['4.6', '4.5', '4.7', '4.4'][index % 4]} sample · 20–30 min',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                const Text(
                  'Illustrative delivery · no ordering',
                  style: TextStyle(color: WantokColors.muted, fontSize: 10),
                ),
                Text(
                  record.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WantokColors.primary,
                    fontSize: 8.5,
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

class _TaxiOptions extends StatefulWidget {
  const _TaxiOptions();
  @override
  State<_TaxiOptions> createState() => _TaxiOptionsState();
}

class _TaxiOptionsState extends State<_TaxiOptions> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Heading('Choose a sample taxi'),
      Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 7),
                child: InkWell(
                  key: ValueKey('sample-vehicle-$i'),
                  onTap: () => setState(() => selected = i),
                  child: Container(
                    height: 105,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: selected == i
                          ? const Color(0xFFEAF3FF)
                          : Colors.white,
                      border: Border.all(
                        color: selected == i
                            ? WantokColors.primary
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          i == 0 ? Icons.local_taxi : Icons.directions_car,
                          color: i == 0
                              ? const Color(0xFFF3B117)
                              : WantokColors.primary,
                          size: 30,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          ['Standard', 'Comfort', 'Van'][i],
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          ['K25–30', 'K35–40', 'K50–60'][i],
                          style: const TextStyle(fontSize: 10),
                        ),
                        const Text(
                          's sample',
                          style: TextStyle(
                            fontSize: 9,
                            color: WantokColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 9),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.account_balance_wallet_outlined,
          color: WantokColors.primary,
        ),
        title: Text(
          'Pay with Wallet · sample only',
          style: TextStyle(fontSize: 12),
        ),
        trailing: SmokeMarker(),
      ),
      const _SampleDisabledButton('Request Taxi'),
    ],
  );
}

class _SampleDisabledButton extends StatelessWidget {
  const _SampleDisabledButton(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: null,
      icon: const SmokeMarker(),
      label: Text('$label · sample disabled'),
    ),
  );
}

class _TravelForm extends StatefulWidget {
  const _TravelForm();
  @override
  State<_TravelForm> createState() => _TravelFormState();
}

class _TravelFormState extends State<_TravelForm> {
  int mode = 0;
  int trip = 0;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  label: Text(
                    ['Flights', 'Hotels', 'Packages'][i],
                    style: const TextStyle(fontSize: 10),
                  ),
                  selected: mode == i,
                  onSelected: (_) => setState(() => mode = i),
                ),
              ),
            ),
        ],
      ),
      Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  label: Text(
                    ['Return', 'One way', 'Multi-city'][i],
                    style: const TextStyle(fontSize: 10),
                  ),
                  selected: trip == i,
                  onSelected: (_) => setState(() => trip = i),
                ),
              ),
            ),
        ],
      ),
      const _Heading('Sample travel enquiry'),
      const _ReadOnlyField('From', 'Port Moresby (POM)', Icons.flight_takeoff),
      const SizedBox(height: 7),
      const _ReadOnlyField('To', 'Brisbane (BNE)', Icons.flight_land),
      const SizedBox(height: 7),
      const Row(
        children: [
          Expanded(
            child: _ReadOnlyField('Depart', '12 Dec', Icons.calendar_month),
          ),
          SizedBox(width: 7),
          Expanded(
            child: _ReadOnlyField('Return', '20 Dec', Icons.calendar_month),
          ),
        ],
      ),
      const SizedBox(height: 7),
      const Row(
        children: [
          Expanded(
            child: _ReadOnlyField(
              'Passengers',
              '1 Adult',
              Icons.person_outline,
            ),
          ),
          SizedBox(width: 7),
          Expanded(
            child: _ReadOnlyField(
              'Class',
              'Economy',
              Icons.airline_seat_recline_normal,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const _SampleDisabledButton('Search Flights'),
    ],
  );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE5EAF2)),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      children: [
        Icon(icon, size: 19, color: WantokColors.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: WantokColors.muted),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SmokeMarker(),
      ],
    ),
  );
}

class _BookingTabs extends StatefulWidget {
  const _BookingTabs();
  @override
  State<_BookingTabs> createState() => _BookingTabsState();
}

class _BookingTabsState extends State<_BookingTabs> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(
                    ['All', 'Upcoming', 'Past', 'Cancelled'][i],
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: selected == i,
                  onSelected: (_) => setState(() => selected = i),
                ),
              ),
          ],
        ),
      ),
      const SmokePreviewSection(
        scene: SmokeScene.bookings,
        heading: 'Sample bookings',
      ),
    ],
  );
}

class _DriverDetails extends StatelessWidget {
  const _DriverDetails();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Heading('Driver on the way'),
      const Text(
        'Illustrative ETA: 3 minutes · not live GPS',
        style: TextStyle(color: WantokColors.muted, fontSize: 12),
      ),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Color(0xFFE9F2FF),
          child: Icon(Icons.person, color: WantokColors.primary),
        ),
        title: Text(
          'John P. · sample driver',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        subtitle: Text('Toyota Corolla · BEA 123 · illustration only'),
        trailing: SmokeMarker(),
      ),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InactiveAction(Icons.call_outlined, 'Call'),
          _InactiveAction(Icons.chat_outlined, 'Message'),
          _InactiveAction(Icons.share_outlined, 'Share'),
        ],
      ),
    ],
  );
}

class _InactiveAction extends StatelessWidget {
  const _InactiveAction(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: const Color(0xFFB1BECE), size: 22),
      const SizedBox(height: 3),
      Text(
        '$label · sample',
        style: const TextStyle(fontSize: 10, color: WantokColors.muted),
      ),
    ],
  );
}

class _WalletActions extends StatelessWidget {
  const _WalletActions();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 14),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InactiveAction(Icons.add_circle_outline, 'Add money'),
          _InactiveAction(Icons.send_outlined, 'Send'),
          _InactiveAction(Icons.qr_code, 'Pay'),
          _InactiveAction(Icons.receipt_long, 'History'),
        ],
      ),
      const SmokePreviewSection(
        scene: SmokeScene.wallet,
        heading: 'Sample recent transactions',
      ),
    ],
  );
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Card(
        elevation: 0,
        color: Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(0xFFE9F2FF),
            child: Icon(Icons.person, color: WantokColors.primary),
          ),
          title: Text(
            'Sample account',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text('Not the signed-in user'),
          trailing: SmokeMarker(),
        ),
      ),
      for (final item in const [
        ('My Bookings', Icons.event_note),
        ('Wallet & Payments', Icons.account_balance_wallet),
        ('Saved Places', Icons.location_on_outlined),
        ('Trusted People', Icons.group_outlined),
        ('Preferences', Icons.tune_rounded),
        ('Help & Support', Icons.help_outline),
        ('Settings', Icons.settings_outlined),
      ])
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            leading: Icon(item.$2, size: 21, color: WantokColors.primary),
            title: Text(item.$1, style: const TextStyle(fontSize: 13)),
            trailing: const SmokeMarker(),
          ),
        ),
    ],
  );
}

class _HomeQuickLinks extends StatelessWidget {
  const _HomeQuickLinks();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Heading('What do you need today?'),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 7,
        mainAxisSpacing: 7,
        childAspectRatio: 1.06,
        children: [
          for (final style in const [
            WantokCategoryStyles.taxi,
            WantokCategoryStyles.food,
            WantokCategoryStyles.groceries,
            WantokCategoryStyles.shopping,
            WantokCategoryStyles.home,
            WantokCategoryStyles.travel,
          ])
            Container(
              decoration: BoxDecoration(
                color: style.accent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WantokCategoryBadge(style: style, size: 35, iconSize: 19),
                  const SizedBox(height: 7),
                  Text(
                    style.title.replaceAll('\n', ' '),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                  const SmokeMarker(),
                ],
              ),
            ),
        ],
      ),
    ],
  );
}
