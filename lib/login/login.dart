import "package:flutter/material.dart";

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //Regression Expression for Student Email
  bool isEmailValid(String email) {
    const pattern = r'^[a-zA-Z]{3}\d{8}@psut.edu.jo$';
    RegExp regex = RegExp(pattern.toString());
    return regex.hasMatch(email);
  }

  //Regression Expression for Student Password
  bool isPasswordValid(String password) {
    return password.length == 8;
  }

  double getScreenWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 100,),
              Center(
                child: Image.asset(
                    "assets/images/logo.png",
                    width: MediaQuery.of(context).size.width * .60,
                  ),
                ),
              // Email Text
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 25.0,
                ),
                child: Text(
                  "Input Your Email",
                  style: TextStyle(
                    color: Color.fromRGBO(143, 110, 67, 1),
                    fontFamily: "Lexend-SemiBold",
                    fontSize: 16,
                  ),
                ),
              ),
              // Email Text Form Field
              Center(
                child: SizedBox(
                  //Input Box of Bus Driver ID
                  width: getScreenWidth(context) - 55,
                  child: TextFormField(
                    controller: _emailController,
                    validator: (psEmail) {
                      if (isEmailValid(psEmail!)) {
                        return null;
                      } else {
                        return 'Invalid Employee Email!';
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 16.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.0),
                        borderSide: const BorderSide(
                          width: 10.0,
                          color: Color.fromRGBO(143, 110, 67, 1),
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.0),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      errorStyle: TextStyle(
                        color: Colors.red[900],
                        fontSize: 16.0,
                        fontFamily: 'Lexend',
                      ),
                      labelStyle: const TextStyle(
                        fontSize: 16.0,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              // SizedBox(height: 8.0),
              // Password Text
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 25.0,
                ),
                child: Text(
                  "Input Your Password",
                  style: TextStyle(
                    color: Color.fromRGBO(143, 110, 67, 1),
                    fontFamily: "Lexend-SemiBold",
                    fontSize: 16,
                  ),
                ),
              ),
              // Password
              Center(
                child: SizedBox(
                  //Input Box of Bus Driver ID
                  width: getScreenWidth(context) - 55,
                  child: TextFormField(
                    controller: _emailController,
                    validator: (psEmail) {
                      if (isEmailValid(psEmail!)) {
                        return null;
                      } else {
                        return 'Invalid Employee Email!';
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 16.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.0),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      errorStyle: TextStyle(
                        color: Colors.red[900],
                        fontSize: 16.0,
                        fontFamily: 'Wellfleet',
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Center(
                child: SizedBox(
                    width: getScreenWidth(context) - 55,
                    child: ElevatedButton(
                        onPressed: () {},
                        child: Padding(
                            padding: EdgeInsetsGeometry.all(16.0),
                            child: Text(
                                "Login",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "Lexend-Regular",
                                fontSize: 18
                              ),
                            )
                        ), 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(143, 110, 67, 1),
                      ),
                    )
                ),
              ),
              SizedBox(
                height: 25,
              ),
              // Google Login
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Login With Google",
                      style: TextStyle(
                        fontFamily: "Lexend-Medium",
                        fontSize: 15
                      ),
                    ),
                    SizedBox(width: 5,),
                    Image.asset("assets/images/icons/google.png"),
                  ],
                ),
              ),
              SizedBox(
                height: 60,
              ),
              // Register Page
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Doesn’t have account?",
                      style: TextStyle(
                          fontFamily: "Lexend-Light",
                          fontSize: 15
                      ),
                    ),
                    SizedBox(width: 5,),
                    Text(
                      "Register",
                      style: TextStyle(
                        fontFamily: "Lexend-Light",
                        color: Colors.blue,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
