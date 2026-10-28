import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:oasx/service/profile_service.dart';

part 'websocket_client.dart';

typedef ChannelConnector = WebSocketChannel Function(Uri uri);

class WebSocketService extends GetxService {
  final Map<String, WebSocketClient> _clients = {};
  final ChannelConnector _connector;
  int _lifecycleGeneration = 0;

  /// 同名连接的在途 Future。
  ///
  /// `connect()` 在 `await close(name)` 与写回 `_clients[name]` 之间有窗口：
  /// 两个并发 connect（比如列表刷新与用户点启动撞车）都看到 existing==null，
  /// 各建一个 client，后者覆盖前者——先建的 channel 没关、还会自行重连，
  /// 表现为日志重复/双连接。这里按名称把并发请求合并到同一个 Future。
  final Map<String, Future<WebSocketClient>> _connecting = {};

  WebSocketService({ChannelConnector? connector})
    : _connector = connector ?? WebSocketChannel.connect;

  /// connect to webSocket
  /// name: scriptName
  /// url(optional): webSocket url, if it is null, it will change to 'ws://${ApiClient().address}/ws/$name'
  /// listener(optional): webSocket message listener. it will add to ws listeners, message broadcast to all listeners
  /// force(optional): Although ws already opened, it will force connect to ws.Deal some ws problems(opened, but error)
  /// return: WebSocketClient. can send message
  Future<WebSocketClient> connect({
    required String name,
    String? url,
    MessageListener? listener,
    bool force = false,
  }) async {
    // 非强制连接时，同名并发请求合并：后来者等待前一个完成，再复用结果。
    // force 表示调用方明确要求重连（例如 ws 已坏），必须各自走完整流程。
    if (!force) {
      final inFlight = _connecting[name];
      if (inFlight != null) {
        final client = await inFlight;
        return client._addListener(listener);
      }
    }
    final future = _connectImpl(
      name: name,
      url: url,
      listener: listener,
      force: force,
    );
    if (!force) {
      _connecting[name] = future;
      // 无论成功失败都要清掉，否则失败后该名称永远拿不到新连接
      future.whenComplete(() => _connecting.remove(name)).ignore();
    }
    return future;
  }

  Future<WebSocketClient> _connectImpl({
    required String name,
    String? url,
    MessageListener? listener,
    bool force = false,
  }) async {
    final generation = _lifecycleGeneration;
    if (url == null) {
      final backend = Uri.parse(ApiClient().address);
      final normalized = backend.hasScheme
          ? backend
          : Uri.parse('http://${ApiClient().address}');
      url = normalized
          .replace(
            scheme: normalized.scheme == 'https' ? 'wss' : 'ws',
            path: '/ws/$name',
            query: '',
          )
          .toString();
    }
    if (ProfileService.isPreview) {
      url = 'ws://${ProfileService.previewAddress}/ws/$name';
    }
    final existing = _clients[name];
    if (!force &&
        existing != null &&
        existing.url == url &&
        existing.status.value != WsStatus.closed &&
        existing.status.value != WsStatus.error) {
      return existing._addListener(listener);
    }
    if (existing != null) {
      await close(name, reconnect: false);
    }
    final client = WebSocketClient(
      name: name,
      url: url,
      connector: _connector,
    )._addListener(listener);
    if (generation != _lifecycleGeneration) {
      await client._close(WebSocketStatus.normalClosure, 'service detached');
      return client;
    }
    _clients[name] = client;
    await client._connect();
    return client;
  }

  /// use manager sends message to script socket
  Future<void> send(String name, String message) async {
    final client = _clients[name];
    if (client != null) {
      client.send(message);
    } else {
      printInfo(info: "ws[$name] want to send, but not connected");
    }
  }

  /// use WebSocketClient to close webSocket and remove this client
  Future<void> close(
    String name, {
    int code = WebSocketStatus.normalClosure,
    String reason = "normal close",
    bool reconnect = false,
  }) async {
    final client = _clients.remove(name);
    if (client != null) {
      await client._close(code, reason, reconnect: reconnect);
    }
    printInfo(info: "ws[$name] closed");
  }

  Future<void> closeAll() async {
    ++_lifecycleGeneration;
    final clients = _clients.values.toList();
    _clients.clear();
    await Future.wait(
      clients.map(
        (client) =>
            client._close(WebSocketStatus.normalClosure, "global close"),
      ),
    );
    printInfo(info: "ws all closed");
  }

  @override
  void onClose() {
    unawaited(closeAll());
    super.onClose();
  }

  void removeAllListeners(String name) {
    final client = _clients[name];
    if (client != null) {
      client._listeners.clear();
    }
    printInfo(info: "ws[$name] listeners removed");
  }
}
