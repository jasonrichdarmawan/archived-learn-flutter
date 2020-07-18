import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Temporary UserRepository provides data to AuthBloc
/// see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment#Unpacking_fields_from_objects_passed_as_function_parameter

class UserRepository {
  auth({
    @required String username,
    @required String password,
  }) async {
    await Future.delayed(Duration(seconds: 1));
    return 'token';
  }

  deleteToken() async {
    await Future.delayed(Duration(seconds: 5));
    return;
  }

  persistToken(String token) async {
    await Future.delayed(Duration(seconds: 5));
    return;
  }

  hasToken() async {
    SuccessLoggedIn token = SuccessLoggedIn();
    if (token.token != null) {
      return true;
    } else {
      return false;
    }
  }
}

/// AuthBloc answers question (Is the user still logged in or logged out?)

abstract class AuthEvent {}

class AuthStart extends AuthEvent {}

class SuccessLoggedIn extends AuthEvent {
  final String token;

  SuccessLoggedIn({this.token});
}

class SuccessLoggedOut extends AuthEvent {}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserRepository userRepository;

  AuthBloc({@required this.userRepository})
    : assert(userRepository != null),
      super(AuthInitial());

  @override
  Stream<AuthState> mapEventToState(AuthEvent event) async* {
    final hasToken = await userRepository.hasToken();

    if (event is AuthStart) {
      if (hasToken) {
        yield AuthSuccess();
      } else {
        yield AuthLoggedOut();
      }
    }
    if (event is SuccessLoggedIn) {
      yield AuthInProgress();
      await userRepository.persistToken(event.token);
      yield AuthSuccess();
    }
    if (event is SuccessLoggedOut) {
      yield AuthInProgress();
      await userRepository.deleteToken();
      yield AuthLoggedOut();
    }
  }

}

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthInProgress extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthLoggedOut extends AuthState {}

/// SplashScaffold

class SplashScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('SplashScaffold')
      ),
    );
  }
}

/// HomeScaffold provides AuthEvent (SuccessLoggedOut) to AuthBloc

class HomeScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HomeScaffold'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              BlocProvider.of<AuthBloc>(context).add(SuccessLoggedOut());
            },
          ),
        ],
      ),
    );
  }
}

/// LogInBloc answers the question (Is the user pressed the Log In button?)

abstract class LogInEvent {}

class LogInButtonPressed extends LogInEvent {
  final String username;
  final String password;

  LogInButtonPressed({
    @required this.username,
    @required this.password
  });
}

abstract class LogInState {}

class LogInInitial extends LogInState {}

class LogInInProgress extends LogInState {}

class LogInFailure extends LogInState {
  final String error;

  LogInFailure({@required this.error});
}

class LogInBloc extends Bloc<LogInEvent, LogInState> {
  final UserRepository userRepository;
  final AuthBloc authBloc;

  LogInBloc({
    @required this.userRepository, 
    @required this.authBloc
  }) : assert(userRepository != null),
       assert(authBloc != null),
       super(LogInInitial());
  
  @override
  Stream<LogInState> mapEventToState(LogInEvent event) async* {
    if (event is LogInButtonPressed) {
      yield LogInInProgress();

      try {
        final token = await userRepository.auth(
          username: event.username,
          password: event.password,
        );
        authBloc.add(SuccessLoggedIn(token: token));
      } catch (error) {
        yield LogInFailure(error: error.toString());
      }
    }
  } 
}

/// LogInScaffold

class LogInScaffold extends StatelessWidget {
  final UserRepository userRepository;

  LogInScaffold({@required this.userRepository}) : assert(userRepository != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log In'),
      ),
      body: BlocProvider(
        create: (context) {
          return LogInBloc(
            authBloc: BlocProvider.of<AuthBloc>(context), 
            userRepository: userRepository,
          );
        },
        child: LogInWidget(),
      ),
    );
  }
}

class LogInWidget extends StatefulWidget {
  @override
  _LogInWidgetState createState() => _LogInWidgetState();
}

class _LogInWidgetState extends State<LogInWidget> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    _onLogInButtonPressed() {
      BlocProvider.of<LogInBloc>(context).add(
        LogInButtonPressed(
          username: _usernameController.text,
          password: _passwordController.text,
        ),
      );
    }

    return BlocListener<LogInBloc, LogInState>(
      listener: (context, state) {
        if (state is LogInFailure) {
          Scaffold.of(context).showSnackBar(
            SnackBar(
              content: Text('${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<LogInBloc, LogInState>(
        builder: (context, state) {
          return Scaffold(
            body: Container(
              child: state is LogInInProgress ? Center(child: CircularProgressIndicator()) 
                : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Username'),
                          controller: _usernameController,
                        ),
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Password'),
                          controller: _passwordController,
                          obscureText: true,
                        ),
                        SizedBox(height: 16),
                        RaisedButton(
                          onPressed: state is! LogInInProgress ? _onLogInButtonPressed : null,
                          child: Text('Log In'),
                        ),
                        Expanded(
                          child: Container(),
                        ),
                        RaisedButton(
                          onPressed: () {},
                          child: Text('Forgot Password'),
                        ),
                      ],
                    ),
                ),
            ),
          );
        }
      ),
    );
  }
}

class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object event) {
    print(event);
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    print(transition);
    super.onTransition(bloc, transition);
  }

  @override
  void onError(Bloc bloc, Object error, StackTrace stackTrace) {
    print(error);
    super.onError(bloc, error, stackTrace);
  }
}

void main() {
  Bloc.observer = SimpleBlocObserver();

  final userRepository = UserRepository();

  runApp(
    BlocProvider<AuthBloc>(
      create: (context) {
        return AuthBloc(userRepository: userRepository)..add(AuthStart());
      },
      child: MyApp(userRepository: userRepository),
    ),
  );
}

class MyApp extends StatelessWidget {
  final UserRepository userRepository;

  const MyApp({@required this.userRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial) {
            return SplashScaffold();
          }
          if (state is AuthSuccess) {
            return HomeScaffold();
          }
          if (state is AuthLoggedOut) {
            return LogInScaffold(userRepository: userRepository);
          }
          if (state is AuthInProgress) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            throw UnimplementedError;
          }
        }
      ),
    );
  }
}