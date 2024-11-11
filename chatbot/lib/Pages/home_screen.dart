import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  // Función que intenta abrir el enlace del repositorio en el navegador web.
  void _openGitHubRepo() async {
    final Uri githubUri = Uri.parse('https://github.com/Joelssj/chatbot.git');
    try {
      if (!await launchUrl(
        githubUri,
        mode: LaunchMode.externalApplication,
      )) {
        throw 'No se pudo abrir el enlace $githubUri';
      }
    } catch (e) {
      print('No se pudo abrir el enlace: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo claro
      appBar: AppBar(
        title: const Text(
          'Información del Alumno',
          style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        elevation: 0, // Sin sombra en el AppBar
        iconTheme: const IconThemeData(color: Colors.blueGrey),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            // Imagen de logo en la parte superior en un cuadro más ancho
            Container(
              width: 200, // Ancho completo
              height: 110, // Ajusta la altura según tus necesidades
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10), // Bordes ligeramente redondeados
                image: const DecorationImage(
                  image: AssetImage('assets/images/logoo.png'),
                  fit: BoxFit.contain, // Ajuste para mostrar toda la imagen
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Botón del repositorio justo debajo del logo
            ElevatedButton(
              onPressed: _openGitHubRepo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Repositorio de GitHub',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Información del alumno en una tarjeta ligera
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoItem('Carrera', 'Ingeniería en Software'),
                    _infoItem('Materia', 'Programación Móvil'),
                    _infoItem('Grupo', 'A'),
                    _infoItem('Alumno', 'Joel de Jesus Lopez Ruiz'),
                    _infoItem('Matrícula', '221204'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Botón para ir al Chatbot en la parte inferior
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/chat');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 36, 87, 162),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Ir al Chatbot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar cada línea de información con un estilo minimalista
  Widget _infoItem(String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        Expanded(
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}



