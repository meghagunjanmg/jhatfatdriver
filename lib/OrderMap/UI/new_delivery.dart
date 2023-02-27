import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/Components/bottom_bar.dart';
import 'package:driver/Routes/routes.dart';
import 'package:driver/Themes/colors.dart';
import 'package:driver/Themes/style.dart';
import 'package:driver/baseurl/baseurl.dart';
import 'package:driver/beanmodel/Multistoreorder.dart';
import 'package:driver/beanmodel/orderbean.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';

class NewDeliveryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NewDeliveryBody();
  }
}

class NewDeliveryBody extends StatefulWidget {
  @override
  _NewDeliveryBodyState createState() => _NewDeliveryBodyState();
}

class _NewDeliveryBodyState extends State<NewDeliveryBody> {
  dynamic cart_id = '';
  dynamic vendorName = '';
  dynamic vendorAddress = '';
  dynamic vendorDistance = '';
  dynamic userName = '';
  dynamic userAddress = '';
  dynamic userphone;
  dynamic vendorlat;
  dynamic vendorlng;
  dynamic dlat;
  dynamic dlng;
  dynamic userlat;
  dynamic userlng;
  dynamic remprice;
  dynamic paymentstatus;
  dynamic paymentMethod;
  dynamic order_id;
  List<OrderDeatisSub> orderDeatisSub;
  dynamic distance;
  dynamic currency;

  GoogleMapController _controller;
  List<LatLng> polylineCoordinates = [];
  final Set<Marker> markers = new Set();
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  bool _added = false;
  List<OrderDetail> orders = [];


