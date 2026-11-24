unit Clock_Analog;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// アナログ時計の筐体、目盛、文字盤と時針・分針・秒針を描画する。

interface

uses Clock_Canvas, Clock_Settings, Clock_Timeline;

procedure DrawAnalogBase(C: TClockCanvas; const S: TClockSettings; const L: TClockLayout);
procedure DrawAnalogHands(C: TClockCanvas; const S: TClockSettings;
  const L: TClockLayout; const T: TClockTime);

implementation

uses System.Math, System.SysUtils, Winapi.D2D1, Clock_Glyphs;

const
  ROMANS: array[1..12] of string = ('I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII');
  STOPWATCH_SUBDIAL_Y = 0.39;
  STOPWATCH_SUBDIAL_RADIUS = 0.245;

procedure Bezel(C: TClockCanvas; X, Y, R: Single; Color: Cardinal; Ornate: Boolean);
begin
  C.Disc(X, Y + 4, R + 22, R + 22, Shade(Color, 0.64), Shade(Color, 0.51), Shade(Color, 0.19));
  C.Disc(X, Y, R + 22, R + 20, Shade(Color, 1.48), Color, Shade(Color, 0.5));
  C.Ring(X, Y, R + 17, R + 17, 1.6, Shade(Color, 1.52), 0.75);
  C.Ring(X, Y, R + 6, R + 6, 5, Shade(Color, 0.48));
  if Ornate then
  begin
    C.Ring(X, Y, R + 13, R + 13, 2, Shade(Color, 1.43));
    C.Ring(X, Y, R + 10, R + 10, 1, Shade(Color, 0.57));
  end;
end;

procedure Screw(C: TClockCanvas; X, Y, R: Single; Color: Cardinal);
begin
  C.Disc(X, Y, R, R, Shade(Color, 1.62), Color, Shade(Color, 0.52));
  C.Line(X - R * 0.52, Y + R * 0.43, X + R * 0.52, Y - R * 0.43, 1.4, Shade(Color, 0.42));
end;

procedure Wood(C: TClockCanvas; X, Y, W, H, Radius: Single; Color: Cardinal; Vertical: Boolean);
var
  I: Integer;
  P, Delta: Single;
begin
  C.Panel(X, Y, W, H, Radius, Shade(Color, 1.23), Color, Shade(Color, 0.44));
  for I := 1 to 27 do
  begin
    P := I / 28;
    Delta := Sin(I * 2.35) * 4;
    if Vertical then
      C.StrokePath([Pt(X + W * P, Y + 14), Pt(X + W * P + Delta, Y + H * 0.38),
        Pt(X + W * P - Delta, Y + H * 0.70), Pt(X + W * P, Y + H - 15)],
        1.4, Shade(Color, 1.28), 0.18)
    else
      C.StrokePath([Pt(X + 16, Y + H * P), Pt(X + W * 0.40, Y + H * P + Delta),
        Pt(X + W * 0.73, Y + H * P - Delta), Pt(X + W - 16, Y + H * P)],
        1.2, Shade(Color, 0.36), 0.20);
  end;
  C.BoxEdge(X + 5, Y + 5, W - 10, H - 10, Radius, 1.4, Shade(Color, 1.37), 0.75);
end;

procedure DrawCase(C: TClockCanvas; const S: TClockSettings; const L: TClockLayout);
var
  X, Y, R, D: Single;
  Body, Metal: Cardinal;
  I: Integer;
  P: TD2D1Point2F;
