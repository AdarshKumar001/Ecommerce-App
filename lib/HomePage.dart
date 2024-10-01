import 'dart:convert';
import 'dart:io';  // Needed for using File
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AddProductPage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> productList = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  // Load products from SharedPreferences
  Future<void> loadProducts() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? productsString = prefs.getString('products');
    if (productsString != null) {
      List<dynamic> productsJson = jsonDecode(productsString);
      productList = productsJson.map((product) => Map<String, dynamic>.from(product)).toList();
    }
    filteredProducts = productList;
    setState(() {
      isLoading = false;
    });
  }

  // Delete a product
  Future<void> deleteProduct(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    productList.removeAt(index);
    prefs.setString('products', jsonEncode(productList));
    setState(() {
      filteredProducts = productList;
    });
  }

  // Filter products based on the search query
  void filterProducts(String query) {
    List<Map<String, dynamic>> filtered = productList
        .where((product) =>
        product['name'].toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {
      filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Product',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                filterProducts(value);
              },
            ),
            const SizedBox(height: 10),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(child: Text('No Product Found'))
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Display 2 items in a row
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                  childAspectRatio: 2 / 3, // Adjust the aspect ratio
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  // Get product image path (if exists)
                  String? imagePath = filteredProducts[index]['image'];

                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: imagePath != null && imagePath.isNotEmpty
                              ? Image.file(
                            File(imagePath),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                              : const Icon(Icons.image_not_supported, size: 80),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    filteredProducts[index]['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '\$${filteredProducts[index]['price']}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),

                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  deleteProduct(index);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Product deleted')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductPage()),
          );
          loadProducts(); // Reload products when returning from AddProductPage
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
