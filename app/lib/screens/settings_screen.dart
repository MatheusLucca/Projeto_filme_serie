import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  final _controller = TextEditingController();
  bool _loaded = false;
  bool _usingEnvDefault = false;
  String _versionInfo = '';

  @override
  void initState() {
    super.initState();
    _settings.getSavedTmdbApiKey().then((savedKey) async {
      final effectiveKey = await _settings.getTmdbApiKey();
      _controller.text = savedKey ?? '';
      _usingEnvDefault = savedKey == null && effectiveKey != null;
      setState(() => _loaded = true);
    });
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _versionInfo = 'v${info.version}+${info.buildNumber}');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _settings.setTmdbApiKey(_controller.text);
    setState(() => _usingEnvDefault = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chave salva.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Chave da API do TMDB',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Usada para buscar pôster e sinopse automaticamente ao adicionar um '
                  'título. Crie uma conta gratuita em themoviedb.org, gere uma API Key '
                  '(v3 auth) em Configurações > API e cole abaixo.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (_usingEnvDefault) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Usando a chave padrão definida no arquivo .env do projeto. '
                    'Preencha abaixo para sobrescrevê-la.',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _save, child: const Text('Salvar')),
                const SizedBox(height: 32),
                if (_versionInfo.isNotEmpty)
                  Text(
                    'Versão do app: $_versionInfo',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
    );
  }
}
