import 'dart:io';
import 'package:mason/mason.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

void run(HookContext context) async {
  await _setPackagePath(context);
  _setStateManagement(context);
}

_setStateManagement(HookContext context) {
  final stateManagement = context.vars['stateManagement'];

  context.vars['isBloc'] = stateManagement == 'bloc';
  context.vars['isCubit'] = stateManagement == 'cubit';
  context.vars['isNone'] = stateManagement == 'none';
}

Future<void> _setPackagePath(HookContext context) async {
  // Encontrar la raíz del proyecto (donde está el pubspec.yaml)
  String currentPath = Directory.current.path;
  String? projectRoot;
  
  while (currentPath != path.dirname(currentPath)) {
    if (await File(path.join(currentPath, 'pubspec.yaml')).exists()) {
      projectRoot = currentPath;
      break;
    }
    currentPath = path.dirname(currentPath);
  }

  if (projectRoot != null) {
    final pubSpecFile = File(path.join(projectRoot, 'pubspec.yaml'));
    final content = await pubSpecFile.readAsString();
    final yamlMap = loadYaml(content);
    final packageName = yamlMap['name'];
    
    // Establecer la ruta completa para los imports
    context.vars['packagePath'] = packageName;
  } else {
    context.logger.err('Not found pubspec.yaml file');
  }
}