begin
  X := L.X; Y := L.Y; R := L.Radius;
  Body := S.Colors[0];
  Metal := Mix(Body, $C4BC9F, 0.55);
  case S.Style of
    csSquare:
      begin
        C.Box(34, 39, 444, 442, 35, Shade(Body, 0.28));
        C.Panel(34, 31, 444, 442, 35, Shade(Body, 1.60), Body, Shade(Body, 0.42));
        C.BoxEdge(41, 38, 430, 428, 29, 1.3, Shade(Body, 1.66));
        C.BoxEdge(51, 47, 410, 414, 24, 3, Shade(Body, 0.43));
        for I := 0 to 3 do
          Screw(C, 51 + (I mod 2) * 410, 49 + (I div 2) * 404, 4.7, Metal);
      end;
    csAntique:
      begin
        C.Disc(X, Y, R + 47, R + 47, Shade(Body, 1.34), Body, Shade(Body, 0.30));
        C.Ring(X, Y, R + 40, R + 40, 4, Shade(Body, 0.45));
        for I := 0 to 95 do
        begin
          P := Polar(X, Y, R + 34, I * Pi / 48);
          C.Oval(P.X, P.Y, 2.4, 2.4, Shade(Metal, 1.31));
        end;
        Bezel(C, X, Y, R, Metal, True);
      end;
    csModern:
      begin
        C.Disc(X, Y + 2, R + 17, R + 17, Shade(Body, 1.44), Body, Shade(Body, 0.39));
        C.Ring(X, Y, R + 13, R + 13, 1.5, Shade(Body, 1.38));
        C.Ring(X, Y, R + 3, R + 3, 2, Shade(Body, 0.5));
      end;
    csAlarm:
      begin
        C.Line(X - 126, Y + 133, X - 165, Y + 213, 21, Metal);
        C.Line(X + 126, Y + 133, X + 165, Y + 213, 21, Metal);
        C.Ring(X, 58, 35, 38, 9, Shade(Metal, 1.39));
        C.Box(X - 12, 78, 24, 77, 6, Metal);
        Bezel(C, X, Y, R, Body, False);
      end;
    csPendulum:
      begin
        Wood(C, 38, 62, 356, 696, 20, Body, True);
        C.Panel(22, 35, 388, 43, 12, Shade(Body, 1.31), Body, Shade(Body, 0.53));
        C.Panel(22, 746, 388, 38, 10, Shade(Body, 1.22), Body, Shade(Body, 0.49));
        C.Panel(X - 107, 394, 214, 329, 42, Shade(Body, 0.44), Shade(Body, 0.26), Shade(Body, 0.12));
        C.BoxEdge(X - 108, 393, 216, 332, 42, 4, Metal, 0.75);
        Bezel(C, X, Y, R, Metal, True);
      end;
    csCuckoo:
      begin
        Wood(C, 80, 173, 360, 353, 16, Body, False);
        C.Polygon([Pt(36, 194), Pt(X, 47), Pt(484, 194), Pt(453, 212),
          Pt(X, 97), Pt(67, 212)], Shade(Body, 0.43));
        C.StrokePath([Pt(48, 182), Pt(X, 38), Pt(472, 182)], 15, Shade(Body, 1.29));
        C.StrokePath([Pt(63, 198), Pt(X, 62), Pt(457, 198)], 4, Shade(Metal, 1.36), 0.69);
        Wood(C, 149, 524, 222, 33, 8, Body, False);
        Bezel(C, X, Y, R, Shade(Body, 1.23), True);
        for I := 0 to 1 do
        begin
          D := -56 + I * 112;
          C.Line(X + D, 554, X + D, 595 + I * 18, 3, Metal);
          C.Disc(X + D, 602 + I * 18, 12, 21, Shade(Metal, 1.42), Metal, Shade(Metal, 0.42));
        end;
      end;
    csWatch:
      begin
        C.Panel(X - 82, 16, 164, 748, 32, Shade(Body, 1.14), Shade(Body, 0.52), Shade(Body, 0.38));
        for I := 0 to 24 do
        begin
          if Abs(30 + I * 30 - Y) < R then Continue;
          C.Box(X - 75, 28 + I * 30, 150, 25, 8, Shade(Body, 0.69));
          C.Line(X - 56, 30 + I * 30, X + 56, 30 + I * 30, 1, Shade(Body, 1.30));
        end;
        C.Panel(X + 164, Y - 23, 31, 46, 7, Shade(Metal, 1.38), Metal, Shade(Metal, 0.4));
        Bezel(C, X, Y, R, Metal, True);
      end;
    csPocket, csStopwatch:
      begin
        if S.Style = csStopwatch then Metal := Mix(Body, $DCE2E7, 0.55);
        C.Ring(X, 67, 34, 39, 13, Metal);
        C.Ring(X, 67, 34, 39, 3, Shade(Metal, 1.48));
        C.Panel(X - 25, 99, 50, 39, 9, Shade(Metal, 1.63), Metal, Shade(Metal, 0.52));
        for I := -4 to 4 do C.Line(X + I * 4, 104, X + I * 4, 131, 1.5, Shade(Metal, 0.57));
        Bezel(C, X, Y, R + 8, Body, True);
        C.Ring(X, Y, R + 2, R + 2, 3, Shade(Metal, 1.4));
      end;
    csSkeleton:
      begin
        Bezel(C, X, Y, R, Body, True);
        for I := 0 to 7 do
        begin
          P := Polar(X, Y, R + 12, I * Pi / 4);
          Screw(C, P.X, P.Y, 4, Body);
        end;
      end;
    csStation:
      begin
        C.Panel(X - 19, 14, 38, 134, 7, Shade(Body, 1.34), Body, Shade(Body, 0.43));
        C.Panel(X - 54, 12, 108, 26, 6, Shade(Body, 1.38), Body, Shade(Body, 0.46));
        C.Box(X - 39, Y - R - 39, 78, 38, 7, Shade(Body, 0.51));
        C.Box(X - R - 30, Y - R - 18, 2 * R + 60, 2 * R + 50, 15, Shade(Body, 0.28));
        C.Panel(X - R - 27, Y - R - 27, 2 * R + 54, 2 * R + 50, 14,
          Shade(Body, 1.34), Body, Shade(Body, 0.54));
        C.BoxEdge(X - R - 22, Y - R - 22, 2 * R + 44, 2 * R + 40, 11,
          1.4, Shade(Body, 1.62), 0.65);
        C.Box(X - R - 8, Y - R - 8, 2 * R + 16, 2 * R + 16, 43, Shade(Body, 0.54));
        C.Line(X - R + 10, Y + R + 15, X + R - 10, Y + R + 15, 1.6, Shade(Body, 1.43));
        for I in [-1, 1] do
        begin
          Screw(C, X + I * (R + 12), Y - R - 12, 3.2, Body);
          Screw(C, X + I * (R + 12), Y + R + 11, 3.2, Body);
        end;
      end;
    csBroadcast:
      begin
        C.Disc(X, Y + 5, R + 99, R + 29, Shade(Body, 0.64), Shade(Body, 0.50), Shade(Body, 0.32));
        C.Disc(X, Y, R + 99, R + 28, Shade(Body, 1.43), Body, Shade(Body, 0.62));
        C.Ring(X, Y, R + 94, R + 23, 1.5, Shade(Body, 1.46), 0.70);
        C.Ring(X, Y, R + 8, R + 8, 6, Shade(Body, 0.56), 0.90);
        C.Ring(X, Y, R + 4, R + 4, 1.4, Shade(Body, 1.54), 0.79);
      end;
    csTower:
      begin
        C.Polygon([Pt(39, 241), Pt(X, 28), Pt(461, 241), Pt(437, 266), Pt(63, 266)], Shade(Body, 0.41));
        C.StrokePath([Pt(47, 240), Pt(X, 36), Pt(453, 240)], 10, Shade(Body, 1.32));
        C.Panel(68, 241, 364, 572, 5, Shade(Body, 1.38), Body, Shade(Body, 0.57));
        for I := 0 to 16 do
        begin
          C.Line(71, 252 + I * 33, 429, 252 + I * 33, 2, Shade(Body, 0.48), 0.67);
          C.Line(140 + (I mod 2) * 53, 252 + I * 33, 140 + (I mod 2) * 53,
            283 + I * 33, 2, Shade(Body, 0.48), 0.67);
          C.Line(296 + (I mod 2) * 53, 252 + I * 33, 296 + (I mod 2) * 53,
            283 + I * 33, 2, Shade(Body, 0.48), 0.67);
        end;
        C.Panel(51, 795, 398, 47, 6, Shade(Body, 1.35), Body, Shade(Body, 0.48));
        for I := -1 to 1 do
          C.Panel(X + I * 82 - 22, 617, 44, 131, 22, Shade(Body, 0.32), Shade(Body, 0.46), Shade(Body, 0.65));
        Bezel(C, X, Y, R, Metal, True);
      end;
    else Bezel(C, X, Y, R, Body, False);
  end;
