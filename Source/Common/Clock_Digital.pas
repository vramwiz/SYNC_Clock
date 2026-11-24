unit Clock_Digital;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 液晶、7セグメント、LED、数字板の筐体と表示を描画する。

interface

uses Clock_Settings, Clock_Timeline, Clock_Canvas;

procedure DrawDigitalBase(C: TClockCanvas; const S: TClockSettings; const L: TClockLayout);
procedure DrawDigitalDisplay(C: TClockCanvas; const S: TClockSettings;
  const L: TClockLayout; const T: TClockTime);

implementation

uses System.SysUtils, System.Math, Winapi.D2D1, Clock_Glyphs;

procedure DrawWatchBase(C: TClockCanvas; const S: TClockSettings; const L: TClockLayout);
const
  SCREEN_HALF_HEIGHT = 137;
  BEZEL_WIDTH = 36;
  BEZEL_HEIGHT = 45;
var
  X, Y, R, HalfWidth, HalfHeight, BandY: Single;
  Body, Metal, Face: Cardinal;
  I: Integer;
begin
  X := L.X;
  Y := L.Y;
  R := L.Radius;
  Face := S.Colors[1];
  if S.Mode = cmFull then
  begin
    Body := S.Colors[0];
    Metal := Mix(Body, $BAC3CA, 0.45);
    HalfWidth := R + BEZEL_WIDTH;
    HalfHeight := SCREEN_HALF_HEIGHT + BEZEL_HEIGHT;

    C.Panel(X - 95, 20, 190, L.Height - 40, 26, Shade(Body, 0.80), Body, Shade(Body, 0.42));
    for I := 0 to 19 do
    begin
      BandY := 34 + I * 34;
      if Abs(BandY + 10 - Y) > HalfHeight - 3 then
        C.Box(X - 84, BandY, 168, 20, 8, Shade(Body, 1.14));
    end;
    C.Panel(X - 108, Y - HalfHeight - 13, 216, HalfHeight * 2 + 26, 21,
      Shade(Body, 1.25), Body, Shade(Body, 0.50));
    for I in [-1, 1] do
    begin
      C.Box(X - HalfWidth - 9, Y + I * 68 - 22, 19, 44, 6, Shade(Body, 0.82));
      C.Box(X + HalfWidth - 10, Y + I * 68 - 22, 19, 44, 6, Shade(Body, 0.82));
    end;

    C.Box(X - HalfWidth, Y - HalfHeight + 5, HalfWidth * 2, HalfHeight * 2, 54, Shade(Body, 0.40));
    C.Panel(X - HalfWidth, Y - HalfHeight, HalfWidth * 2, HalfHeight * 2, 54,
      Shade(Metal, 1.42), Metal, Shade(Metal, 0.48));
    C.BoxEdge(X - HalfWidth + 5, Y - HalfHeight + 5, HalfWidth * 2 - 10,
      HalfHeight * 2 - 10, 50, 1.8, Shade(Metal, 1.66), 0.80);
    C.Panel(X - R - 15, Y - SCREEN_HALF_HEIGHT - 15, R * 2 + 30,
      SCREEN_HALF_HEIGHT * 2 + 30, 36, Shade(Body, 0.48), Body, Shade(Body, 0.62));
  end;

  C.Panel(X - R, Y - SCREEN_HALF_HEIGHT, R * 2, SCREEN_HALF_HEIGHT * 2, 24,
    Shade(Face, 0.65), Face, Shade(Face, 1.18));
  C.BoxEdge(X - R + 3, Y - SCREEN_HALF_HEIGHT + 3, R * 2 - 6,
    SCREEN_HALF_HEIGHT * 2 - 6, 22, 1.5, Shade(Face, 1.40));
end;

procedure DrawDigitalStopwatchBase(C: TClockCanvas; const S: TClockSettings; const L: TClockLayout);
const
  SCREEN_HALF_HEIGHT = 86;
var
  X, Y, R: Single;
  Body, Face: Cardinal;
