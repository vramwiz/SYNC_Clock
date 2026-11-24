unit Clock_Renderer;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 透過 Direct2D サーフェス、静的レイヤーのキャッシュ、RGBA 転送を管理する。

interface

uses Winapi.D2D1, Winapi.Wincodec, AviUtl2FilterTypes, Clock_Canvas,
  Clock_Settings, Clock_Timeline;

type
  TClockRenderer = class
  private
    FFactory: ID2D1Factory;
    FWic: IWICImagingFactory;
    FBitmap: IWICBitmap;
    FTarget: ID2D1RenderTarget;
    FBackground: ID2D1Bitmap;
    FCanvas: TClockCanvas;
    FComCookie: Pointer;
    FWidth, FHeight: Integer;
    FStyle: TClockStyle;
    FMode: TClockMode;
    FColors: TClockColors;
    FPremultiplied, FPixels: TArray<TPIXEL_RGBA>;
    procedure ResetTarget;
    procedure EnsureTarget(Width, Height: Integer);
    procedure UpdateBackground(const S: TClockSettings; const L: TClockLayout);
  public
    destructor Destroy; override;
    // 呼出側で直列化する。転送するRGBAは本インスタンスが保持する。
    procedure Render(const S: TClockSettings; const T: TClockTime;
      SetImage: TFILTER_SET_IMAGE_DATA);
  end;

implementation

uses System.SysUtils, System.Math, System.Win.ComObj, Winapi.Windows, Winapi.ActiveX, Winapi.DxgiFormat,
  Clock_Analog, Clock_Digital, Clock_Mechanics;

function CoIncrementMTAUsage(out Cookie: Pointer): HRESULT; stdcall;
  external 'ole32.dll' name 'CoIncrementMTAUsage';
function CoDecrementMTAUsage(Cookie: Pointer): HRESULT; stdcall;
  external 'ole32.dll' name 'CoDecrementMTAUsage';

destructor TClockRenderer.Destroy;
begin
  ResetTarget;
  FFactory := nil;
  FWic := nil;
  if FComCookie <> nil then CoDecrementMTAUsage(FComCookie);
  inherited;
end;

procedure TClockRenderer.ResetTarget;
begin
  FreeAndNil(FCanvas);
  FBackground := nil;
  FTarget := nil;
  FBitmap := nil;
  FWidth := 0;
  FHeight := 0;
end;

procedure TClockRenderer.EnsureTarget(Width, Height: Integer);
var
  Properties: TD2D1RenderTargetProperties;
begin
  if FComCookie = nil then OleCheck(CoIncrementMTAUsage(FComCookie));
  if FFactory = nil then
    OleCheck(D2D1CreateFactory(D2D1_FACTORY_TYPE_MULTI_THREADED, ID2D1Factory, nil, FFactory));
  if FWic = nil then
    OleCheck(CoCreateInstance(CLSID_WICImagingFactory, nil, CLSCTX_INPROC_SERVER,
      IID_IWICImagingFactory, FWic));
  if (FWidth = Width) and (FHeight = Height) then Exit;
  ResetTarget;
  OleCheck(FWic.CreateBitmap(Width, Height, @GUID_WICPixelFormat32bppPBGRA,
    WICBitmapCacheOnLoad, FBitmap));
  Properties := D2D1RenderTargetProperties(D2D1_RENDER_TARGET_TYPE_SOFTWARE,
    D2D1PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED), 96, 96);
  OleCheck(FFactory.CreateWicBitmapRenderTarget(FBitmap, Properties, FTarget));
  FCanvas := TClockCanvas.Create(FFactory, FTarget);
  SetLength(FPremultiplied, Width * Height);
  SetLength(FPixels, Width * Height);
  FWidth := Width;
  FHeight := Height;
end;

procedure TClockRenderer.UpdateBackground(const S: TClockSettings; const L: TClockLayout);
var
  Layer: ID2D1BitmapRenderTarget;
  C: TClockCanvas;
  Size: TD2D1SizeF;
begin
  if (FBackground <> nil) and (S.Style = FStyle) and (S.Mode = FMode) and
    (S.Colors[0] = FColors[0]) and (S.Colors[1] = FColors[1]) and (S.Colors[2] = FColors[2]) then Exit;
  FBackground := nil;
  if S.Mode = cmDisplay then Exit;
  Size := D2D1SizeF(L.Width, L.Height);
  OleCheck(FTarget.CreateCompatibleRenderTarget(@Size, nil, nil,
    D2D1_COMPATIBLE_RENDER_TARGET_OPTIONS_NONE, Layer));
  C := TClockCanvas.Create(FFactory, Layer);
  try
    Layer.BeginDraw;
    try
      Layer.Clear(D2D1ColorF(0, 0, 0, 0));
      if S.Style = csHourglass then DrawHourglassBase(C, S, L)
      else if IsDigital(S.Style) then DrawDigitalBase(C, S, L)
      else DrawAnalogBase(C, S, L);
    finally
      OleCheck(Layer.EndDraw);
    end;
    OleCheck(Layer.GetBitmap(FBackground));
  finally
    C.Free;
  end;
  FStyle := S.Style;
  FMode := S.Mode;
  FColors := S.Colors;
