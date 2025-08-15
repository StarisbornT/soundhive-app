

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/model/asset_model.dart';
import 'package:soundhive2/utils/utils.dart';

class AssetsDetailsScreen extends ConsumerStatefulWidget {
  final Asset asset;
  const AssetsDetailsScreen({Key? key, required this.asset}) : super(key: key);

  @override
  ConsumerState<AssetsDetailsScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends ConsumerState<AssetsDetailsScreen> {

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(widget.asset.imageUrl ?? '', height: 200, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.asset.assetName,
              style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1A191E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 Utils.confirmRow('Status', widget.asset.status),
                  Utils.confirmRow('Asset Type', widget.asset.assetType),
                 Utils.confirmRow('Price', Utils.formatCurrency(widget.asset.price)),
                  Utils.confirmRow('Date Submitted', DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.asset.createdAt)))

                ],
              ),
            ),
            const SizedBox(height: 16),
             Container(
               width: double.infinity,
               padding: EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Color(0xFF1A191E),
                 borderRadius: BorderRadius.circular(10),
               ),
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.start,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                    "About ${widget.asset.assetName}",
                    style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400,
                    ),
                               ),
                    Text(
                     widget.asset.assetDescription,
                     style: TextStyle(color: Colors.grey, fontSize: 14),
                   ),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }

}