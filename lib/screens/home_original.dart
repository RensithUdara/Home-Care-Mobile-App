import 'package:flutter/material.dart';
import 'package:home_care/components/add_product.dart';
import 'package:home_care/components/bottom_add_bar.dart';
import 'package:home_care/components/item_tile.dart';
import 'package:home_care/components/search_bar.dart'; // Ensure this is imported
import 'package:home_care/models/products.dart';
import 'package:home_care/screens/product.dart';
import 'package:home_care/screens/profile.dart';
import 'package:home_care/services/firestore/firestore_services.dart';

class Home extends StatefulWidget {
  final String uid;
  final String email;

  const Home({super.key, required this.uid, required this.email});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<List<Products>> _products;
  int _productsCount = 0;

  @override
  void initState() {
    super.initState();
    refreshProducts();
  }

  void refreshProducts() {
    setState(() {
      _products = FirestoreService.fetchProducts(widget.uid);
    });

    // Update count after products are fetched
    _products.then((products) {
      updateCount(products.length);
    });
  }

  void updateCount(int length) {
    setState(() {
      _productsCount = length;
    });
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  void deleteProduct(String id) async {
    await FirestoreService.deleteProduct(id);
    refreshProducts();
  }

  @override
  Widget build(BuildContext context) {
    int hour = DateTime.now().hour;
    String greeting = _getGreeting(hour);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$greeting,",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              "Welcome to Home Care !",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.inversePrimary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 12.0,
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProfilePage(
                              email: widget.email,
                            )));
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset(
                  'images/avatar.jpg',
                  height: 45,
                  width: 45,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding:
            const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 5,
            ),
            const MainSearchBar(),
            const SizedBox(
              height: 3,
            ),
            Expanded(
              child: FutureBuilder<List<Products>>(
                future: _products,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }

                  List<Products> products = snapshot.data!;

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      Products product = products[index];
                      return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductPage(
                                  product: product,
                                  onDelete: deleteProduct,
                                  onProductEdited: refreshProducts,
                                ),
                              ),
                            );
                          },
                          child: ItemTile(product: product));
                    },
                  );
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            BottomAddBar(
              productCount: _productsCount,
              onTap: () {
                _showAddProductBottomSheet(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddProductBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return AddProductBottomSheet(
          onProductAdded: refreshProducts,
          uid: widget.uid,
        );
      },
    );
  }
}
