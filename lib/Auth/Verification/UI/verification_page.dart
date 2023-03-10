import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:driver/baseurl/baseurl.dart';
import 'package:driver/beanmodel/profilebean.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:pin_code_text_field/pin_code_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver/Themes/colors.dart';
import 'package:driver/Themes/style.dart';
import 'package:toast/toast.dart';

import '../../../Routes/routes.dart';

class VerificationPage extends StatelessWidget {
  final VoidCallback onVerificationDone;

  VerificationPage(this.onVerificationDone);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Text(
          'Verification',
          style: headingStyle,
        ),
      ),
      body: OtpVerify(onVerificationDone),
    );
  }
}

//otp verification class
class OtpVerify extends StatefulWidget {
  final VoidCallback onVerificationDone;

  OtpVerify(this.onVerificationDone);

  @override
  _OtpVerifyState createState() => _OtpVerifyState();
}

class _OtpVerifyState extends State<OtpVerify> {
  final TextEditingController _controller = TextEditingController();
  FirebaseMessaging messaging;
  bool isDialogShowing = false;
  dynamic token = '';
  var showDialogBox = false;
  var verificaitonPin = "";
  String phoneNo;
  String smsOTP;
  String verificationId;
  String errorMessage = '';
  String contact = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer _timer;

  @override
  void initState() {
    messaging = FirebaseMessaging();
    messaging.getToken().then((value) {
      token = value;
    });

    super.initState();
    getd();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void getd() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    contact = pref.getString("delivery_boy_phone");

    print(contact);

    generateOtp('+91$contact');
  }

