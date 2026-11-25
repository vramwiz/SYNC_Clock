# SYNC_Clock の配布 ZIP

`make_release_zip.bat` はビルド済みの `SYNC_Clock.auf2` と説明・ライセンスを `SYNC_Clock.zip` に梱包し、`SYNC_Clock.catalog.json` の末尾バージョンへ本体の XXH3-128 を設定します。

## 作成手順

1. Delphi で Win64 Release をビルドします。標準の参照先は `C:\ProgramData\aviutl2\Plugin\SYNC_Clock` です。
2. [xxHash 公式 v0.8.4 の Windows 版](https://github.com/Cyan4973/xxHash/releases/download/v0.8.4/xxhsum_win64_v0_8_4.zip)の `xxhsum.exe` を `Win64\Dependencies\xxHash-0.8.4\xxhsum.exe` に配置するか、PATH に登録します。
3. `setup\make_release_zip.bat` を実行します。カタログのバージョンと本体の製品バージョンが一致すると梱包します。初回の配布バージョンは `v1.0.0` です。

参照先を指定する場合は、次のように実行します。

```bat
setup\make_release_zip.bat -ReleaseDirectory "D:\Release\SYNC_Clock" -XxhsumPath "D:\Tools\xxhsum.exe"
```

## 配布 ZIP の内容

```text
SYNC_Clock/
  SYNC_Clock.auf2
  README.md
  LICENSE
  THIRD_PARTY_NOTICES.md
  ThirdParty/
    LICENSE.AviUtl2-SDK.txt
```

カタログは解凍した `SYNC_Clock` フォルダーをプラグインフォルダーへまとめてコピーします。アンインストールでは ZIP からインストールしたファイルのみを個別に削除します。公開時は実際の公開日とカタログの `release_date` を照合し、該当するタグのリリースに ZIP を添付します。
