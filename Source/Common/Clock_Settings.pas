unit Clock_Settings;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 時計の外観・パラメータ・プリセットと、各スタイルの座標系を定義する。

interface

type
  TClockStyle = (csRound, csSquare, csAntique, csModern, csAlarm, csPendulum,
    csCuckoo, csWatch, csDigitalWatch, csPocket, csDigital12, csDigital24,
    csLED12, csLED24, csFlip, csSkeleton, csStation, csTower, csStopwatch,
    csHourglass, csBroadcast, csDigitalStopwatch);
  TClockMode = (cmFull, cmDial, cmDisplay);
  TGlassMode = (gmAuto, gmOn, gmOff);
  TGlassShape = (gsEllipse, gsRectangle, gsRounded);
  TClockTrack = (ctYear, ctMonth, ctDay, ctHour, ctMinute, ctSecond, ctSpeed,
    ctAlarmHour, ctAlarmMinute, ctGlassX, ctGlassY, ctGlassScale, ctGlassAspect,
    ctGlassCorner, ctGlassStrength, ctVolume);
  TClockTrackDefinition = record
    Name: PWideChar;
    Minimum, Maximum, Step: Double;
  end;
  TClockColors = array[0..2] of Cardinal;
  TClockSettings = record
    Style: TClockStyle;
    Mode: TClockMode;
    Colors: TClockColors;
    Values: array[TClockTrack] of Double;
    GlassMode: TGlassMode;
    GlassShape: TGlassShape;
    Countdown, Alarm, Sound: Boolean;
  end;
  TClockLayout = record
    Width, Height, X, Y, Radius: Integer;
  end;
  TClockPreset = record
    Colors: TClockColors;
    GlassShape: TGlassShape;
    GlassScale, GlassAspect, Reflection: Integer;
  end;