  @override
  Widget build(BuildContext context) {
//    MobileNumberArg mobileNumberArg = ModalRoute.of(context).settings.arguments;

    return SingleChildScrollView(
      child: Container(
        height: MediaQuery
            .of(context)
            .size
            .height - 100,
        child: Stack(
          children: <Widget>[
            Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(
                          top: 10, bottom: 5, right: 80, left: 80),
                      child: Center(
                        child: Text(
                          'Verify your phone number',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: kMainTextColor,
                              fontSize: 30,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      child: Text(
                        "Enter your otp code here.",
                        textAlign: TextAlign.center,
                        style: Theme
                            .of(context)
                            .textTheme
                            .headline6
                            ?.copyWith(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      padding: EdgeInsets.only(right: 20.0, left: 20.0),
                      child: Column(
                        children: <Widget>[
                          SizedBox(height: 10.0),
                          PinCodeTextField(
                            autofocus: false,
                            controller: _controller,
                            hideCharacter: false,
                            highlight: true,
                            highlightColor: kHintColor,
                            defaultBorderColor: kMainColor,
                            hasTextBorderColor: kMainColor,
                            maxLength: 6,
                            pinBoxRadius: 20,
                            onDone: (text) {
                              SystemChannels.textInput
                                  .invokeMethod('TextInput.hide');
                              verificaitonPin = text;
                              smsOTP = text as String;
                            },
                            pinBoxWidth: 40,
                            pinBoxHeight: 40,
                            hasUnderline: false,
                            wrapAlignment: WrapAlignment.spaceAround,
                            pinBoxDecoration: ProvidedPinBoxDecoration
                                .roundedPinBoxDecoration,
                            pinTextStyle: TextStyle(fontSize: 22.0),
                            pinTextAnimatedSwitcherTransition:
                            ProvidedPinBoxTextAnimation.scalingTransition,
                            pinTextAnimatedSwitcherDuration:
                            Duration(milliseconds: 300),
                            highlightAnimationBeginColor: Colors.black,
                            highlightAnimationEndColor: Colors.white12,
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 15.0),
                          const Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Didn't you receive any code?",
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.center,
                              style:
                              TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
                          SizedBox(height: 10.0),
                          InkWell(
                            onTap: () {
                              generateOtp('+91$contact');
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Text("Resend Code"),
                            ),
                          ),
                          const SizedBox(height: 10.0),

                          Visibility(
                              visible: showDialogBox,
                              child: const Align(
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                  ],
                )),
            Positioned(
              bottom: 12,
              left: 20,
              right: 20.0,
              child: new GestureDetector(
                onTap: () {
                  if (!showDialogBox) {
                    setState(() {
                      showDialogBox = true;
                    });
                  }
                  verifyOtp();
                },
                child: Container(
                  alignment: Alignment.center,
                  height: 52,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                      color: kMainColor),

                  child: Text(
                    'Verify',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      color: kWhiteColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void hitService(String verificaitonPin, BuildContext context) async {
    if (token != null && token.length > 0) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var url = driverlogin;
      http.post(url, body: {
        'phone': prefs.getString('delivery_boy_phone'),
        'otp': verificaitonPin,
        'device_id': '${token}'
      }).then((response) {
        print("DATA " + response.body.toString());
        if (response.statusCode == 200) {
          var jsonData = jsonDecode(response.body);
          if (jsonData['status'] == 1) {
            DriverProfile profile = DriverProfile.fromJson(jsonData['data']);
            prefs.setInt('duty', 0);
            var delivery_id = int.parse('${profile.delivery_boy_id}');
            prefs.setInt("delivery_boy_id", delivery_id);
            prefs.setString("delivery_boy_name", profile.delivery_boy_name);
            prefs.setString("delivery_boy_image", profile.delivery_boy_image);
            prefs.setString("delivery_boy_phone", profile.delivery_boy_phone);
            prefs.setString("delivery_boy_pass", profile.delivery_boy_pass);
            prefs.setString("device_id", profile.device_id);
            prefs.setString("delivery_boy_status", profile.delivery_boy_status);
            prefs.setString("is_confirmed", profile.is_confirmed);
            var cityadmin_id = int.parse(
                '${(profile.cityadmin_id != null) ? profile.cityadmin_id : 0}');
            prefs.setInt("cityadmin_id", cityadmin_id);
            var phone_verify = int.parse('${profile.phone_verify}');
            prefs.setInt("phoneverifed", phone_verify);
            prefs.setBool("islogin", true);
            if (jsonData['currency'] != null &&
                jsonData['currency']
                    .toString()
                    .length > 2) {
              CurrencyData currencyData =
              CurrencyData.fromJson(jsonData['currency']);
              prefs.setString("curency", '${currencyData.currency_sign}');
            }
            Toast.show(jsonData['message'], context,
                duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
            widget.onVerificationDone();
          } else {
            prefs.setInt("phoneverifed", 0);
            prefs.setBool("islogin", false);
            Toast.show(jsonData['message'], context,
                duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
            setState(() {
              showDialogBox = false;
            });
          }
        }
      });
    } else {
      messaging.getToken().then((value) {
        token = value;
        hitService(verificaitonPin, context);
      });
    }
  }

  //Method for generate otp from firebase
  Future<void> generateOtp(String contact) async {
    var smsOTPSent = (String verId, [int forceCodeResend]) {
      verificationId = verId;
      print("** " + verificationId);
    };
    try {
      await _auth.verifyPhoneNumber(
          phoneNumber: contact,
          codeAutoRetrievalTimeout: (String verId) {
            verificationId = verId;
          },
          codeSent: smsOTPSent,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (AuthCredential phoneAuthCredential) {
            /////verifyOtp();
          },
          verificationFailed: (Exception exception) {
            // Navigator.pop(context, exception.message);
          });
    } catch (e) {
      handleError(e as FirebaseAuthException);
      // Navigator.pop(context, (e as PlatformException).message);
    }
  }

  //Method for verify otp entered by user
  Future<void> verifyOtp() async {
    if (smsOTP == null || smsOTP == '') {
      showAlertDialog(context, 'please enter 6 digit otp');
      return;
    }

    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsOTP,
      );

      await _auth.signInWithCredential(credential);

      print(smsOTP);
      hitService(smsOTP, context);
    } catch (e) {
      print(e.toString());

      handleError(e as FirebaseAuthException);
    }
  }

  //Method for handle the errors
  void handleError(FirebaseAuthException error) {
    switch (error.code) {
      case 'ERROR_INVALID_VERIFICATION_CODE':
        FocusScope.of(context).requestFocus(FocusNode());
        setState(() {
          errorMessage = 'Invalid Code';
        });
        showAlertDialog(context, 'Invalid Code');
        break;
      default:
        showAlertDialog(context, error.message.toString());
        break;
    }
  }

  //Basic alert dialogue for alert errors and confirmations
  void showAlertDialog(BuildContext context, String message) {
    // set up the AlertDialog
    final CupertinoAlertDialog alert = CupertinoAlertDialog(
      title: const Text('Error'),
      content: Text('\n$message'),
      actions: <Widget>[
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('Ok'),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop("Discard");
          },
        )
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
