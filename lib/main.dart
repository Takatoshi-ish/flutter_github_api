import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
        'per_page': 100,
      },
    );
    final List items = response.data['items'];
    debugPrint('items: $items');
    githubRepo = items.map((e) => GithubRepo.fromMap(e)).toList();
    setState(() {});
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
                title: GestureDetector(
                  child: Row(
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
                            githubRepo[index].name,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 14.0),
                          ),
                          Text(
                            '⭐ ${githubRepo[index].starCount}',
                            style: const TextStyle(
                                color: Colors.black, fontSize: 18.0),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    launchUrlString(githubRepo[index].htmlUrl);
                  }, // タップ
                  onLongPress: () {
                    print("onLongTap called.");
                  }, // 長押し
                ),
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
  final String htmlUrl;

  GithubRepo({
    required this.name,
    required this.starCount,
    required this.avatarUrl,
    required this.htmlUrl,
  });

  factory GithubRepo.fromMap(Map<String, dynamic> map) {
    return GithubRepo(
      name: map['full_name'] ?? '',
      starCount: map['stargazers_count'] ?? 0,
      avatarUrl: map['owner']['avatar_url'] ?? '',
      htmlUrl: map['html_url'] ?? '',
    );
  }
}
