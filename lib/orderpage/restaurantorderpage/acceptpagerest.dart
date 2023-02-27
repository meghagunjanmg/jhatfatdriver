import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as loc;
import 'package:driver/Components/bottom_bar.dart';
import 'package:driver/Routes/routes.dart';
import 'package:driver/Themes/colors.dart';
import 'package:driver/Themes/style.dart';
import 'package:driver/baseurl/baseurl.dart';
import 'package:driver/beanmodel/todayrestorder.dart';
import 'package:driver/orderpage/restaurantorderpage/rest_slide_up_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';

class AcceptedPageRest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AcceptedBodyRest();
  }
}

class AcceptedBodyRest extends StatefulWidget {
  @override
  _AcceptedRestBodyState createState() => _AcceptedRestBodyState();
}

class _AcceptedRestBodyState extends State<AcceptedBodyRest> {
  dynamic cart_id = '';
  dynamic vendorName = '';
  dynamic vendorAddress = '';
  dynamic vendorDistance = '';
  dynamic userName = '';
  dynamic userAddress = '';
  dynamic userphone;
  dynamic vendor_phone;
  dynamic vendorlat;
  dynamic vendorlng;
  dynamic dlat;
  dynamic dlng;
  dynamic userlat;
  dynamic userlng;
  dynamic remprice;
  dynamic paymentstatus;
  dynamic paymentMethod;
  dynamic user_id;
  List<TodayRestaurantOrderDetails> orderDeatisSub;
  List<AddonList> addons;
  dynamic distance;
  dynamic currency;
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData> _locationSubscription;
  GoogleMapController _controller;
  List<LatLng> polylineCoordinates = [];
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  bool _added = false;

  double latitude=0.0;

  double longitude=0.0;

  @override
  void initState() {
    getCurrency();
    super.initState();
  }

  getCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currency = prefs.getString('curency');
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    final ProgressDialog pr = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false, showLogs: true);
    pr.style(
        message: 'Loading please wait...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));
    final Map<String, Object> dataObject =
        ModalRoute.of(context).settings.arguments;
    setState(() {
      cart_id = dataObject['cart_id'];
      vendorName = dataObject['vendorName'];
      vendorAddress = dataObject['vendorAddress'];
      userName = dataObject['userName'];
      userAddress = dataObject['userAddress'];
      userphone = dataObject['userphone'];
      vendorlat = dataObject['vendorlat'];
      vendorlng = dataObject['vendorlng'];
      vendor_phone = dataObject['vendor_phone'];
      dlat = dataObject['dlat'];
      dlng = dataObject['dlng'];
      userlat = dataObject['userlat'];
      userlng = dataObject['userlng'];
      remprice = dataObject['remprice'];
      paymentstatus = dataObject['paymentstatus'];
      paymentMethod = dataObject['paymentMethod'];
      user_id = dataObject['user_id'];
      orderDeatisSub = dataObject['itemDetails'] as List;
      addons = dataObject['addons'] as List;
      distance = calculateDistance(
          double.parse(vendorlat), double.parse(vendorlng), double.parse(userlat), double.parse(userlng))
          .toStringAsFixed(2);
      latitude=double.parse(vendorlat);
      longitude=double.parse(vendorlng);

    });

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: AppBar(
            automaticallyImplyLeading: true,
            title: Text('Order - #${cart_id}',
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    .copyWith(fontWeight: FontWeight.w500)),
            actions: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                child: FlatButton.icon(
                  icon: Icon(
                    isOpen ? Icons.close : Icons.shopping_basket,
                    color: kMainColor,
                    size: 13.0,
                  ),
                  label: Text(isOpen ? 'Close' : 'Order Info',
                      style: Theme.of(context).textTheme.caption.copyWith(
                            fontSize: 11.7,
                            fontWeight: FontWeight.bold,
                          )),
                  onPressed: () {
                    setState(() {
                      if (isOpen)
                        isOpen = false;
                      else
                        isOpen = true;
                    });
                  },
                ),
              )
            ],
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                child:
                GoogleMap(
                  mapType: MapType.normal,
                  markers: Set<Marker>.of(markers.values),
                  polylines: Set<Polyline>.of(polylines.values),
                  initialCameraPosition: CameraPosition(
                      target: LatLng(double.parse(vendorlat),double.parse(vendorlng)),
                      zoom: 14),
                  onMapCreated: (GoogleMapController controller) async {
                    _addMarker(LatLng(double.parse(vendorlat), double.parse(vendorlng)), "source", BitmapDescriptor.defaultMarkerWithHue(90));
                    _addMarker(LatLng(double.parse(userlat), double.parse(userlng)), "dest", BitmapDescriptor.defaultMarkerWithHue(90));
                    getDirections();

                    setState(() {
                      _controller = controller;
                    });


                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 16.3),
                          child: Image.asset(
                            'images/vegetables_fruitsact.png',
                            height: 42.3,
                            width: 33.7,
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(
                              '${vendorName}',
                              style: orderMapAppBarTextStyle.copyWith(
                                  letterSpacing: 0.07),
                            ),
                            subtitle: Row(
                              children: <Widget>[
                                Text(
                                  '${distance}km ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline6
                                      .copyWith(
                                          fontSize: 11.7,
                                          letterSpacing: 0.06,
                                          color: kMainColor,
                                          fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '(20 min)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline6
                                      .copyWith(
                                          fontSize: 11.7,
                                          letterSpacing: 0.06,
                                          color: Color(0xffc1c1c1)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20.0),
                          child: FlatButton(
                            onPressed: () {
                              _getDirection(
                                  'https://www.google.com/maps/search/?api=1&query=${userlat},${userlng}');
                            },
                            color: kMainColor,
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.navigation,
                                  color: kWhiteColor,
                                  size: 14.0,
                                ),
                                SizedBox(
                                  width: 4.0,
                                ),
                                Text(
                                  'Direction',
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption
                                      .copyWith(
                                          color: kWhiteColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.7,
                                          letterSpacing: 0.06),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      color: kCardBackgroundColor,
                      thickness: 1.0,
                    ),
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(
                              left: 36.0, bottom: 6.0, top: 6.0, right: 20.0),
                          child: ImageIcon(
                            AssetImage('images/custom/ic_pickup_pointact.png'),
                            size: 13.3,
                            color: kMainColor,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${vendorName}',
                                style: orderMapAppBarTextStyle.copyWith(
                                    fontSize: 10.0, letterSpacing: 0.05),
                              ),
                              SizedBox(
                                height: 5.0,
                              ),
                              Text(
                                '${vendorAddress}',
                                style: Theme.of(context)
                                    .textTheme
                                    .caption
                                    .copyWith(
                                        fontSize: 10.0, letterSpacing: 0.05),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
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
                                  _launchURL("tel://${vendor_phone}");
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(
                              left: 36.0, bottom: 12.0, top: 12.0, right: 20.0),
                          child: ImageIcon(
                            AssetImage('images/custom/ic_droppointact.png'),
                            size: 13.3,
                            color: kMainColor,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${userName}',
                              style: orderMapAppBarTextStyle.copyWith(
                                  fontSize: 10.0, letterSpacing: 0.05),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              '${userAddress}',
                              style: Theme.of(context)
                                  .textTheme
                                  .caption
                                  .copyWith(
                                      fontSize: 10.0, letterSpacing: 0.05),
                            ),
                          ],
                        ),
                      ],
                    ),
                    BottomBar(
                        text: "Marked as Picked",
                        onTap: () {
                          pr.show();
                          hitService(cart_id, pr);
                        }),
                  ],
                ),
              )
            ],
          ),
          isOpen
              ? OrderInfoContainerRest(orderDeatisSub, remprice, paymentMethod,
                  paymentstatus, currency, addons)
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  void hitService(cartid, ProgressDialog pr) async {

    var url = resturant_delivery_out;
    var client = http.Client();
    client.post(url, body: {'cart_id': '${cartid}'}).then((value) {
      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          pr.hide();
          Toast.show('Order Picked', context,
              duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
          Navigator.popAndPushNamed(context, PageRoutes.restonway, arguments: {
            "cart_id": cart_id,
            "vendorName": vendorName,
            "vendorAddress": vendorAddress,
            "vendorlat": vendorlat,
            "vendorlng": vendorlng,
            "vendor_phone": vendor_phone,
            "dlat": dlat,
            "dlng": dlng,
            "userlat": userlat,
            "userlng": userlng,
            "userName": userName,
            "userAddress": userAddress,
            "userphone": userphone,
            "itemDetails": orderDeatisSub,
            "remprice": remprice,
            "paymentstatus": paymentstatus,
            "paymentMethod": paymentMethod,
            "user_id": user_id,
            "ui_type": "2",
            "addons": addons
          });
        } else {
          pr.hide();
          Toast.show('Some error occurred please contact with store.', context,
              duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
        }
      }
    }).catchError((e) {
      pr.hide();
      print(e);
    });
  }

  _launchURL(url) async {
  try {
  launch(url);
} catch (error, stack) {
  // log error
}
  }

  _getDirection(url) async {
  try {
  launch(url);
} catch (error, stack) {
  // log error
}
  }
  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
    Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  getDirections() async {
    List<LatLng> polylineCoordinates = [];
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
     apikey,
      PointLatLng(double.parse(vendorlat), double.parse(vendorlng)),
      PointLatLng(double.parse(userlat), double.parse(userlng)),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    addPolyLine(polylineCoordinates);
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: kMainColor,
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
    setState(() {});
  }

}
