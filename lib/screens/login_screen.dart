import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  StateMachineController? _controller;

  SMIBool? isChecking;
  SMIBool? isHandsUp;
  SMITrigger? trigSuccess;
  SMITrigger? trigFail;
  SMINumber? numLook;

  bool _obscurePassword = true;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  Timer? _emailTimer;
  final Duration _emailTimerDuration = const Duration(milliseconds: 1500);

  // FocusNodes para detectar cambios de foco
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Credenciales válidas
  final String _validEmail = "usuario@gmail.com";
  final String _validPassword = "1234";

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    
    // Agregar listeners para los focus nodes
    _emailFocusNode.addListener(_onEmailFocusChanged);
    _passwordFocusNode.addListener(_onPasswordFocusChanged);
  }

  @override
  void dispose() {
    _emailTimer?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    
    // Limpiar los focus nodes
    _emailFocusNode.removeListener(_onEmailFocusChanged);
    _passwordFocusNode.removeListener(_onPasswordFocusChanged);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    
    super.dispose();
  }

  void _onEmailFocusChanged() {
    if (_emailFocusNode.hasFocus) {
      // Cuando el email gana foco, dejar de taparse los ojos
      if (isHandsUp != null) {
        isHandsUp!.change(false);
      }
    }
  }

  void _onPasswordFocusChanged() {
    if (_passwordFocusNode.hasFocus) {
      // Cuando el password gana foco, taparse los ojos
      if (isHandsUp != null) {
        isHandsUp!.change(true);
      }
    } else {
      // Cuando el password pierde el foco, dejar de taparse los ojos
      if (isHandsUp != null) {
        isHandsUp!.change(false);
      }
    }
  }

  void _onEmailChanged() {
    // Cancelar el timer anterior si existe
    _emailTimer?.cancel();
    
    if (_emailController.text.isNotEmpty) {
      // Si hay texto, hacer que el personaje mire hacia el texto
      if (numLook != null) {
        numLook!.change(_emailController.text.length.toDouble());
      }
      
      if (isHandsUp != null) {
        isHandsUp!.change(false);
      }
      
      if (isChecking != null) {
        isChecking!.change(true);
      }
      
      // Iniciar un nuevo timer para resetear la mirada
      _emailTimer = Timer(_emailTimerDuration, _resetLook);
    } else {
      // Si no hay texto, resetear inmediatamente
      _resetLook();
    }
  }

  void _resetLook() {
    if (numLook != null) {
      numLook!.change(0.0); // Regresar la mirada al frente (valor 0)
    }
    
    if (isChecking != null) {
      isChecking!.change(false);
    }
  }

  void _unfocusAll() {
    // Quitar el foco de todos los campos
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
  }

  void _login() {
    // Quitar el foco primero
    _unfocusAll();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validar credenciales
    if (email == _validEmail && password == _validPassword) {
      // Login exitoso
      if (trigSuccess != null) {
        trigSuccess!.fire();
      }
      
      // Mostrar mensaje de éxito
      
      
      // Opcional: Limpiar campos después de login exitoso
      Future.delayed(const Duration(seconds: 2), () {
        _emailController.clear();
        _passwordController.clear();
        _resetLook();
      });
      
    } else {
      // Login fallido
      if (trigFail != null) {
        trigFail!.fire();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: _unfocusAll,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'animated_login_character.riv',
                    stateMachines: ["Login Machine"],
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        "Login Machine",
                      );
                      if (_controller == null) return;

                      artboard.addController(_controller!);
                      isChecking = _controller!.findSMI("isChecking");
                      isHandsUp = _controller!.findSMI("isHandsUp");
                      trigSuccess = _controller!.findSMI("trigSuccess");
                      trigFail = _controller!.findSMI("trigFail");
                      numLook = _controller!.findSMI("numLook");
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email",
                    prefixIcon: const Icon(Icons.mail),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  focusNode: _passwordFocusNode,
                  onChanged: (value) {
                    if (isChecking != null) {
                      isChecking!.change(false);
                    }
                  },
                  controller: _passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: size.width,
                  child: const Text(
                    "Forgot Password?",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                //boton de login
                const SizedBox(height: 10),
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _login, // Cambiado a la función _login
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: size.width,
                  child: Row(
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Sign up",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}