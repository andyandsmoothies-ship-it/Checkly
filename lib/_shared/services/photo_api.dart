abstract class PhotoApi {
  /// Upload a single photo payload to the server.
  /// Returns the signed/public URL of the successfully uploaded asset.
  Future<String> uploadPhoto(String sId, String path, {String? answerId});
}