begin
  X := L.X;
  Y := L.Y;
  R := L.Radius;
  Face := S.Colors[1];
  if S.Mode = cmFull then
  begin
    Body := S.Colors[0];
    C.StrokePath([Pt(X - 23, Y + 204), Pt(X - 32, Y + 248), Pt(X - 13, Y + 278),
      Pt(X + 23, Y + 285), Pt(X + 45, Y + 262), Pt(X + 33, Y + 225)], 7, Shade(Body, 1.19));
    C.Box(X - 39, Y + 196, 78, 38, 13, Shade(Body, 0.56));
    C.BoxEdge(X - 25, Y + 215, 50, 8, 4, 1.4, Shade(Body, 1.47), 0.75);

    C.Panel(X - 29, Y - 223, 58, 26, 6, Shade(Body, 1.36), Body, Shade(Body, 0.50));
    C.Polygon([Pt(X - 197, Y - 137), Pt(X - 173, Y - 187), Pt(X - 146, Y - 185),
      Pt(X - 156, Y - 132)], Shade(Body, 1.16));
    C.Polygon([Pt(X + 146, Y - 185), Pt(X + 174, Y - 187), Pt(X + 197, Y - 137),
      Pt(X + 156, Y - 132)], Shade(Body, 1.24));

    C.Box(X - 207, Y - 197, 414, 415, 95, Shade(Body, 0.35));
    C.Panel(X - 207, Y - 201, 414, 415, 95, Shade(Body, 1.20), Body, Shade(Body, 0.53));
    C.BoxEdge(X - 202, Y - 196, 404, 405, 91, 2, Shade(Body, 1.35), 0.75);
    C.Panel(X - 181, Y - 153, 362, 307, 76, Shade(Body, 0.45), Shade(Body, 0.70), Shade(Body, 1.08));
    C.BoxEdge(X - 181, Y - 153, 362, 307, 76, 2.2, Shade(Body, 1.45), 0.55);
    C.Box(X - 38, Y - 127, 76, 5, 2.5, Mix(Body, Face, 0.79));
    C.Box(X - 28, Y + 111, 56, 5, 2.5, Shade(Body, 1.54));
  end;
  C.Panel(X - R, Y - SCREEN_HALF_HEIGHT, R * 2, SCREEN_HALF_HEIGHT * 2, 19,
    Shade(Face, 0.70), Face, Shade(Face, 1.23));
  C.BoxEdge(X - R + 3, Y - SCREEN_HALF_HEIGHT + 3, R * 2 - 6,
    SCREEN_HALF_HEIGHT * 2 - 6, 17, 2, Shade(Face, 0.60), 0.82);
end;

procedure DrawDigitalBase(C: TClockCanvas; const S: TClockSettings; const L: TClockLayout);
var
  X, Y, R, H, Corner: Single;
  Body, Face: Cardinal;
  I: Integer;
begin
  if S.Mode = cmDisplay then Exit;
  if S.Style = csDigitalWatch then
  begin
    DrawWatchBase(C, S, L);
    Exit;
  end;
  if S.Style = csDigitalStopwatch then
  begin
    DrawDigitalStopwatchBase(C, S, L);
    Exit;
  end;
  X := L.X; Y := L.Y; R := L.Radius;
  Body := S.Colors[0]; Face := S.Colors[1];
  H := L.Height * 0.70;
  Corner := 18;
  if S.Style = csFlip then Corner := 8;
  if S.Style = csDigital12 then Corner := 26;
  if S.Style in [csLED12, csLED24] then Corner := 12;
  if S.Mode = cmFull then
  begin
    C.Box(X - R - 31, Y - H / 2 - 17, 2 * R + 62, H + 44, Corner + 7, Shade(Body, 0.28));
    C.Panel(X - R - 31, Y - H / 2 - 22, 2 * R + 62, H + 44, Corner + 7,
      Shade(Body, 1.49), Body, Shade(Body, 0.44));
    C.BoxEdge(X - R - 25, Y - H / 2 - 16, 2 * R + 50, H + 32, Corner + 4,
      1.5, Shade(Body, 1.54));
    if S.Style = csDigital12 then
      for I := -5 to 5 do
        C.Line(X + I * 8, Y + H / 2 + 12, X + I * 8 + 3, Y + H / 2 + 12, 2, Shade(Body, 0.29));
  end;
  C.Panel(X - R, Y - H / 2, R * 2, H, Corner,
    Shade(Face, 0.64), Face, Shade(Face, 1.18));
  C.BoxEdge(X - R + 3, Y - H / 2 + 3, R * 2 - 6, H - 6, Corner - 2, 1.5, Shade(Face, 1.42));
