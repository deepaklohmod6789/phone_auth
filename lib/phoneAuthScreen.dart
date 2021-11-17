import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:phone_auth/homeScreen.dart';
import 'package:phone_auth/toast.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final FirebaseAuth firebaseAuth=FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String? phoneNumber;
  TextEditingController otpEditingController = TextEditingController();
  String? _verificationId;
  int? forceResendingToken;
  bool showOtpScreen=false;
  late StreamController<ErrorAnimationType> errorController;
  bool loading=false;

  @override
  void initState()
  {
    errorController = StreamController<ErrorAnimationType>();
    super.initState();
  }

  @override
  void dispose()
  {
    errorController.close();
    super.dispose();
  }

  void verifyPhoneNumber()async{
    if(_formKey.currentState!.validate())
    {
      setState(() {
        loading=true;
      });
      PhoneVerificationCompleted verificationCompleted = (PhoneAuthCredential phoneAuthCredential) async {
        User? user;
        bool error=false;
        try{
          user=(await firebaseAuth.signInWithCredential(phoneAuthCredential)).user!;
        } catch (e){
        print("Failed to sign in: " + e.toString());
        error=true;
        }
        if(!error&&user!=null){
          String id=user.uid;
          //here you can store user data in backend
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomeScreen(userId: id)));
        }
      };

      PhoneVerificationFailed verificationFailed = (FirebaseAuthException authException) {
        showToast(authException.message!);
      };
      PhoneCodeSent codeSent = (String? verificationId, [int? forceResendingToken]) async {
        showToast('Please check your phone for the verification code.');
        this.forceResendingToken=forceResendingToken;
        _verificationId = verificationId;
      };
      PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout = (String verificationId) {
        _verificationId = verificationId;
      };
      try {
        await firebaseAuth.verifyPhoneNumber(
            phoneNumber: phoneNumber!,
            timeout: const Duration(seconds: 5),
            forceResendingToken: forceResendingToken!=null?forceResendingToken:null,
            verificationCompleted: verificationCompleted,
            verificationFailed: verificationFailed,
            codeSent: codeSent,
            codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
        showOtpScreen=true;
      } catch (e) {
        showToast("Failed to Verify Phone Number: $e");
        showOtpScreen=false;
      }
      setState(() {
        loading=false;
      });
    }
  }
  void signInWithPhoneNumber() async {
    bool error=false;
    User? user;
    AuthCredential credential;
    setState(() {
      loading=true;
    });
    try {
      credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpEditingController.text,
      );
      user = (await firebaseAuth.signInWithCredential(credential)).user!;
    } catch (e) {
      showToast("Failed to sign in: " + e.toString());
      error=true;
    }
    if(!error&&user!=null&&user.uid!=null){
      String id=user.uid;
      //here you can store user data in backend
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomeScreen(userId: id)));
    }
    setState(() {
      loading=false;
    });
  }

  Padding signInScreen()
  {
    return Padding(
      padding: EdgeInsets.fromLTRB(25, 35, 25, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Greetings,',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 15.0,
              ),
            ),
            SizedBox(height: 15,),
            Text(
              'Enter your mobile number to\nbecome our member',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 22.0,
                letterSpacing: 1.05,
              ),
            ),
            SizedBox(height: 30,),
            Container(
              padding: EdgeInsets.all(6.0),
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white,
              ),
              child: InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  phoneNumber=number.phoneNumber;
                },
                onInputValidated: (bool value) {
                  print(value);
                },
                selectorConfig: SelectorConfig(
                  selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                ),
                spaceBetweenSelectorAndTextField: 0,
                ignoreBlank: false,
                autoValidateMode: AutovalidateMode.disabled,
                selectorTextStyle: TextStyle(color: Colors.black),
                initialValue: PhoneNumber(isoCode: 'IN'),
                formatInput: false,
                keyboardType:
                TextInputType.numberWithOptions(signed: true, decimal: true),
                inputBorder: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 55,),
            GestureDetector(
              onTap: ()=>verifyPhoneNumber(),
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15),
                margin: EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: Colors.orange,
                ),
                child: Text(
                  'Get OTP',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Padding otpScreen(){
    return Padding(
      padding: EdgeInsets.fromLTRB(30, 40, 30, 0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Verification',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 15.0,
              ),
            ),
            SizedBox(height: 15,),
            Text(
              "You'll receive an OTP on",
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 22.0,
                letterSpacing: 1.05,
              ),
            ),
            Text.rich(
              TextSpan(
                  text: 'number : ',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15.0,),
                  children: [
                    TextSpan(
                      text: phoneNumber,
                      style: TextStyle(color: Colors.black),
                    ),
                  ]
              ),
            ),
            SizedBox(height: 30,),
            AbsorbPointer(
              child: PinCodeTextField(
                appContext: context,
                length: 6,
                obscureText: false,
                hintCharacter: '0',
                hintStyle: TextStyle(color: const Color(0x36000000),),
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  borderWidth: 0,
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  activeColor: Colors.white,
                ),
                animationDuration: Duration(milliseconds: 300),
                enableActiveFill: true,
                errorAnimationController: errorController,
                controller: otpEditingController,
                onCompleted: (v) {
                  print("Completed");
                },
                onChanged: (value) {
                  print(value);
                },
                beforeTextPaste: (text) {
                  print("Allowing to paste $text");
                  return true;
                },
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: ()=>verifyPhoneNumber(),
                child: Container(
                  child: Text(
                    'Code not received?',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 0.688,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10,),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3,childAspectRatio: 16/12),
              physics: NeverScrollableScrollPhysics(),
              itemCount: 9,
              itemBuilder: (context,index){
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: (){
                    otpEditingController.text += (index+1).toString();
                    otpEditingController.selection=TextSelection.fromPosition(TextPosition(offset: otpEditingController.text.length));
                  },
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      (index+1).toString(),
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            GridView(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3,childAspectRatio: 16/12),
              physics: NeverScrollableScrollPhysics(),
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: (){
                    if(otpEditingController.text.length>=1)
                      otpEditingController.text = otpEditingController.text.substring(0,otpEditingController.text.length-1);
                    otpEditingController.selection=TextSelection.fromPosition(TextPosition(offset: otpEditingController.text.length));
                  },
                  child: Container(
                      alignment: Alignment.center,
                      child: Icon(Icons.backspace_outlined,color: Colors.black,)
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: (){
                    otpEditingController.text += 0.toString();
                    otpEditingController.selection=TextSelection.fromPosition(TextPosition(offset: otpEditingController.text.length));
                  },
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      '0',
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: (){
                    if(otpEditingController.text.length==6){
                      signInWithPhoneNumber();
                    }
                    else if(otpEditingController.text.length<6){
                      showToast("Enter complete otp");
                    }
                  },
                  child: Container(
                      alignment: Alignment.center,
                      child: Text("OK",style: TextStyle(fontSize: 18),),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          showOtpScreen?otpScreen():signInScreen(),
          loading?Center(child: CircularProgressIndicator(),):Container(),
        ],
      ),
    );
  }
}
