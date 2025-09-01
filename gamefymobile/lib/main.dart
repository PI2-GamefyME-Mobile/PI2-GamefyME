import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding/decoding
Color roxoHeader = Color(0xFF4E008A);
Color roxoBotao = Color(0xFF6F00B9);
Color gradienteTop = Color(0xFF2D0052);
Color gradienteBottom = Color(0xFF390066);
Color roxoCard = Color(0xFF6C1BBD);
Color roxoCard2 = Color(0xFF7A2BE2);
Color roxoCard3 = Color(0xFF4E008A);
Color roxoCard4 = Color(0xFF36015F);
Color verdeXp = Color(0xFF00FF99);
Color amareloMoeda = Color(0xFFFFE066);
Color cinzaSub = Color(0xFF7A7A7A);
Color branco = Color(0xFFFFFFFF);


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "GamefyME",
      theme: ThemeData(
        textTheme: GoogleFonts.jersey10TextTheme(
          Theme.of(context).textTheme
        )),
      home: const WelcomePage(), // Primeira tela do app
    );
  }
}

class WelcomePage extends StatelessWidget { 
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoHeader, // fundo roxo
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),


          const SizedBox(height: 40),

          // Título central
          const Text(
            "GamefyME",
            style: TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 30),

          // Ícone do controle (adicione sua imagem em assets)
          Image.asset(
            "assets/images/logo.png", // Certifique-se de ter essa imagem
            width: 190,
          ),

          const SizedBox(height: 50),

          // Botões Login e Registrar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A0DAD), // roxo
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                    Navigator.of(context).push(_createRoute());
                },
                child: const Text("Login",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A0DAD),
                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const RegisterPage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.ease;
                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          return SlideTransition(position: animation.drive(tween), child: child);
                        },
                      ),
                    );
                },
                  // Navega para registrar
                child: const Text("Registrar",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
Route<void> _createRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

// ====== TELA DE LOGIN ======
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoHeader, // roxo de fundo
      body: Center(
        child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
        Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // Campo Email
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withValues(alpha:  0.8),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              TextField(
                decoration: InputDecoration(
                  hintText: "Digite seu email",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Campo Senha
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Senha",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              TextField(
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Digite sua senha",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
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

              // Botão de Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Login",
                    style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),

                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Link "Esqueceu a senha?"
              GestureDetector(
                onTap: () {},
                child: const Text(
                  "Esqueceu a senha?",
                  style: TextStyle(
                    color: Color(0xFF7B1FA2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
              Positioned(
                top: -150, // sobe a imagem
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 180,

                ),
              ),
            ],
        )
      )
    );
  }
}

// ====== TELA DE REGISTRO ======
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  Future<void> _registrar() async {
    if (_senhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("As senhas não coincidem.")),
      );
      return;
    }

    setState(() => _loading = true);

    final url = Uri.parse("http://172.16.42.25/api/cadastro"); // emulador Android
    // se for celular real, troque 10.0.2.2 pelo IP da sua máquina

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nmusuario": _nomeController.text,
        "emailusuario": _emailController.text,
        "senha": _senhaController.text,
        "confsenha": _confirmarSenhaController.text,
        "dtnascimento": "2000-01-01" // Data fixa para teste
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 201) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuário cadastrado com sucesso!")),
        );
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // volta para tela de login
      
    } else {
          final data = jsonDecode(response.body);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["erro"] ?? "Erro ao cadastrar.")),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/images/logo.png', height: 120),

              const SizedBox(height: 30),

              // Nome
              TextField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: "Nome",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 15),

              // Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 15),

              // Senha
              TextField(
                controller: _senhaController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Senha",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Confirmar Senha
              TextField(
                controller: _confirmarSenhaController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: "Confirmar Senha",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Botão registrar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Registrar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 15),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  "Já tem conta? Faça login",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}