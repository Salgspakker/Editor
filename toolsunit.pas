unit toolsunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus,
  ExtCtrls, StdCtrls, LCLIntf, LCLType, Buttons, ColorBox,
  GraphMath, Spin, FPCanvas, TypInfo, LCL, transformunit, figuresunit;

type

  TFigureClass = class of TFigure;

  TIntegerArray = array of integer;

  TProperty = class
    procedure ObjectsCreate(APanel: TPanel; Value: integer); virtual;abstract;
  end;

  ArrayOfProperty = array of TProperty;

  TWidthProperty = class(TProperty)
    procedure ObjectsCreate(APanel: TPanel; Value: integer);override;
    procedure WidthChange(Sender: TObject);
  end;

  TPenStyleProperty = class(TProperty)
    procedure ObjectsCreate(APanel: TPanel; Value: integer);override;
    procedure PenStyleChange(Sender: TObject);
    procedure PenStylesBoxDrawItem(Control: TWinControl;
      Index: Integer; ARect: TRect; State: TOwnerDrawState);
  end;

  TBrushStyleProperty = class(TProperty)
    procedure ObjectsCreate(APanel: TPanel; Value: integer);override;
    procedure BrushStyleChange(Sender: TObject);
    procedure BrushStylesBoxDrawItem(Control: TWinControl;
      Index: Integer; ARect: TRect; State: TOwnerDrawState);
  end;

  TPenColorProperty = class(TProperty)
    procedure ObjectsCreate(APanel: TPanel; Value: integer);override;
    procedure PenColorChange(Sender: TObject);
  end;

  TBrushColorProperty = class(TProperty)
    procedure ObjectsCreate(APanel: TPanel; Value: integer); override;
    procedure BrushColorChange(Sender: TObject);
  end;

  TAnglesProperty = class(TProperty)
    procedure ObjectsCreate(APanel: TPanel; Value: integer)override;
    procedure AnglesChange(Sender: TObject);
  end;

  TTool = class
    Name:        string;
    Angle:       integer;
    Width:       integer;
    PenColor:    TColor;
    BrushStyle:  TBrushStyle;
    PenStyle:    TPenStyle;
    BrushColor:  TColor;
    Properties:  array of TProperty;
    FigureClass: TFigureClass;
    procedure AddPoint(APoint: TPoint); virtual;
    procedure FigureCreate(AFigureClass: TFigureClass; APoint: TPoint;
      APenColor, ABrushColor: TColor);
    procedure StopDraw(X,Y, AHeight, AWidth: integer;
      RBtn: boolean); virtual;
    procedure PropertiesListCreate; virtual; abstract;
    procedure PropertiesCreate(APanel: TPanel);virtual;
  end;

  TMagnifierTool = class(TTool)
    Figure: TRectangle;
    procedure PropertiesListCreate; override;
    procedure StopDraw(X,Y, AHeight, AWidth: integer;
      RBtn: boolean); override;
  end;

  THandTool = class(TTool)
    Figure: THandFigure;
    procedure AddPoint(APoint: TPoint); override;
    procedure StopDraw(X,Y, AHeight, AWidth: integer;
      RBtn: boolean); override;
    procedure PropertiesListCreate; override;
  end;

 TPolylineTool = class(TTool)
  public
    Figure: TPolyline;
    procedure PropertiesListCreate; override;
  end;

  TRectangleTool = class(TTool)
  public
    Figure: TRectangle;
    procedure PropertiesListCreate; override;
  end;

  TRoundRectTool = class(TTool)
  public
    Figure: TRoundRect;
    procedure PropertiesListCreate; override;
  end;

  TEllipseTool = class(TTool)
  public
    Figure: TEllipse;
    procedure PropertiesListCreate; override;
  end;

  TLineTool = class(TTool)
  public
    Figure: TLine;
    procedure PropertiesListCreate; override;
  end;

  TTriangleTool = class(TTool)
  public
    Figure: TTriangle;
    procedure PropertiesListCreate; override;
  end;

var
  ToolRegistry: array of TTool;
  CTool: TTool;
  InvalidateHandler:  procedure of Object;
  DeletePanelHandler: procedure of Object;
  CreatePanelHandler: procedure of Object;

implementation

procedure TRectangleTool.PropertiesListCreate;
begin
  SetLength(Properties,5);
  Properties[0]:=TWidthProperty.Create;
  Properties[1]:=TPenStyleProperty.Create;
  Properties[2]:=TBrushStyleProperty.Create;
  Properties[3]:=TPenColorProperty.Create;
  Properties[4]:=TBrushColorProperty.Create;
