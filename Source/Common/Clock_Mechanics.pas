unit Clock_Mechanics;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 振り子、鳩、目覚ましベル、歯車と砂時計の可動部を直接時刻から描画する。

interface

uses Clock_Canvas, Clock_Settings, Clock_Timeline;

procedure DrawMechanism(C: TClockCanvas; const S: TClockSettings;
  const L: TClockLayout; const T: TClockTime);
procedure DrawHourglassBase(C: TClockCanvas; const S: TClockSettings; const L: TClockLayout);
procedure DrawSand(C: TClockCanvas; const S: TClockSettings;
  const L: TClockLayout; const T: TClockTime);

implementation

uses System.Math, Winapi.D2D1;

function AlarmAge(const S: TClockSettings; const T: TClockTime): Double;
begin
  if not S.Alarm then Exit(1E9);
  Result := EventAge(T.DaySeconds, S.Values[ctAlarmHour] * 3600 +
    S.Values[ctAlarmMinute] * 60, 86400, T.Speed);
end;

procedure Bell(C: TClockCanvas; X, Y, Angle: Single; Color: Cardinal);
var
  Points: array[0..26] of TD2D1Point2F;
  I: Integer;
  A: Single;
begin
  for I := 0 to 24 do
  begin
    A := I * Pi / 24;
    Points[I] := Pt(X + 56 * Cos(A) * Cos(Angle) + 40 * Sin(A) * Sin(Angle),
      Y + 56 * Cos(A) * Sin(Angle) - 40 * Sin(A) * Cos(Angle));
  end;
  Points[25] := Pt(Points[24].X - 4 * Sin(Angle), Points[24].Y + 4 * Cos(Angle));
  Points[26] := Pt(Points[0].X - 4 * Sin(Angle), Points[0].Y + 4 * Cos(Angle));
  C.Polygon(Points, Shade(Color, 1.05));
  C.StrokePath(Slice(Points, 25), 5, Shade(Color, 1.46));
  C.Line(Points[25].X, Points[25].Y, Points[26].X, Points[26].Y, 6, Shade(Color, 0.46));
  C.Oval(X - 8, Y - 25, 17, 4, $FFFFFF, 0.20);
end;

procedure Gear(C: TClockCanvas; X, Y, R, Turn: Single; Teeth: Integer; Metal: Cardinal);
const
  TOOTH_RADIUS: array[0..3] of Single = (0.88, 1, 1, 0.88);
var
  Points: array[0..127] of TD2D1Point2F;
  I: Integer;
  A: Single;
  P, Q: TD2D1Point2F;
begin
  for I := 0 to Teeth * 4 - 1 do
    Points[I] := Polar(X, Y, R * TOOTH_RADIUS[I mod 4], Turn + I * Pi / (2 * Teeth));
  C.Polygon(Slice(Points, Teeth * 4), Shade(Metal, 0.66));
  C.StrokePath(Slice(Points, Teeth * 4), 1.7, Shade(Metal, 1.3), 0.85, True);
  C.Disc(X, Y, R * 0.82, R * 0.82, Shade(Metal, 1.54), Metal, Shade(Metal, 0.42));
  C.Ring(X, Y, R * 0.64, R * 0.64, 3, Shade(Metal, 0.55), 0.85);
  for I := 0 to 5 do
  begin
    A := Turn + I * Pi / 3;
    P := Polar(X, Y, R * 0.45, A);
    Q := Polar(X, Y, R * 0.45, A + 0.26);
    C.Line(P.X + 1, P.Y + 1, Q.X + 1, Q.Y + 1, R * 0.23, Shade(Metal, 1.38));
    C.Line(P.X, P.Y, Q.X, Q.Y, R * 0.23, Shade(Metal, 0.25));
  end;
  C.Disc(X, Y, R * 0.21, R * 0.21, Shade(Metal, 1.53), Metal, Shade(Metal, 0.49));
  C.Line(X - R * 0.11, Y, X + R * 0.11, Y, 2, Shade(Metal, 0.45));
end;

procedure DrawMechanism(C: TClockCanvas; const S: TClockSettings;
  const L: TClockLayout; const T: TClockTime);
var
  X, Y, Swing, Angle, Progress, DoorWidth, Beak: Single;
  Age: Double;
  Body, Metal, Ink: Cardinal;
