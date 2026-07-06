import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show AppBar, Axis, BuildContext, BoxFit, CircleAvatar, Colors, Column, CrossAxisAlignment, Divider, EdgeInsets, Expanded, FontWeight, Icon, Icons, InkWell, ListView, MaterialApp, Padding, Row, Scaffold, SizedBox, Size, State, StatefulWidget, StatelessWidget, Text, TextStyle, ThemeData, Widget, runApp, IconButton, ElevatedButton, ClipRRect, Image, BorderRadius, NeverScrollableScrollPhysics;

class FlutterTts {
  Function? _completionHandler;
  bool _awaitSpeakCompletion = false;

  Future<void> setLanguage(String language) async {}
  Future<void> setSpeechRate(double rate) async {}
  Future<void> setPitch(double pitch) async {}
  Future<void> setVolume(double volume) async {}
  Future<void> awaitSpeakCompletion(bool awaitCompletion) async {
    _awaitSpeakCompletion = awaitCompletion;
  }

  void setCompletionHandler(Function() handler) {
    _completionHandler = handler;
  }

  Future<void> speak(String text) async {
    final utterance = html.SpeechSynthesisUtterance(text)..lang = 'ja-JP';
    final completer = _awaitSpeakCompletion ? Completer<void>() : null;

    utterance.onEnd.listen((html.Event event) {
      if (_completionHandler != null) {
        final result = _completionHandler!();
        if (result is Future) {
          result.catchError((_) {});
        }
      }
      completer?.complete();
    });

    html.window.speechSynthesis?.speak(utterance);
    if (completer != null) {
      await completer.future;
    }
  }