end;

procedure TRoundRectTool.PropertiesListCreate;
begin
  SetLength(Properties,6);
  Properties[0]:=TWidthProperty.Create;
  Properties[1]:=TPenStyleProperty.Create;
  Properties[2]:=TBrushStyleProperty.Create;
  Properties[3]:=TPenColorProperty.Create;
  Properties[4]:=TBrushColorProperty.Create;
  Properties[5]:=TAnglesProperty.Create;
end;

procedure TMagnifierTool.PropertiesListCreate;
begin
  SetLength(Properties,0);
end;

procedure THandTool.PropertiesListCreate;
begin
  SetLength(Properties,0);
end;

procedure TLineTool.PropertiesListCreate;
begin
  SetLength(Properties,3);
  Properties[0]:=TWidthProperty.Create;
  Properties[1]:=TPenStyleProperty.Create;
  Properties[2]:=TPenColorProperty.Create;
end;

procedure TPolylineTool.PropertiesListCreate;
begin
  SetLength(Properties,3);
  Properties[0]:=TWidthProperty.Create;
  Properties[1]:=TPenStyleProperty.Create;
  Properties[2]:=TPenColorProperty.Create;
end;

procedure TEllipseTool.PropertiesListCreate;
begin
  SetLength(Properties,5);
  Properties[0]:=TWidthProperty.Create;
  Properties[1]:=TPenStyleProperty.Create;
  Properties[2]:=TBrushStyleProperty.Create;
  Properties[3]:=TPenColorProperty.Create;
  Properties[4]:=TBrushColorProperty.Create;
end;

procedure TTriangleTool.PropertiesListCreate;
begin
  SetLength(Properties,5);
  Properties[0]:=TWidthProperty.Create;
  Properties[1]:=TPenStyleProperty.Create;
  Properties[2]:=TBrushStyleProperty.Create;
  Properties[3]:=TPenColorProperty.Create;
  Properties[4]:=TBrushColorProperty.Create;
end;

procedure TAnglesProperty.AnglesChange(Sender: TObject);
var i: Integer;
begin
  CTool.Angle:=(Sender as TSpinEdit).value;
  InvalidateHandler;
end;

procedure TBrushStyleProperty.BrushStyleChange(Sender:TObject);
var i: Integer;
begin
  CTool.BrushStyle:=CaseBrushStyle((Sender as TComboBox).ItemIndex);
  InvalidateHandler;
end;

procedure TPenColorProperty.PenColorChange(Sender:TObject);
var i: Integer;
begin
  CTool.PenColor:=(Sender as TColorBox).selected;
  InvalidateHandler;
end;

procedure TWidthProperty.WidthChange(Sender: TObject);
var i: Integer;
begin
  CTool.Width:=(Sender as TSpinEdit).Value ;
  InvalidateHandler;
end;

procedure TBrushColorProperty.BrushColorChange(Sender: TObject);
var i: Integer;
begin
  CTool.BrushColor:=(Sender as TColorBox).selected;
  InvalidateHandler;
end;

procedure TPenStyleProperty.PenStyleChange(Sender: TObject);
var i: Integer;
begin
  CTool.PenStyle:=CasePenStyle((Sender as TComboBox).ItemIndex);
  InvalidateHandler;
end;

procedure TPenStyleProperty.PenStylesBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var ps: integer;
begin
  ps:=ARect.Top + 7;
  (Control as TComboBox).Canvas.Pen.Style:=CasePenStyle(Index);
  (Control as TComboBox).Canvas.Line(0, ps, 100, ps);
end;

procedure TBrushStyleProperty.BrushStylesBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var PRect: TRect;
begin
  PRect.Left:=ARect.Left+8;
  PRect.Right:=ARect.Right-8;
  PRect.Top:=ARect.Top+4;
  PRect.Bottom:=ARect.Bottom-4;
  (Control as TComboBox).Canvas.Brush.Style:=CaseBrushStyle(Index);
  (Control as TComboBox).Canvas.Brush.Color:=clBlack;
  (Control as TComboBox).Canvas.Rectangle(PRect);
end;

