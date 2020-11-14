import 'dart:async';

import 'package:bbb_app/src/connect/meeting/main_websocket/module.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/video/connection/incoming_screenshare_video_connection.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/video/connection/incoming_webcam_video_connection.dart';
import 'package:bbb_app/src/connect/meeting/main_websocket/video/connection/outgoing_webcam_video_connection.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';

/// Module dealing with video stream stuff.
class VideoModule extends Module {

  /// Video streams subscription topic to subscribe to.
  static const _subscriptionTopicVideo = "video-streams";
  static const _subscriptionTopicScreenshare = "screenshare";

  /// Controller over which we will publish updated video connection lists.
  StreamController<Map<String, IncomingWebcamVideoConnection>> _videoConnectionsStreamController =
      StreamController<Map<String, IncomingWebcamVideoConnection>>.broadcast();

  /// Controller over which we will publish updated screenshare connection lists.
  StreamController<Map<String, IncomingScreenshareVideoConnection>> _screenshareVideoConnectionsStreamController =
  StreamController<Map<String, IncomingScreenshareVideoConnection>>.broadcast();

  /// List of video connections we currently have.
  Map<String, IncomingWebcamVideoConnection> _videoConnectionsByCameraId = {};

  /// Lookup of the camera ID by a stream ID.
  Map<String, String> _cameraIdByStreamIdLookup = {};

  /// video connection for screenshare stream.
  Map<String, IncomingScreenshareVideoConnection> _screenshareVideoConnections = {};

  /// Info for the current meeting.
  final MeetingInfo _meetingInfo;

  /// Webcam the user shares.
  OutgoingWebcamVideoConnection _webcamShare;

  VideoModule(messageSender, this._meetingInfo,) : super(messageSender);

  @override
  void onConnected() {
    subscribe(_subscriptionTopicVideo);
    subscribe(_subscriptionTopicScreenshare);
  }

  @override
  Future<void> onDisconnect() {
    _videoConnectionsStreamController.close();
    _screenshareVideoConnectionsStreamController.close();
    _videoConnectionsByCameraId.forEach((key, videoConnection) {
      videoConnection.close();
    });
    _screenshareVideoConnections.forEach((key, videoConnection) {
      videoConnection.close();
    });
    unshareWebcam();
  }

  @override
  void processMessage(Map<String, dynamic> msg) {
    final String method = msg["msg"];

    if (method == "added") {
      String collectionName = msg["collection"];

      if (collectionName == "video-streams") {
        String cameraID = msg["fields"]["stream"];
        if (cameraID != null) {
          print("Adding new video stream...");

          IncomingWebcamVideoConnection v = IncomingWebcamVideoConnection(_meetingInfo, cameraID);
          _videoConnectionsByCameraId[cameraID] = v;

          v.init().then((value) => {

            // Publish changed video connections list
            _videoConnectionsStreamController.add(_videoConnectionsByCameraId)

          });

          _cameraIdByStreamIdLookup[msg["id"]] = cameraID;

        }

      } else if (collectionName == "screenshare") {
        String id = msg["id"];
        if (id != null) {
          print("Adding new screenshare stream...");

          IncomingScreenshareVideoConnection v = IncomingScreenshareVideoConnection(_meetingInfo);
          _screenshareVideoConnections[id] = v;

          v.init().then((value) => {

            //Publish changed screenshare connections list
            _screenshareVideoConnectionsStreamController.add(_screenshareVideoConnections)

          });

        }
      }

    } else if (method == "removed") {
      String collectionName = msg["collection"];

      if (collectionName == "video-streams") {
        print("Removing video stream...");

        String streamID = msg["id"];
        String cameraID = _cameraIdByStreamIdLookup[streamID];

        IncomingWebcamVideoConnection v = _videoConnectionsByCameraId.remove(cameraID);

        // Publish changed video connections list
        _videoConnectionsStreamController.add(_videoConnectionsByCameraId);

        v.close();

      } else if (collectionName == "screenshare") {
        print("Removing screenshare stream...");

        String id = msg["id"];

        IncomingScreenshareVideoConnection v = _screenshareVideoConnections.remove(id);

        // Publish changed video connections list
        _screenshareVideoConnectionsStreamController.add(_screenshareVideoConnections);

        v.close();
      }
    }
  }

  void shareWebcam() {
    if(_webcamShare == null) {
      _webcamShare = OutgoingWebcamVideoConnection(_meetingInfo, messageSender);
      _webcamShare.init();
    }
  }

  void unshareWebcam() {
    if(_webcamShare != null) {
      _webcamShare.close();
      _webcamShare = null;
    }
  }

  /// Get a stream of video connections lists that are updated when new camera IDs pop up
  /// or are removed.
  Stream<Map<String, IncomingWebcamVideoConnection>> get videoConnectionsStream => _videoConnectionsStreamController.stream;

  /// Get a stream of screenshare connections lists that are updated when new screenshares pop up
  /// or are removed.
  Stream<Map<String, IncomingScreenshareVideoConnection>> get screenshareVideoConnectionsStream => _screenshareVideoConnectionsStreamController.stream;

  /// Get the currently listed video connections.
  Map<String, IncomingWebcamVideoConnection> get videoConnections => _videoConnectionsByCameraId;

  /// Get the currently listed screenshare connections.
  Map<String, IncomingScreenshareVideoConnection> get screenshareVideoConnections => _screenshareVideoConnections;
}
