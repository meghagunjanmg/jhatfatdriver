import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animated_widgets/widgets/rotation_animated.dart';
import 'package:animated_widgets/widgets/shake_animated_widget.dart';
import 'package:driver/Auth/login_navigator.dart';
import 'package:driver/Components/list_tile.dart';
import 'package:driver/Routes/routes.dart';
import 'package:driver/Themes/colors.dart';
import 'package:driver/Themes/style.dart';
import 'package:driver/baseurl/baseurl.dart';
import 'package:driver/beanmodel/Multistoreorder.dart';
import 'package:driver/beanmodel/orderbean.dart';
import 'package:driver/beanmodel/dutyonoff.dart';
import 'package:driver/beanmodel/restaurantbeancomplete.dart';
import 'package:driver/beanmodel/todayrestorder.dart';
import 'package:driver/parcel/parcelbean/orderdetailpageparcel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boom_menu/flutter_boom_menu.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';

var scfoldKey = GlobalKey<ScaffoldState>();

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage>
    with TickerProviderStateMixin,WidgetsBindingObserver {

  final List<Tab> tabs = <Tab>[
    Tab(text: 'NEW ORDERS'),
    Tab(text: 'COMPLETED ORDERS'),
  ];
  TabController tabController;

  Completer<GoogleMapController> _controller = Completer();
  var onOffLine = 'GO OFFLINE';
  var status = 0;
  dynamic lat;
  dynamic lng;
  SharedPreferences preferences;
  dynamic driverName = '';
  dynamic driverNumber = '';
  dynamic imageUrld = '';
  static const LatLng _center = const LatLng(45.343434, -122.545454);
  CameraPosition kGooglePlex = CameraPosition(
    target: _center,
    zoom: 12.151926,
  );
  bool isRun = false;
  bool isRingBell = false;
  Timer timer;
  var orderCount = 0;

  List<OrderDetails> todayOrder = [];
  List<TodayRestaurantOrder> restOrder = [];
  List<TodayOrderParcel> parcelOrder = [];

  dynamic currency;

  List<OrderDetail> orders=[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    getCurrency();
    _getLocation();
    getSharedPref();
    hitStatusServiced();
    getAllApi();
    tabController = TabController(length: tabs.length, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        setState(() {
          todayOrder = null;
          restOrder = null;
          parcelOrder = null;
        });
        print(tabController.index);
        if (tabController.index == 0) {
          getAllApi();
        } else if (tabController.index == 1) {
          getAllApi2();
        }
      }
    });

  }
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);

  // These are the callbacks
  switch (state) {
    case AppLifecycleState.resumed:
      {
        print("REFRESH");
        getCurrency();
        _getLocation();
        getSharedPref();
        hitStatusServiced();
        if (tabController.index == 0) {
          getAllApi();
        } else if (tabController.index == 1) {
          getAllApi2();
        }
      }
      break;
    case AppLifecycleState.inactive:
    // TODO: Handle this case.
      break;
    case AppLifecycleState.paused:
    // TODO: Handle this case
      break;
    case AppLifecycleState.detached:
    // TODO: Handle this case.
      break;
  }
}
@override
void dispose() {
  super.dispose();
  if (timer != null) {
    timer.cancel();
  }
  WidgetsBinding.instance.removeObserver(this);
}

  getAllApi() {
    setState(() {
      todayOrder = null;
      restOrder = null;
      parcelOrder = null;
    });
    getTodayOrders();
    getTodayRestOrders();
    getTodayParcelOrders();
  }

  getAllApi2() {
    setState(() {
      todayOrder = null;
      restOrder = null;
      parcelOrder = null;
    });
    getCompleteOrders();
    getCompleteRestOrders();
    getCompleteParcelOrders();
  }

  _launchURL(url) async {
    try {
      launch(url);
    } catch (error, stack) {
      // log error
    }
  }

  getCompleteOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');

    var todayOrderUrl = completed_orders;
    var client = http.Client();
    client.post(todayOrderUrl, body: {'delivery_boy_id': '${boyId}'}).then(
            (value) {
          if (value.statusCode == 200 && value.body != null) {
            var jsonData = jsonDecode(value.body);
            print('${jsonData.toString()}');
            if (value.body.toString().contains("[{\"order_details\":\"no orders found\"}]") || value.body.toString().contains("[{\"no_order\":\"no orders found\"}]")) {
              // Toast.show(
              //   'No grocery order found!',
              //   context,
              //   gravity: Toast.BOTTOM,
              //   duration: Toast.LENGTH_SHORT,
              // );

            } else {
              var jsonList = jsonData as List;
              List<OrderDetails> orderDetails =
              jsonList.map((e) => OrderDetails.fromJson(e)).toList();
              print('${orderDetails.toString()}');
              setState(() {
                todayOrder = orderDetails;
              });
            }
          }
        }).catchError((e) {
      Toast.show(
        'No grocery order found!',
        context,
        gravity: Toast.BOTTOM,
        duration: Toast.LENGTH_SHORT,
      );
      print(e);
    });
  }

  getCompleteRestOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');

    var todayOrderUrl = dboy_completed_order;
    var client = http.Client();
    client.post(todayOrderUrl, body: {'delivery_boy_id': '${boyId}'}).then(
            (value) {
          if (value.statusCode == 200 && value.body != null) {
            var jsonData = jsonDecode(value.body);
            print('${jsonData.toString()}');
            if (value.body.toString().contains("[{\"order_details\":\"no orders found\"}]") || value.body.toString().contains("[{\"no_order\":\"no orders found\"}]")) {
              // Toast.show(
              //   'No restaurant order found!',
              //   context,
              //   gravity: Toast.BOTTOM,
              //   duration: Toast.LENGTH_SHORT,
              // );

            } else {
              var jsonList = jsonData as List;
              List<TodayRestaurantOrder> orderDetails =
              jsonList.map((e) => TodayRestaurantOrder.fromJson(e)).toList();
              print('${orderDetails.toString()}');
              setState(() {
                restOrder = orderDetails.cast<TodayRestaurantOrder>();
              });
            }
          }
        }).catchError((e) {
      Toast.show(
        'No restaurant order found!',
        context,
        gravity: Toast.BOTTOM,
        duration: Toast.LENGTH_SHORT,
      );
      print(e);
    });
  }

  getCompleteParcelOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');
    var todayOrderUrl = parcel_dboy_completed_order;
    var client = http.Client();
    client.post(todayOrderUrl, body: {'delivery_boy_id': '${boyId}'}).then(
            (value) {
          if (value.statusCode == 200 && value.body != null) {
            var jsonData = jsonDecode(value.body);
            print('${jsonData.toString()}');
            if (value.body.toString().contains("[{\"order_details\":\"no orders found\"}]") || value.body.toString().contains("[{\"no_order\":\"no orders found\"}]")) {
              // Toast.show(
              //   'No Order Found!',
              //   context,
              //   gravity: Toast.BOTTOM,
              //   duration: Toast.LENGTH_SHORT,
              // );

            } else {
              var jsonList = jsonData as List;
              List<TodayOrderParcel> orderDetails =
              jsonList.map((e) => TodayOrderParcel.fromJson(e)).toList();
              print('${orderDetails.toString()}');
              setState(() {
                parcelOrder = orderDetails;
              });
            }
          }
        }).catchError((e) {
      Toast.show(
        'No Order Found!',
        context,
        gravity: Toast.BOTTOM,
        duration: Toast.LENGTH_SHORT,
      );
      print(e);
    });
  }



  getTodayOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');
    var todayOrderUrl = ordersfortoday;
    var client = http.Client();
    client.post(todayOrderUrl, body: {'delivery_boy_id': '${boyId}'}).then(
            (value) {
          print('g ${value.body}');
          if (value.statusCode == 200 && value.body != null) {
            var jsonData = jsonDecode(value.body);
            if (value.body
                .toString()
                .contains("[{\"order_details\":\"no orders found\"}]") ||
                value.body
                    .toString()
                    .contains("[{\"no_order\":\"no orders found\"}]")) {
            } else {
              var jsonList = jsonData as List;
              List<OrderDetails> orderDetails =
              jsonList.map((e) => OrderDetails.fromJson(e)).toList();
              print('${orderDetails.toString()}');
              setState(() {
                todayOrder = orderDetails;
              });
            }
          }
        }).catchError((e) {
      Toast.show(
        'No Order Found!',
        context,
        gravity: Toast.BOTTOM,
        duration: Toast.LENGTH_SHORT,
      );
      print(e);
    });
  }

  getTodayRestOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');
    var todayOrderUrl = dboy_today_order;
    var client = http.Client();
    client.post(todayOrderUrl, body: {'delivery_boy_id': '${boyId}'}).then(
            (value) {
          print('resr ${value.body}');
          if (value.statusCode == 200 && value.body != null) {
            var jsonData = jsonDecode(value.body);
            print('${jsonData.toString()}');
            if (value.body
                .toString()
                .contains("[{\"order_details\":\"no orders found\"}]") ||
                value.body
                    .toString()
                    .contains("[{\"no_order\":\"no orders found\"}]")) {

            } else {
              var jsonList = jsonData as List;
              List<TodayRestaurantOrder> orderDetails =
              jsonList.map((e) => TodayRestaurantOrder.fromJson(e)).toList();
              print('${orderDetails.toString()}');
              setState(() {
                restOrder = orderDetails;
              });
            }
          }
        }).catchError((e) {
      Toast.show(
        'No Order Found!',
        context,
        gravity: Toast.BOTTOM,
        duration: Toast.LENGTH_SHORT,
      );
      print(e);
    });
  }


  getTodayParcelOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');
    var todayOrderUrl = parcel_dboy_today_order;
    var client = http.Client();
    client.post(todayOrderUrl, body: {'delivery_boy_id': '${boyId}'}).then(
            (value) {
          print('par ${value.body}');
          if (value.statusCode == 200 && value.body != null) {
            var jsonData = jsonDecode(value.body);
            if (value.body
                .toString()
                .contains("[{\"order_details\":\"no orders found\"}]") ||
                value.body
                    .toString()
                    .contains("[{\"no_order\":\"no orders found\"}]")) {

            } else {
              var jsonList = jsonData as List;
              List<TodayOrderParcel> orderDetails =
              jsonList.map((e) => TodayOrderParcel.fromJson(e)).toList();
              print('${orderDetails.toString()}');
              setState(() {
                parcelOrder = orderDetails;
              });
            }
          }
        }).catchError((e) {
      Toast.show(
        'No Order Found!',
        context,
        gravity: Toast.BOTTOM,
        duration: Toast.LENGTH_SHORT,
      );
      print(e);
    });
  }

  void setTimerTask() async {
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (this.timer == null) {
        this.timer = timer;
      }
      hitTestServices();
    });
  }

  _getDirection(url) async {
    try {
      launch(url);
    } catch (error, stack) {
      // log error
    }
  }
  void hitStatusServiced() async {
    setState(() {
      isRun = true;
    });
    preferences = await SharedPreferences.getInstance();
    print('${status} - ${preferences.getInt('delivery_boy_id')}');
    var client = http.Client();
    var statusUrl = driverstatus;
    client.post(statusUrl, body: {
      'delivery_boy_id': '${preferences.getInt('delivery_boy_id')}'
    }).then((value) {
      setState(() {
        isRun = false;
      });
      if (value.statusCode == 200 && value.body != null) {
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          var sat = jsonData['data']['delivery_boy_status'];
          print('${sat}');
          if (sat == "online") {
            preferences.setInt('duty', 1);
            setState(() {
              status = 1;
            });
          } else {
            preferences.setInt('duty', 0);
            setState(() {
              status = 0;
            });
          }
        }
      }
    }).catchError((e) {
      print(e);
      setState(() {
        isRun = false;
      });
    });
  }

  void _getLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      bool isLocationServiceEnableds =
          await Geolocator.isLocationServiceEnabled();
      if (isLocationServiceEnableds) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        Timer(Duration(seconds: 5), () async {
          double lat = position.latitude;
          double lng = position.longitude;
          prefs.setString("lat", lat.toStringAsFixed(8));
          prefs.setString("lng", lng.toStringAsFixed(8));
          setLocation(lat, lng);
        });
        Geolocator.getPositionStream(distanceFilter: 1, timeInterval: 15)
            .listen((positionNew) {
          print(positionNew == null
              ? 'Unknown'
              : positionNew.latitude.toString() +
                  ', ' +
                  positionNew.longitude.toString());
          double lat = positionNew.latitude;
          double lng = positionNew.longitude;
          prefs.setString("lat", lat.toStringAsFixed(8));
          prefs.setString("lng", lng.toStringAsFixed(8));
          setLocation(lat, lng);
        });
      } else {
        await Geolocator.openLocationSettings().then((value) {
          if (value) {
            _getLocation();
          } else {
            Toast.show('Location permission is required!', context,
                duration: Toast.LENGTH_SHORT);
          }
        }).catchError((e) {
          Toast.show('Location permission is required!', context,
              duration: Toast.LENGTH_SHORT);
        });
      }
    } else if (permission == LocationPermission.denied) {
      LocationPermission permissiond = await Geolocator.requestPermission();
      if (permissiond == LocationPermission.whileInUse ||
          permissiond == LocationPermission.always) {
        _getLocation();
      } else {
        Toast.show('Location permission is required!', context,
            duration: Toast.LENGTH_SHORT);
      }
    } else if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings().then((value) {
        _getLocation();
      }).catchError((e) {
        Toast.show('Location permission is required!', context,
            duration: Toast.LENGTH_SHORT);
      });
    }
  }

  setLocation(lats, lngs) {
    print('state - ${scfoldKey.currentState}');
    setState(() {
      lat = lats;
      lng = lngs;
      kGooglePlex = CameraPosition(
        target: LatLng(lats, lngs),
        zoom: 12.151926,
      );
    });
  }

  void getSharedPref() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {
      driverName = preferences.getString('delivery_boy_name');
      driverNumber = preferences.getString('delivery_boy_phone');
      imageUrld = Uri.parse('${imageBaseUrl}${preferences.getString('delivery_boy_image')}');
      print('${preferences.getInt('duty')}');
      setState(() {
        status = preferences.getInt('duty');
      });
    });
  }

  void getCurrency() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
   
    var currencyUrl = currencys;
    var client = http.Client();
    client.get(currencyUrl).then((value) {
      var jsonData = jsonDecode(value.body);
      if (value.statusCode == 200 && jsonData['status'] == "1") {
        print('${jsonData['data'][0]['currency_sign']}');
        preferences.setString(
            'curency', '${jsonData['data'][0]['currency_sign']}');
        setState(() {
          currency = '${jsonData['data'][0]['currency_sign']}';
        });
      }
    }).catchError((e) {
      print(e);
    });
  }
  void getorders(orderid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');
    var url = ordersfortodaydetails;
    var client = http.Client();
    client.post(url, body: {'order_id': orderid.toString(), 'delivery_boy_id': boyId.toString()})
        .then((value) {
      if (value.statusCode == 200) {
        var tagObjsJson = jsonDecode(value.body) as List;
        List<Multistoreorder> tagObjs = tagObjsJson
            .map((tagJson) => Multistoreorder.fromJson(tagJson))
            .toList();
        List<OrderDetail> temp = [];
        tagObjs.forEach((element) {
          element.orderDetails.forEach((element) async {
            temp.add(element);
          });
        });
        setState(() {
          orders.clear();
          orders = temp;
        });
      }
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {

    return
      DefaultTabController(
        length: tabs.length,
        child:
        Scaffold(
      key: scfoldKey,
      appBar:
      PreferredSize(
        preferredSize: Size.fromHeight(100.0),
        child: AppBar(
          centerTitle: false,
          title: Text(
            'My Orders',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          actions: [
            isRun
                ? CupertinoActivityIndicator(
              radius: 15,
            )
                : Container(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: FlatButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: (status == 1) ? kRed : kGreen)),
                color: (status == 1) ? kRed : kGreen,
                onPressed: () {
                  // Navigator.popAndPushNamed(context, PageRoutes.offlinePage)
                  if (!isRun) {
                    hitStatusService();
                  }
                },
                child: Text(
                  '${status == 1 ? 'Go Offline' : 'Go Online'}',
                  style: Theme.of(context).textTheme.caption.copyWith(
                      color: kWhiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.7,
                      letterSpacing: 0.06),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(0.0),
            child: TabBar(
              controller: tabController,
              tabs: tabs,
              isScrollable: true,
              labelColor: kMainColor,
              unselectedLabelColor: kLightTextColor,
              indicatorPadding: EdgeInsets.symmetric(horizontal: 24.0),
            ),
          ),
        ),
      ),
      drawer: Account(driverName, driverNumber,imageUrld),
      body:
      TabBarView(
      controller: tabController,
      children: tabs.map((Tab tab) {
    return
      (todayOrder != null && todayOrder.length > 0 || restOrder != null && restOrder.length > 0 || parcelOrder != null && parcelOrder.length > 0)
          ?
      RefreshIndicator(
      onRefresh: () {
        Future.delayed(
          Duration(seconds: 1),
              () {
            if (tabController.index == 0) {
              getAllApi();
            } else if (tabController.index == 1) {
              getAllApi2();
            }
          }
      );
        },
      child:
            SingleChildScrollView(
              primary: true,
              physics: const AlwaysScrollableScrollPhysics(),

              child: Column(
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  (todayOrder != null)?
                  Visibility(
                    visible: (todayOrder != null && todayOrder.length > 0)
                        ? true
                        : false,
                    child: Column(
                      children: [
                        Text(
                          'Grocery Orders',
                          style: Theme.of(context).textTheme.headline6.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Color(0xff6a6c74),
                              fontSize: 16),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        ListView.separated(
                          primary: false,
                          shrinkWrap: true,
                          itemCount: todayOrder.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                print('${lat} - ${lng}');
                                if (todayOrder[index].order_status == "Pending" ||
                                    todayOrder[index].order_status ==
                                        "pending" ||
                                    todayOrder[index].order_status ==
                                        "Confirmed" || todayOrder[index].order_status ==
                                    "Confirm")
                                {

                                  Navigator.pushNamed(
                                      context, PageRoutes.newDeliveryPage,
                                      arguments: {
                                        "cart_id": todayOrder[index].cart_id,
                                        "vendorName":
                                        todayOrder[index].vendor_name,
                                        "vendorAddress":
                                        todayOrder[index].vendor_address,
                                        "vendorlat":
                                        todayOrder[index].vendor_lat,
                                        "vendorlng":
                                        todayOrder[index].vendor_lng,
                                        "vendor_phone":
                                        todayOrder[index].vendor_phone,
                                        "dlat": lat,
                                        "dlng": lng,
                                        "userlat": todayOrder[index].user_lat,
                                        "userlng": todayOrder[index].user_lng,
                                        "userName": todayOrder[index].user_name,
                                        "userAddress":
                                        todayOrder[index].user_address,
                                        "userphone":
                                        todayOrder[index].user_phone,
                                        "itemDetails":
                                        todayOrder[index].order_details,
                                        "remprice":
                                        todayOrder[index].remaining_price,
                                        "paymentstatus":
                                        todayOrder[index].payment_status,
                                        "paymentMethod":
                                        todayOrder[index].payment_method,
                                        "order_id": todayOrder[index].order_id,

                                        "ui_type": "1"
                                      }).then((value) {
                                    getAllApi();getAllApi2();
                                  });
                                } else if (todayOrder[index].order_status ==
                                    "Delivery Accepted") {
                                  Navigator.pushNamed(
                                      context, PageRoutes.acceptedPage,
                                      arguments: {
                                        "cart_id": todayOrder[index].cart_id,
                                        "vendorName":
                                        todayOrder[index].vendor_name,
                                        "vendorAddress":
                                        todayOrder[index].vendor_address,
                                        "vendorlat":
                                        todayOrder[index].vendor_lat,
                                        "vendorlng":
                                        todayOrder[index].vendor_lng,
                                        "vendor_phone":
                                        todayOrder[index].vendor_phone,
                                        "dlat": lat,
                                        "dlng": lng,
                                        "userlat": todayOrder[index].user_lat,
                                        "userlng": todayOrder[index].user_lng,
                                        "userName": todayOrder[index].user_name,
                                        "userAddress":
                                        todayOrder[index].user_address,
                                        "userphone":
                                        todayOrder[index].user_phone,
                                        "itemDetails":
                                        todayOrder[index].order_details,
                                        "remprice":
                                        todayOrder[index].remaining_price,
                                        "paymentstatus":
                                        todayOrder[index].payment_status,
                                        "paymentMethod":
                                        todayOrder[index].payment_method,
                                        "order_id": todayOrder[index].order_id,

                                        "ui_type": "1"
                                      }).then((value) {
                                    getAllApi();getAllApi2();
                                  });
                                } else if (todayOrder[index].order_status ==
                                    "Out For Delivery") {
                                  Navigator.pushNamed(
                                      context, PageRoutes.onWayPage,
                                      arguments: {
                                        "cart_id": todayOrder[index].cart_id,
                                        "vendorName":
                                        todayOrder[index].vendor_name,
                                        "vendorAddress":
                                        todayOrder[index].vendor_address,
                                        "vendorlat":
                                        todayOrder[index].vendor_lat,
                                        "vendorlng":
                                        todayOrder[index].vendor_lng,
                                        "vendor_phone":
                                        todayOrder[index].vendor_phone,
                                        "dlat": lat,
                                        "dlng": lng,
                                        "userlat": todayOrder[index].user_lat,
                                        "userlng": todayOrder[index].user_lng,
                                        "userName": todayOrder[index].user_name,
                                        "userAddress":
                                        todayOrder[index].user_address,
                                        "userphone":
                                        todayOrder[index].user_phone,
                                        "itemDetails":
                                        todayOrder[index].order_details,
                                        "remprice":
                                        todayOrder[index].remaining_price,
                                        "paymentstatus":
                                        todayOrder[index].payment_status,
                                        "paymentMethod":
                                        todayOrder[index].payment_method,
                                        "order_id": todayOrder[index].order_id,

                                        "ui_type": "1"
                                      }).then((value) {
                                    getAllApi();getAllApi2();
                                  });
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Card(
                                elevation: 5,
                                color: kWhiteColor,
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  // margin: EdgeInsets.symmetric(horizontal: 10),
                                  padding: EdgeInsets.symmetric(vertical: 5),
                                  color: kWhiteColor,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 16.3),
                                            child: Image.asset(
                                              'images/vegetables_fruitsact.png',
                                              height: 42.3,
                                              width: 33.7,
                                            ),
                                          ),
                                          Expanded(
                                            child: ListTile(
                                              title: Text(
                                                'Order Id - #${todayOrder[index].cart_id}',
                                                style: orderMapAppBarTextStyle
                                                    .copyWith(
                                                    letterSpacing: 0.07),
                                              ),
                                              subtitle: Text(
                                                '${todayOrder[index].delivery_date} | ${todayOrder[index].time_slot}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline6
                                                    .copyWith(
                                                    fontSize: 11.7,
                                                    letterSpacing: 0.06,
                                                    color:
                                                    Color(0xffc1c1c1)),
                                              ),
                                              trailing: Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Text(
                                                    '${todayOrder[index].order_status}',
                                                    style:
                                                    orderMapAppBarTextStyle
                                                        .copyWith(
                                                        color:
                                                        kMainColor),
                                                  ),
                                                  SizedBox(height: 7.0),
                                                  Text(
                                                    '${todayOrder[index].total_items} items | $currency ${todayOrder[index].remaining_price}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline6
                                                        .copyWith(
                                                        fontSize: 11.7,
                                                        letterSpacing: 0.06,
                                                        color: Color(
                                                            0xffc1c1c1)),
                                                  )
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),

                                      Visibility(
                                          visible:
                                          (todayOrder[index].order_status ==
                                              'Out for delivery')
                                              ? true
                                              : false,
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                alignment: Alignment.centerLeft,
                                                padding:
                                                EdgeInsets.only(left: 20),
                                                color: kCardBackgroundColor,
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      height: 5,
                                                    ),
                                                    Text(
                                                      'Delivery Contact',
                                                      style: TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                    SizedBox(
                                                      height: 5,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Row(
                                                        children: <Widget>[
                                                          Padding(
                                                            padding:
                                                            EdgeInsets.only(
                                                                left: 36.0,
                                                                bottom: 6.0,
                                                                top: 12.0,
                                                                right:
                                                                12.0),
                                                            child: ImageIcon(
                                                              AssetImage(
                                                                  'images/icons/ic_name.png'),
                                                              size: 13.3,
                                                              color: kMainColor,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${todayOrder[index].user_name}',
                                                            style: Theme.of(
                                                                context)
                                                                .textTheme
                                                                .caption
                                                                .copyWith(
                                                                fontSize:
                                                                13.0,
                                                                letterSpacing:
                                                                0.05),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: <Widget>[
                                                          Padding(
                                                            padding:
                                                            EdgeInsets.only(
                                                                left: 36.0,
                                                                bottom:
                                                                12.0,
                                                                top: 12.0,
                                                                right:
                                                                12.0),
                                                            child: ImageIcon(
                                                              AssetImage(
                                                                  'images/icons/ic_phone.png'),
                                                              size: 13.3,
                                                              color: kMainColor,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${todayOrder[index].user_phone}',
                                                            style: Theme.of(
                                                                context)
                                                                .textTheme
                                                                .caption
                                                                .copyWith(
                                                                fontSize:
                                                                13.0,
                                                                letterSpacing:
                                                                0.05),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 10),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _launchURL(
                                                            "tel://${todayOrder[index].user_phone}");
                                                      },
                                                      behavior: HitTestBehavior
                                                          .opaque,
                                                      child: Card(
                                                        elevation: 8,
                                                        clipBehavior:
                                                        Clip.hardEdge,
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                50)),
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                          kMainTextColor
                                                              .withOpacity(
                                                              0.2),
                                                          child: Icon(
                                                            Icons.call,
                                                            color: kGreen,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              )
                                            ],
                                          )),
                                      Visibility(
                                          visible:
                                          (todayOrder[index].order_status ==
                                              'Out for delivery' ||
                                              todayOrder[index]
                                                  .order_status ==
                                                  'Out For Delivery')
                                              ? true
                                              : false,
                                          // visible:true,
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: [
                                                  RaisedButton(
                                                    padding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 15),
                                                    onPressed: () {
                                                      if(orders.isEmpty){
                                                        getorders(todayOrder[index].order_id);
                                                      }
                                                      sleep(Duration(seconds:2));
                                                      Navigator.pushNamed(
                                                          context,
                                                          PageRoutes
                                                              .itemDetails,
                                                          arguments: {
                                                            "cart_id":
                                                            '${todayOrder[index].cart_id}',
                                                            "itemDetails":orders,
                                                            "currency": currency
                                                          });
                                                    },
                                                    child: Text(
                                                      'Item Detail\'s',
                                                      textAlign:
                                                      TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: kWhiteColor,
                                                          fontWeight:
                                                          FontWeight.w600),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 20,
                                                  ),
                                                  RaisedButton(
                                                    padding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 15),
                                                    onPressed: () {
                                                      _getDirection(
                                                          'https://www.google.com/maps/search/?api=1&query=${todayOrder[index].user_lat},${todayOrder[index].user_lng}');
                                                    },
                                                    child: Text(
                                                      'Get Direction',
                                                      textAlign:
                                                      TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: kWhiteColor,
                                                          fontWeight:
                                                          FontWeight.w600),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                            ],
                                          ))
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) {
                            return Divider(
                              height: 8,
                              color: Colors.transparent,
                            );
                          },
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ):Container(),
                  (restOrder != null)?
                  Visibility(
                    visible: (restOrder != null && restOrder.length > 0)
                        ? true
                        : false,
                    child: Column(
                      children: [
                        Text(
                          'Restaurant Orders',
                          style: Theme.of(context).textTheme.headline6.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Color(0xff6a6c74),
                              fontSize: 16),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        ListView.separated(
                          primary: false,
                          shrinkWrap: true,
                          itemCount: restOrder.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                print('${lat} - ${lng}');
                                if (restOrder[index].order_status == "Pending" ||
                                    restOrder[index].order_status ==
                                        "pending" ||
                                    restOrder[index].order_status ==
                                        "Confirmed" || restOrder[index].order_status ==
                                    "Confirm") {
                                  Navigator.pushNamed(
                                      context, PageRoutes.newdeliveryrest,
                                      arguments: {
                                        "cart_id": restOrder[index].cart_id,
                                        "vendorName":
                                        restOrder[index].vendor_name,
                                        "vendorAddress":
                                        restOrder[index].vendor_address,
                                        "vendorlat":
                                        restOrder[index].vendor_lat,
                                        "vendorlng":
                                        restOrder[index].vendor_lng,
                                        "vendor_phone":
                                        restOrder[index].vendor_phone,
                                        "dlat": lat,
                                        "dlng": lng,
                                        "userlat": restOrder[index].user_lat,
                                        "userlng": restOrder[index].user_lng,
                                        "userName": restOrder[index].user_name,
                                        "userAddress":
                                        restOrder[index].user_address,
                                        "userphone":
                                        restOrder[index].user_phone,
                                        "itemDetails":
                                        restOrder[index].order_details,
                                        "remprice":
                                        restOrder[index].remaining_price,
                                        "paymentstatus":
                                        restOrder[index].payment_status,
                                        "paymentMethod":
                                        restOrder[index].payment_method,
                                        "user_id": restOrder[index].cart_id,

                                        "ui_type": "2",
                                        "addons": restOrder[index].addons
                                      }).then((value) {
                                    getAllApi();getAllApi2();
                                  });
                                } else if (restOrder[index].order_status ==
                                    "Delivery Accepted") {
                                  Navigator.pushNamed(
                                      context, PageRoutes.restacceptpage,
                                      arguments: {
                                        "cart_id": restOrder[index].cart_id,
                                        "vendorName":
                                        restOrder[index].vendor_name,
                                        "vendorAddress":
                                        restOrder[index].vendor_address,
                                        "vendorlat":
                                        restOrder[index].vendor_lat,
                                        "vendorlng":
                                        restOrder[index].vendor_lng,
                                        "vendor_phone":
                                        restOrder[index].vendor_phone,
                                        "dlat": lat,
                                        "dlng": lng,
                                        "userlat": restOrder[index].user_lat,
                                        "userlng": restOrder[index].user_lng,
                                        "userName": restOrder[index].user_name,
                                        "userAddress":
                                        restOrder[index].user_address,
                                        "userphone":
                                        restOrder[index].user_phone,
                                        "itemDetails":
                                        restOrder[index].order_details,
                                        "remprice":
                                        restOrder[index].remaining_price,
                                        "paymentstatus":
                                        restOrder[index].payment_status,
                                        "paymentMethod":
                                        restOrder[index].payment_method,
                                        "user_id": restOrder[index].cart_id,

                                        "ui_type": "2",
                                        "addons": restOrder[index].addons
                                      }).then((value) {
                                    getAllApi();getAllApi2();
                                  });
                                } else if (restOrder[index].order_status ==
                                    "Out For Delivery") {
                                  Navigator.pushNamed(
                                      context, PageRoutes.restonway,
                                      arguments: {
                                        "cart_id": restOrder[index].cart_id,
                                        "vendorName":
                                        restOrder[index].vendor_name,
                                        "vendorAddress":
                                        restOrder[index].vendor_address,
                                        "vendorlat":
                                        restOrder[index].vendor_lat,
                                        "vendorlng":
                                        restOrder[index].vendor_lng,
                                        "vendor_phone":
                                        restOrder[index].vendor_phone,
                                        "dlat": lat,
                                        "dlng": lng,
                                        "userlat": restOrder[index].user_lat,
                                        "userlng": restOrder[index].user_lng,
                                        "userName": restOrder[index].user_name,
                                        "userAddress":
                                        restOrder[index].user_address,
                                        "userphone":
                                        restOrder[index].user_phone,
                                        "itemDetails":
                                        restOrder[index].order_details,
                                        "remprice":
                                        restOrder[index].remaining_price,
                                        "paymentstatus":
                                        restOrder[index].payment_status,
                                        "paymentMethod":
                                        restOrder[index].payment_method,
                                        "user_id": restOrder[index].cart_id,

                                        "ui_type": "2",
                                        "addons": restOrder[index].addons
                                      }).then((value) {
                                    getAllApi();getAllApi2();
                                  });
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Card(
                                elevation: 5,
                                color: kWhiteColor,
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  // margin: EdgeInsets.symmetric(horizontal: 10),
                                  padding: EdgeInsets.symmetric(vertical: 5),
                                  color: kWhiteColor,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 16.3),
                                            child: Image.asset(
                                              'images/vegetables_fruitsact.png',
                                              height: 42.3,
                                              width: 33.7,
                                            ),
                                          ),
                                          Expanded(
                                            child: ListTile(
                                              title: Text(
                                                'Order Id - #${restOrder[index].cart_id}',
                                                style: orderMapAppBarTextStyle
                                                    .copyWith(
                                                    letterSpacing: 0.07),
                                              ),
                                              subtitle: Text(
                                                '${restOrder[index].delivery_date}',
                                                // | ${restOrder[index].time_slot}
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline6
                                                    .copyWith(
                                                    fontSize: 11.7,
                                                    letterSpacing: 0.06,
                                                    color:
                                                    Color(0xffc1c1c1)),
                                              ),
                                              trailing: Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Text(
                                                    '${restOrder[index].order_status}',
                                                    style:
                                                    orderMapAppBarTextStyle
                                                        .copyWith(
                                                        color:
                                                        kMainColor),
                                                  ),
                                                  SizedBox(height: 7.0),
                                                  Text(
                                                    '${restOrder[index].order_details.length} items | $currency ${restOrder[index].remaining_price}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline6
                                                        .copyWith(
                                                        fontSize: 11.7,
                                                        letterSpacing: 0.06,
                                                        color: Color(
                                                            0xffc1c1c1)),
                                                  )
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      Container(
                                        width:
                                        MediaQuery.of(context).size.width,
                                        alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.only(left: 20),
                                        color: kCardBackgroundColor,
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: 5,
                                            ),
                                            Text('Pickup and Destination',
                                                style: TextStyle(fontSize: 14)),
                                            SizedBox(
                                              height: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.only(
                                                left: 36.0,
                                                bottom: 6.0,
                                                top: 12.0,
                                                right: 12.0),
                                            child: ImageIcon(
                                              AssetImage(
                                                  'images/custom/ic_pickup_pointact.png'),
                                              size: 13.3,
                                              color: kMainColor,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '${restOrder[index].vendor_name}\n${restOrder[index].vendor_address}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption
                                                  .copyWith(
                                                  fontSize: 10.0,
                                                  letterSpacing: 0.05),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.only(
                                                left: 36.0,
                                                bottom: 12.0,
                                                top: 12.0,
                                                right: 12.0),
                                            child: ImageIcon(
                                              AssetImage(
                                                  'images/custom/ic_droppointact.png'),
                                              size: 13.3,
                                              color: kMainColor,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '${restOrder[index].user_address}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption
                                                  .copyWith(
                                                  fontSize: 10.0,
                                                  letterSpacing: 0.05),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Visibility(
                                          visible:
                                          (restOrder[index].order_status ==
                                              'Out for delivery')
                                              ? true
                                              : false,
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                alignment: Alignment.centerLeft,
                                                padding:
                                                EdgeInsets.only(left: 20),
                                                color: kCardBackgroundColor,
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      height: 5,
                                                    ),
                                                    Text(
                                                      'Delivery Contact',
                                                      style: TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                    SizedBox(
                                                      height: 5,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Row(
                                                        children: <Widget>[
                                                          Padding(
                                                            padding:
                                                            EdgeInsets.only(
                                                                left: 36.0,
                                                                bottom: 6.0,
                                                                top: 12.0,
                                                                right:
                                                                12.0),
                                                            child: ImageIcon(
                                                              AssetImage(
                                                                  'images/icons/ic_name.png'),
                                                              size: 13.3,
                                                              color: kMainColor,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${restOrder[index].user_name}',
                                                            style: Theme.of(
                                                                context)
                                                                .textTheme
                                                                .caption
                                                                .copyWith(
                                                                fontSize:
                                                                13.0,
                                                                letterSpacing:
                                                                0.05),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: <Widget>[
                                                          Padding(
                                                            padding:
                                                            EdgeInsets.only(
                                                                left: 36.0,
                                                                bottom:
                                                                12.0,
                                                                top: 12.0,
                                                                right:
                                                                12.0),
                                                            child: ImageIcon(
                                                              AssetImage(
                                                                  'images/icons/ic_phone.png'),
                                                              size: 13.3,
                                                              color: kMainColor,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${restOrder[index].user_phone}',
                                                            style: Theme.of(
                                                                context)
                                                                .textTheme
                                                                .caption
                                                                .copyWith(
                                                                fontSize:
                                                                13.0,
                                                                letterSpacing:
                                                                0.05),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 10),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _launchURL(
                                                            "tel://${restOrder[index].user_phone}");
                                                      },
                                                      behavior: HitTestBehavior
                                                          .opaque,
                                                      child: Card(
                                                        elevation: 8,
                                                        clipBehavior:
                                                        Clip.hardEdge,
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                50)),
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                          kMainTextColor
                                                              .withOpacity(
                                                              0.2),
                                                          child: Icon(
                                                            Icons.call,
                                                            color: kGreen,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              )
                                            ],
                                          )),
                                      Visibility(
                                          visible:
                                          (restOrder[index].order_status ==
                                              'Out for delivery' ||
                                              restOrder[index]
                                                  .order_status ==
                                                  'Out For Delivery')
                                              ? true
                                              : false,
                                          // visible:true,
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: [
                                                  RaisedButton(
                                                    padding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 15),
                                                    onPressed: () {
                                                      Navigator.pushNamed(context,
                                                          PageRoutes.itemDetailsPh,
                                                          arguments: {
                                                            "cart_id": '${restOrder[index].cart_id}',
                                                            "itemDetails": restOrder[index].order_details,
                                                            "currency": currency,
                                                            'addons':restOrder[index].addons,
                                                            "itemDetails":
                                                            restOrder[index].order_details,
                                                            "remprice": restOrder[index].remaining_price,
                                                            "paymentstatus":
                                                            restOrder[index].payment_status,
                                                            "paymentMethod":
                                                            restOrder[index].payment_method,
                                                            "user_id": restOrder[index].cart_id,

                                                          });
                                                    },
                                                    child: Text(
                                                      'Item Detail\'s',
                                                      textAlign:
                                                      TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: kWhiteColor,
                                                          fontWeight:
                                                          FontWeight.w600),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 20,
                                                  ),
                                                  RaisedButton(
                                                    padding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 15),
                                                    onPressed: () {
                                                      _getDirection(
                                                          'https://www.google.com/maps/search/?api=1&query=${restOrder[index].user_lat},${restOrder[index].user_lng}');
                                                    },
                                                    child: Text(
                                                      'Get Direction',
                                                      textAlign:
                                                      TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: kWhiteColor,
                                                          fontWeight:
                                                          FontWeight.w600),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                            ],
                                          ))
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) {
                            return Divider(
                              height: 8,
                              color: Colors.transparent,
                            );
                          },
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ):Container(),
                  (parcelOrder != null)?
                  Visibility(
                    visible: (parcelOrder != null && parcelOrder.length > 0)
                        ? true
                        : false,
                    child: Column(
                      children: [
                        Text(
                          'Parcel Orders',
                          style: Theme.of(context).textTheme.headline6.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Color(0xff6a6c74),
                              fontSize: 16),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        ListView.separated(
                          primary: false,
                          shrinkWrap: true,
                          itemCount: parcelOrder.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                print('${lat} - ${lng}');
                                if (parcelOrder[index].order_status == "Pending" ||
                                    parcelOrder[index].order_status ==
                                        "pending" ||
                                    parcelOrder[index].order_status ==
                                        "Confirmed") {
                                  Navigator.pushNamed(
                                      context, PageRoutes.newdeliveryparcel,
                                      arguments: {
                                        "cart_id": parcelOrder[index].cart_id,
                                        "vendorName":
                                        parcelOrder[index].vendor_name,
                                        "vendorAddress":
                                        parcelOrder[index].vendor_loc,
                                        "vendorlat": parcelOrder[index].source_lat,
                                        "vendorlng": parcelOrder[index].source_lng,
                                        "vendor_phone":
                                        parcelOrder[index].vendor_phone,
                                        "dlat": lat,
                                        "dlng": lng,
                                        "userlat": parcelOrder[index].destination_lat,
                                        "userlng": parcelOrder[index].destination_lng,
                                        "userName":
                                        parcelOrder[index].user_name,
                                        "userAddress":
                                        '${parcelOrder[index].source_houseno}${parcelOrder[index].source_add}${parcelOrder[index].source_landmark}${parcelOrder[index].source_city}${parcelOrder[index].source_state}(${parcelOrder[index].source_pincode})',
                                        "userphone":
                                        parcelOrder[index].user_phone,
                                        "itemDetails": parcelOrder[index],
                                        "remprice":
                                        '${(double.parse('${double.parse('${parcelOrder[index].distance}').toStringAsFixed(2)}') > 1) ? (double.parse('${parcelOrder[index].charges}') * double.parse('${double.parse('${parcelOrder[index].distance}').toStringAsFixed(2)}')) : double.parse('${parcelOrder[index].charges}')}',
                                        "paymentstatus":
                                        parcelOrder[index].payment_status,
                                        "paymentMethod":
                                        parcelOrder[index].payment_method,
                                        "user_id": parcelOrder[index].cart_id,

                                        "ui_type": "4",
                                      }).then((value) {
                                    getAllApi();getAllApi2();
                                  });
                                } else if (parcelOrder[index].order_status ==
                                    "Delivery Accepted") {
                                  Navigator.pushNamed(
                                      context, PageRoutes.parcelacceptpage,
                                      arguments: {
                                        "cart_id": parcelOrder[index].cart_id,
                                        "vendorName":
                                        parcelOrder[index].vendor_name,
                                        "vendorAddress":
                                        parcelOrder[index].vendor_loc,
                                        "vendorlat": parcelOrder[index].lat,
                                        "vendorlng": parcelOrder[index].lng,
                                        "vendor_phone":
                                        parcelOrder[index].vendor_phone,
                                        "dlat": lat,
                                        "dlng": lng,
                                        "userlat": '',
                                        "userlng": '',
                                        "userName":
                                        parcelOrder[index].user_name,
                                        "userAddress":
                                        '${parcelOrder[index].source_houseno}${parcelOrder[index].source_add}${parcelOrder[index].source_landmark}${parcelOrder[index].source_city}${parcelOrder[index].source_state}(${parcelOrder[index].source_pincode})',
                                        "userphone":
                                        parcelOrder[index].user_phone,
                                        "itemDetails": parcelOrder[index],
                                        "remprice":
                                        '${(double.parse('${double.parse('${parcelOrder[index].distance}').toStringAsFixed(2)}') > 1) ? (double.parse('${parcelOrder[index].charges}') * double.parse('${double.parse('${parcelOrder[index].distance}').toStringAsFixed(2)}')) : double.parse('${parcelOrder[index].charges}')}',
                                        "paymentstatus":
                                        parcelOrder[index].payment_status,
                                        "paymentMethod":
                                        parcelOrder[index].payment_method,
                                        "user_id": parcelOrder[index].cart_id,

                                        "ui_type": "4",
                                      }).then((value) {
                                    getAllApi();getAllApi2();
                                  });
                                } else if (parcelOrder[index].order_status ==
                                    "Out For Delivery") {
                                  Navigator.pushNamed(
                                      context, PageRoutes.parcelonway,
                                      arguments: {
                                        "cart_id": parcelOrder[index].cart_id,
                                        "vendorName":
                                        parcelOrder[index].vendor_name,
                                        "vendorAddress":
                                        parcelOrder[index].vendor_loc,
                                        "vendorlat": parcelOrder[index].lat,
                                        "vendorlng": parcelOrder[index].lng,
                                        "vendor_phone":
                                        parcelOrder[index].vendor_phone,
                                        "dlat": lat,
                                        "dlng": lng,
                                        "userlat": '',
                                        "userlng": '',
                                        "userName":
                                        parcelOrder[index].user_name,
                                        "userAddress":
                                        '${parcelOrder[index].source_houseno}${parcelOrder[index].source_add}${parcelOrder[index].source_landmark}${parcelOrder[index].source_city}${parcelOrder[index].source_state}(${parcelOrder[index].source_pincode})',
                                        "userphone":
                                        parcelOrder[index].user_phone,
                                        "itemDetails": parcelOrder[index],
                                        "remprice":
                                        '${(double.parse('${double.parse('${parcelOrder[index].distance}').toStringAsFixed(2)}') > 1) ? (double.parse('${parcelOrder[index].charges}') * double.parse('${double.parse('${parcelOrder[index].distance}').toStringAsFixed(2)}')) : double.parse('${parcelOrder[index].charges}')}',
                                        "paymentstatus":
                                        parcelOrder[index].payment_status,
                                        "paymentMethod":
                                        parcelOrder[index].payment_method,
                                        "user_id": parcelOrder[index].cart_id,

                                        "ui_type": "4",
                                      }).then((value) {
                                    getAllApi();getAllApi2();
                                  });
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Card(
                                elevation: 5,
                                color: kWhiteColor,
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  // margin: EdgeInsets.symmetric(horizontal: 10),
                                  padding: EdgeInsets.only(top: 5, bottom: 5),
                                  color: kWhiteColor,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 16.3),
                                            child: Image.asset(
                                              'images/vegetables_fruitsact.png',
                                              height: 42.3,
                                              width: 33.7,
                                            ),
                                          ),
                                          Expanded(
                                            child: ListTile(
                                              title: Text(
                                                'Order Id - #${parcelOrder[index].cart_id}',
                                                style: orderMapAppBarTextStyle
                                                    .copyWith(
                                                    letterSpacing: 0.07),
                                              ),
                                              subtitle: Text(
                                                '${parcelOrder[index].pickup_date}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline6
                                                    .copyWith(
                                                    fontSize: 11.7,
                                                    letterSpacing: 0.06,
                                                    color:
                                                    Color(0xffc1c1c1)),
                                              ),
                                              trailing: Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Text(
                                                    '${parcelOrder[index].order_status}',
                                                    style:
                                                    orderMapAppBarTextStyle
                                                        .copyWith(
                                                        color:
                                                        kMainColor),
                                                  ),
                                                  SizedBox(height: 7.0),
                                                  Text(
                                                    '$currency ${(double.parse('${double.parse('${parcelOrder[index].distance}').toStringAsFixed(2)}') > 1) ? (double.parse('${parcelOrder[index].charges}') * double.parse('${double.parse('${parcelOrder[index].distance}').toStringAsFixed(2)}')) : double.parse('${parcelOrder[index].charges}')}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline6
                                                        .copyWith(
                                                        fontSize: 11.7,
                                                        letterSpacing: 0.06,
                                                        color: Color(
                                                            0xffc1c1c1)),
                                                  )
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      Container(
                                        width:
                                        MediaQuery.of(context).size.width,
                                        alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.only(left: 20),
                                        color: kCardBackgroundColor,
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: 5,
                                            ),
                                            Text('Pickup and Destination',
                                                style: TextStyle(fontSize: 14)),
                                            SizedBox(
                                              height: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width:
                                        MediaQuery.of(context).size.width,
                                        padding: const EdgeInsets.only(
                                            left: 20, top: 5, bottom: 5),
                                        child: Text('Vendor Address',
                                            style: Theme.of(context)
                                                .textTheme
                                                .caption
                                                .copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.06,
                                                color: kMainColor)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 10.0, left: 20),
                                        child: Row(
                                          children: <Widget>[
                                            Icon(
                                              Icons.location_city,
                                              size: 30,
                                            ),
                                            SizedBox(
                                              width: 20,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    '${parcelOrder[index].vendor_name}',
                                                    style:
                                                    orderMapAppBarTextStyle
                                                        .copyWith(
                                                        fontSize: 10.0,
                                                        letterSpacing:
                                                        0.05),
                                                  ),
                                                  SizedBox(
                                                    height: 5.0,
                                                  ),
                                                  Text(
                                                    '${parcelOrder[index].vendor_loc}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .caption
                                                        .copyWith(
                                                        fontSize: 10.0,
                                                        letterSpacing:
                                                        0.05),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            FittedBox(
                                              fit: BoxFit.fill,
                                              child: Row(
                                                children: <Widget>[
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.phone,
                                                      color: kMainColor,
                                                      size: 15.0,
                                                    ),
                                                    onPressed: () {
                                                      _launchURL(
                                                          "tel://${parcelOrder[index].vendor_phone}");
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 5.0,
                                      ),
                                      Container(
                                        width:
                                        MediaQuery.of(context).size.width,
                                        padding: const EdgeInsets.only(
                                            left: 20, top: 5, bottom: 5),
                                        child: Text('Pickup Address',
                                            style: Theme.of(context)
                                                .textTheme
                                                .caption
                                                .copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.06,
                                                color: kMainColor)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 10.0, left: 20),
                                        child: Row(
                                          children: <Widget>[
                                            Icon(
                                              Icons.location_city,
                                              size: 30,
                                            ),
                                            SizedBox(
                                              width: 20,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    '${parcelOrder[index].source_name}',
                                                    style:
                                                    orderMapAppBarTextStyle
                                                        .copyWith(
                                                        fontSize: 10.0,
                                                        letterSpacing:
                                                        0.05),
                                                  ),
                                                  SizedBox(
                                                    height: 5.0,
                                                  ),
                                                  Text(
                                                    '${parcelOrder[index].source_add}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .caption
                                                        .copyWith(
                                                        fontSize: 10.5,
                                                        letterSpacing:
                                                        0.05),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            FittedBox(
                                              fit: BoxFit.fill,
                                              child: Row(
                                                children: <Widget>[
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.phone,
                                                      color: kMainColor,
                                                      size: 15.0,
                                                    ),
                                                    onPressed: () {
                                                      _launchURL(
                                                          "tel://${parcelOrder[index].source_phone}");
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width:
                                        MediaQuery.of(context).size.width,
                                        padding: const EdgeInsets.only(
                                            left: 20, top: 5, bottom: 5),
                                        child: Text('Destination Address',
                                            style: Theme.of(context)
                                                .textTheme
                                                .caption
                                                .copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.06,
                                                color: kMainColor)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 10.0, left: 20),
                                        child: Row(
                                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Icon(
                                              Icons.location_city,
                                              size: 30,
                                            ),
                                            SizedBox(
                                              width: 20,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    '${parcelOrder[index].destination_name}',
                                                    style:
                                                    orderMapAppBarTextStyle
                                                        .copyWith(
                                                        fontSize: 10.0,
                                                        letterSpacing:
                                                        0.05),
                                                  ),
                                                  SizedBox(
                                                    height: 5.0,
                                                  ),
                                                  Text(
                                                    '${parcelOrder[index].destination_add}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .caption
                                                        .copyWith(
                                                        fontSize: 10.5,
                                                        letterSpacing:
                                                        0.05),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            FittedBox(
                                              fit: BoxFit.fill,
                                              child: Row(
                                                children: <Widget>[
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.phone,
                                                      color: kMainColor,
                                                      size: 15.0,
                                                    ),
                                                    onPressed: () {
                                                      _launchURL(
                                                          "tel://${parcelOrder[index].destination_phone}");
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Visibility(
                                          visible: (parcelOrder[index]
                                              .order_status ==
                                              'Out for delivery' ||
                                              parcelOrder[index]
                                                  .order_status ==
                                                  'Out For Delivery')
                                              ? true
                                              : false,
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                alignment: Alignment.centerLeft,
                                                padding:
                                                EdgeInsets.only(left: 20),
                                                color: kCardBackgroundColor,
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      height: 5,
                                                    ),
                                                    Text(
                                                      'Delivery Contact',
                                                      style: TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                    SizedBox(
                                                      height: 5,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Row(
                                                        children: <Widget>[
                                                          Padding(
                                                            padding:
                                                            EdgeInsets.only(
                                                                left: 36.0,
                                                                bottom: 6.0,
                                                                top: 12.0,
                                                                right:
                                                                12.0),
                                                            child: ImageIcon(
                                                              AssetImage(
                                                                  'images/icons/ic_name.png'),
                                                              size: 13.3,
                                                              color: kMainColor,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${parcelOrder[index].destination_name}',
                                                            style: Theme.of(
                                                                context)
                                                                .textTheme
                                                                .caption
                                                                .copyWith(
                                                                fontSize:
                                                                13.0,
                                                                letterSpacing:
                                                                0.05),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: <Widget>[
                                                          Padding(
                                                            padding:
                                                            EdgeInsets.only(
                                                                left: 36.0,
                                                                bottom:
                                                                12.0,
                                                                top: 12.0,
                                                                right:
                                                                12.0),
                                                            child: ImageIcon(
                                                              AssetImage(
                                                                  'images/icons/ic_phone.png'),
                                                              size: 13.3,
                                                              color: kMainColor,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${parcelOrder[index].destination_phone}',
                                                            style: Theme.of(
                                                                context)
                                                                .textTheme
                                                                .caption
                                                                .copyWith(
                                                                fontSize:
                                                                13.0,
                                                                letterSpacing:
                                                                0.05),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 10),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _launchURL(
                                                            "tel://${parcelOrder[index].destination_phone}");
                                                      },
                                                      behavior: HitTestBehavior
                                                          .opaque,
                                                      child: Card(
                                                        elevation: 8,
                                                        clipBehavior:
                                                        Clip.hardEdge,
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                50)),
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                          kMainTextColor
                                                              .withOpacity(
                                                              0.2),
                                                          child: Icon(
                                                            Icons.call,
                                                            color: kGreen,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              )
                                            ],
                                          )),
                                      Visibility(
                                          visible: (parcelOrder[index]
                                              .order_status ==
                                              'Out for delivery' ||
                                              parcelOrder[index]
                                                  .order_status ==
                                                  'Out For Delivery')
                                              ? true
                                              : false,
                                          // visible:true,
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: [
                                                  RaisedButton(
                                                    padding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 15),
                                                    onPressed: () {
                                                      Navigator.pushNamed(
                                                          context,
                                                          PageRoutes
                                                              .itemDetailsparcel,
                                                          arguments: {
                                                            "cart_id":
                                                            '${parcelOrder[index].cart_id}',
                                                            "itemDetails":
                                                            parcelOrder[
                                                            index],
                                                            "currency": currency
                                                          });
                                                    },
                                                    child: Text(
                                                      'Item Detail\'s',
                                                      textAlign:
                                                      TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: kWhiteColor,
                                                          fontWeight:
                                                          FontWeight.w600),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 20,
                                                  ),
                                                  RaisedButton(
                                                    padding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 15),
                                                    onPressed: () {
                                                      _getDirection(
                                                          'https://www.google.com/maps/search/?api=1&query=${parcelOrder[index].destination_lat},${parcelOrder[index].destination_lng}');
                                                    },
                                                    child: Text(
                                                      'Get Direction',
                                                      textAlign:
                                                      TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: kWhiteColor,
                                                          fontWeight:
                                                          FontWeight.w600),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                            ],
                                          ))
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) {
                            return Divider(
                              height: 8,
                              color: Colors.transparent,
                            );
                          },
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ):Container(),
                ],
              ),
            )
        )
          :
      Align(
        alignment: Alignment.center,
        child: Text(
          (tabController.index == 0)
              ? 'No Orders for Today'
              : 'No Completed Orders',
          textAlign: TextAlign.center,
        ),
      )
    ;
      }).toList(),
      ),

      // floatingActionButton:
      //     BoomMenu(
      //   animatedIcon: AnimatedIcons.menu_close,
      //   animatedIconTheme: IconThemeData(size: 22.0),
      //   // child: Text('1'),
      //   onOpen: () {
      //   },
      //   onClose: () => print('DIAL CLOSED'),
      //   scrollVisible: true,
      //   overlayColor: Colors.black,
      //   overlayOpacity: 0.2,
      //   children: [
      //     MenuItem(
      //       title: "Today Order's",
      //       titleColor: kWhiteColor,
      //       subtitle: "Tap to view orders",
      //       subTitleColor: kWhiteColor,
      //       backgroundColor: Colors.deepOrange,
      //       onTap: () => Navigator.pushNamed(context, PageRoutes.todayOrder)
      //           .then((value) {
      //         hitTestServices();
      //       }),
      //     ),
      //     MenuItem(
      //       title: "Next Day Order's",
      //       titleColor: Colors.white,
      //       subtitle: "Tap to view orders",
      //       subTitleColor: kWhiteColor,
      //       backgroundColor: Colors.green,
      //       onTap: () => Navigator.pushNamed(context, PageRoutes.nextDayOrder)
      //           .then((value) {
      //         hitTestServices();
      //       }),
      //     ),
      //   ],
      // ),
    )
      );
  }

  void hitTestServices() async {
    preferences = await SharedPreferences.getInstance();
    var client = http.Client();
    var dboy_completed_orderd = today_order_count;
    client.post(dboy_completed_orderd, body: {
      'delivery_boy_id': '${preferences.getInt('delivery_boy_id')}'
    }).then((value) {
      if (value.statusCode == 200 && value.body != null) {
        var jsonData = jsonDecode(value.body);
        print('${jsonData.toString()}');
        if (jsonData['status'] == "1") {
          if (jsonData['data'] > 0) {
            orderCount = jsonData['data'];
          }
          if (orderCount > 0) {
            setState(() {
              isRingBell = true;
            });
          } else {
            setState(() {
              isRingBell = false;
            });
          }
        } else {
          if (orderCount > 0) {
            setState(() {
              isRingBell = true;
            });
          } else {
            setState(() {
              isRingBell = false;
            });
          }
        }
      }
    }).catchError((e) {
      if (orderCount > 0) {
        setState(() {
          isRingBell = true;
        });
      } else {
        setState(() {
          isRingBell = false;
        });
      }
      print(e);
    });
  }

  void hitStatusService() async {
    setState(() {
      isRun = true;
    });
    preferences = await SharedPreferences.getInstance();
    dynamic statuss = preferences.getInt('duty');
    var client = http.Client();
    var statusUrl = dboy_status;
    client.post(statusUrl, body: {
      'delivery_boy_id': '${preferences.getInt('delivery_boy_id')}',
      'status': '${statuss == 1 ? 0 : 1}'
    }).then((value) {
      setState(() {
        isRun = false;
      });
      if (value.statusCode == 200 && value.body != null) {
        var jsonData = jsonDecode(value.body);
        DutyOnOff dutyOnOff = DutyOnOff.fromJson(jsonData);
        switch (dutyOnOff.status.toString().trim()) {
          case '0':
            print('0');
            break;
          case '1':
            print('1');
            preferences.setInt('duty', 1);
            setState(() {
              status = preferences.getInt('duty');
            });
            break;
          case '2':
            print('2');
            preferences.setInt('duty', 0);
            setState(() {
              status = preferences.getInt('duty');
            });
            break;
        }
        Toast.show(dutyOnOff.message, context, duration: Toast.LENGTH_SHORT);
      }
    }).catchError((e) {
      print(e);
      setState(() {
        isRun = false;
      });
    });
  }
}

class Account extends StatefulWidget {
  final dynamic driverName;
  final dynamic driverNumber;
  final dynamic imageUrld;

  Account(this.driverName, this.driverNumber, this.imageUrld);

  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String number;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          Container(
            child: UserDetails(widget.driverName, widget.driverNumber, widget.imageUrld),
          ),
          Divider(
            color: kCardBackgroundColor,
            thickness: 8.0,
          ),
          BuildListTile(
              image: 'images/account/ic_menu_home.png',
              text: 'Home',
              onTap: () => Navigator.pop(context)),
          BuildListTile(
              image: 'images/account/ic_menu_tncact.png',
              text: 'Terms & Conditions',
              onTap: () {
                scfoldKey.currentState.openEndDrawer();
                Navigator.pushNamed(context, PageRoutes.tncPage);
              }),
          BuildListTile(
              image: 'images/account/ic_menu_supportact.png',
              text: 'Support',
              onTap: () {
                scfoldKey.currentState.openEndDrawer();
                Navigator.pushNamed(context, PageRoutes.supportPage,
                    arguments: number);
              }),
          BuildListTile(
            image: 'images/account/ic_menu_aboutact.png',
            text: 'About us',
            onTap: () {
              scfoldKey.currentState.openEndDrawer();
              Navigator.pushNamed(context, PageRoutes.aboutUsPage);
            },
          ),
          Column(
            children: <Widget>[
              BuildListTile(
                  image: 'images/account/ic_menu_insight.png',
                  text: 'Order History',
                  onTap: () {
                    scfoldKey.currentState.openEndDrawer();
                    Navigator.pushNamed(context, PageRoutes.insightPage);
                  }),
              LogoutTile(),
            ],
          ),
        ],
      ),
    );
  }
}

class LogoutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BuildListTile(
      image: 'images/account/ic_menu_logoutact.png',
      text: 'Logout',
      onTap: () {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Logging out'),
                content: Text('Are you sure?'),
                actions: <Widget>[
                  FlatButton(
                    child: Text('No'),
                    textColor: kMainColor,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: kTransparentColor)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  FlatButton(
                      child: Text('Yes'),
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: kTransparentColor)),
                      textColor: kMainColor,
                      onPressed: () async {
                        SharedPreferences pref =
                            await SharedPreferences.getInstance();
                        pref.clear().then((value) {
                          if (value) {
                            Navigator.pushAndRemoveUntil(context,
                                MaterialPageRoute(builder: (context) {
                              return LoginNavigator();
                            }), (Route<dynamic> route) => false);
                          }
                        });
                      })
                ],
              );
            });
      },
    );
  }
}

class UserDetails extends StatelessWidget {
  final dynamic driverName;
  final dynamic driverNumber;
  final dynamic imageUrld;

  UserDetails(this.driverName, this.driverNumber, this.imageUrld);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 20,
            ),
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 32.0,
                  backgroundImage: NetworkImage('${imageUrld}'),
                ),
                SizedBox(
                  width: 20.0,
                ),
                InkWell(
                  onTap: () {
                    scfoldKey.currentState.openEndDrawer();
                    Navigator.pushNamed(context, PageRoutes.editProfile);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('\n' + '${driverName}',
                          style: Theme.of(context).textTheme.bodyText1),
                      Text('\n' + '${driverNumber}',
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2
                              .copyWith(color: Color(0xff9a9a9a))),
                      SizedBox(
                        height: 5.0,
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ));
  }

}
