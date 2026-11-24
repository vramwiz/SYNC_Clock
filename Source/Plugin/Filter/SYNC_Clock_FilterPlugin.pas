unit SYNC_Clock_FilterPlugin;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 時計演出をメディアオブジェクトとして登録し、映像と音声をホストへ渡す。

interface

uses AviUtl2FilterTypes;

const
  CLOCK_REQUIRED_VERSION = 2011600;

function GetClockFilterTable: PFILTER_PLUGIN_TABLE;

implementation

uses System.SysUtils, System.SyncObjs, Winapi.Windows, PluginFilterTable,
  Clock_Settings, Clock_Timeline, Clock_Renderer, Clock_Audio, Clock_Parameters;

type
  TClockSession = class
    Renderer: TClockRenderer;
    Lock: TCriticalSection;
    constructor Create;
    destructor Destroy; override;
  end;

var
  TableInitialized: Boolean;

constructor TClockSession.Create;
begin
  inherited Create;
  Lock := TCriticalSection.Create;
  Renderer := TClockRenderer.Create;
end;

destructor TClockSession.Destroy;
begin
  Renderer.Free;
  Lock.Free;
  inherited;
end;

function ClockVideo(Video: PFILTER_PROC_VIDEO): Byte; cdecl;
var
  S: TClockSettings;
  T: TClockTime;
  Session: TClockSession;
begin
  Result := 0;
  if (Video = nil) or (Video^.Object_ = nil) or (Video^.UserData = nil) or
    not Assigned(Video^.SetImageData) then Exit;
  try
    S := ReadClockSettings;
    T := EvaluateClock(S, Video^.Scene, Video^.Object_, Video^.Edit, Video^.Object_^.Frame);
    Session := TClockSession(Video^.UserData);
    Session.Lock.Acquire;
    try
      Session.Renderer.Render(S, T, Video^.SetImageData);
      Result := 1;
    finally
      Session.Lock.Release;
    end;
  except
    on E: Exception do OutputDebugString(PWideChar('SYNC_Clock video: ' + E.Message));
  end;
end;

function ClockAudio(Audio: PFILTER_PROC_AUDIO): Byte; cdecl;
begin
  Result := 0;
  if (Audio = nil) or (Audio^.Object_ = nil) or not Assigned(Audio^.SetSampleData) then Exit;
  try
    RenderClockAudio(Audio, ReadClockSettings);
    Result := 1;
  except
    on E: Exception do OutputDebugString(PWideChar('SYNC_Clock audio: ' + E.Message));
  end;
end;

function CreateClock(EffectID: Int64): Pointer; cdecl;
begin
  Result := nil;
  try
    Result := TClockSession.Create;
  except
    on E: Exception do OutputDebugString(PWideChar('SYNC_Clock create: ' + E.Message));
  end;
end;

procedure DestroyClock(EffectID: Int64; UserData: Pointer); cdecl;
begin
  try
    TClockSession(UserData).Free;
  except
    on E: Exception do OutputDebugString(PWideChar('SYNC_Clock destroy: ' + E.Message));
  end;
end;

function GetClockFilterTable: PFILTER_PLUGIN_TABLE;
begin
  if not TableInitialized then
  begin
    SetupPluginTable(FILTER_FLAG_VIDEO or FILTER_FLAG_AUDIO or FILTER_FLAG_INPUT or
      FILTER_FLAG_USERDATA, '時計演出', 'SYNC', '時計演出 / SYNC_Clock v1.0.0', ClockVideo, ClockAudio);
    RegisterClockParameters;
    GetPluginTable^.Func_Create := CreateClock;
    GetPluginTable^.Func_Destroy := DestroyClock;
    TableInitialized := True;
  end;
  Result := GetPluginTable;
end;

end.