  @override
  void initState() {
    super.initState();
    getCurrency();

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
        ModalRoute
            .of(context)
            .settings
            .arguments;
    setState(() {
      cart_id = dataObject['cart_id'];
      vendorName = dataObject['vendorName'];
      vendorAddress = dataObject['vendorAddress'];
      userName = dataObject['userName'];
      userAddress = dataObject['userAddress'];
      userphone = dataObject['userphone'];
      vendorlat = dataObject['vendorlat'];
      vendorlng = dataObject['vendorlng'];
      dlat = dataObject['dlat'];
      dlng = dataObject['dlng'];
      userlat = dataObject['userlat'];
      userlng = dataObject['userlng'];
      remprice = dataObject['remprice'];
      paymentstatus = dataObject['paymentstatus'];
      paymentMethod = dataObject['paymentMethod'];
      order_id = dataObject['order_id'];
      orderDeatisSub = dataObject['itemDetails'] as List;
      // distance = calculateDistance(
      //         double.parse(vendorlat), double.parse(vendorlng), dlat, dlng)
      //     .toStringAsFixed(2);
    });
    if(orders.isEmpty){
      getorders(order_id);
    }

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
                  padding:
                  EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                  child: FlatButton.icon(
                    icon: Icon(
                      Icons.shopping_basket,
                      color: kMainColor,
                      size: 13.0,
                    ),
                    label: Text('Order Info',
                        style: Theme.of(context).textTheme.caption.copyWith(
                          fontSize: 11.7,
                          fontWeight: FontWeight.bold,
                        )),
                    onPressed: () {
                      Navigator.pushNamed(
                          context,
                          PageRoutes
                              .itemDetails,
                          arguments: {
                            "cart_id":
                            '${cart_id}',
                            "itemDetails":
                            orders,
                            "currency": currency
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
                      markers: markers, //markers to show on map
                      polylines: Set<Polyline>.of(polylines.values),
                      initialCameraPosition: CameraPosition(
                          target: LatLng(double.parse(vendorlat),double.parse(vendorlng)),
                          zoom: 14),
                      onMapCreated: (GoogleMapController controller) async {
                        ///getDirections();
                        addPolyLine(polylineCoordinates);
                        setState(() {
                          _controller = controller;
                        });


                      },
                    ),
                  ),
                  Text(
                    'Shops Locations',
                    style: orderMapAppBarTextStyle.copyWith(
                        fontSize: 20.0, letterSpacing: 0.05,fontWeight: FontWeight.w900),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 400, minHeight: 100),
                    child:
                    ListView.builder(
                        itemCount: orders.length,
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          return
                            Column(
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
                                              '${orders[index].vendorName}',
                                              style: orderMapAppBarTextStyle.copyWith(
                                                  letterSpacing: 0.07),
                                            ),
                                            subtitle: Row(
                                                children: <Widget>[
                                                  Container(
                                                    child: ImageIcon(
                                                      AssetImage('images/custom/ic_pickup_pointact.png'),
                                                      size: 13.3,
                                                      color: kMainColor,
                                                    ),
                                                  ),
                                                  Container (
                                                    child: new Column (
                                                      children: <Widget>[
                                                        new Text (
                                                          '${orders[index].vendorAddress}'
                                                          ,
                                                          style: Theme
                                                              .of(context)
                                                              .textTheme
                                                              .body1
                                                              .copyWith(fontSize: 10.0, letterSpacing: 0.05),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ]
                                            )
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[
                                          FittedBox(
                                            fit: BoxFit.fill,
                                            child: Row(
                                              children: <Widget>[
                                                MaterialButton(
                                                  onPressed: () {
                                                    _getDirection(
                                                        'https://www.google.com/maps/search/?api=1&query=${orders[index].vendorLat},${orders[index].vendorLng}');
                                                  },
                                                  color: kMainColor,
                                                  textColor: Colors.white,
                                                  child: Icon(
                                                    Icons.navigation,
                                                    size: 15,
                                                  ),
                                                  padding: EdgeInsets.all(10),
                                                  shape: CircleBorder(),

                                                ),
                                              ],
                                            ),
                                          ),

                                          FittedBox(
                                            fit: BoxFit.fill,
                                            child: Row(
                                              children: <Widget>[
                                                MaterialButton(
                                                  onPressed: () {
                                                    _launchURL("tel://${orders[index].vendorPhone}");
                                                  },
                                                  color: kMainColor,
                                                  textColor: Colors.white,
                                                  child: Icon(
                                                    Icons.phone,
                                                    size: 15,
                                                  ),
                                                  padding: EdgeInsets.all(10),
                                                  shape: CircleBorder(),

                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                    ],
                                  ),
                                  Divider(
                                    thickness: 1.2,
                                  )
                                  ,]);
                        }),
                  ),

                  ConstrainedBox(
                    constraints: BoxConstraints(),
                    child:
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        children: <Widget>[
                          Text(
                            'User Location',
                            style: orderMapAppBarTextStyle.copyWith(
                                fontSize: 20.0, letterSpacing: 0.05,fontWeight: FontWeight.w900),
                          ),
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
                                      '${userName}',
                                      style: orderMapAppBarTextStyle.copyWith(
                                          letterSpacing: 0.07),
                                    ),
                                    subtitle: Row(
                                        children: <Widget>[
                                          Container(
                                            child: ImageIcon(
                                              AssetImage('images/custom/ic_pickup_pointact.png'),
                                              size: 13.3,
                                              color: kMainColor,
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Container (
                                                child: new Column (
                                                  children: <Widget>[
                                                    new Text (
                                                      '${userAddress}'
                                                      ,
                                                      style: Theme
                                                          .of(context)
                                                          .textTheme
                                                          .body1
                                                          .copyWith(fontSize: 10.0, letterSpacing: 0.05),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ]
                                    )
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  FittedBox(
                                    fit: BoxFit.fill,
                                    child: Row(
                                      children: <Widget>[
                                        MaterialButton(
                                          onPressed: () {
                                            _getDirection(
                                                'https://www.google.com/maps/search/?api=1&query=${userlat},${userlng}');
                                          },
                                          color: kMainColor,
                                          textColor: Colors.white,
                                          child: Icon(
                                            Icons.navigation,
                                            size: 15,
                                          ),
                                          padding: EdgeInsets.all(10),
                                          shape: CircleBorder(),

                                        ),
                                      ],
                                    ),
                                  ),

                                  FittedBox(
                                    fit: BoxFit.fill,
                                    child: Row(
                                      children: <Widget>[
                                        MaterialButton(
                                          onPressed: () {
                                            _launchURL("tel://${userphone}");
                                          },
                                          color: kMainColor,
                                          textColor: Colors.white,
                                          child: Icon(
                                            Icons.phone,
                                            size: 15,
                                          ),
                                          padding: EdgeInsets.all(10),
                                          shape: CircleBorder(),

                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                            ],
                          ),

                          BottomBar(
                              text: "Mark as Picked",
                              onTap: () {
                                pr.show();
                                hitService(cart_id, pr);
                              } // Navigator.popAndPushNamed(context, PageRoutes.acceptedPage),
                          ),
                        ],
                      ),
                    ),
                  ),


                ],
              ),

            ]
        )
    );
  }

  void hitService(cartid, ProgressDialog pr) async {

    var url = delivery_accepted;
    var client = http.Client();
    client.post(url, body: {'cart_id': '${cartid}'}).then((value) {
      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          pr.hide();
          Toast.show('Order Accepted', context,
              duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);

          Navigator.popAndPushNamed(context, PageRoutes.acceptedPage,
              arguments: {
                "cart_id": cart_id,
                "vendorName": vendorName,
                "vendorAddress": vendorAddress,
                "vendorlat": vendorlat,
                "vendorlng": vendorlng,
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
                "order_id": order_id
              });
        } else {
          pr.hide();
          Toast.show('Order Not Accepted', context,
              duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
        }
      }
    }).catchError((e) {
      pr.hide();
      print(e);
    });
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

            polylineCoordinates.add(new LatLng(double.parse(element.vendorLat),double.parse(element.vendorLng)));
            markers.add(Marker( //add second marker
              markerId: MarkerId(element.vendorId.toString()),
              position: LatLng(double.parse(element.vendorLat),double.parse(element.vendorLng)), //position of marker
              infoWindow: InfoWindow( //popup info
                title: element.vendorName,
              ),
              icon: BitmapDescriptor.defaultMarker, //Icon for Marker
            ));



            polylineCoordinates.add(new LatLng(double.parse(userlat),double.parse(userlng)));
            markers.add(Marker( //add second marker
              markerId: MarkerId(userlng.toString()),
              position: LatLng(double.parse(userlat),double.parse(userlng)), //position of marker
              infoWindow: InfoWindow( //popup info
                title: userName,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), //Icon for Marker
            ));


          });
        });
        addPolyLine(polylineCoordinates);

        setState(() {
          orders.clear();
          orders = temp;
        });
      }
    }).catchError((e) {
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

}