const
  CLOCK_SPEED_LIMIT = 8640000;
  CLOCK_STYLE_NAMES: array[TClockStyle] of PWideChar = (
    '壁掛け時計（丸型・標準）', '壁掛け時計（四角型）', '壁掛け時計（アンティーク）',
    '壁掛け時計（モダン）', '目覚まし時計', '柱時計（振り子付き）', '鳩時計',
    '腕時計（アナログ）', '腕時計（デジタル）', '懐中時計',
    'デジタル時計（12時間制）', 'デジタル時計（24時間制）', 'LED時計（12時間制）',
    'LED時計（24時間制）', 'パタパタ時計', 'スケルトン時計（歯車付き）',
    '駅時計', '時計塔', 'ストップウォッチ', '砂時計', '時報時計', 'ストップウォッチ（デジタル）');
  CLOCK_MODE_NAMES: array[TClockMode] of PWideChar = ('時計全体', '文字盤', '時刻表示のみ');
  GLASS_MODE_NAMES: array[TGlassMode] of PWideChar = ('自動', 'ON', 'OFF');
  GLASS_SHAPE_NAMES: array[TGlassShape] of PWideChar = ('円', '四角', '角丸四角');
  CLOCK_TRACKS: array[TClockTrack] of TClockTrackDefinition = (
    (Name:'年'; Minimum:1; Maximum:9999; Step:1),
    (Name:'月'; Minimum:1; Maximum:12; Step:1),
    (Name:'日'; Minimum:1; Maximum:31; Step:1),
    (Name:'時'; Minimum:0; Maximum:99; Step:1),
    (Name:'分'; Minimum:0; Maximum:59; Step:1),
    (Name:'秒'; Minimum:0; Maximum:59; Step:1),
    (Name:'時間進行倍率'; Minimum:-CLOCK_SPEED_LIMIT; Maximum:CLOCK_SPEED_LIMIT; Step:1),
    (Name:'アラーム時'; Minimum:0; Maximum:23; Step:1),
    (Name:'アラーム分'; Minimum:0; Maximum:59; Step:1),
    (Name:'ガラスX'; Minimum:-512; Maximum:512; Step:1),
    (Name:'ガラスY'; Minimum:-512; Maximum:512; Step:1),
    (Name:'ガラス拡大率'; Minimum:0; Maximum:200; Step:1),
    (Name:'ガラス縦横比'; Minimum:-100; Maximum:100; Step:1),
    (Name:'ガラス角丸'; Minimum:0; Maximum:100; Step:1),
    (Name:'ガラス反射強度'; Minimum:0; Maximum:100; Step:1),
    (Name:'音量'; Minimum:0; Maximum:100; Step:0.01));
  CLOCK_LAYOUTS: array[TClockStyle] of TClockLayout = (
    (Width:512; Height:512; X:256; Y:256; Radius:202),
    (Width:512; Height:512; X:256; Y:256; Radius:189),
    (Width:512; Height:512; X:256; Y:256; Radius:177),
    (Width:512; Height:512; X:256; Y:256; Radius:211),
    (Width:512; Height:548; X:256; Y:297; Radius:168),
    (Width:432; Height:820; X:216; Y:234; Radius:145),
    (Width:520; Height:660; X:260; Y:344; Radius:144),
    (Width:440; Height:780; X:220; Y:390; Radius:152),
    (Width:484; Height:740; X:242; Y:370; Radius:157),
    (Width:512; Height:596; X:256; Y:327; Radius:180),
    (Width:600; Height:280; X:300; Y:140; Radius:248),
    (Width:640; Height:300; X:320; Y:150; Radius:267),
    (Width:600; Height:270; X:300; Y:135; Radius:251),
    (Width:640; Height:285; X:320; Y:143; Radius:270),
    (Width:680; Height:325; X:340; Y:158; Radius:274),
    (Width:512; Height:512; X:256; Y:256; Radius:185),
    (Width:512; Height:598; X:256; Y:328; Radius:193),
    (Width:500; Height:900; X:250; Y:388; Radius:147),
    (Width:480; Height:584; X:240; Y:320; Radius:171),
    (Width:400; Height:600; X:200; Y:300; Radius:123),
    (Width:680; Height:500; X:340; Y:250; Radius:194),
    (Width:500; Height:650; X:250; Y:289; Radius:169));
  CLOCK_PRESETS: array[TClockStyle] of TClockPreset = (
    (Colors:($36404B,$F1EDE1,$232D36); GlassShape:gsEllipse; GlassScale:100; GlassAspect:0; Reflection:48),
    (Colors:($565C60,$E9E6DE,$262329); GlassShape:gsRounded; GlassScale:109; GlassAspect:0; Reflection:48),
    (Colors:($75452C,$E6C99B,$4D2F1D); GlassShape:gsEllipse; GlassScale:100; GlassAspect:0; Reflection:40),
    (Colors:($29323D,$172430,$D8EBEB); GlassShape:gsEllipse; GlassScale:100; GlassAspect:0; Reflection:58),
    (Colors:($9C3545,$FFF0D4,$27212B); GlassShape:gsEllipse; GlassScale:100; GlassAspect:0; Reflection:39),
    (Colors:($603923,$F0D7A6,$3A291D); GlassShape:gsEllipse; GlassScale:100; GlassAspect:0; Reflection:37),
    (Colors:($754225,$E4BC79,$3B2419); GlassShape:gsEllipse; GlassScale:100; GlassAspect:0; Reflection:25),
    (Colors:($455765,$101B29,$F1E8CE); GlassShape:gsEllipse; GlassScale:100; GlassAspect:0; Reflection:57),
    (Colors:($38424D,$A6B699,$243326); GlassShape:gsRounded; GlassScale:98; GlassAspect:13; Reflection:31),
    (Colors:($AD7845,$FFEDC5,$483022); GlassShape:gsEllipse; GlassScale:100; GlassAspect:0; Reflection:52),
    (Colors:($413528,$20241D,$E5C66D); GlassShape:gsRounded; GlassScale:100; GlassAspect:61; Reflection:25),
    (Colors:($394551,$0A141C,$87E2D2); GlassShape:gsRounded; GlassScale:100; GlassAspect:62; Reflection:44),
    (Colors:($502D30,$170F17,$FF5E62); GlassShape:gsRounded; GlassScale:100; GlassAspect:63; Reflection:33),
    (Colors:($293B4F,$0E1627,$72BDFF); GlassShape:gsRounded; GlassScale:100; GlassAspect:64; Reflection:35),
    (Colors:($47474A,$202127,$F7E8D1); GlassShape:gsRectangle; GlassScale:100; GlassAspect:59; Reflection:25),
    (Colors:($83725A,$16232A,$ECD29C); GlassShape:gsEllipse; GlassScale:100; GlassAspect:0; Reflection:52),
    (Colors:($424C51,$E7E9E6,$192327); GlassShape:gsRounded; GlassScale:100; GlassAspect:0; Reflection:32),
    (Colors:($826A59,$2C4549,$EBD4A9); GlassShape:gsEllipse; GlassScale:100; GlassAspect:0; Reflection:36),
    (Colors:($8A969D,$F2F0E9,$253039); GlassShape:gsEllipse; GlassScale:100; GlassAspect:0; Reflection:29),
    (Colors:($65422F,$80BDCC,$E7AE62); GlassShape:gsRounded; GlassScale:100; GlassAspect:0; Reflection:50),
    (Colors:($A1BAC1,$09141B,$EEF5ED); GlassShape:gsEllipse; GlassScale:98; GlassAspect:0; Reflection:20),
    (Colors:($262E37,$A7B3A6,$22332D); GlassShape:gsRounded; GlassScale:99; GlassAspect:49; Reflection:28));