end;

function DisplayText(const S: TClockSettings; const T: TClockTime;
  Offset: Integer; out Meridiem: string): string;
var
  H, M, Sec: Int64;
  Total: Int64;
begin
  Meridiem := '';
  if S.Style = csDigitalStopwatch then
  begin
    Total := Floor(T.Stopwatch * 100 + 0.000001);
    Exit(Format('%.2d:%.2d.%.2d', [Total div 6000, Total div 100 mod 60, Total mod 100]));
  end;
  if UsesCountdown(S) then
    Total := Max(Int64(0), Ceil(T.Remaining - 0.0000001) + Offset)
  else
    Total := Floor(PositiveMod(T.DaySeconds + Offset, 86400) + 0.0000001);
  Sec := Total mod 60;
  M := Total div 60 mod 60;
  H := Total div 3600;
  if not UsesCountdown(S) then
    if S.Style in [csDigital12, csLED12] then
    begin
      Meridiem := 'AM';
      if H >= 12 then Meridiem := 'PM';
      H := H mod 12;
      if H = 0 then H := 12;
    end;
  if (S.Style in [csDigital12, csLED12, csDigitalWatch]) and not UsesCountdown(S) then
    Result := Format('%.2d:%.2d', [H, M])
  else
    Result := Format('%.2d:%.2d:%.2d', [H, M, Sec]);
end;

procedure DrawDigitalDisplay(C: TClockCanvas; const S: TClockSettings;
  const L: TClockLayout; const T: TClockTime);
var
  Display: TClockDisplay;
  Text, Previous, Meridiem, Unused, LabelText: string;
  I, Offset: Integer;
  X, Y, W, H, Gap, Advance, Weight, Phase, Part: Single;
  Blink, Unlit, Flipping: Boolean;
  Ink, Face: Cardinal;
  Ch: Char;
