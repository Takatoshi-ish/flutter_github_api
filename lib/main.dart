import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: GithubPage(),
    );
  }
}

class GithubPage extends StatefulWidget {
  const GithubPage({super.key});

  @override
  State<GithubPage> createState() => _GithubPageState();
}

class _GithubPageState extends State<GithubPage> {
  // 初期値は空のListを与えます。
  List<GithubRepo> githubRepo = [];

  // 非同期の関数になったため返り値の型にFutureがつき、さらに async キーワードが追加されました。
  Future<void> fetchRepository(String text) async {
    // await で待つことで Future が外れ Response 型のデータを受け取ることができました。
    final response = await Dio().get(
      'https://api.github.com/search/repositories',
      queryParameters: {
        'sort': 'stars',
        'q': text,
        'per_page': 20,
      },
    );
    final List items = response.data['items'];
    debugPrint('items: $items');
    githubRepo = items.map((e) => GithubRepo.fromMap(e)).toList();
    setState(() {});
  }

  Future<void> shareImage(String url) async {
    // まずは一時保存に使えるフォルダ情報を取得します。
    // Future 型なので await で待ちます
    final dir = await getTemporaryDirectory();

    final response = await Dio().get(
      url,
      options: Options(
        // 画像をダウンロードするときは ResponseType.bytes を指定します。
        responseType: ResponseType.bytes,
      ),
    );
    // フォルダの中に image.png という名前でファイルを作り、そこに画像データを書き込みます。
    final imageFile =
        await File('${dir.path}/image.png').writeAsBytes(response.data);

    // path を指定すると share できます。
    await Share.shareFiles([imageFile.path]);
  }

  // この関数の中の処理は初回に一度だけ実行されます。
  @override
  void initState() {
    fetchRepository('Flutter');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          decoration: const InputDecoration(
              fillColor: Colors.white, filled: true, hintText: '検索'),
          onFieldSubmitted: (text) {
            print(text);
            fetchRepository(text);
          },
        ),
      ),
      body: Center(
        child: ListView.builder(
          itemCount: githubRepo.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(width: 1.0, color: Colors.grey))),
              child: ListTile(
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        githubRepo[index].avatarUrl,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${githubRepo[index].name}',
                          style: TextStyle(color: Colors.black, fontSize: 14.0),
                        ),
                        Text(
                          '${githubRepo[index].starCount}',
                          style: TextStyle(color: Colors.black, fontSize: 18.0),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  print("onTap called.");
                }, // タップ
                onLongPress: () {
                  print("onLongTap called.");
                }, // 長押し
              ),
            );
          },
        ),
      ),
    );
  }
}

class GithubRepo {
  final String name;
  final int starCount;
  final String avatarUrl;

  GithubRepo({
    required this.name,
    required this.starCount,
    required this.avatarUrl,
  });

  factory GithubRepo.fromMap(Map<String, dynamic> map) {
    return GithubRepo(
      name: map['full_name'] ?? '',
      starCount: map['stargazers_count'] ?? 0,
      avatarUrl: map['owner']['avatar_url'] ?? '',
    );
  }
}
