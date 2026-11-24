unit Clock_Timeline;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// ホストから取得した倍率カーブと基準日時を、任意フレームの表示状態へ変換する。

interface

uses AviUtl2FilterTypes, Clock_Settings;

type
  TClockTime = record
    RealSeconds, FrameSeconds, Speed, Elapsed: Double;
    DaySeconds, Remaining, Duration, Stopwatch: Double;
    Year, Month, Day, Hour, Minute, Second: Word;
  end;

// Frame はオブジェクトの先頭を 0 とする。Edit と Obj は呼出中だけ借用する。
function EvaluateClock(const S: TClockSettings; Scene: PSCENE_INFO;
  Obj: POBJECT_INFO; Edit: PEDIT_SECTION; Frame: Double): TClockTime;
function PositiveMod(Value, Period: Double): Double;
function EventAge(Value, Target, Period, Speed: Double): Double;

implementation

uses System.SysUtils, System.Math, System.DateUtils;

const
  SECONDS_PER_DAY = 86400.0;

function PositiveMod(Value, Period: Double): Double;
begin
  Result := Value - Floor(Value / Period) * Period;
end;

function EventAge(Value, Target, Period, Speed: Double): Double;
begin
  if Speed = 0 then Exit(1E9);
  if Speed > 0 then
    Result := PositiveMod(Value - Target, Period)
  else
    Result := PositiveMod(Target - Value, Period);
  // 高倍率では発生直後の表示時間を伸ばしすぎない。
  Result := Result / Min(4.0, Abs(Speed));
end;

function IntegrateSpeed(const S: TClockSettings; Obj: POBJECT_INFO;
  Edit: PEDIT_SECTION; Frame: Double): Double;
const
  SAMPLES_PER_SECTION = 64;
var
  Info: TTRACK_INFO;
  Count, Index: Integer;
  SectionEnd, SectionStart, LastFrame, Origin, A, B, Sample, Integral: Double;
  IsMoving: Boolean;
  function ReadSpeed(AtFrame: Double; out Value: Double): Boolean;
  begin
    Result := Edit^.GetEffectTrackValue(Obj^.EffectHandle, CLOCK_TRACKS[ctSpeed].Name,
      AtFrame + Origin, @Value);
    if Result then Value := TrackValue(ctSpeed, Value);
  end;
begin
  Result := Frame * Round(S.Values[ctSpeed]);
  if (Frame <= 0) or (Edit = nil) or (Obj = nil) or (Obj^.EffectHandle = nil) then Exit;
  if not Assigned(Edit^.GetEffectTrackValue) then Exit;
  Count := 1;
  if (Obj^.Handle <> nil) and Assigned(Edit^.GetObjectSectionNum) and
    Assigned(Edit^.GetObjectSectionFrame) then
    Count := Max(1, Edit^.GetObjectSectionNum(Obj^.Handle));
  IsMoving := True;
  if Assigned(Edit^.GetEffectTrackInfo) then
  begin
    Info := Default(TTRACK_INFO);
    if Edit^.GetEffectTrackInfo(Obj^.EffectHandle, CLOCK_TRACKS[ctSpeed].Name,
      @Info, SizeOf(Info)) then
      IsMoving := Info.Mode <> nil;
  end;
  if (Count = 1) and not IsMoving then Exit;

  // SDK 編集 API の座標はシーン基準。積分区間はオブジェクト基準に揃える。
  Origin := Obj^.FrameS;
  SectionStart := 0;
  LastFrame := Max(1, Obj^.FrameTotal);
  Integral := 0;
  for Index := 1 to Count do
  begin
    SectionEnd := LastFrame;
    if Index < Count then
      SectionEnd := Edit^.GetObjectSectionFrame(Obj^.Handle, Index) - Origin;
    if SectionEnd <= SectionStart then Continue;
    // 区間ごとに固定の積分格子を使う。部分区間が伸びても過去の評価点は変わらない。
    if not IsMoving then
    begin
      if not ReadSpeed(SectionStart, Sample) then Exit;
      Integral := Integral + Sample * (Min(Frame, SectionEnd) - SectionStart);
    end
    else
    begin
      A := SectionStart;
      while (A < Frame) and (A < SectionEnd) do
      begin
        B := Min(SectionEnd, A + Max(1.0, (SectionEnd - SectionStart) / SAMPLES_PER_SECTION));
        if not ReadSpeed((A + B) * 0.5, Sample) then Exit;
        Integral := Integral + Sample * (Min(Frame, B) - A);
        A := B;
      end;
    end;
    SectionStart := SectionEnd;
    if SectionStart >= Frame then Break;
  end;
  if SectionStart < Frame then
    Integral := Integral + (Frame - SectionStart) * Round(S.Values[ctSpeed]);
  Result := Integral;
end;

function EvaluateClock(const S: TClockSettings; Scene: PSCENE_INFO;
  Obj: POBJECT_INFO; Edit: PEDIT_SECTION; Frame: Double): TClockTime;
var
  Y, M, D: Word;
  Anchor, Offset, MaxSeconds: Double;
  BaseDays, Days, WholeSecond: Int64;
begin
  Result := Default(TClockTime);
  if (Scene <> nil) and (Scene^.Rate > 0) and (Scene^.Scale > 0) then
    Result.FrameSeconds := Scene^.Scale / Scene^.Rate
  else
    Result.FrameSeconds := 1 / 30;
  Frame := Max(0.0, Frame);
  Result.RealSeconds := Frame * Result.FrameSeconds;
  Result.Speed := Round(S.Values[ctSpeed]);
  Result.Elapsed := IntegrateSpeed(S, Obj, Edit, Frame) * Result.FrameSeconds;
  Result.Duration := Round(S.Values[ctHour]) * 3600 +
    Round(S.Values[ctMinute]) * 60 + Round(S.Values[ctSecond]);
  Result.Remaining := Max(0.0, Result.Duration - Result.Elapsed);
  Result.Stopwatch := Max(0.0, Result.Duration + Result.Elapsed);

  Y := Round(S.Values[ctYear]);
  M := Round(S.Values[ctMonth]);
  D := Min(Round(S.Values[ctDay]), DaysInAMonth(Y, M));
  Anchor := EncodeDate(1, 1, 1);
  BaseDays := Round(EncodeDate(Y, M, D) - Anchor);
  Offset := Result.Elapsed + Min(23, Round(S.Values[ctHour])) * 3600 +
    Round(S.Values[ctMinute]) * 60 + Round(S.Values[ctSecond]);
  MaxSeconds := (EncodeDate(9999, 12, 31) - Anchor - BaseDays + 1) * SECONDS_PER_DAY - 0.001;
  Offset := EnsureRange(Offset, -BaseDays * SECONDS_PER_DAY, MaxSeconds);
  Days := Floor(Offset / SECONDS_PER_DAY);
  // 日付と小数秒を別々に保持し、基準年の大きさによる精度低下を抑える。
  DecodeDate(Anchor + BaseDays + Days, Result.Year, Result.Month, Result.Day);
  Result.DaySeconds := Offset - Days * SECONDS_PER_DAY;
  WholeSecond := Min(Int64(86399), Floor(Result.DaySeconds + 0.00000001));
  Result.Hour := WholeSecond div 3600;
  Result.Minute := WholeSecond mod 3600 div 60;
  Result.Second := WholeSecond mod 60;
end;

end.