begin
  X := L.X; Y := L.Y;
  Body := S.Colors[0];
  Ink := S.Colors[2];
  Metal := Mix(Body, $E6C677, 0.64);
  case S.Style of
    csPendulum:
      begin
        Angle := Sin(PositiveMod(T.RealSeconds, 2) * Pi) * 0.24;
        Swing := Sin(Angle) * 224;
        Y := 421 + Cos(Angle) * 224;
        C.Line(X, 421, X + Swing, Y, 8, Shade(Metal, 0.70));
        C.Line(X - 1, 421, X + Swing - 1, Y, 2, Shade(Metal, 1.38));
        C.Disc(X + Swing, Y, 43, 43, Shade(Metal, 1.5), Metal, Shade(Metal, 0.47));
        C.Ring(X + Swing, Y, 34, 34, 2, Shade(Metal, 1.26));
        C.Oval(X + Swing - 9, Y - 11, 12, 6, $FFFFFF, 0.19);
      end;
    csCuckoo:
      begin
        Age := EventAge(T.DaySeconds, 0, 3600, T.Speed);
        Progress := EnsureRange(Min(Age / 0.45, (3.1 - Age) / 0.55), 0.0, 1.0);
        if (Progress <= 0) and (S.Mode <> cmFull) then Exit;
        if S.Mode <> cmDisplay then
        begin
          C.Panel(X - 47, 121, 94, 75, 13, Shade(Body, 0.48), Shade(Body, 0.20), Shade(Body, 0.42));
          C.BoxEdge(X - 47, 121, 94, 75, 13, 3, Shade(Body, 1.30));
        end;
        DoorWidth := 42 * (1 - 0.86 * Progress);
        if (S.Mode <> cmDisplay) or (Progress > 0) then
        begin
          C.Panel(X - 43, 125, DoorWidth, 67, 4, Shade(Body, 1.34), Body, Shade(Body, 0.68));
          C.Panel(X + 43 - DoorWidth, 125, DoorWidth, 67, 4, Shade(Body, 1.24), Body, Shade(Body, 0.68));
        end;
        if Progress <= 0.12 then Exit;
        X := X - 19 + Progress * 20;
        Y := 188 - Progress * 25 + Sin(PositiveMod(Age, 0.55) * 2 * Pi / 0.55) * 2;
        C.Oval(X - 8, Y + 13, 23 * Progress, 12 * Progress, Shade(Ink, 1.48));
        C.Oval(X - 12, Y + 12, 15 * Progress, 7 * Progress, Shade(Ink, 1.20));
        C.Disc(X + 8, Y, 12 * Progress, 12 * Progress, Shade(Metal, 1.45), Metal, Shade(Metal, 0.60));
        C.Oval(X + 12, Y - 3, 2.2, 2.2, $221E18);
        Beak := 13 * Progress;
        C.Polygon([Pt(X + 17, Y - 1), Pt(X + 17 + Beak, Y + 2), Pt(X + 17, Y + 5)], Shade(Metal, 1.24));
      end;
    csAlarm:
      begin
        Age := AlarmAge(S, T);
        if (S.Mode <> cmFull) and (Age >= 5) then Exit;
        Angle := 0;
        if Age < 5 then Angle := Sin(PositiveMod(T.RealSeconds, 0.083) * 2 * Pi / 0.083) * 0.12;
        Bell(C, X - 129, 118, -0.44 + Angle, Body);
        Bell(C, X + 129, 118, 0.44 - Angle, Body);
        if Age < 5 then
        begin
          C.Line(X - 171, 66, X - 161, 49, 3, Metal, 0.76);
          C.Line(X + 171, 66, X + 161, 49, 3, Metal, 0.76);
        end;
      end;
    csSkeleton:
      begin
        Angle := PositiveMod(T.Elapsed, 18) * (2 * Pi / 18);
        Gear(C, X - 67, Y - 24, 74, Angle, 24, Metal);
        Gear(C, X + 50, Y - 27, 49, -Angle * 1.5 + 0.08, 16, Mix(Metal, $AB6E44, 0.52));
        Gear(C, X + 31, Y + 76, 62, Angle * 1.2, 20, Shade(Metal, 1.18));
      end;
  end;
end;

function VesselWidth(Height: Single): Single;
begin
  Result := 5 + 119 * Sin(Abs(Height) / 176 * Pi / 2);
end;

function Vessel(const L: TClockLayout): TArray<TD2D1Point2F>;
var
  I: Integer;
  Y, W: Single;
begin
  SetLength(Result, 66);
  for I := 0 to 32 do
  begin
    Y := -176 + I * 11;
    W := VesselWidth(Y);
    Result[I] := Pt(L.X + W, L.Y + Y);
    Result[65 - I] := Pt(L.X - W, L.Y + Y);
  end;
end;

procedure DrawHourglassBase(C: TClockCanvas; const S: TClockSettings; const L: TClockLayout);
var
  Frame: Cardinal;
  Shape: TArray<TD2D1Point2F>;
  I: Integer;