  Future<void> stop() async {
    html.window.speechSynthesis?.cancel();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TTS Twitter Timeline',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'sans-serif',
      ),
      home: const TimelinePage(),
    );
  }
}

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasStartedAtLeastOnce = false;
  int _currentSpeakingIndex = -1;
  bool _isTimelineLoopActive = false;
  int _detailSpeakStep = 0;

  // 📝 あなたのパソコン内のファイル名（大文字・小文字、assets/の有無）に完全対応させたデータ
  final List<Map<String, dynamic>> _tweets = [
       {
             'name': '風紀委員',
             'username': '@hibari_kyoya',
             'content': '満員電車でカバンがぶつかった瞬間、心の中の雲雀恭弥が「咬み殺すよ」ってトンファー構えた。',
             'imageUrls': [], 
             'comments': [
               {
                 'name': '匿名さん',
                 'username': '@user2',
                 'content': '殺意高すぎてワオ',
                 'imageUrls': []
               }
             ]
           },
           {
             'name': 'リペ',
             'username': '@amazon_haizjin',
             'content': '通販で「合計2,900円、あと100円で送料無料！」と言われたワイ、必死に探して「120円の入浴剤」をカゴに追加。\n\n欲しくもない入浴剤のために合計金額が増えていることに気づいてはいけない。それがプロの買い物。',
             'imageUrls': [],
             'comments': [
               {
                 'name': 'あこあこ',
                 'username': '@jungle_buyer',
                 'content': '完全に私で草。100円の送料ケチって、どうでもいい500円のペンとか買っちゃいます。',
                 'imageUrls': []
               }
             ]
           },
               {
             'name': '田中丸',
             'username': '@sauna_shiaku',
             'content': '週5でサウナ通ってるワイ、ついに「ととのう」を超えて、サウナ室に入った瞬間から実家の安心感を得るレベルに到達。もはやここが本籍地。',
             'imageUrls': [], // 💡 画像1枚
             'comments': [
               {
                 'name': '山郷',
                 'username': '@mizu_furo',
                 'content': 'わかります。サウナハット被った瞬間にもう実家帰省完了ですよね。',
                 'imageUrls': []
               }
             ]
           },
           {
             'name': '上腕十頭筋',
             'username': '@muscle_biz',
             'content': '上司「最近元気ないね、悩み事？」\nワイ「いえ、昨日デッドリフトで追い込みすぎて、ただ脚の感覚が無いだけです（ニッコリ）」\n\nメンタルは鋼だがフィジカルが生まれたての小鹿。',
             'imageUrls': [], // 💡 画像0枚（文字だけ）
             'comments': [
               {
                 'name': 'おらす',
                 'username': '@protein_brother',
                 'content': 'オフィスビル内の階段が一番の敵になるやつですねwww',
                 'imageUrls': []
               }
             ]
           },
           {
             'name': 'ソロキャンプの極み',
             'username': '@solo_camper',
             'content': '今週末のソロキャンプのスタメン発表します。肉を焼いて、焚き火を見て、寝る。これ以上の贅沢ってこの世にある？',
             'imageUrls': [], // 💡 画像2枚
             'comments': []
           },
           {
             'name': 'ラーメンパトロール豚',
             'username': '@ramen_heavy',
             'content': '【悲報】「今日こそは絶対にアッサリした中華そばを食べる」と誓って家を出たのに、気づいたらニンニクヤサイマシマシの呪文を唱えていた。脳が勝手に二郎を求めてる。',
             'imageUrls': [], // 💡 画像1枚
             'comments': [
               {
                 'name': 'ジロリアンA',
                 'username': '@jiro_freak',
                 'content': 'それは不可抗力です。黄色い看板を見たら最後、足が勝手に動きますから。',
                 'imageUrls': []
               }
             ]
           },
           {
             'name': 'ちらちらり',
             'username': '@kicks_collector',
             'content': '朝から限定スニーカーの抽選並んだけど安定の落選。物欲の神様、俺が一体何をしたって言うんだ…（通算20回目の落選メールを見つめながら）',
             'imageUrls': [], // 💡 画像0枚
             'comments': [
               {
                 'name': 'ぞらさん',
                 'username': '@line_master',
                 'content': 'お疲れ様です。私も同じく「ご用意できませんでした」を喰らいました。転売ヤー滅ぶべし。',
                 'imageUrls': []
               }
             ]
           },
           {
             'name': 'ハルキ',
             'username': '@mens_cosme',
             'content': 'ドラッグストアでメンズ洗顔料を買おうとしたら、「男の脂を根こそぎ破壊！！超絶クール炭炭爽快！！」みたいな最強の兵器みたいな名前のやつしかなくて、普通の優しい保湿系が欲しいワイ困惑。',
             'imageUrls': [], // 💡 画像0枚
             'comments': [
               {
                 'name': 'Yuuu',
                 'username': '@skin_care_boy',
                 'content': 'わかりすぎるwww スースーするやつは顔面がヒリヒリして痛いんですよね笑',
                 'imageUrls': []
               }
             ]
           },
           {
             'name': 'otibe',
             'username': '@fps_gamer',
             'content': '学生時代「社会人になっても毎日ゲームするぞ！」\n現在のワイ「金はある。最新ハードもある。夜11時にログインして、画面を見つめたまま睡魔に負けて即シャットダウン。」\n\nこれが大人の現実か。',
             'imageUrls': [], // 💡 画像0枚
             'comments': [
               {
                 'name': 'wato',
                 'username': '@old_gamer',
                 'content': 'ゲームを「起動するエネルギー」が残ってないんですよね…悲しい。',
                 'imageUrls': []
               }
             ]
           },
           {
             'name': '散歩と珈琲',
             'username': '@coffee_walk',
             'content': '新しいコーヒーミルを買ったので、朝から豆をガリガリ引いてる。この静かな時間のために生きてるまである。',
             'imageUrls': [],
             'comments': []
           },
           {
             'name': '漆黒社畜',
             'username': '@kaden_review',
             'content': 'ついに念願のドラム式洗濯乾燥機を導入したんだけど、これ人類の発明の中でトップクラスにノーベル賞ものだと思う。干す作業が消えただけでQOL（生活の質）が爆上がりした。',
             'imageUrls': [], 
             'comments': [
               {
                 'name': '焼き鳥',
                 'username': '@time_saver',
                 'content': 'ドラム式と食洗機は一人暮らしの三種の神器ですからね！投資する価値ありです！',
                 'imageUrls': []
               }
             ]
           },
           {
             'name':'ゆあち',
             'username':'@yua_chi',
             'content':'遊ぶ時の遅刻は大体いらないこだわりのせい',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'草超えすぎて地球',
             'username':'@earth_overflow',
             'content':'学校の英語教師変な人しかいない気がする',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'匿名',
             'username':'@anonymous_user',
             'content':'最近の天気予報、当たらなすぎて笑える',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'未来の自分',
             'username':'@future_me',
             'content':'今日の自分に言いたいことは「もっと寝ろ」',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'ゆあち',
             'username':'@yua_chi',
             'content':'30代の自分が想像できないけど、きっと死ぬこともできてない',
             'imageUrls':[],
             'comments':[
               {
                 'name':'匿名',
                 'username':'@anonymous_user',
                 'content':'わかる',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'匿名',
             'username':'@anonymous_user',
             'content':'最近のニュース、どれもこれも信じられない',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'やきそばティ',
             'username':'@yakisoba_t',
             'content':'子ども好きっていう人はガキが嫌い',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'あ',
             'username':'@anonymous_user',
             'content':'バイトしたほうがいいんだろうけど怒られるとすぐ涙出るから無理。怒られることが嫌なんじゃなくて、すぐ涙が出てきて自分が悪くないと思ってるように取られるのがいや',
             'imageUrls':[],
             'comments':[
               {
                 'name':'ゆいぴち',
                 'username':'@yui_pichi',
                 'content':'そうなんだよね（ ;  ; ）こっちは泣きたくて泣いてるんじゃないのに',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'水瀬',
             'username':'@water_se',
             'content':'台風の朝は電車にメイクして髪巻いてるキラキラ✨JK✨いなくてネ申',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'たろ',
             'username':'@taro',
             'content':'駅の階段ですっ転んで死ぬ。俺は弱い',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'もジェ',
             'username':'@moje',
             'content':'本日、自転車で爆走する男児を走って追いかける父親に2回遭遇。春だなあ',
             'imageUrls':[],
             'comments':[
               {
                 'name':'ひろき',
                 'username':'@hiroki',
                 'content':'自分すぎる',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'meteo',
             'username':'@meteo00',
             'content':'久しぶりに靴下でスカート履いたらスースーするとかいう、初めてスカート履かされた商業BL受けのようなことを思った',
             'imageUrls':[],
             'comments':[
               {
                 'name':'こくとぅ',
                 'username':'@kokuto1098',
                 'content':'こっち見てんじゃねえよっ///',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'ブックオフの妖精',
             'username':'@bookoff_fairy',
             'content':'半年前に買って読んでない',
             'imageUrls':['images/IMG_4790.jpg'],
             'comments':[]
           },
           {
             'name':'はく',
             'username':'@haku0203',
             'content':'親はお風呂が体力を使うものだという認識ではない？？？おかしい',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'かりんとう',
             'username':'@karintou',
             'content':'Amazonでリップ買ったらこれ',
             'imageUrls':['images/IMG_4774.JPG'],
             'comments':[
               {
                 'name':'えびび',
                 'username':'@ebibi',
                 'content':'え、これどういうこと？',
                 'imageUrls':[]
               },
               {
                 'name':'ぽちほ',
                 'username':'@pochiho',
                 'content':'草',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'inn!!!',
             'username':'@innnnn',
             'content':'共学の男子と女子校と男子校に混じって4人でカラオケ行った。まじでグロくておもろかった。二度と行かねえ',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'さっち',
             'username':'@satchi',
             'content':'車乗ってたら歩道橋から車に向かって手を振る小学生3人組に遭遇。しかも振り方が皇族だった',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'ミスティ',
             'username':'@misty_ALST',
             'content':'2日ぶりにちゃんとしたご飯食べたらお腹痛くなった、、、人間弱すぎだろ、、、だから宇宙人にペットにされるんだよ',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'間こち',
             'username':'@machikochi276',
             'content':'5限の授業好きな先生なのに睡魔に勝てなくてこれ',
             'imageUrls':['images/1772757839-WTMfo4ParYbDjxNsuRGmqI7F.webp'],
             'comments':[
               {
                 'name':'コンフィス系しょん',
                 'username':'@confis_shon',
                 'content':'全員起きろ　やり直しだ',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'赤豚',
             'username':'@akabuta',
             'content':'美術系アニメで作画がいいのはないのか？デッサンのシーンがおかしすぎる',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'3歩下がって刺す',
             'username':'@3po_sagatte_sasu',
             'content':'古文に人の心とかないんか（意訳）出てきてアツい',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'さお',
             'username':'@sao_000000',
             'content':'新海誠すぎる',
             'imageUrls':['images/IMG_4767.JPG'],
             'comments':[]
           },
           {
             'name':'メンケア厨',
             'username':'@men_care_',
             'content':'非オタの友達がえぶホス見始めたっていうから喜んでたら8話で見るのやめちゃった、、、全人類がアニメを見れると思ってはいけない',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'inn!!!',
             'username':'@innnnn',
             'content':'平成の顔ととのいに生まれたかった',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'カプここ',
             'username':'@kapukoko',
             'content':'なりたいと思ってしまう時点で本当のそういう子にはなれないの悲しい😭自覚なくかわいい女の子でいたかった',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'れんな',
             'username':'@renna_',
             'content':'ブロンなくなっちゃった（ ;  ; ）誰かペイペイください',
             'imageUrls':[],
             'comments':[
               {
                 'name':'マイストン',
                 'username':'@miston',
                 'content':'DMみて',
                 'imageUrls':[]
               },
               {
                 'name':'やみおぢ',
                 'username':'@yami_oji',
                 'content':'お話聞いてあげるよー',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'ゆのん',
             'username':'@yunon_33',
             'content':'Tag\n依存先ください\n08/🚺/躁鬱/リスカ/OD/メンヘラ/通話△/DM◎\n#病み垢さんと繋がりたい#病み垢女子と繋がりたい#病み垢男子と繋がりたい#',
             'imageUrls':['images/_.jpeg','images/IMG_4789.jpg'],
             'comments':[
               {
                 'name':'ウユ',
                 'username':'@uuuuyyyuuuu',
                 'content':'めちゃかわいいです💕フォロー失礼します❣️DMしてもいいですか、、、？',
                 'imageUrls':[]
               },
               {
                 'name':'すお',
                 'username':'@sao_000000',
                 'content':'仲良くしたいです！',
                 'imageUrls':[]
               },
               {
                 'name':'冥',
                 'username':'@mei_000000',
                 'content':'依存してもいいよ',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'えのこ',
             'username':'@ennnnokoko',
             'content':'スタバがステータスみたいになってるのなんで？正直そんなすごいものじゃなくね',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'るり',
             'username':'@luli_1015',
             'content':'レイヤーとかコミケ参戦の人が荷物とか雰囲気で察せるのおもろい',
             'imageUrls':[],
             'comments':[
               {
                 'name':'岡本れいな',
                 'username':'@reina_okamoto000',
                 'content':'わかるwコスイベとかキャリー軍団についていけば着く',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'きみぴ',
             'username':'@ki_mi_pi',
             'content':'置き場所ないせいで毎日起きたらこれ',
             'imageUrls':['images/IMG_4770.JPG'],
             'comments':[
               {
                 'name':'もろこし',
                 'username':'@mo_looo_cos',
                 'content':'アキラくんに見下ろされている！',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'岡本れいな',
             'username':'@reina_okamoto000',
             'content':'cos 初出しレオ\nるりちと併せ楽しすぎた😘',
             'imageUrls':['images/20267421_41_182.jpeg','images/20267421_41_18.jpeg'],
             'comments':[
               {
                 'name':'るり',
                 'username':'@luli_1015',
                 'content':'レオくん顔良すぎたー‼️今度はロケ撮しよ‼️',
                 'imageUrls':[]
               },
               {
                 'name':'ちも7/5星願',
                 'username':'@chim0_cos404',
                 'content':'れいなさんのレオくん！ウィッグセットしたって見てから楽しみにしてました！顔良すぎです😍',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'るり',
             'username':'@luli_1015',
             'content':'cos 冴木\n\nレオくん、なんかめっちゃ怒られてるんだけど、、\n\nレオ▶︎@reina_okamoto000',
             'imageUrls':['images/30_20260704231744.PNG','images/31_20260704232546.jpg'],
             'comments':[
               {
                 'name':'岡本れいな',
                 'username':'@reina_okamoto000',
                 'content':'冴木😍メロすぎだから私服も出して！',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'LR',
             'username':'@LRLR_lr',
             'content':'しかし警部、これから死のうとする人間がバケツプリンを作るでしょうか',
             'imageUrls':[],
             'comments':[]
           },
           {
             'name':'愚者',
             'username':'@gusya_0301',
             'content':'土日体力もメンタルも限界でこれだった',
             'imageUrls':['images/IMG_4521.JPG'],
             'comments':[]
           },
           {
             'name':'ダイラタンシー老体',
             'username':'@DKusaoy___',
             'content':'大金持ちになりたいって言ってんじゃないの。\n金曜の夜にハーゲン買って帰りたいって言ってんの。',
             'imageUrls':['images/IMG_4786.JPG'],
             'comments':[
               {
                 'name':'ブラック漆黒',
                 'username':'@KAHSUisha_3948',
                 'content':'ほんとそれ',
                 'imageUrls':[]
               },
               {
                 'name':'竹善煮',
                 'username':'@tikutiku__2',
                 'content':'そうなんだよ！多少の贅沢もできない経済とか終わってる',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'オシダ',
             'username':'@oshi_da_leo000',
             'content':'レオが刺さりすぎてる',
             'imageUrls':['images/IMG_1246.JPG'],
             'comments':[
               {
                 'name':'ので',
                 'username':'@nod_eexx',
                 'content':'絶対好きだって言ったじゃん',
                 'imageUrls':[]
               }
             ]
           },
           {
             'name':'さおりん',
             'username':'@saorinn_flower',
             'content':'自宅のミモザが咲きました☺️今年も綺麗でいい香り✨',
             'imageUrls':['images/IMG_3365.jpg'],
             'comments':[]
           },
           {
             'name':'なぐるんた',
             'username':'@nagulunta',
             'content':'原稿進捗　ツヤベタ最高',
             'imageUrls':['images/IMG_3282.jpg'],
             'comments':[]
           },
           {
             'name':'era',
             'username':'@e_r_a__',
             'content':'教室に9億',
             'imageUrls':['images/IMG_4453.jpg'],
             'comments':[]
           },
           {
             'name':'きろサイ7/5星願',
             'username':'@k_sai_sx',
             'content':'概念ネイル（とれてます）',
             'imageUrls':['images/IMG_1312.JPG','images/IMG_1313.JPG'],
             'comments':[
               {
                 'name':'杢露',
                 'username':'@mokuro__1001',
                 'content':'かわいいです！明日お会いできるの楽しみです！',
                 'imageUrls':[]
               }
             ]
           }
  ];

  Map<String, dynamic>? _selectedTweet;

  @override
  void initState() {
    super.initState();
    _tweets.shuffle();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("ja-JP");
      await _flutterTts.setSpeechRate(1.2);
      await _flutterTts.setPitch(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint("TTS初期化エラー: $e");
    }

    _flutterTts.setCompletionHandler(() async {
      if (!mounted) return;

      if (_selectedTweet != null) {
        final List<dynamic> currentComments = _selectedTweet!['comments'];
        
        if (_detailSpeakStep >= 1 && _detailSpeakStep <= currentComments.length) {
          final nextCommentText = currentComments[_detailSpeakStep - 1]['content']!;
          _detailSpeakStep++;
          await _executeSpeak(nextCommentText);
        } else {
          await Future.delayed(const Duration(milliseconds: 1500));
          if (_selectedTweet == null) return;
          _detailSpeakStep = 1;
          await _executeSpeak(_selectedTweet!['content']!);
        }
        return; 
      }

      if (!_isTimelineLoopActive) return;

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!_isTimelineLoopActive || _selectedTweet != null) return;

      if (_currentSpeakingIndex >= 0 && _currentSpeakingIndex < _tweets.length - 1) {
        _speakTimeline(_currentSpeakingIndex + 1);
      } else {
        _speakTimeline(0);
      }
    });
  }

  Future<void> _executeSpeak(String text) async {
    if (text.isEmpty) return;
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("発話エラー: $e");
    }
  }

  void _speakTimeline(int index) async {
    if (!mounted || !_isTimelineLoopActive) return;
    _currentSpeakingIndex = index;
    String text = _tweets[index]['content']!;
    await _executeSpeak(text);
  }

  void _speakDetail(String text) async {
    _isTimelineLoopActive = false;
    _currentSpeakingIndex = -1;
    try {
      await _flutterTts.stop();
    } catch (_) {}

    if (text.isNotEmpty) {
      _detailSpeakStep = 1;
      await Future.delayed(const Duration(milliseconds: 250));
      await _executeSpeak(text);
    }
  }

  @override
  void dispose() {
    try {
      _flutterTts.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDetailMode = _selectedTweet != null;

    return Scaffold(
      appBar: AppBar(
        leading: isDetailMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  _detailSpeakStep = 0;
                  try {
                    await _flutterTts.stop();
                  } catch (_) {}
                  setState(() {
                    _selectedTweet = null;
                    _tweets.shuffle();
                  });
                  Future.delayed(const Duration(milliseconds: 250), () {
                    _isTimelineLoopActive = true;
                    _speakTimeline(0);
                  });
                },
              )
            : null,
        title: isDetailMode
            ? const Text(
                '投稿とコメント',
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: isDetailMode
          ? _buildDetailView()
          : Column(
              children: [
                if (!_hasStartedAtLeastOnce)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('タイムラインの自動読み上げを開始'),
                      onPressed: () {
                        setState(() {
                          _hasStartedAtLeastOnce = true;
                          _isTimelineLoopActive = true;
                        });
                        _speakTimeline(0);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _tweets.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tweet = _tweets[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTweet = tweet;
                            _hasStartedAtLeastOnce = true;
                          });
                          _speakDetail(tweet['content']!);
                        },
                        child: _buildTweetCard(tweet),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTweetCard(Map<String, dynamic> tweet) {
    final String name = tweet['name'] ?? '';
    final String username = tweet['username'] ?? '';
    final String content = tweet['content'] ?? '';
    final List<dynamic> imageUrls = tweet['imageUrls'] ?? [];
    final String avatarText = name.isNotEmpty ? name[0] : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Row(
          children: [
            Text(
              avatarText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(username, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
          const SizedBox(height: 12),
          Text(content),
          if (imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imageUrls[index] as String,
                    fit: BoxFit.cover,
                    width: 180,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Colors.black12),
        ],
      ),
    );
  }

  Widget _buildDetailView() {
    final List<dynamic> currentComments = _selectedTweet!['comments'];

    return ListView(
      children: [
        _buildTweetCard(_selectedTweet!),
        const Divider(height: 30, thickness: 2, color: Colors.black12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('コメント', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        ),
        if (currentComments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('コメントはありません'),
          ),
        ...List.generate(
          currentComments.length,
          (index) => Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildTweetCard(currentComments[index]),
          ),
        ),
      ],
    );
  }
}