end;

procedure DrawStopwatchSubdial(C: TClockCanvas; X, Y, Radius: Single; Ink: Cardinal);
var
  I: Integer;
  Angle, TickLength: Single;
  Outer, Inner, LabelPosition: TD2D1Point2F;
begin
  C.Ring(X, Y, Radius, Radius, 0.9, Ink, 0.44);
  for I := 1 to 30 do
  begin
    Angle := I * Pi / 15;
    Outer := Polar(X, Y, Radius - 2, Angle);
    TickLength := 3.5;
    if I mod 5 = 0 then TickLength := 6;
    Inner := Polar(X, Y, Radius - 2 - TickLength, Angle);
    C.Line(Outer.X, Outer.Y, Inner.X, Inner.Y, 1, Ink, 0.77);
    if I mod 5 <> 0 then Continue;
    LabelPosition := Polar(X, Y, Radius * 0.63, Angle);
    VectorText(C, IntToStr(I), LabelPosition.X, LabelPosition.Y, 9.4, Ink, 1.1);
  end;
end;

procedure DrawAnalogBase(C: TClockCanvas; const S: TClockSettings; const L: TClockLayout);
var
  X, Y, R, A, TickLength, Stroke, TickRadius, LabelRadius: Single;
  I, Hour: Integer;
  P, Q: TD2D1Point2F;
  Face, Ink, Tick: Cardinal;

  procedure DrawLabel(const Text: string; Distance, Angle, Height: Single; Roman: Boolean);
  var
    Position: TD2D1Point2F;
    CharacterCount: Integer;
  begin
    CharacterCount := Length(Text);
    // 長い表記ほど斜めの目盛りに近づくため、文字数に応じて内側へ寄せる。
    if CharacterCount > 1 then
      Distance := Distance - R * (0.06 + 0.025 * (CharacterCount - 2));
    Position := Polar(X, Y, Distance, Angle);
    if Roman then
      VectorText(C, Text, Position.X, Position.Y, Height, Ink, 1.0)
    else
      VectorText(C, Text, Position.X, Position.Y, Height, Ink);
  end;

