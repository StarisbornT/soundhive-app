import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/model/market_orders_service_model.dart';
import 'package:soundhive2/utils/extension.dart';
import '../../../../model/service_model.dart';
import '../../../../utils/utils.dart';

// class MarketplaceReceiptScreen extends ConsumerStatefulWidget {
//   final String serviceId;
//   const MarketplaceReceiptScreen({Key? key, required this.serviceId})
//       : super(key: key);
//
//   @override
//   ConsumerState<MarketplaceReceiptScreen> createState() => _AssetScreenState();
// }
//
// class _AssetScreenState extends ConsumerState<MarketplaceReceiptScreen> {
//
//   // Widget build(BuildContext context) {
//   //   return Scaffold(
//   //       backgroundColor: Colors.black,
//   //       appBar: AppBar(
//   //         backgroundColor: Colors.transparent,
//   //         elevation: 0,
//   //         leading: IconButton(
//   //           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//   //           onPressed: () => Navigator.pop(context),
//   //         ),
//   //       ),
//   //       body: SingleChildScrollView(
//   //           padding: const EdgeInsets.all(16.0),
//   //           child: Column(
//   //               crossAxisAlignment: CrossAxisAlignment.start, children: [
//   //             Text(
//   //               service.service.serviceType,
//   //               style: const TextStyle(
//   //                 color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500,
//   //               ),
//   //             ),
//   //             Container(
//   //               alignment: Alignment.center,
//   //               child: Column(
//   //                 children: [
//   //                   Text(
//   //                     'You Paid',
//   //                     textAlign: TextAlign.center,
//   //                     style: const TextStyle(
//   //                       color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300,
//   //                     ),
//   //                   ),
//   //                   Text(
//   //                     Utils.formatCurrency(service.service.totalAmountPaid),
//   //                     textAlign: TextAlign.center,
//   //                     style: const TextStyle(
//   //                       color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400,
//   //                     ),
//   //                   ),
//   //                 ],
//   //               ),
//   //             ),
//   //             Container(
//   //               width: double.infinity,
//   //               padding: EdgeInsets.all(16),
//   //               decoration: BoxDecoration(
//   //                 color: Color(0xFF1A191E),
//   //                 borderRadius: BorderRadius.circular(10),
//   //               ),
//   //               child: Column(
//   //                 crossAxisAlignment: CrossAxisAlignment.start,
//   //                 children: [
//   //                   Utils.confirmRow('Service', service.service.serviceType),
//   //                   const SizedBox(height: 20,),
//   //                   Utils.confirmRow('Work Type', service.service.workType),
//   //                   const SizedBox(height: 20,),
//   //                   Utils.confirmRow('Service Provider', "${service.service.seller.firstName} ${service.service.seller.lastName}"),
//   //                   const SizedBox(height: 20,),
//   //                   Utils.confirmRow('Start Date', DateFormat('dd/MM/yyyy').format(DateTime.parse(service.createdAt))),
//   //                   const SizedBox(height: 20,),
//   //                   Utils.confirmRow('Completed Date', service.purchaseApprovalAt == null ? '' : DateFormat('dd/MM/yyyy').format(DateTime.parse(service.purchaseApprovalAt!)) ),
//   //                   const SizedBox(height: 20,),
//   //                   Center(
//   //                     child: ClipRRect(
//   //                       borderRadius: BorderRadius.circular(10),
//   //                       child: Image.network(service.service.imageUrl ?? '', height: 200, fit: BoxFit.cover),
//   //                     ),
//   //                   ),
//   //                 ],
//   //               ),
//   //             ),
//   //           ])));
//   // }
// }