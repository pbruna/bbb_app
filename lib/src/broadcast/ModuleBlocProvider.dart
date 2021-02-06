import 'package:bbb_app/src/broadcast/snackbar_bloc.dart';
import 'package:bbb_app/src/broadcast/user_interaction_bloc.dart';
import 'package:bbb_app/src/broadcast/user_voice_status_bloc.dart';

class ModuleBlocProvider {
  SnackbarCubit snackbarCubit;
  UserVoiceStatusBloc userVoiceStatusBloc;
  UserInteractionCubit muteToggleCubit;
}