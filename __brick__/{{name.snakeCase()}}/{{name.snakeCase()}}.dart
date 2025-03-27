// Domain
{{#useRepository}}export 'domain/contracts/{{name.snakeCase()}}_repository.dart';{{/useRepository}}
export 'domain/contracts/{{name.snakeCase()}}_service.dart';
export 'domain/services/{{name.snakeCase()}}_service_impl.dart';

// Infrastructure
{{#useRepository}}export 'infrastructure/repositories/{{name.snakeCase()}}_repository_impl.dart';{{/useRepository}}

// Presentation
{{#isBloc}}export 'presentation/bloc/{{name.snakeCase()}}_bloc.dart';{{/isBloc}}
{{#isCubit}}export 'presentation/cubit/{{name.snakeCase()}}_cubit.dart';{{/isCubit}}