function PresetSettings(Style: TClockStyle): TClockSettings;
function TrackValue(Track: TClockTrack; Value: Double): Double;
function IsDigital(Style: TClockStyle): Boolean;
function UsesCountdown(const S: TClockSettings): Boolean;
function ShowsGlass(const S: TClockSettings): Boolean;

implementation

uses System.Math;

function PresetSettings(Style: TClockStyle): TClockSettings;
var
  Preset: TClockPreset;
begin
  Result := Default(TClockSettings);
  Preset := CLOCK_PRESETS[Style];
  Result.Style := Style;
  Result.Colors := Preset.Colors;
  Result.Values[ctYear] := 2026;
  Result.Values[ctMonth] := 1;
  Result.Values[ctDay] := 1;
  Result.Values[ctHour] := 10;
  Result.Values[ctMinute] := 8;
  Result.Values[ctSecond] := 36;
  Result.Values[ctSpeed] := 1;
  Result.Values[ctAlarmHour] := 7;
  Result.Values[ctGlassScale] := Preset.GlassScale;
  Result.Values[ctGlassAspect] := Preset.GlassAspect;
  Result.Values[ctGlassCorner] := 30;
  Result.Values[ctGlassStrength] := Preset.Reflection;
  Result.Values[ctVolume] := 50;
  Result.GlassShape := Preset.GlassShape;
  if Style in [csStopwatch, csDigitalStopwatch, csHourglass] then
  begin
    Result.Values[ctHour] := 0;
    Result.Values[ctMinute] := 0;
    Result.Values[ctSecond] := 0;
    if Style = csHourglass then Result.Values[ctMinute] := 1;
  end;
end;

function TrackValue(Track: TClockTrack; Value: Double): Double;
begin
  if IsNan(Value) then Value := CLOCK_TRACKS[Track].Minimum;
  Result := EnsureRange(Value, CLOCK_TRACKS[Track].Minimum, CLOCK_TRACKS[Track].Maximum);
end;

function IsDigital(Style: TClockStyle): Boolean;
begin
  Result := Style in [csDigitalWatch, csDigital12, csDigital24, csLED12, csLED24, csFlip,
    csDigitalStopwatch];
end;

function UsesCountdown(const S: TClockSettings): Boolean;
begin
  Result := (S.Style = csHourglass) or
    (S.Countdown and IsDigital(S.Style) and (S.Style <> csDigitalStopwatch));
end;

function ShowsGlass(const S: TClockSettings): Boolean;
begin
  Result := (S.GlassMode = gmOn) or
    ((S.GlassMode = gmAuto) and (S.Mode = cmFull) and
      not (S.Style in [csCuckoo, csHourglass, csFlip]));
end;

end.

