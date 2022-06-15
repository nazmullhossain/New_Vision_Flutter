import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:new_vision/others/helper.dart';
import 'package:new_vision/no_internet_page.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(useHybridComposition: true),
      ios: IOSInAppWebViewOptions(allowsInlineMediaPlayback: true));

  late PullToRefreshController pullToRefreshController;
  String url = "https://sukhtaraintltd.com/";
  double progress = 0;
  String pageTitle = 'Loading...';
  bool reloading=false;

  Future<void> _checkConnectivity()async{
    bool _connected = await Helper().checkConnectivity();
    if(!_connected){
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>
      const NoInternetPage()), (route) => false);
    }else{
      Future.delayed(const Duration(seconds: 2)).then((value) => _checkConnectivity());
    }
  }

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initialize();
  }

  Future<void> _initialize()async{
    if (kDebugMode) {
      print('initialized');
    }

    webViewController?.loadUrl(
        urlRequest: URLRequest(url: Uri.parse(url)));

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(color: Colors.blue),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(urlRequest: URLRequest(
              url: await webViewController?.getUrl()));
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:() async{
      bool canBack = await webViewController!.canGoBack();
      if(canBack){
        webViewController!.goBack();
        return false;
      }else{
        return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Do you want to exit?'),
            actions:[
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:const Text('Yes',style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No',style: TextStyle(color: Colors.green)),
              )
            ],
          ),
        )) ?? false;
      }},
      child: Scaffold(
        body: _bodyUI(),
      ),
    );
  }


  Widget _bodyUI()=>SafeArea(
    child: Stack(
      alignment: Alignment.center,
      children: [
        Column(
            children: <Widget>[
              Expanded(
                child: InAppWebView(
                  key: webViewKey,
                  initialUrlRequest: URLRequest(url: Uri.parse(url)),

                  initialOptions: options,
                  pullToRefreshController: pullToRefreshController,

                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  onProgressChanged: (InAppWebViewController? controller, int? progress) {
                    if (progress == 100) {
                      pullToRefreshController.endRefreshing();
                    }
                    pullToRefreshController.isRefreshing().then((value){
                      if(value) {
                        setState(()=>reloading=true);
                      }else{setState(()=>reloading=false);}
                    });
                    setState(() => this.progress = progress! / 100);
                  },
                  onTitleChanged: (InAppWebViewController? controller, String? title) {
                    setState(() => pageTitle = title!);
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      this.url = url.toString();
                    });
                  },
                  onLoadStop: (controller, url) async {
                    pullToRefreshController.endRefreshing();
                    setState(() {
                      this.url = url.toString();
                    });
                  },
                  onLoadError: (controller, url, code, message) {
                    pullToRefreshController.endRefreshing();
                  },
                  androidOnPermissionRequest: (controller, origin, resources) async {
                    return PermissionRequestResponse(
                        resources: resources,
                        action: PermissionRequestResponseAction.GRANT);
                  },
                  onUpdateVisitedHistory: (controller, url, androidIsReload) {
                    setState(() {
                      this.url = url.toString();
                    });
                  },
                ),
              )
              // ignore: unnecessary_null_comparison
            ].where((Object o) => o != null).toList()),

        if (progress != 1.0 && reloading==false)
          SizedBox(
              height: 50,
              width: 50,
              child: SleekCircularSlider(
                  appearance: CircularSliderAppearance(
                    customWidths: CustomSliderWidths(progressBarWidth: 5),
                    spinnerMode: true,
                  ))
          ),
      ],
    ),
  );

}