begin
  if S.Mode = cmDisplay then Exit;
  Frame := S.Colors[0];
  Shape := Vessel(L);
  if S.Mode = cmFull then
  begin
    for I in [-1, 1] do
    begin
      C.Panel(L.X + I * 133 - 12, 108, 24, 384, 11, Shade(Frame, 1.45), Frame, Shade(Frame, 0.42));
      C.Line(L.X + I * 133 - 4, 127, L.X + I * 133 - 4, 476, 1.6, $EBCD9F, 0.5);
      C.Panel(42, L.Y + I * 196 - 22, 316, 44, 15, Shade(Frame, 1.46), Frame, Shade(Frame, 0.46));
      C.Line(67, L.Y + I * 196 - 11, 333, L.Y + I * 196 - 11, 1.8, Shade(Frame, 1.40), 0.63);
    end;
  end;
  C.Polygon(Shape, S.Colors[1], 0.14);
  C.StrokePath(Shape, 4, Shade(S.Colors[1], 1.26), 0.77, True);
end;

procedure DrawSand(C: TClockCanvas; const S: TClockSettings;
  const L: TClockLayout; const T: TClockTime);
var
  Fraction, Top, Pile, Y, W, Phase, X, Density: Single;
  Points: array[0..42] of TD2D1Point2F;
  I: Integer;
  Sand, GlassInk: Cardinal;
begin
  Fraction := 0;
  if T.Duration > 0 then Fraction := EnsureRange(T.Remaining / T.Duration, 0.0, 1.0);
  Sand := S.Colors[2];
  GlassInk := Shade(S.Colors[1], 1.4);
  if Fraction > 0.0001 then
  begin
    Top := -169 * Sqrt(Fraction);
    for I := 0 to 20 do
    begin
      Y := Top * (1 - I / 20);
      W := Max(2, VesselWidth(Y) - 3.5);
      Points[I] := Pt(L.X + W, L.Y + Y);
      Points[41 - I] := Pt(L.X - W, L.Y + Y);
    end;
    C.Polygon(Slice(Points, 42), Sand, 0.91);
    W := VesselWidth(Top) - 4;
    C.Oval(L.X, L.Y + Top, W, Min(5.0, W * 0.15), Shade(Sand, 1.25), 0.85);
    for I := 0 to 61 do
    begin
      Y := Top * (1 - ((I * 31) mod 97) / 97);
      W := VesselWidth(Y) - 5;
      X := (2 * ((I * 43) mod 89) / 89 - 1) * W;
      C.Oval(L.X + X, L.Y + Y, 1.1, 1.1, Shade(Sand, 1.37), 0.54);
    end;
  end;
  Pile := Sqrt(1 - Fraction);
  if Pile > 0.0001 then
  begin
    W := Pile * 116;
    Top := Pile * 93;
    for I := 0 to 40 do
    begin
      X := (I / 20 - 1) * W;
      Y := 172 - Top * Power(1 - Abs(I / 20 - 1), 1.12);
      Points[I] := Pt(L.X + X, L.Y + Y);
    end;
    C.Polygon(Slice(Points, 41), Shade(Sand, 0.85));
    C.StrokePath(Slice(Points, 41), 2.2, Shade(Sand, 1.40), 0.75);
    for I := 0 to 65 do
    begin
      X := (2 * ((I * 43) mod 89) / 89 - 1) * W;
      Y := 171 - Top * Power(Max(0.0, 1 - Abs(X) / W), 1.12) * (((I * 31) mod 97) / 97);
      C.Oval(L.X + X, L.Y + Y, 1.2, 1.2, Shade(Sand, 1.4), 0.51);
    end;
  end;
  if (Fraction > 0) and (T.Duration > 0) and (T.Elapsed >= 0) then
  begin
    Density := 3 + 4 * Pile;
    for I := 0 to 24 do
    begin
      Phase := PositiveMod(T.Elapsed * 2 + I / 25, 1);
      Y := (172 - Pile * 93) * Sqr(Phase);
      X := Sin(I * 2.41) * Density * Phase;
      C.Oval(L.X + X, L.Y + Y, 1.2, 1.6, Shade(Sand, 1.28), 0.80);
    end;
  end;
  if S.Mode <> cmDisplay then
  begin
    C.StrokePath([Pt(L.X - 96, L.Y - 158), Pt(L.X - 88, L.Y - 129),
      Pt(L.X - 57, L.Y - 80), Pt(L.X - 26, L.Y - 40)], 6, GlassInk, 0.42);
    C.StrokePath([Pt(L.X + 23, L.Y + 40), Pt(L.X + 51, L.Y + 74),
      Pt(L.X + 85, L.Y + 129), Pt(L.X + 93, L.Y + 155)], 5, GlassInk, 0.36);
  end;
end;

end.

