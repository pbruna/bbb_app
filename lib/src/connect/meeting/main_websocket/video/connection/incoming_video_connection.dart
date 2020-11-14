import 'package:bbb_app/src/connect/meeting/main_websocket/video/connection/video_connection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class IncomingVideoConnection extends VideoConnection {

  IncomingVideoConnection(var meetingInfo) : super(meetingInfo);

  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  @override
  Future<void> init() {
    return remoteRenderer.initialize().then((value) => super.init());
  }

  @override
  void close() {
    super.close();

    //workaround. seems like the dispose is not called properly from the ListView in main_view.dart.
    //can not dispose before RTCVideoView isn't displayed anymore. --> wait 10 seconds as this is async...
    Future.delayed(const Duration(seconds: 10), () {
      print("disposing renderer");
      remoteRenderer.dispose();
    });
  }

  @override
  onAddStream(stream) {
    //remoteRenderer.srcObject = stream;
  }

  @override
  onRemoveStream(stream) {
    remoteRenderer.srcObject = null;
  }

}