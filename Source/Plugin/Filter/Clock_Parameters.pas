unit Clock_Parameters;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// ホストの設定項目を登録し、プリセットを対象オブジェクトに適用する。

interface

uses Clock_Settings;

procedure RegisterClockParameters;
function ReadClockSettings: TClockSettings;

implementation

uses System.Math, System.SysUtils, Winapi.Windows, AviUtl2FilterTypes,
  PluginFilterTable;

var
  PresetItem, StyleItem, ModeItem, TimingItem, GlassItem, ShapeItem: TFILTER_ITEM_SELECT;
  ApplyButton: TFILTER_ITEM_BUTTON;
  Styles: array[0..Ord(High(TClockStyle)) + 1] of TFILTER_ITEM_SELECT_ITEM;
  Modes: array[0..Ord(High(TClockMode)) + 1] of TFILTER_ITEM_SELECT_ITEM;
  Timings: array[0..2] of TFILTER_ITEM_SELECT_ITEM;
  GlassModes: array[0..Ord(High(TGlassMode)) + 1] of TFILTER_ITEM_SELECT_ITEM;
  Shapes: array[0..Ord(High(TGlassShape)) + 1] of TFILTER_ITEM_SELECT_ITEM;
  Tracks: array[TClockTrack] of TFILTER_ITEM_TRACK;
  Colors: array[0..2] of TFILTER_ITEM_COLOR;
  SoundItem, AlarmItem: TFILTER_ITEM_CHECK;
  Groups, GroupEnds: array[0..6] of TFILTER_ITEM_GROUP;

const
  COLOR_NAMES: array[0..2] of PWideChar = ('色1', '色2', '色3');
  GROUP_NAMES: array[0..6] of PWideChar = ('時計スタイル・描画モード', '色設定',
    '基準日時', '時間進行・カウントダウン', '時計固有の動作', 'ガラス設定', '音声');

procedure ApplyPreset(Edit: PEDIT_SECTION; Obj: OBJECT_HANDLE; Effect, Item: PWideChar); cdecl;
var
  S: TClockSettings;
  Preset: TClockStyle;
  Track: TClockTrack;
  I: Integer;
  Saved: PAnsiChar;
  Name, Target: string;
  procedure SetItem(Field: PWideChar; const Value: UTF8String);
  begin
    if not Edit^.SetObjectItemValue(Obj, PWideChar(Target), Field, PAnsiChar(Value)) then
      OutputDebugString(PWideChar('SYNC_Clock preset: ' + string(Field)));
  end;
begin
  if (Edit = nil) or (Obj = nil) or (Effect = nil) then Exit;
  if not Assigned(Edit^.SetObjectItemValue) then Exit;
  try
    Target := Effect;
    Preset := TClockStyle(EnsureRange(PresetItem.Value, 0, Ord(High(TClockStyle))));
    if Assigned(Edit^.GetObjectItemValue) then
    begin
      Saved := Edit^.GetObjectItemValue(Obj, PWideChar(Target), PresetItem.Name);
      if Saved <> nil then
      begin
        Name := string(UTF8String(Saved));
        for I := 0 to Ord(High(TClockStyle)) do
          if Name = string(CLOCK_STYLE_NAMES[TClockStyle(I)]) then
          begin
            Preset := TClockStyle(I);
            Break;
          end;
      end;
    end;
    S := PresetSettings(Preset);
    SetItem(StyleItem.Name, UTF8String(string(CLOCK_STYLE_NAMES[Preset])));
    SetItem(ModeItem.Name, UTF8String(string(CLOCK_MODE_NAMES[S.Mode])));
    SetItem(GlassItem.Name, UTF8String(string(GLASS_MODE_NAMES[S.GlassMode])));
    SetItem(ShapeItem.Name, UTF8String(string(GLASS_SHAPE_NAMES[S.GlassShape])));
    SetItem(TimingItem.Name, '通常時計');
    SetItem(AlarmItem.Name, '0');
    SetItem(SoundItem.Name, '0');
    for I := Low(Colors) to High(Colors) do
      SetItem(Colors[I].Name, UTF8String(IntToHex(S.Colors[I], 6)));
    for Track := Low(TClockTrack) to High(TClockTrack) do
      SetItem(Tracks[Track].Name, UTF8String(FloatToStr(S.Values[Track], TFormatSettings.Invariant)));
  except
    on E: Exception do OutputDebugString(PWideChar('SYNC_Clock preset: ' + E.Message));
  end;
end;