begin
  if S.Mode = cmDisplay then Exit;
  X := L.X; Y := L.Y; R := L.Radius;
  Face := S.Colors[1]; Ink := S.Colors[2];
  if S.Mode = cmFull then DrawCase(C, S, L);
  if S.Style = csSquare then
  begin
    C.Panel(X - 207, Y - 207, 414, 414, 25, Shade(Face, 1.32), Face, Shade(Face, 0.73));
    C.BoxEdge(X - 207, Y - 207, 414, 414, 25, 3, Shade(Face, 0.59));
  end
  else if S.Style = csStation then
  begin
    C.Panel(X - R, Y - R, R * 2, R * 2, 38, Shade(Face, 1.30), Face, Shade(Face, 0.75));
    C.BoxEdge(X - R + 3, Y - R + 3, R * 2 - 6, R * 2 - 6, 35, 2, Shade(Face, 0.60), 0.72);
  end
  else if S.Style = csSkeleton then
  begin
    C.Oval(X, Y, R, R, Face);
    C.Ring(X, Y, R - 21, R - 21, 32, Shade(Face, 1.10));
    C.Ring(X, Y, R - 38, R - 38, 1.5, Shade(Face, 1.48));
  end
  else
  begin
    C.Disc(X, Y, R, R, Shade(Face, 1.50), Face, Shade(Face, 0.78));
    C.Ring(X, Y, R - 3, R - 3, 3, Shade(Face, 0.65), 0.63);
  end;

  if S.Style in [csAntique, csPendulum, csPocket, csTower, csStopwatch] then
    C.Ring(X, Y, R - 16, R - 16, 1.2, Ink, 0.50);

  for I := 0 to 59 do
  begin
    A := I * Pi / 30;
    TickLength := R * 0.038;
    Stroke := 1.3;
    Tick := Mix(Face, Ink, 0.68);
    if I mod 5 = 0 then
    begin
      TickLength := R * 0.095;
      Stroke := 3.0;
      Tick := Ink;
    end;
    if (S.Style = csBroadcast) and (I mod 5 = 0) and (I mod 15 <> 0) then
    begin
      P := Polar(X, Y, R - 16, A);
      C.Oval(P.X, P.Y, 4.2, 4.2, Ink);
      Continue;
    end;
    if S.Style = csStation then
    begin
      // 太い時目盛りを残し、分目盛りは数字より控えめにする。
      TickLength := TickLength * 0.75;
      if I mod 5 = 0 then Stroke := 4.1;
    end
    else if S.Style = csModern then
    begin
      if I mod 5 <> 0 then Continue;
      Stroke := 7;
      if I mod 15 = 0 then TickLength := TickLength * 1.65;
    end;
    TickRadius := R - 12;
    if S.Style = csSquare then
      TickRadius := (R - 7) / Max(Abs(Sin(A)), Abs(Cos(A)));
    P := Polar(X, Y, TickRadius, A);
    Q := Polar(X, Y, TickRadius - TickLength, A);
    C.Line(P.X, P.Y, Q.X, Q.Y, Stroke, Tick);
  end;

  if not (S.Style in [csModern, csSkeleton, csStopwatch]) then
    for Hour := 1 to 12 do
    begin
      LabelRadius := R * 0.74;
      if S.Style = csSquare then
        LabelRadius := (R - 37) / Max(Abs(Sin(Hour * Pi / 6)), Abs(Cos(Hour * Pi / 6)));
      if (S.Style in [csWatch, csBroadcast]) and (Hour mod 3 <> 0) then Continue;
      if S.Style = csStation then
        DrawLabel(IntToStr(Hour), R * 0.73, Hour * Pi / 6, R * 0.17, False)
      else if S.Style = csBroadcast then
        DrawLabel(IntToStr(Hour), R * 0.70, Hour * Pi / 6, R * 0.175, False)
      else if S.Style in [csAntique, csPendulum, csPocket, csTower] then
        DrawLabel(ROMANS[Hour], LabelRadius, Hour * Pi / 6, R * 0.14, True)
      else
        DrawLabel(IntToStr(Hour), LabelRadius, Hour * Pi / 6, R * 0.14, False);
    end;

  if S.Style = csStopwatch then
  begin
    for I := 1 to 12 do
      DrawLabel(IntToStr(I * 5), R * 0.76, I * Pi / 6, 23, False);
    DrawStopwatchSubdial(C, X, Y - R * STOPWATCH_SUBDIAL_Y, R * STOPWATCH_SUBDIAL_RADIUS, Ink);
  end;
