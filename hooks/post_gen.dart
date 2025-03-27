import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

void run(HookContext context) async {
  await _moveToCorrectLocation(context);
  await _cleanupGitKeep(context);
  await _ensureEmptyDirectories(context);
  await _cleanupUnusedFiles(context);
  await _removeBlankLines(context);
}

Future<void> _cleanupGitKeep(HookContext context) async {
  final featurePath = await _getFeaturePath(context);
  if (featurePath != null) {
    final dir = Directory(featurePath);
    if (await dir.exists()) {
      await for (var file in dir.list(recursive: true)) {
        if (file is File && path.basename(file.path) == '.gitkeep') {
          await file.delete();
        }
      }
    }
  }
}

Future<void> _moveToCorrectLocation(HookContext context) async {
  final projectRoot = await _findProjectRoot();
  if (projectRoot != null) {
    final featureName = (context.vars['name'] as String).snakeCase;
    final generatedPath = Directory.current.path;
    final targetPath = path.join(projectRoot, 'lib', 'src', 'features', featureName);
    
    // Crear el directorio destino si no existe
    await Directory(targetPath).create(recursive: true);
    
    // Mover todos los archivos generados a la ubicación correcta
    final sourceDir = Directory(path.join(generatedPath, featureName));
    if (await sourceDir.exists()) {
      await for (var entity in sourceDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: sourceDir.path);
          final newPath = path.join(targetPath, relativePath);
          await Directory(path.dirname(newPath)).create(recursive: true);
          await entity.rename(newPath);
        }
      }
      // Limpiar el directorio temporal
      await sourceDir.delete(recursive: true);
    }
  }
}

Future<void> _ensureEmptyDirectories(HookContext context) async {
  final featurePath = await _getFeaturePath(context);
  if (featurePath != null) {
    // Lista de directorios que deben existir
    final directories = [
      'domain/contracts',
      'domain/services',
      'infrastructure/repositories',
      'infrastructure/mappers',
      'presentation/widgets',
      if (context.vars['isBloc'] as bool) 'presentation/bloc',
      if (context.vars['isCubit'] as bool) 'presentation/cubit',
    ];

    for (final dir in directories) {
      final dirPath = path.join(featurePath, dir);
      await Directory(dirPath).create(recursive: true);
    }
  }
}

Future<void> _cleanupUnusedFiles(HookContext context) async {
  final featurePath = await _getFeaturePath(context);
  if (featurePath != null) {
    // Si no se usa repository, eliminar los archivos relacionados
    if (!(context.vars['useRepository'] as bool)) {
      final filesToDelete = [
        'domain/contracts/{{name.snakeCase()}}_repository.dart',
        'infrastructure/repositories/{{name.snakeCase()}}_repository_impl.dart'
      ].map((f) => f
        .replaceAll('{{name.snakeCase()}}', (context.vars['name'] as String).snakeCase));

      for (final file in filesToDelete) {
        final filePath = path.join(featurePath, file);
        final fileToDelete = File(filePath);
        if (await fileToDelete.exists()) {
          await fileToDelete.delete();
        }
      }
    }
  }
}

Future<void> _removeBlankLines(HookContext context) async {
  final featurePath = await _getFeaturePath(context);
  if (featurePath != null) {
    final dir = Directory(featurePath);
    if (await dir.exists()) {
      await for (var entity in dir.list(recursive: true)) {
        if (entity is File && path.extension(entity.path) == '.dart') {
          final content = await entity.readAsString();
          final lines = content.split('\n');
          
          // Remover líneas en blanco consecutivas
          final cleanedLines = <String>[];
          bool previousWasBlank = false;
          
          for (var line in lines) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) {
              if (!previousWasBlank) {
                cleanedLines.add('');
                previousWasBlank = true;
              }
            } else {
              cleanedLines.add(line);
              previousWasBlank = false;
            }
          }
          
          // Remover líneas en blanco al final del archivo
          while (cleanedLines.isNotEmpty && cleanedLines.last.trim().isEmpty) {
            cleanedLines.removeLast();
          }
          
          // Asegurar que haya una línea en blanco al final
          cleanedLines.add('');
          
          await entity.writeAsString(cleanedLines.join('\n'));
        }
      }
    }
  }
}

Future<String?> _getFeaturePath(HookContext context) async {
  final projectRoot = await _findProjectRoot();
  if (projectRoot != null) {
    final featureName = (context.vars['name'] as String).snakeCase;
    return path.join(projectRoot, 'lib', 'src', 'features', featureName);
  }
  return null;
}

Future<String?> _findProjectRoot() async {
  String currentPath = Directory.current.path;
  while (currentPath != path.dirname(currentPath)) {
    if (await File(path.join(currentPath, 'pubspec.yaml')).exists()) {
      return currentPath;
    }
    currentPath = path.dirname(currentPath);
  }
  return null;
}
