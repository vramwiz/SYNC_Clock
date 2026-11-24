# ライセンスと共通基盤の由来

時計演出（SYNC_Clock） © 2026 VRAMの魔術師

本体コードのライセンスは GNU General Public License v3.0（GPL-3.0-only）です。全文は [LICENSE](LICENSE) を参照してください。

## AviUtl ExEdit2 Plugin SDK

- Copyright (c) 2025 Kenkun
- MIT ライセンス
- 対象は `Source/Lib/AviUtl2FilterTypes.pas` の ABI 定義です。ライセンス全文は [ThirdParty/LICENSE.AviUtl2-SDK.txt](ThirdParty/LICENSE.AviUtl2-SDK.txt) を参照してください。

## 継承元

- **SYNC_WeatherFX** から Delphi のプロジェクト構成、SDK 型定義、DLL の公開関数、登録処理、および `setup` フォルダーを継承しました。
- SDK 定義と登録処理は **SYNC_AquaFX**、**SYNC_ParticleFX**、**SYNC_Mine** を経由しています。登録処理の由来は **Syncroh2 / SYNC_Lyrics** です。
- 描画は Windows の Direct2D と WIC を使用します。Delphi RTL を使用します。

