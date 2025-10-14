import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_food_page.dart';
import 'edit_food_page.dart';
import 'food_detail_screen.dart';

class FoodListPage extends StatelessWidget {
  const FoodListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final foods = FirebaseFirestore.instance.collection('foods');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách món ăn'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: foods.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('Chưa có món ăn nào!'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final food = docs[i];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: food['image_url'] != null && food['image_url'] != ''
                      ? Image.network(food['image_url'], width: 60, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.fastfood, size: 40),
                  title: Text(food['name']),
                  subtitle: Text('Calo: ${food['calories']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FoodDetailScreen(foodId: food.id),
                      ),
                    );
                  },
                  trailing: PopupMenuButton(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EditFoodPage(foodId: food.id, data: food)),
                        );
                      } else if (value == 'delete') {
                        await foods.doc(food.id).delete();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xóa món ăn!')),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                      const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                  ),
                ),

              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFoodPage()));
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