end;

procedure DrawAnalogHands(C: TClockCanvas; const S: TClockSettings;
  const L: TClockLayout; const T: TClockTime);
var
  X, Y, R, FrameAdvance, A, HandWidth, SubdialY: Single;
  Time: Double;
  Ink, SecondInk: Cardinal;
  P: TD2D1Point2F;
  procedure Hand(Turn, Length, Width: Single; Color: Cardinal);
  var
    Tip, Shoulder, LeftSide, RightSide, Tail, Highlight, LeftEdge, RightEdge: TD2D1Point2F;
    Angle: Single;
  begin
    Angle := Turn * 2 * Pi;
    Tip := Polar(X, Y, Length, Angle);
    Shoulder := Polar(X, Y, Length * 0.69, Angle);
    Tail := Polar(X, Y, -R * 0.13, Angle);
    LeftSide := Polar(X, Y, Width, Angle - Pi / 2);
    RightSide := Polar(X, Y, Width, Angle + Pi / 2);
    if S.Style = csBroadcast then
    begin
      Shoulder := Polar(X, Y, Length * 0.50, Angle);
      LeftEdge := Polar(Shoulder.X, Shoulder.Y, Width * 0.84, Angle - Pi / 2);
      RightEdge := Polar(Shoulder.X, Shoulder.Y, Width * 0.84, Angle + Pi / 2);
      C.Polygon([Tail, LeftSide, RightSide], Color);
      C.StrokePath([LeftSide, LeftEdge, Tip, RightEdge, RightSide, LeftSide], 2.5, Color);
      Exit;
    end;
    if S.Style in [csAntique, csPocket, csPendulum, csTower] then
    begin
      C.Polygon([Pt(Tail.X + 2, Tail.Y + 3), Pt(LeftSide.X + 2, LeftSide.Y + 3),
        Pt(Shoulder.X + 2, Shoulder.Y + 3), Pt(Tip.X + 2, Tip.Y + 3),
        Pt(RightSide.X + 2, RightSide.Y + 3)], 0, 0.24);
      C.Polygon([Tail, LeftSide, Shoulder, Tip, RightSide], Color);
      C.Oval(Shoulder.X, Shoulder.Y, Width * 0.70, Width * 0.70, Color);
    end
    else if S.Style = csStation then
    begin
      C.Line(Tail.X + 2, Tail.Y + 3, Tip.X + 2, Tip.Y + 3, Width * 1.8, 0, 0.24);
      C.Line(Tail.X, Tail.Y, Tip.X, Tip.Y, Width * 1.8, Color);
    end
    else
    begin
      C.Polygon([Pt(Tail.X + 2, Tail.Y + 3), Pt(LeftSide.X + 2, LeftSide.Y + 3),
        Pt(Tip.X + 2, Tip.Y + 3), Pt(RightSide.X + 2, RightSide.Y + 3)], 0, 0.25);
      C.Polygon([Tail, LeftSide, Tip, RightSide], Color);
    end;
    Highlight := Polar(X, Y, Length * 0.93, Angle);
    C.Line(X, Y, Highlight.X, Highlight.Y, 1.2, Shade(Color, 1.38), 0.76);
  end;
  procedure FastTrail(Period, Length, Stroke: Single; Color: Cardinal);
  var
    Index: Integer;
    Advance, Step, Ang, ShutterOffset: Single;
    Target: TD2D1Point2F;
  begin
    Advance := FrameAdvance / Period;
    if Abs(Advance) < 0.12 then Exit;
    Step := EnsureRange(Advance, -0.85, 0.85);
    ShutterOffset := 0;
    if (Abs(Advance) >= 0.95) and (Abs(Advance - Round(Advance)) < 0.025) then
      ShutterOffset := 0.35 * Sin(PositiveMod(T.RealSeconds, 0.38) * 2 * Pi / 0.38);
    // 主針の角度はそのままに、露光内の残像で高速回転を表す。
    for Index := 1 to 8 do
    begin
      Ang := (PositiveMod(Time, Period) / Period - Step * (Index + ShutterOffset) / 9) * 2 * Pi;
      Target := Polar(X, Y, Length, Ang);
      C.Line(X, Y, Target.X, Target.Y, Stroke, Color, 0.08);
    end;
  end;
