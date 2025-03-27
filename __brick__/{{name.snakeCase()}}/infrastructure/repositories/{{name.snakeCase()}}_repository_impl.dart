{{#useRepository}}
import 'package:{{packagePath}}/src/features/{{name.snakeCase()}}/domain/contracts/{{name.snakeCase()}}_repository.dart';

class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  // TODO: Implement methods
}
{{/useRepository}}