end;

procedure TClockRenderer.Render(const S: TClockSettings; const T: TClockTime;
  SetImage: TFILTER_SET_IMAGE_DATA);
var
  L: TClockLayout;
  X, Y, RX, RY, Scale, Aspect, Strength, Corner, ShakeX, ShakeY: Single;
  MarginX, MarginY, I, Alpha: Integer;
  Dest: TD2D1RectF;
  Raw: TPIXEL_RGBA;
  function Straight(Value: Byte): Byte;
  begin
    Result := Min(255, (Integer(Value) * 255 + Alpha div 2) div Alpha);
  end;
begin
  L := CLOCK_LAYOUTS[S.Style];
  X := L.X + S.Values[ctGlassX];
  Y := L.Y + S.Values[ctGlassY];
  Scale := S.Values[ctGlassScale] * 0.01;
  Aspect := S.Values[ctGlassAspect] * 0.01;
  RX := L.Radius * Scale * (1 + Min(Aspect, 0.0));
  RY := L.Radius * Scale * (1 - Max(Aspect, 0.0));
  Strength := S.Values[ctGlassStrength] * 0.01;
  if not ShowsGlass(S) or (Strength <= 0) or (RX <= 0) or (RY <= 0) then
  begin
    RX := 0;
    RY := 0;
  end;
  MarginX := 0;
  MarginY := 0;
  if RX > 0 then
  begin
    MarginX := Max(0, Ceil(Max(RX + 2 - X, X + RX + 2 - L.Width)));
    MarginY := Max(0, Ceil(Max(RY + 2 - Y, Y + RY + 2 - L.Height)));
  end;
  ShakeX := 0;
  ShakeY := 0;
  if (S.Style = csAlarm) and S.Alarm and
    (EventAge(T.DaySeconds, S.Values[ctAlarmHour] * 3600 +
      S.Values[ctAlarmMinute] * 60, 86400, T.Speed) < 5) then
  begin
    ShakeX := Sin(PositiveMod(T.RealSeconds, 0.091) * 2 * Pi / 0.091) * 5;
    ShakeY := Sin(PositiveMod(T.RealSeconds, 0.123) * 2 * Pi / 0.123) * 2;
  end;
  EnsureTarget(L.Width + 2 * MarginX, L.Height + 2 * MarginY);
  UpdateBackground(S, L);
  FCanvas.Translate(MarginX + ShakeX, MarginY + ShakeY);
  FTarget.BeginDraw;
  try
    FTarget.Clear(D2D1ColorF(0, 0, 0, 0));
    if FBackground <> nil then
    begin
      Dest := D2D1RectF(0, 0, L.Width, L.Height);
      FTarget.DrawBitmap(FBackground, @Dest);
    end;
    if S.Style = csHourglass then DrawSand(FCanvas, S, L, T)
    else if IsDigital(S.Style) then DrawDigitalDisplay(FCanvas, S, L, T)
    else
    begin
      DrawMechanism(FCanvas, S, L, T);
      DrawAnalogHands(FCanvas, S, L, T);
    end;
    Corner := 0;
    if S.GlassShape = gsRounded then Corner := S.Values[ctGlassCorner];
    FCanvas.Glass(X, Y, RX, RY, Corner, Strength, S.GlassShape = gsEllipse);
  finally
    if Failed(FTarget.EndDraw) then
    begin
      ResetTarget;
      OleCheck(E_FAIL);
    end;
  end;

  OleCheck(FBitmap.CopyPixels(nil, FWidth * 4, Length(FPremultiplied) * 4, @FPremultiplied[0]));
  for I := 0 to High(FPixels) do
  begin
    Raw := FPremultiplied[I];
    Alpha := Raw.A;
    if Alpha = 0 then FPixels[I] := Default(TPIXEL_RGBA)
    else
    begin
      if Alpha <> 255 then
      begin
        Raw.B := Straight(Raw.B);
        Raw.G := Straight(Raw.G);
        Raw.R := Straight(Raw.R);
      end;
      FPixels[I].R := Raw.B;
      FPixels[I].G := Raw.G;
      FPixels[I].B := Raw.R;
      FPixels[I].A := Raw.A;
    end;
  end;
  SetImage(@FPixels[0], FWidth, FHeight);
end;

end.

