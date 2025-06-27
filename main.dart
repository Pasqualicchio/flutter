import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestione Foto',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final commessaController = TextEditingController();
  final matricolaController = TextEditingController();
  final itemController = TextEditingController();

  Uint8List? _imageBytes;
  final List<File> _pendingUploads = [];
  final List<String> _sentHistory = [];

  // Funzione per scegliere e caricare un'immagine
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final commessa = commessaController.text.trim();
    final matricola = matricolaController.text.trim();
    final item = itemController.text.trim();

    if (!_validateFields(commessa, matricola, item)) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final isConnected = await _checkConnectivity();

      if (isConnected) {
        await _uploadImage(file, commessa, matricola, item);
      } else {
        _pendingUploads.add(file);
        _showMessage('⚠️ Nessuna connessione. Immagine salvata per l\'invio successivo.');
      }
    }
  }

  // Funzione per caricare l'immagine al server
  Future<void> _uploadImage(File imageFile, String commessa, String matricola, String item) async {
    final uri = Uri.parse('http://127.0.0.1:5005/upload');  // Usa la stessa porta

    final request = http.MultipartRequest('POST', uri)
      ..fields['commessa'] = commessa
      ..fields['matricola'] = matricola
      ..fields['item'] = item
      ..files.add(await http.MultipartFile.fromPath(
        'images[]',  // Il campo che usi nel backend Flask per accettare l'immagine
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

    try {
      final response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _sentHistory.add('${DateTime.now()}: $commessa / $matricola / $item');
          _imageBytes = null;
          _pendingUploads.remove(imageFile);  // Rimuovi il file dalla coda una volta caricato
        });
        _showMessage('✅ Immagine inviata con successo');
      } else {
        _showMessage('❌ Errore invio: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('❌ Errore di rete: $e');
    }
  }

  // Funzione per riprovare a caricare i file in coda
  Future<void> _retryPendingUploads() async {
    if (_pendingUploads.isEmpty) {
      _showMessage('📭 Nessun file in attesa');
      return;
    }

    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      _showMessage('❌ Ancora offline. Riprova più tardi.');
      return;
    }

    final commessa = commessaController.text.trim();
    final matricola = matricolaController.text.trim();
    final item = itemController.text.trim();

    if (!_validateFields(commessa, matricola, item)) return;

    for (final file in List<File>.from(_pendingUploads)) {
      await _uploadImage(file, commessa, matricola, item);
      _pendingUploads.remove(file);
    }

    _showMessage('✅ Tutti i file in attesa sono stati inviati.');
  }

  // Controlla la connettività di rete
  Future<bool> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Funzione di validazione dei campi
  bool _validateFields(String commessa, String matricola, String item) {
    if (commessa.isEmpty || matricola.isEmpty || item.isEmpty) {
      _showMessage('⚠️ Compila tutti i campi prima di inviare.');
      return false;
    }
    return true;
  }

  // Funzione per mostrare messaggi
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestione Fotografica')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: commessaController,
                decoration: const InputDecoration(labelText: 'Commessa'),
              ),
              TextField(
                controller: matricolaController,
                decoration: const InputDecoration(labelText: 'Matricola'),
              ),
              TextField(
                controller: itemController,
                decoration: const InputDecoration(labelText: 'Numero Item'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickAndUploadImage(ImageSource.camera),
                    child: const Text('📸 Scatta Foto'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _pickAndUploadImage(ImageSource.gallery),
                    child: const Text('🖼️ Galleria'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_imageBytes != null)
                Image.memory(_imageBytes!, height: 200),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _retryPendingUploads,
                icon: const Icon(Icons.refresh),
                label: const Text('📤 Riprova Upload Salvati'),
              ),
              const Divider(),
              const Text('📜 Cronologia Invii'),
              ..._sentHistory.map((entry) => Text(entry)).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
