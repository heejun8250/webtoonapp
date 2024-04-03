import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webtoonclone/models/webtoon_detail_model.dart';
import 'package:webtoonclone/models/webtoon_episode_model.dart';
import 'package:webtoonclone/services/api_service.dart';
import 'package:webtoonclone/widgets/episode_widget.dart';

class DetailScreen extends StatefulWidget {
  final String title, thumb, id;

  const DetailScreen({
    super.key,
    required this.title,
    required this.thumb,
    required this.id,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<WebtoonDetailModel> webtoon;
  late Future<List<WebtoonEpisodeModel>> episodes;
  late SharedPreferences prefs;
  bool isLiked = false;

  Future initPrefs() async {
    // 휴대폰 저장소와 연결
    prefs = await SharedPreferences.getInstance();
    // 휴대폰 저장소에 저장된 likedToons를 가져와 변수에 저장
    final likedToons = prefs.getStringList('likedToons');
    // likedToons에 저장된 값이 있는지 확인
    if (likedToons != null) {
      // likedToons에 해당 id값이 포함되 있으면 isLiked를 true로 변경
      if (likedToons.contains(widget.id) == true) {
        setState(() {
          isLiked = true;
        });
      }
      // likedToons가 null이면 휴대폰 저장소에 'likedToons'이라는 key로 []를 저장
    } else {
      await prefs.setStringList('likedToons', []);
    }
  }

  @override
  void initState() {
    super.initState();
    webtoon = ApiService.getToonById(widget.id);
    episodes = ApiService.getLatestEpisodesById(widget.id);
    // 앱이 시작할 때 intiPrefs 함수 실행
    initPrefs();
  }

  onHeartTap() async {
    // 휴대폰 저장소에 저장된 likedToons를 가져와 변수에 저장
    final likedToons = prefs.getStringList('likedToons');

    // likedToons가 null이 아닐 때
    if (likedToons != null) {
      // isLiked가 true면 해당 id값을 제거
      if (isLiked) {
        likedToons.remove(widget.id);
        // false면 해당 id값을 추가
      } else {
        likedToons.add(widget.id);
      }
      // 휴대폰 저장소에 'likedToons'이라는 key로 likedToons 리스트를 저장
      await prefs.setStringList('likedToons', likedToons);
      setState(() {
        isLiked = !isLiked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              onHeartTap();
            },
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_outline,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: widget.id,
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 15,
                              offset: Offset(10, 10),
                              color: Colors.black.withOpacity(0.5),
                            )
                          ]),
                      clipBehavior: Clip.hardEdge,
                      child: Image.network(
                        widget.thumb,
                        headers: const {
                          "User-Agent":
                              "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                                  "AppleWebKit/537.36 (KHTML, like Gecko) "
                                  "Chrome/110.0.0.0 Safari/537.36",
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 25,
              ),
              FutureBuilder(
                future: webtoon,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.data!.about,
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Text(
                          '${snapshot.data!.genre} / ${snapshot.data!.age}',
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ],
                    );
                  }
                  return Text('...');
                },
              ),
              const SizedBox(
                height: 25,
              ),
              FutureBuilder(
                future: episodes,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        for (var episode in snapshot.data!)
                          Episode(episode: episode, webtoonId: widget.id)
                      ],
                    );
                  }
                  return Container();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