procedure RegisterClockParameters;
var
  I: Integer;
  S: TClockSettings;
  procedure BeginGroup(Index: Integer);
  begin
    AddGroup(Groups[Index], GROUP_NAMES[Index], Ord(Index < 2));
  end;
  procedure EndGroup(Index: Integer);
  begin
    AddGroup(GroupEnds[Index], '', 0);
  end;
  procedure AddTracks(First, Last: TClockTrack);
  var
    Kind: TClockTrack;
    Def: TClockTrackDefinition;
  begin
    for Kind := First to Last do
    begin
      Def := CLOCK_TRACKS[Kind];
      AddTrack(Tracks[Kind], Def.Name, S.Values[Kind], Def.Minimum, Def.Maximum, Def.Step);
    end;
  end;
begin
  S := PresetSettings(csRound);
  for I := 0 to Ord(High(TClockStyle)) do
  begin
    Styles[I].Name := CLOCK_STYLE_NAMES[TClockStyle(I)];
    Styles[I].Value := I;
  end;
  for I := 0 to Ord(High(TClockMode)) do
  begin
    Modes[I].Name := CLOCK_MODE_NAMES[TClockMode(I)];
    Modes[I].Value := I;
  end;
  for I := 0 to Ord(High(TGlassMode)) do
  begin
    GlassModes[I].Name := GLASS_MODE_NAMES[TGlassMode(I)];
    GlassModes[I].Value := I;
  end;
  for I := 0 to Ord(High(TGlassShape)) do
  begin
    Shapes[I].Name := GLASS_SHAPE_NAMES[TGlassShape(I)];
    Shapes[I].Value := I;
  end;
  Timings[0].Name := '通常時計';
  Timings[1].Name := 'カウントダウン';
  Timings[1].Value := 1;

  AddSelect(PresetItem, 'プリセット', Ord(S.Style), @Styles[0]);
  AddButton(ApplyButton, '設定を反映', ApplyPreset);
  BeginGroup(0);
  AddSelect(StyleItem, 'スタイル', Ord(S.Style), @Styles[0]);
  AddSelect(ModeItem, '描画モード', Ord(S.Mode), @Modes[0]);
  EndGroup(0);
  BeginGroup(1);
  for I := Low(Colors) to High(Colors) do
    AddColor(Colors[I], COLOR_NAMES[I], Byte(S.Colors[I] and 255),
      Byte((S.Colors[I] shr 8) and 255), Byte((S.Colors[I] shr 16) and 255));
  EndGroup(1);
  BeginGroup(2);
  AddTracks(ctYear, ctSecond);
  EndGroup(2);
  BeginGroup(3);
  AddTracks(ctSpeed, ctSpeed);
  AddSelect(TimingItem, '動作方式', 0, @Timings[0]);
  EndGroup(3);
  BeginGroup(4);
  AddCheck(AlarmItem, 'アラーム', 0);
  AddTracks(ctAlarmHour, ctAlarmMinute);
  EndGroup(4);
  BeginGroup(5);
  AddSelect(GlassItem, 'ガラス面', Ord(S.GlassMode), @GlassModes[0]);
  AddSelect(ShapeItem, 'ガラス形状', Ord(S.GlassShape), @Shapes[0]);
  AddTracks(ctGlassX, ctGlassStrength);
  EndGroup(5);
  BeginGroup(6);
  AddCheck(SoundItem, '効果音', 0);
  AddTracks(ctVolume, ctVolume);
  EndGroup(6);
end;

function ReadClockSettings: TClockSettings;
var
  I: Integer;
  Track: TClockTrack;
begin
  Result.Style := TClockStyle(EnsureRange(StyleItem.Value, 0, Ord(High(TClockStyle))));
  Result.Mode := TClockMode(EnsureRange(ModeItem.Value, 0, Ord(High(TClockMode))));
  Result.GlassMode := TGlassMode(EnsureRange(GlassItem.Value, 0, Ord(High(TGlassMode))));
  Result.GlassShape := TGlassShape(EnsureRange(ShapeItem.Value, 0, Ord(High(TGlassShape))));
  Result.Countdown := TimingItem.Value = 1;
  Result.Sound := SoundItem.Value <> 0;
  Result.Alarm := AlarmItem.Value <> 0;
  for I := Low(Colors) to High(Colors) do
    Result.Colors[I] := (Cardinal(Colors[I].R) shl 16) or (Cardinal(Colors[I].G) shl 8) or Colors[I].B;
  for Track := Low(TClockTrack) to High(TClockTrack) do
    Result.Values[Track] := TrackValue(Track, Tracks[Track].Value);
end;

end.