begin
  X := L.X; Y := L.Y; R := L.Radius;
  Time := T.DaySeconds;
  if S.Style = csStopwatch then Time := PositiveMod(T.Stopwatch, 43200);
  Ink := S.Colors[2];
  SecondInk := Mix(Ink, $D34131, 0.75);
  if S.Style in [csModern, csWatch, csSkeleton, csTower] then
    SecondInk := Mix(Ink, $E4A650, 0.52)
  else if S.Style in [csStation, csBroadcast, csStopwatch] then
    SecondInk := Ink;
  FrameAdvance := T.Speed * T.FrameSeconds;
  if S.Style <> csStopwatch then
  begin
    FastTrail(43200, R * 0.52, 6, Ink);
    FastTrail(3600, R * 0.77, 5, Ink);
  end
  else if T.Stopwatch = 0 then FrameAdvance := 0;
  FastTrail(60, R * 0.87, 2, SecondInk);
  HandWidth := R * 0.042;
  if S.Style in [csModern, csStation] then HandWidth := HandWidth * 0.65;
  if S.Style = csAlarm then
  begin
    A := (S.Values[ctAlarmHour] + S.Values[ctAlarmMinute] / 60) * Pi / 6;
    P := Polar(X, Y, R * 0.65, A);
    C.Line(X, Y, P.X, P.Y, 3, Shade(Ink, 1.45), 0.57);
  end;
  if S.Style <> csStopwatch then
  begin
    Hand(PositiveMod(Time, 43200) / 43200, R * 0.53, HandWidth, Ink);
    Hand(PositiveMod(Time, 3600) / 3600, R * 0.77, HandWidth * 0.73, Ink);
  end
  else
  begin
    SubdialY := Y - R * STOPWATCH_SUBDIAL_Y;
    A := PositiveMod(T.Stopwatch, 1800) * Pi / 900;
    P := Polar(X, SubdialY, R * STOPWATCH_SUBDIAL_RADIUS * 0.81, A);
    C.Line(X - Sin(A) * 7, SubdialY + Cos(A) * 7, P.X, P.Y, 2.5, Ink);
    C.Disc(X, SubdialY, 3.7, 3.7, Shade(Ink, 1.44), Ink, Shade(Ink, 0.60));
  end;
  A := PositiveMod(Time, 60) * Pi / 30;
  P := Polar(X, Y, R * 0.88, A);
  C.Line(X - Sin(A) * 24, Y + Cos(A) * 24, P.X, P.Y, R * 0.017, SecondInk);
  if S.Style = csBroadcast then
    C.Oval(X, Y, R * 0.048, R * 0.048, Ink)
  else
    C.Disc(X, Y, R * 0.051, R * 0.051, Shade(Ink, 1.61), Ink, Shade(Ink, 0.46));
end;

end.