procedure TBrushColorProperty.ObjectsCreate(APanel: TPanel; Value: integer);
var BrushLabel: TLabel; BrushBox: TColorBox;
begin
  BrushLabel        :=TLabel.Create(APanel);
  BrushLabel.Left   :=340;
  BrushLabel.Caption:='Цвет Заливки';
  BrushLabel.Parent :=APanel;
  BrushBox          :=TColorBox.Create(APanel);
  BrushBox.Style    :=[cbStandardColors,cbExtendedColors,cbSystemColors, cbPrettynames];
  BrushBox.ReadOnly :=True;
  BrushBox.Top      :=20;
  BrushBox.left     :=340;
  BrushBox.ItemIndex:=Value;
  BrushBox.Parent   :=APanel;
  BrushBox.OnChange :=@BrushColorChange;
  BrushBox.Selected :=clWhite;
  CTool.BrushColor  :=clWhite;
end;

procedure TAnglesProperty.ObjectsCreate(APanel: TPanel; Value: integer);
var AngleLabel: TLabel;  AngleSpin1: TSpinEdit;
begin
  AngleLabel         :=TLabel.Create(APanel);
  AngleLabel.Left    :=600;
  AngleLabel.Caption :='Скругление угла';
  AngleLabel.Parent  :=APanel;
  AngleSpin1         :=TSpinEdit.Create(APanel);
  AngleSpin1.Top     :=20;
  AngleSpin1.left    :=600;
  AngleSpin1.Parent  :=APanel;
  AngleSpin1.MinValue:=1;
  AngleSpin1.OnChange:=@AnglesChange;
end;

procedure TBrushStyleProperty.ObjectsCreate(APanel: TPanel; Value: integer);
var BrushStylesLable: TLabel; BrushStylesBox: TComboBox;
begin
  BrushStylesLable              :=TLabel.Create(APanel);
  BrushStylesLable.Left         :=470;
  BrushStylesLable.Caption      :='Стиль заливки';
  BrushStylesLable.Parent       :=APanel;
  BrushStylesBox                :=TComboBox.Create(APanel);
  BrushStylesBox.Items.CommaText:=',,,,,,';
  BrushStylesBox.ReadOnly       :=True;
  BrushStylesBox.Top            :=20;
  BrushStylesBox.Left           :=470;
  BrushStylesBox.Style          :=csOwnerDrawFixed;
  BrushStylesBox.ItemIndex      :=Value;
  BrushStylesBox.OnDrawItem     :=@BrushStylesBoxDrawItem;
  BrushStylesBox.Parent         :=APanel;
  BrushStylesBox.OnChange       :=@BrushStyleChange;
  CTool.BrushStyle              :=bsSolid;
end;

procedure TPenColorProperty.ObjectsCreate(APanel: TPanel; Value: integer);
var PenLable: TLabel; PenBox: TColorBox;
begin
  PenLable        :=TLabel.Create(APanel);
  PenLable.Left   :=80;
  PenLable.Caption:='Цвет Кисти';
  PenLable.Parent :=APanel;
  PenBox          :=TColorBox.Create(APanel);
  PenBox.Style    :=[cbStandardColors,cbExtendedColors,cbSystemColors, cbPrettyNames];
  PenBox.ReadOnly :=True;
  PenBox.Top      :=20;
  PenBox.Left     :=80;
  PenBox.ItemIndex:=Value;
  PenBox.Parent   :=APanel;
  PenBox.OnChange :=@PenColorChange;
  CTool.PenColor  :=clBlack;
end;

procedure TWidthProperty.ObjectsCreate(APanel: TPanel; Value: integer);
var WidthLabel: TLabel; ToolWidth: TSpinEdit;
begin
  WidthLabel        :=TLabel.Create(APanel);
  WidthLabel.Left   :=10;
  WidthLabel.Caption:='Ширина';
  WidthLabel.Parent :=APanel;
  ToolWidth         :=TSpinEdit.Create(APanel);
  ToolWidth.Top     :=20;
  ToolWidth.left    :=10;
  ToolWidth.MinValue:=1;
  ToolWidth.Parent  :=APanel;
  ToolWidth.Value   :=Value;
  ToolWidth.OnChange:=@WidthChange;
  CTool.Width       :=1;
end;

procedure TPenStyleProperty.ObjectsCreate(APanel: TPanel; Value: integer);
var PenStylesLable: TLabel; PenStylesBox: TComboBox;
begin
  PenStylesLable              :=TLabel.Create(APanel);
  PenStylesLable.left         :=210;
  PenStylesLable.Caption      :='Стиль Кисти';
  PenStylesLable.Parent       :=APanel;
  PenStylesBox                :=TComboBox.Create(APanel);
  PenStylesBox.ReadOnly       :=True;
  PenStylesBox.Top            :=20;
  PenStylesBox.left           :=210;
  PenStylesBox.Parent         :=APanel;
  PenStylesBox.Items.CommaText:=',,,,';
  PenStylesBox.Style          :=csOwnerDrawFixed;
  PenStylesBox.ItemIndex      :=Value;
  PenStylesBox.OnDrawItem     :=@PenStylesBoxDrawItem;
  PenStylesBox.OnChange       :=@PenStyleChange;
  CTool.PenStyle              :=psSolid;
