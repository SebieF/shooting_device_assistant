import 'dart:async';

import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_extend/share_extend.dart';

import '../../translations.dart';

class PDFScreen extends StatefulWidget {
  final String pathPDF;

  PDFScreen({Key? key, required this.pathPDF}) : super(key: key);

  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> {
  final Completer<PDFViewController> _controller =
  Completer<PDFViewController>();

  final List<TabItem> tabs = [
    TabItem(icon: Icons.arrow_back, title: allTranslations.text("back")),
    TabItem(
        icon: Icons.share,
        title: allTranslations.text("share")
    )
  ];

  int pages = 0;
  int currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  _PDFScreenState();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: ConvexAppBar(
        items: tabs,
        activeColor: Theme
            .of(context)
            .primaryColor,
        color: Theme
            .of(context)
            .primaryColor,
        backgroundColor: Theme
            .of(context)
            .bottomAppBarTheme.color,
        initialActiveIndex: 0,
        // ADD
        onTap: (int i) =>
        {
          if (i == 0) Navigator.of(context).pop(), //BACK
          if (i == 1) share()
        },
      ),
      body: PDFView(
        filePath: widget.pathPDF,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
        onRender: (_pages) {
          setState(() {
            pages = _pages!;
            isReady = true;
          });
        },
        onError: (error) {
          print(error.toString());
        },
        onPageError: (page, error) {
          print('$page: ${error.toString()}');
        },
        onViewCreated: (PDFViewController pdfViewController) {
          _controller.complete(pdfViewController);
        },
        onPageChanged: (int? page, int? total) {
          print('page change: $page/$total');
        },
      ),
    );
  }

  void share() {
    ShareExtend.share(widget.pathPDF, "pdf");
  }
}