begin
  Ink := S.Colors[2];
  Face := S.Colors[1];
  Display := cdSevenSegment;
  if S.Style in [csLED12, csLED24] then Display := cdDots;
  if S.Style = csFlip then Display := cdVector;
  Text := DisplayText(S, T, 0, Meridiem);
  H := 109;
  if S.Style = csDigitalWatch then
  begin
    H := 105;
    if UsesCountdown(S) then H := 90;
  end;
  if S.Style = csFlip then H := 133;
  if S.Style = csDigitalStopwatch then H := 100;
  Unlit := S.Mode <> cmDisplay;
  Y := L.Y - H * 0.64;
  if (S.Style in [csFlip, csDigitalStopwatch]) or ((S.Style = csDigitalWatch) and UsesCountdown(S)) then
    Y := L.Y - H * 0.5;
  Weight := 0;
  for Ch in Text do
    if CharInSet(Ch, [':', '.']) then Weight := Weight + 0.38 else Weight := Weight + 1;
  W := Min(H * 0.68, (2 * L.Radius - 29) / (Weight + 0.13 * (Length(Text) - 1)));
  Gap := W * 0.13;
  X := L.X - (W * Weight + Gap * (Length(Text) - 1)) * 0.5;
  Blink := (S.Style = csDigitalStopwatch) or (T.Speed = 0) or (Abs(T.Speed) > 2) or (T.Second mod 2 = 0);
  if UsesCountdown(S) then
    Blink := (T.Speed = 0) or (T.Remaining <= 0) or (Abs(T.Speed) > 2) or
      (Ceil(T.Remaining - 0.0000001) mod 2 = 0);
  Previous := Text;
  Flipping := False;
  Phase := 1;
  if (S.Style = csFlip) and (T.RealSeconds > 0) and (T.Speed <> 0) and
    (not UsesCountdown(S) or (T.Remaining > 0)) then
  begin
    Offset := -Sign(T.Speed);
    if UsesCountdown(S) then Offset := -Offset;
    Phase := EventAge(T.DaySeconds, 0, 1, T.Speed) / 0.22;
    if UsesCountdown(S) then Phase := EventAge(T.Remaining, 0, 1, -T.Speed) / 0.22;
    if (Phase < 1) and (Abs(T.Speed) <= 4) then
    begin
      Previous := DisplayText(S, T, Offset, Unused);
      Flipping := Length(Previous) = Length(Text);
    end;
  end;

  if S.Style in [csLED12, csLED24] then
    C.Glow(L.X, Y + H / 2, Min(L.Radius, W * Weight * 0.6), H * 0.80, Ink, 0.25);
  for I := 1 to Length(Text) do
  begin
    Ch := Text[I];
    Advance := W;
    if CharInSet(Ch, [':', '.']) then Advance := W * 0.38;
    if (S.Style = csFlip) and (Ch <> ':') then
    begin
      if Unlit then
        C.Panel(X - Gap * 0.32, Y - 6, Advance + Gap * 0.64, H + 12, 5,
          Shade(Face, 1.20), Face, Shade(Face, 0.66));
      if Flipping and (Previous[I] <> Ch) then
      begin
        // 旧板の上半分が閉じてから新板の下半分が降りる。
        C.PushClip(X, Y, Advance, H * 0.5);
        try Glyph(C, Ch, X, Y, Advance, H, Ink, Display);
        finally C.PopClip end;
        C.PushClip(X, Y + H * 0.5, Advance, H * 0.5);
        try Glyph(C, Previous[I], X, Y, Advance, H, Ink, Display);
        finally C.PopClip end;
        Part := H * 0.5 * Abs(Cos(Phase * Pi));
        if Part > 0.5 then
        begin
          if Phase < 0.5 then
          begin
            C.Box(X, Y + H * 0.5 - Part, Advance, Part, 1, Shade(Face, 0.86));
            C.PushClip(X, Y + H * 0.5 - Part, Advance, Part);
            try Glyph(C, Previous[I], X, Y + H * 0.5 - Part, Advance, Part * 2, Ink, Display);
            finally C.PopClip end;
          end
          else
          begin
            C.Box(X, Y + H * 0.5, Advance, Part, 1, Shade(Face, 1.04));
            C.PushClip(X, Y + H * 0.5, Advance, Part);
            try Glyph(C, Ch, X, Y + H * 0.5 - Part, Advance, Part * 2, Ink, Display);
            finally C.PopClip end;
          end;
        end;
      end
      else Glyph(C, Ch, X, Y, Advance, H, Ink, Display);
      if Unlit then
        C.Line(X - Gap * 0.22, Y + H * 0.5, X + Advance + Gap * 0.22,
          Y + H * 0.5, 2, Shade(Face, 0.42));
    end
    else if (Ch <> ':') or Blink then Glyph(C, Ch, X, Y, Advance, H, Ink, Display, Unlit);
    X := X + Advance + Gap;
  end;
  if Meridiem <> '' then
    VectorText(C, Meridiem, L.X + L.Radius * 0.68, Y + H + 27, 18, Ink);
  if not UsesCountdown(S) and (S.Style in [csDigitalWatch, csDigital24]) then
  begin
    LabelText := Format('%.4d-%.2d-%.2d', [T.Year, T.Month, T.Day]);
    VectorText(C, LabelText, L.X, Y + H + 26, 16, Ink);
  end;
end;

end.

