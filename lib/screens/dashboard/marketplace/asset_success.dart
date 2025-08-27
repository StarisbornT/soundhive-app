
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../model/asset_model.dart';
import '../../../utils/utils.dart';

// class OrderSuccessScreen extends ConsumerStatefulWidget {
//   final Asset asset;
//   const OrderSuccessScreen({Key? key, required this.asset}) : super(key: key);
//
//   // @override
//   // _OrderSuccessScreenState createState() => _OrderSuccessScreenState();
// }
// class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen>  {
//   bool _isDownloading = false;
//   double _downloadProgress = 0;
//   final _download  = MediaDownload();
//   Future<void> _downloadFile() async {
//       _download.downloadMedia(context, widget.asset.assetUrl);
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//           child: Padding(
//               padding: EdgeInsets.all(12.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Order',
//                   textAlign: TextAlign.left,
//                   style: TextStyle(color: Colors.white, fontSize: 24),
//                 ),
//                 SizedBox(height: 20,),
//                 Center(
//                   child:  ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: (widget.asset.imageUrl?.isNotEmpty ?? false)
//                         ? Image.network(
//                       widget.asset.imageUrl!,
//                       height: 200,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) =>
//                           Utils.buildImagePlaceholder(),
//                     )
//                         : Utils.buildImagePlaceholder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   widget.asset.assetName,
//                   style: const TextStyle(
//                     color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 SizedBox(height: 20,),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.transparent,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(24),
//                         side: BorderSide(color: Color(0xFF656566)), // <-- Border added here
//                       ),
//                       padding: EdgeInsets.symmetric(vertical: 14),
//                       elevation: 0, // Optional: removes shadow for a flat look
//                     ),
//                     onPressed:  _downloadFile,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.file_download_outlined, color: Colors.white),
//                         SizedBox(width: 8),
//                         Text(
//                           'Download',
//                           style: TextStyle(color: Colors.white, fontSize: 16),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               SizedBox(height: 20,),
//                 Text(
//                   'Order Details',
//                   style: const TextStyle(
//                     color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400,
//                   ),
//                 ),
//                 SizedBox(height: 20,),
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Color(0xFF1A191E),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Utils.confirmRow('Item', widget.asset.assetName),
//                       Utils.confirmRow('Type', widget.asset.assetType),
//                       Utils.confirmRow('Amount Paid', Utils.formatCurrency(widget.asset.price)),
//                       Utils.confirmRow('Seller', "${widget.asset.seller!.firstName} ${widget.asset.seller!.lastName}")
//
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ),
//     );
//   }
// }