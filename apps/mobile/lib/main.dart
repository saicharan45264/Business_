import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const configuredUrl = String.fromEnvironment('API_URL');
String get baseUrl => configuredUrl.isNotEmpty
    ? configuredUrl
    : (Platform.isAndroid
          ? 'http://10.0.2.2:3000/api/v1'
          : 'http://127.0.0.1:3000/api/v1');
Future<dynamic> request(
  String path, {
  Map<String, dynamic>? body,
  String method = 'POST',
}) async {
  final uri = Uri.parse('$baseUrl/$path');
  final response = body == null
      ? await http.get(uri)
      : method == 'PUT'
      ? await http.put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
      : await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
  final data = jsonDecode(response.body);
  if (response.statusCode >= 400)
    throw Exception(data['message'] ?? 'Request failed');
  return data;
}

String money(dynamic value) =>
    '₹${(double.tryParse('$value') ?? 0).toStringAsFixed(2)}';
void main() => runApp(const GiriApp());

class GiriApp extends StatelessWidget {
  const GiriApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Giri Fruits',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      useMaterial3: true,
    ),
    home: const Dashboard(),
  );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int selected = 0;
  bool loading = true;
  String? error;
  List<dynamic> products = [],
      parties = [],
      stock = [],
      sales = [],
      purchases = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await Future.wait(
        [
          'products',
          'parties',
          'stock',
          'books/customers',
          'books/dealer-bills',
        ].map((p) => request(p)),
      );
      if (!mounted) return;
      setState(() {
        products = data[0];
        parties = data[1];
        stock = data[2];
        sales = data[3];
        purchases = data[4];
        loading = false;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          error =
              'Unable to connect to the server. Check the API address and connection.\n$e';
          loading = false;
        });
    }
  }

  Future<void> addMaster(String type) async {
    final name = TextEditingController(), phone = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            if (type != 'fruit')
              TextField(
                controller: phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != true || name.text.trim().isEmpty) return;
    try {
      await request(
        type == 'fruit' ? 'products' : 'parties',
        body: type == 'fruit'
            ? {'name': name.text.trim()}
            : {
                'name': name.text.trim(),
                'role': type == 'customer' ? 'retailer' : 'supplier',
                'phone': phone.text.trim(),
              },
      );
      await load();
    } catch (e) {
      showError(e);
    }
  }

  void showError(Object e) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }

  Future<void> billEditor(bool dealer) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BillEditor(dealer: dealer, products: products, parties: parties),
      ),
    );
    if (changed == true) await load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _stock(), _bills(false), _bills(true)];
    return Scaffold(
      appBar: AppBar(
        title: const Text('గిరి ఫ్రూట్స్ · ఏలూరు'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : pages[selected],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (v) => setState(() => selected = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            label: 'Dealers',
          ),
        ],
      ),
    );
  }

  Widget _home() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'Business books',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonal(
            onPressed: () => addMaster('customer'),
            child: const Text('Add customer'),
          ),
          FilledButton.tonal(
            onPressed: () => addMaster('dealer'),
            child: const Text('Add dealer'),
          ),
          FilledButton.tonal(
            onPressed: () => addMaster('fruit'),
            child: const Text('Add fruit'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: () => billEditor(false),
        icon: const Icon(Icons.add),
        label: const Text('Create customer bill'),
      ),
      const SizedBox(height: 8),
      FilledButton.tonalIcon(
        onPressed: () => billEditor(true),
        icon: const Icon(Icons.add),
        label: const Text('Create dealer bill'),
      ),
      const SizedBox(height: 20),
      const Text('Development preview — not ready for live business records.'),
    ],
  );
  Widget _stock() => RefreshIndicator(
    onRefresh: load,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Available boxes',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        if (stock.isEmpty) const ListTile(title: Text('No fruit added yet.')),
        for (final item in stock)
          Card(
            child: ListTile(
              title: Text('${item['name']}'),
              trailing: Text('${item['boxes']} boxes'),
            ),
          ),
      ],
    ),
  );
  Widget _bills(bool dealer) {
    final bills = dealer ? purchases : sales;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dealer ? 'Dealer bills' : 'Customer bills',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () => billEditor(dealer),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'New bill',
            ),
          ],
        ),
        if (bills.isEmpty) const ListTile(title: Text('No bills yet.')),
        for (final b in bills)
          Card(
            child: ListTile(
              title: Text('${b[dealer ? 'dealer' : 'customer']}'),
              subtitle: Text(
                '${b[dealer ? 'bill_date' : 'sale_date']} · Remaining ${money(b['remaining'])}',
              ),
              trailing: Text(money(b['current_total'])),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BillDetails(bill: b, dealer: dealer, onChanged: load),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class BillDetails extends StatefulWidget {
  final Map<String, dynamic> bill;
  final bool dealer;
  final Future<void> Function() onChanged;
  const BillDetails({
    super.key,
    required this.bill,
    required this.dealer,
    required this.onChanged,
  });
  @override
  State<BillDetails> createState() => _BillDetailsState();
}

class _BillDetailsState extends State<BillDetails> {
  late Map<String, dynamic> bill;
  @override
  void initState() {
    super.initState();
    bill = Map.of(widget.bill);
  }

  Future<void> pay() async {
    final c = TextEditingController(text: '${bill['amount_paid']}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update amount paid'),
        content: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final r = await request(
        widget.dealer
            ? 'books/dealer-bills/${bill['id']}/payment'
            : 'sales/${bill['id']}/payment',
        method: 'PUT',
        body: {'amountPaid': c.text},
      );
      setState(() {
        bill['amount_paid'] = r['amount_paid'];
        bill['remaining'] = r['remaining'];
      });
      await widget.onChanged();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.dealer ? 'Dealer bill' : 'Customer bill'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${bill[widget.dealer ? 'dealer' : 'customer']}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          'Bill #${bill['id']} · ${bill[widget.dealer ? 'bill_date' : 'sale_date']}',
        ),
        const Divider(),
        for (final i in bill['items'] as List<dynamic>)
          ListTile(
            title: Text('${i['fruit']}'),
            subtitle: Text(
              '${i['quantity']} boxes × ${money(i['price_per_box'])}',
            ),
            trailing: Text(money(i['total_price'])),
          ),
        const Divider(),
        ListTile(
          title: const Text('Current bill'),
          trailing: Text(money(bill['current_total'])),
        ),
        ListTile(
          title: const Text('Previous outstanding'),
          trailing: Text(money(bill['previous_due'])),
        ),
        ListTile(
          title: const Text('Paid'),
          trailing: Text(money(bill['amount_paid'])),
        ),
        ListTile(
          title: const Text('Remaining on this bill'),
          trailing: Text(money(bill['remaining'])),
        ),
        FilledButton(onPressed: pay, child: const Text('Update amount paid')),
      ],
    ),
  );
}