end;

procedure TTool.PropertiesCreate(APanel: TPanel);
var i:integer;
begin
  CTool.PropertiesListCreate;
  for i:=0 to High(CTool.Properties) do
    CTool.Properties[i].ObjectsCreate(APanel, 0);
end;

procedure TTool.StopDraw(X,Y, AHeight, AWidth: integer; RBtn: boolean);
begin
end;

procedure RegisterTool(ATool: TTool; AFigureClass: TFigureClass; AName: string);
begin
  SetLength(ToolRegistry,length(ToolRegistry)+1);
  ToolRegistry[high(ToolRegistry)]:=ATool;
  with ToolRegistry[high(ToolRegistry)] do
  begin
    FigureClass:=AFigureClass;
    Name:=AName;
  end;
end;

procedure TMagnifierTool.StopDraw(X,Y, AHeight, AWidth: integer; RBtn: boolean);
var d: double;
begin
  with Figures[high(Figures)] as TMagnifierFrame do
  begin
    if(Points[low(Points)].x+5>Points[high(Points)].x) then
    begin
      if (not RBtn) then
        d:=Scale*2
      else
        d:=Scale/2;
      if (d>1000) or (d<10) then
      begin
        setlength(Figures,length(Figures)-1);
        exit;
      end;
      Scale:=d;
      ToPointZoom(FloatPoint(X,Y));
      RBtn:=false;
    end
    else
      RectScale(AHeight, AWidth, Points[0], Points[high(points)]);
    setlength(Figures,length(Figures)-1);
  end;
end;

procedure THandTool.StopDraw(X,Y, AHeight, AWidth: integer;
  RBtn: boolean);
begin
  SetLength(Figures,length(Figures)-1);
end;

procedure TTool.AddPoint(APoint: TPoint);
begin
  with Figures[high(Figures)] do
  begin
    SetLength(Points,length(Points)+1);
    Points[high(Points)]:=S2W(APoint);
  end;
  SetMaxMinFloatPoints(S2W(APoint));
end;

procedure THandTool.AddPoint(APoint: TPoint);
begin
  with Figures[high(Figures)] do
  begin
    SetLength(Points,length(Points)+1);
    Points[high(Points)].x:=S2W(APoint).x-Points[low(Points)].x;
    Points[high(Points)].y:=S2W(APoint).y-Points[low(Points)].y;
    Offset.x:=OffsetFirstPoint.x-APoint.x;
    Offset.y:=OffsetFirstPoint.y-APoint.y;
  end;
end;

procedure TTool.FigureCreate(AFigureClass: TFigureClass; APoint: TPoint;
  APenColor, ABrushColor: TColor);
begin
  SetLength(Figures,length(Figures)+1);
  Figures[high(Figures)]:=AFigureClass.Create;
  with Figures[high(Figures)] do
  begin
    FAngle:=Self.Angle;
    FBrushStyle:=Self.BrushStyle;
    FPenStyle:=Self.PenStyle;
    FWidth:=Self.Width;
    FPenColor:=Self.PenColor;;
    FBrushColor:=Self.BrushColor;
    SetLength(Points,1);
    Points[high(Points)]:=S2W(APoint);
  end;
  OffsetFirstPoint.x:=Offset.x+APoint.x;
  OffsetFirstPoint.y:=Offset.y+APoint.y;
  SetMaxMinFloatPoints(S2W(APoint));
end;


initialization
  RegisterTool(TPolyLineTool.Create,  TPolyLine,       'Карандаш');
  RegisterTool(TLineTool.Create,      TLine,           'Линия');
  RegisterTool(TRectangleTool.Create, TRectangle,      'Прямоугольник');
  RegisterTool(TEllipseTool.Create,   TEllipse,        'Эллипс');
  RegisterTool(TTriangleTool.Create,  TTRiangle,       'Треугольник');
  RegisterTool(TRoundRectTool.Create, TRoundRect,      'Круглоугольник');
  RegisterTool(TMagnifierTool.Create, TMagnifierFrame, 'Лупа');
  RegisterTool(THandTool.Create,      THandFigure,     'Рука');
end.

