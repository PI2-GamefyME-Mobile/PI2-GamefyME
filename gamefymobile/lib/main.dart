import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'admin_desafios_screen.dart';
import 'admin_conquistas_screen.dart';
import 'services/auth_service.dart';
import 'services/google_auth_service.dart';
import 'services/notification_service.dart';
import 'services/timer_service.dart';
import 'config/app_colors.dart';
import 'config/theme_provider.dart';
import 'forgot_password_screen.dart';
import 'utils/common_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar serviços
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  await TimerService().resumeTimerIfNeeded();
  
  final authService = AuthService();
  final token = await authService.getToken();
  bool valid = false;
  if (token != null) {
    valid = await authService.validateSession();
  }
  runApp(MyApp(isLoggedIn: valid));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "GamefyME",
            theme: ThemeData(
              scaffoldBackgroundColor: themeProvider.fundoApp,
              primaryColor: AppColors.roxoHeader,
              textTheme: GoogleFonts.jersey10TextTheme(Theme.of(context).textTheme).apply(
                bodyColor: themeProvider.textoTexto,
                displayColor: themeProvider.textoTexto,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: themeProvider.fundoCard,
                labelStyle: TextStyle(color: themeProvider.textoCinza),
                hintStyle: TextStyle(color: themeProvider.textoCinza),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            routes: {
              '/admin-desafios': (context) => const AdminDesafiosScreen(),
              '/admin-conquistas': (context) => const AdminConquistasScreen(),
            },
            home: isLoggedIn ? const HomeScreen() : const WelcomePage(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt', 'BR')],
          );
        },
      ),
    );
  }
}

// ====== PÁGINA DE BOAS-VINDAS ======
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4E008A), // Cor antiga
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "GamefyME",
              style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 30),
            Image.asset("assets/images/logo.png", width: 190, errorBuilder: (c, e, s) => const SizedBox()),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A0DAD), // Cor antiga
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).push(_createSlideRoute(const LoginPage())),
                    child: const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 20),
                Flexible(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A0DAD), // Cor antiga
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).push(_createSlideRoute(const RegisterPage())),
                    child: const Text("Registrar", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Helper para criar a animação de transição de tela
Route _createSlideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _googleAuthService = GoogleAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false; // Estado para o Checkbox

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Carrega o e-mail salvo, se existir
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  // Salva ou remove o e-mail conforme a seleção
  Future<void> _handleRememberMe(bool value) async {
    setState(() {
      _rememberMe = value;
    });
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text);
    } else {
      await prefs.remove('saved_email');
    }
  }


  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final senha = _passwordController.text;

    if (email.isEmpty || !CommonUtils.validEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Informe um email válido.")));
      return;
    }
    if (senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha a senha.")));
      return;
    }

    setState(() => _isLoading = true);

    // Salva ou remove o email antes de fazer o login
    await _handleRememberMe(_rememberMe);

    final result = await _authService.login(email, senha);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Erro ao autenticar')));
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    final result = await _googleAuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Login com Google realizado!'))
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen())
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erro no login com Google'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4E008A), // Cor antiga
      appBar: AppBar(
        backgroundColor: const Color(0xFF4E008A), // Cor antiga
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', height: 150, errorBuilder: (c, e, s) => const SizedBox()),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, // Card branco
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CommonUtils.buildTextField(
                      context: context,
                      controller: _emailController,
                      label: "Email",
                      hint: "Digite seu email",
                      keyboardType: TextInputType.emailAddress
                    ),
                    const SizedBox(height: 15),
                    CommonUtils.buildTextField(
                      context: context,
                      controller: _passwordController,
                      label: "Senha",
                      hint: "Digite sua senha",
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Checkbox "Lembrar-me"
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _rememberMe = value;
                              });
                            }
                          },
                          checkColor: Colors.white,
                          activeColor: const Color(0xFF7B1FA2),
                        ),
                        Expanded(
                          child: const Text("Lembrar-me", style: TextStyle(color: Colors.black87)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, // Botão preto
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Login", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () {
                        // Ação para "Esqueceu a senha?"
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Esqueceu a senha?',
                        style: TextStyle(
                          color: AppColors.roxoProfundo,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Divider com "OU"
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.grey)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('OU', style: TextStyle(color: Colors.grey[600])),
                        ),
                        const Expanded(child: Divider(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Botão de login com Google
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          height: 24,
                          errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.login, color: Colors.black87),
                        ),
                        label: const Text(
                          'Continuar com Google',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
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


// ====== TELA DE REGISTRO ======
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _authService = AuthService();
  final _googleAuthService = GoogleAuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }


  Future<void> _handleRegister() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confSenha = _confirmarSenhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || confSenha.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, preencha todos os campos.")));
        return;
    }
    if (!CommonUtils.validEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Informe um email válido.")));
      return;
    }
    // RN 06: Validação completa de senha
    final senhaValidacao = CommonUtils.validatePassword(senha);
    if (senhaValidacao != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(senhaValidacao)));
      return;
    }
    if (senha != confSenha) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("As senhas não coincidem.")));
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.register(
      nome: nome,
      email: email,
      senha: senha,
      confSenha: confSenha,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Registrado com sucesso')));
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Erro ao registrar')));
    }
  }

  Future<void> _handleGoogleRegister() async {
    setState(() => _isLoading = true);

    final result = await _googleAuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Registrado com Google!'))
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erro no registro com Google'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4E008A), // Cor antiga
      appBar: AppBar(
        backgroundColor: const Color(0xFF4E008A), // Cor antiga
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(label: "Nome de usuário", hint: "Nome de usuário", controller: _nomeController),
              const SizedBox(height: 15),
              _buildTextField(label: "Email", hint: "exemplo@email.com", controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildTextField(
                label: "Senha",
                hint: "Digite sua senha",
                controller: _senhaController,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: "Confirmar Senha",
                hint: "Repita sua senha",
                controller: _confirmarSenhaController,
                obscure: _obscureConfirmPassword,
                suffix: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Botão preto
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Registrar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              // Divider com "OU"
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.grey)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OU', style: TextStyle(color: Colors.grey[600])),
                  ),
                  const Expanded(child: Divider(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 20),
              // Botão de registro com Google
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _handleGoogleRegister,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.login, color: Colors.black87),
                  ),
                  label: const Text(
                    'Registrar com Google',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper para os campos de texto com o tema claro
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black), // Texto digitado em preto
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            fillColor: Colors.grey[200], // Fundo cinza claro
            filled: true,
            suffixIcon: suffix,
             border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}