class BillLine {
  String? product;
  String boxes = '';
  String price = '';
}

class BillEditor extends StatefulWidget {
  final bool dealer;
  final List<dynamic> products, parties;
  const BillEditor({
    super.key,
    required this.dealer,
    required this.products,
    required this.parties,
  });
  @override
  State<BillEditor> createState() => _BillEditorState();
}

class _BillEditorState extends State<BillEditor> {
  String? party;
  DateTime date = DateTime.now();
  final lines = <BillLine>[BillLine()];
  final paid = TextEditingController(text: '0');
  bool saving = false;
  String? requestKey;
  @override
  void dispose() {
    paid.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (party == null ||
        lines.any(
          (l) =>
              l.product == null ||
              (int.tryParse(l.boxes) ?? 0) < 1 ||
              !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(l.price),
        ) ||
        !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(paid.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select a party and fruit, and enter valid boxes and prices.',
          ),
        ),
      );
      return;
    }
    setState(() => saving = true);
    requestKey ??= 'mobile-${DateTime.now().microsecondsSinceEpoch}';
    final dateText =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final body = <String, dynamic>{
      widget.dealer ? 'dealerId' : 'retailerId': int.parse(party!),
      widget.dealer ? 'billDate' : 'saleDate': dateText,
      'requestKey': requestKey,
      'amountPaid': paid.text,
      'lines': lines
          .map(
            (l) => {
              'productId': int.parse(l.product!),
              'boxes': int.parse(l.boxes),
              'unitPrice': l.price,
            },
          )
          .toList(),
    };
    try {
      await request(widget.dealer ? 'books/dealer-bills' : 'sales', body: body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e. Check the bill list before retrying.')),
        );
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = widget.parties
        .where((p) => p['role'] == (widget.dealer ? 'supplier' : 'retailer'))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dealer ? 'New dealer bill' : 'New customer bill'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: party,
            decoration: InputDecoration(
              labelText: widget.dealer ? 'Dealer' : 'Customer',
            ),
            items: contacts
                .map(
                  (p) => DropdownMenuItem<String>(
                    value: '${p['id']}',
                    child: Text('${p['name']}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => party = v),
          ),
          ListTile(
            title: Text(
              'Bill date: ${date.toIso8601String().substring(0, 10)}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => date = picked);
            },
          ),
          for (var n = 0; n < lines.length; n++)
            Card(
              key: ObjectKey(lines[n]),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: lines[n].product,
                      decoration: const InputDecoration(labelText: 'Fruit'),
                      items: widget.products
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: '${p['id']}',
                              child: Text('${p['name']}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => lines[n].product = v),
                    ),
                    TextFormField(
                      initialValue: lines[n].boxes,
                      decoration: const InputDecoration(labelText: 'Boxes'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => lines[n].boxes = v,
                    ),
                    TextFormField(
                      initialValue: lines[n].price,
                      decoration: const InputDecoration(
                        labelText: 'Price per box',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (v) => lines[n].price = v,
                    ),
                    if (lines.length > 1)
                      TextButton(
                        onPressed: () => setState(() => lines.removeAt(n)),
                        child: const Text('Remove fruit'),
                      ),
                  ],
                ),
              ),
            ),
          TextButton.icon(
            onPressed: () => setState(() => lines.add(BillLine())),
            icon: const Icon(Icons.add),
            label: const Text('Add another fruit'),
          ),
          TextField(
            controller: paid,
            decoration: const InputDecoration(labelText: 'Amount paid'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? 'Saving…' : 'Generate bill'),
          ),
        ],
      ),
    );
  }
}
