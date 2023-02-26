import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'response/chat_bot_response.dart';

class ChatBotApi {
  ChatBotApi(this._dio);
  String? baseUrl = 'https://gymkhana.iitb.ac.in/chatbot/';
  final Dio _dio;

  Future<ChatBotResponse> getAnswers(
    String query,
  ) async {
    const Map<String, dynamic> extra = <String, dynamic>{};
    final Map<String, dynamic> queryParameters = <String, dynamic>{
      'data': query
    };
    final Map<String, dynamic> headers = <String, dynamic>{};
    final Map<String, dynamic> data = <String, dynamic>{};
    final Response<String> result = await _dio.fetch<String>(
        _setStreamType<String>(
            Options(method: 'GET', headers: headers, extra: extra)
                .compose(_dio.options, '/',
                    queryParameters: queryParameters, data: data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final Map<String, dynamic> val =
        json.decode(result.data!) as Map<String, dynamic>;
    final ChatBotResponse value = ChatBotResponse.fromJson(val);
    return value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }
}
