# SYNC_Clock 作業ノート

## 継承した共通基盤

- `SYNC_WeatherFX` の `.dpr` / `.dproj`、リソース、SDK 型定義、フィルターテーブル登録処理、ライセンスを基に作成した。本体は `SYNC_Clock.dproj` / `SYNC_Clock.auf2` の1つ。製品 GUID は新規発行した。
- `setup` は WeatherFX の配布処理を継承し、時計演出の v1.0.0 用に更新した。バッチとカタログの使い方は [setup/README.md](setup/README.md) を参照。
- 元からあった `git_init.bat` は保持した。制作仕様の原文は `docs/SPECIFICATION.md` に保存した。

## ビルド・配置

- Delphi 37.0 / Win64。IDE で開くプロジェクトは `SYNC_Clock.dproj`。
- Delphi の環境変数を設定し、プロジェクトルートで Win64 の Debug と Release をビルドする。

```powershell
cmd /c 'call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat" && msbuild SYNC_Clock.dproj /t:Rebuild /p:Config=Debug /p:Platform=Win64'
cmd /c 'call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat" && msbuild SYNC_Clock.dproj /t:Rebuild /p:Config=Release /p:Platform=Win64'
```

- Debug / Release 共通の配置先は `C:\ProgramData\aviutl2\Plugin\SYNC_Clock\`。ビルド後イベントで DLL を AUF2 としてコピーし、DLL を削除する。Release は RSM も削除する。DCU は構成ごとに `Win64\Debug\DCU` / `Win64\Release\DCU` に置く。
- デバッガーホストは両構成とも `D:\aviutl2_v2.1.16\aviutl2.exe`。通常の検査ではコマンドラインから本体 AUF2 を読み込む。IDE・AviUtl2 での表示確認は別に記録する。
- 最低対応バージョンは AviUtl2 v2.1.16。公式 SDK の `MediaObject.cpp` と同じ映像・音声のメディア入力として登録し、画像サイズはスタイルで確保する。標準描画の変形項目は AviUtl2 側で管理する。
- 公式 SDK 配布元は [AviUtlのお部屋](https://spring-fragrance.mints.ne.jp/aviutl/)。`filter2.h` と `plugin2.h` を参照して音声処理と倍率トラック参照の ABI を追加した。

## 処理の構成

- `Source/Plugin/Filter` で DLL の設定項目を管理する。プリセットは設定ボタンから対象オブジェクトの編集 API に書き込み、描画中は設定値を変更しない。
- `Clock_Timeline.pas` は基準日時を補正し、オブジェクトのフレーム位置を日時と経過時間に変換する。一定倍率は直接計算し、中間点がある場合は SDK から区間を取得して倍率を積分する。移動曲線は区間ごとの固定サンプルで近似する。
- `Clock_Renderer.pas` はスタイル・描画モード・色の組み合わせで静的レイヤーを再利用する。針、歯車、砂などは任意時刻から描画する。ガラスが標準描画範囲を超える場合は出力を対称に広げる。
- `Clock_Audio.pas` はタイムライン上のサンプル位置から音声を合成する。高速時は発音頻度を制限する。砂時計は無音。

## 作業規則

- ユニット追加時は `.dpr` の `in` と `.dproj` の `DCCReference` の両方を更新し、必要に応じて検索パスへ登録する。
- 日本語を含む `.pas` / `.dpr` / Windows PowerShell 用 `.ps1` は UTF-8 BOM、CRLF。ユニット冒頭に役割を書き、公開処理では入出力・所有権・重要な副作用を必要に応じて記す。
- UI・描画・データ処理を分離する。SDK の型やコールバックを変える際は公式定義を照合し、ホストのポインターはコールバック内だけ借用する。Delphi 例外を DLL 境界の外へ出さない。


## 検査結果（2026-11-24）

- Delphi 37.0 の Win64 Debug / Release で Rebuild。両構成とも警告0・エラー0。最終配置は Release の `SYNC_Clock.auf2`。
- 本番 AUF2 を検査 EXE から読み込み、20スタイルのプリセット、3描画モードの透過、逆シーク、うるう日・年末と分数フレームレート、停止・逆行・最大倍率、SDK 模擬トラックの中間点、ガラスの縦横比、音声と音量を確認した。Debug / Release の40枚の出力画像はバイト単位で一致した。
- 検査ログと全20スタイルの見本は `Win64/Verification`。実際の AviUtl2 上でのメニュー表示・配置・書き出しは未確認。
- `setup` の5ファイル（既存ZIPを含む）はコピー元と SHA-256 が一致した。

## AviUtl2カタログ登録時の共通ルール

1. **概要は35文字以内。** `Setup/*.catalog.json` の `summary` は、JSONのエスケープ表記ではなく実際の表示文字列を数える。機能の詳細や補足は概要に詰め込まず、説明・READMEに記載する。
2. **既存タグを優先する。** [公開カタログの `index.json`](https://github.com/Neosku/aviutl2-catalog-data/blob/main/index.json) で、同じ製品や近い用途に使われているタグの表記を確認し、用途を表すものだけを選ぶ。同義語を重ねたり、製品ごとに新しいタグを量産したりしない。
3. **配布専用フォルダー単位で導入・削除する。** ZIP内を製品専用フォルダーにまとめ、ダウンロード・展開後の配置はフォルダーの `copy` 1件、アンインストールはその専用フォルダーだけを指定する `delete` 1件を基本とする。共有フォルダーや、ユーザー素材・設定を含むフォルダーは一括削除しない。既存パッケージで変更する際は、配布ZIPの配置とセットアップスクリプトの検証条件も確認し、整合しない場合は既存の手順を維持する。
