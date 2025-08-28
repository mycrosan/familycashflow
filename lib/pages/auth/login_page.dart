import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo e título
                Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Fluxo Família',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Faça login na sua conta' : 'Crie sua conta',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Campos do formulário
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Digite seu email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email é obrigatório';
                    }
                    if (!value.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Senha',
                  hintText: 'Digite sua senha',
                  obscureText: _obscurePassword,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Senha é obrigatória';
                    }
                    if (value.length < 6) {
                      return 'Senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Botão de ação
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return CustomButton(
                      text: _isLogin ? 'Entrar' : 'Cadastrar',
                      onPressed: authProvider.isLoading ? null : _handleSubmit,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Mensagem de erro
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.error != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          authProvider.error!,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 24),

                // Alternar entre login e registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? 'Não tem uma conta?' : 'Já tem uma conta?',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _formKey.currentState?.reset();
                          // authProvider.clearError();
                        });
                      },
                      child: Text(
                        _isLogin ? 'Cadastre-se' : 'Faça login',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isLogin) {
      success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await authProvider.register(
        _emailController.text.trim().split('@')[0], // Usar parte do email como nome
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (success) {
      // Login/registro bem-sucedido, navegar para a página principal
      // O Consumer no main.dart já vai redirecionar automaticamente
    }
  }
}
