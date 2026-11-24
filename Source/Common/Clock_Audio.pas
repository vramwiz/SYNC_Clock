unit Clock_Audio;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// オブジェクトのサンプル位置を使い、時計の効果音を波形から生成する。

interface

uses AviUtl2FilterTypes, Clock_Settings;

// ホストのチャンネルごとに32-bit PCMを渡す。外部音源を使わない。
procedure RenderClockAudio(Audio: PFILTER_PROC_AUDIO; const S: TClockSettings);

implementation

uses System.Math, Clock_Timeline;

function Tone(Frequency, Age: Double): Double;
begin
  Result := Sin(2 * Pi * Frequency * Age);
end;

function ClockSample(const S: TClockSettings; const T: TClockTime;
  Time, Elapsed: Double): Single;
var
  Period, Age, Value, ClockSeconds, Pitch: Double;
  Target: Double;
begin
  Result := 0;
  if (S.Style = csHourglass) or ((T.Speed = 0) and (S.Style <> csPendulum)) then Exit;
  if (Time < 0) or (UsesCountdown(S) and (T.Duration - Elapsed < 0)) then Exit;
  ClockSeconds := T.DaySeconds + (Elapsed - T.Elapsed);
  if UsesCountdown(S) then ClockSeconds := T.Duration - Elapsed;
  if S.Style in [csStopwatch, csDigitalStopwatch] then
  begin
    ClockSeconds := T.Duration + Elapsed;
    if ClockSeconds < 0 then Exit;
  end;

  Period := Max(1.0, Ceil(Abs(T.Speed) / 4.0));
  if UsesCountdown(S) then Age := EventAge(ClockSeconds, 0, Period, -T.Speed)
  else Age := EventAge(ClockSeconds, 0, Period, T.Speed);
  if T.Speed <> 0 then Age := Age * Min(4.0, Abs(T.Speed)) / Abs(T.Speed);
  if S.Style = csPendulum then Age := PositiveMod(Time, 1);
  if (Abs(T.Speed) > 4) and (S.Style <> csPendulum) then
  begin
    // 高速時の連続した鐘やベルを抑え、最大でおよそ毎秒4回の短い音にまとめる。
    if Age < 0.052 then
      Result := Tone(691, Age) * Exp(-92 * Age) * 0.25 * (S.Values[ctVolume] / 100);
    Exit;
  end;
  Value := 0;
  case S.Style of
    csDigitalWatch, csDigital12, csDigital24, csLED12, csLED24:
      begin
        if UsesCountdown(S) then
          Age := EventAge(ClockSeconds, 0, Max(1.0, Period), -T.Speed)
        else
          Age := EventAge(ClockSeconds, 0, Max(60.0, Period), T.Speed);
        if Age < 0.075 then Value := Tone(1175, Age) * (1 - Age / 0.075) * 0.27;
      end;
    csCuckoo:
      begin
        Age := EventAge(ClockSeconds, 0, 3600, T.Speed);
        if (Age >= 0.45) and (Age < 2.5) then
        begin
          Age := PositiveMod(Age - 0.45, 0.67);
          Pitch := 785;
          if Age > 0.13 then Pitch := 587;
          if Age < 0.29 then Value := Tone(Pitch, Age) * Sin(Pi * Age / 0.29) * 0.32;
        end;
      end;
    csAlarm:
      begin
        Target := S.Values[ctAlarmHour] * 3600 + S.Values[ctAlarmMinute] * 60;
        if S.Alarm and (EventAge(ClockSeconds, Target, 86400, T.Speed) < 5) then
        begin
          Age := PositiveMod(Time, 0.105);
          Value := (Tone(1720, Age) + 0.55 * Tone(2290, Age) + 0.28 * Tone(2871, Age)) *
            Exp(-35 * Age) * 0.24;
        end
        else if Age < 0.045 then Value := Tone(805, Age) * Exp(-97 * Age) * 0.21;
      end;
    csPendulum, csTower, csStation:
      begin
        if Age < 0.09 then Value := (Tone(477, Age) + 0.55 * Tone(1311, Age)) * Exp(-66 * Age) * 0.22;
        Age := EventAge(ClockSeconds, 0, 3600, T.Speed);
        if (Abs(T.Speed) <= 4) and (Age < 1.36) then
          Value := Value + (Tone(302, Age) + 0.47 * Tone(532, Age) +
            0.26 * Tone(803, Age)) * Exp(-3.8 * Age) * 0.31;
      end;
    csFlip:
      if Age < 0.085 then Value := (Tone(183, Age) + 0.34 * Tone(1151, Age)) * Exp(-54 * Age) * 0.25;
    else
      if Age < 0.052 then Value := (Tone(691, Age) + 0.44 * Tone(1859, Age)) * Exp(-92 * Age) * 0.25;
  end;
  Result := EnsureRange(Value * (S.Values[ctVolume] / 100), -1.0, 1.0);
end;

procedure RenderClockAudio(Audio: PFILTER_PROC_AUDIO; const S: TClockSettings);
var
  Obj: POBJECT_INFO;
  T, Next: TClockTime;
  I, Channel, SampleRate: Integer;
  Frame, CurrentFrame: Int64;
  Samples: TArray<Single>;
  Time, FramePosition, FramesPerSample, Elapsed: Double;
begin
  Obj := Audio^.Object_;
  if (Obj^.SampleNum <= 0) or (Obj^.SampleNum > 1000000) or
    (Obj^.ChannelNum <= 0) or (Obj^.ChannelNum > 32) then Exit;
  SetLength(Samples, Obj^.SampleNum);
  if S.Sound and (S.Values[ctVolume] > 0) and (S.Style <> csHourglass) and (Audio^.Scene <> nil) then
  begin
    SampleRate := Audio^.Scene^.SampleRate;
    if SampleRate > 0 then
    begin
      FramesPerSample := 30 / SampleRate;
      if (Audio^.Scene^.Rate > 0) and (Audio^.Scene^.Scale > 0) then
        FramesPerSample := Audio^.Scene^.Rate / (Double(Audio^.Scene^.Scale) * SampleRate);
      CurrentFrame := -1;
      for I := 0 to High(Samples) do
      begin
        Time := (Obj^.SampleIndex + I) / SampleRate;
        FramePosition := Max(0.0, (Obj^.SampleIndex + I) * FramesPerSample);
        Frame := Floor(FramePosition);
        if Frame <> CurrentFrame then
        begin
          if (CurrentFrame >= 0) and (Frame = CurrentFrame + 1) then T := Next
          else T := EvaluateClock(S, Audio^.Scene, Obj, Audio^.Edit, Frame);
          Next := EvaluateClock(S, Audio^.Scene, Obj, Audio^.Edit, Frame + 1);
          T.Speed := (Next.Elapsed - T.Elapsed) / T.FrameSeconds;
          if Abs(T.Speed) < 0.000001 then T.Speed := 0;
          CurrentFrame := Frame;
        end;
        Elapsed := T.Elapsed + (Next.Elapsed - T.Elapsed) * (FramePosition - Frame);
        Samples[I] := ClockSample(S, T, Time, Elapsed);
      end;
    end;
  end;
  for Channel := 0 to Obj^.ChannelNum - 1 do
    Audio^.SetSampleData(@Samples[0], Channel);
end;

end.

