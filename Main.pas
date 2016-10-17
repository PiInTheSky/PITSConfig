unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.ListBox, FMX.Edit,
  FMX.Objects, System.UIConsts;

type TValueType = (vtString, vtInteger, vtFloat, vtBoolean, vtList);

type
  TSetting = record
      Name:     String;
      VT:       TValueType;
      Text:     String;
      Default:  String;
      Desc:     String;
      Options:  String;
      KeyField: Boolean;
      Index:    Integer;
  end;

type
  TValue = record
      Name:         String;
      ValueString:  String;
      Page:         Integer;
      // CommentedOut: Boolean;
  end;

type
  TfrmMain = class(TForm)
    Panel1: TPanel;
    lblGeneral: TLabel;
    lblRTTY: TLabel;
    lblLoRa0: TLabel;
    lblLoRa1: TLabel;
    lblAPRS: TLabel;
    Panel2: TPanel;
    StyleBook1: TStyleBook;
    lstSettings: TListBox;
    Panel3: TPanel;
    lblExplanation: TLabel;
    lblEnabled: TLabel;
    chkValue: TCheckBox;
    edtValue: TEdit;
    cmbValue: TComboBox;
    OpenDialog1: TOpenDialog;
    Label1: TLabel;
    chkEnabled: TCheckBox;
    SaveDialog1: TSaveDialog;
    procedure lblGeneralClick(Sender: TObject);
    procedure lstSettingsChange(Sender: TObject);
    procedure lblRTTYClick(Sender: TObject);
    procedure lblLoRa0Click(Sender: TObject);
    procedure lblLoRa1Click(Sender: TObject);
    procedure lblAPRSClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure chkEnabledChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure cmbValueChange(Sender: TObject);
    procedure edtValueChange(Sender: TObject);
    procedure chkValueChange(Sender: TObject);
  private
    { Private declarations }
    Enabled: Array[1..4] of Boolean;
    CurrentSettings: Array of TSetting;
    CurrentPrefix: String;
    CurrentPageIndex, CurrentChannel: Integer;
    Values: Array of TValue;
    procedure ShowSelection(ALabel: TLabel; Active: Boolean);
    procedure LoadSettings(Settings: Array of TSetting; Section: Integer; Prefix: String; Channel: Integer);
    procedure ShowSettings(Settings: array of TSetting; ALabel: TLabel; Prefix: String; Channel: Integer);
    procedure ShowLoRaSettings(ALabel: TLabel; Channel: Integer);
    procedure LoadSettingsFile(FileName: String);
    function FindSetting(Parameter: String): Integer;
    function GetSettingValue(Parameter: String): String;
    function FindOrAddSetting(Parameter: String; Value: String; FromFile: Boolean; Section: Integer; CommentOut: Boolean): Integer;
  public
    { Public declarations }
  end;

const
    GeneralSettings: array [0..15] of TSetting =
    (
        (Name: 'disable_monitor';      VT: vtBoolean; Text: 'Disable Monitor';                              Default: 'N';       Desc: 'Check this to disable the monitor after the Pi boots.  Saves 20mA and extends the run time by about 10%, however the monitor will no longer work!  Best used only if you connect to the Pi via ssh.'),
        (Name: 'camera';               VT: vtBoolean; Text: 'Enable Camera';                                Default: 'Y';       Desc: 'Check this to enable photography by the tracker software.  If enabled, photographs are taken independently for each radio channel (RTTY, LoRa 0 and LoRa 1), and also full-sized images for storage but not transmission.' + '  See the settings below for full-sized images, and see the RTTY and LoRa pages for settings specific to those radio channels.'),
        (Name: 'high';                 VT: vtInteger; Text: 'Height for larger images';                     Default: '2000';    Desc: 'Once above this altitude (in metres), two things happen to the imaging.  First, the image size (height and width in pixels) changes from that set for "low" images to that set for "high" images.' + '  Normally this would result in larger images being taken.  Second, the ratio of image packets vs telemetry packets changes from the hard-coded default of 1:1, to whatever ratio is configured for that radio channel'),
        (Name: 'enable_bmp085';        VT: vtBoolean; Text: 'Enable BMP085 / 180';                          Default: 'N';       Desc: 'Enables an external BMP085 or BMP180 pressure/temperature sensor.  These are available on breakout boards and connect to the I2C port on the side of the PITS+ board (not available on the PITS Zero).' + '  The pressure and temperature are sampled every 10 seconds and are included in the telemetry for RTTY and LoRa';),
        (Name: 'enable_bme280';        VT: vtBoolean; Text: 'Enable BME280';                                Default: 'N';       Desc: 'Enables an external BME280 humidity/pressure/temperature sensor.  These are available on breakout boards and connect to the I2C port on the side of the PITS+ board (not available on the PITS Zero).' + '  The humidity, pressure and temperature are sampled every 10 seconds and are included in the telemetry for RTTY and LoRa'),
        (Name: 'external_temperature'; VT: vtInteger; Text: 'External Temperature Index';                   Default: '1';       Desc: 'If an external DS18B20 temperature sensor is added, it is automatically identified.  However, it is then not possible for the software to then know which sensor is internal and which external.' + '  Set to 1 initially; if the internal and external temperatures are reversed then set to 0 instead'),
        (Name: 'logging';              VT: vtList;    Text: 'Logging Options';                              Default: 'None';    Desc: 'Selects which log files get written to:' + #13 + #10 + #10 + '    GPS - Writes GPS (NMEA) data to gps.txt' + #13 + #10 + #10 + '    Telemetry - Writes RTTY stream to telemetry.txt'; Options: 'None^GPS^Telemetry^GPS,Telemetry'),
        (Name: 'full_low_width';       VT: vtInteger; Text: 'Width of Full Size Images (low altitudes)';    Default: '320';     Desc: 'Width in pixels of full size images when at low altitudes (below the "high" setting above).  Generally best to keep this to a moderate value as it will be used for pre-launch photography.'),
        (Name: 'full_low_height';      VT: vtInteger; Text: 'Height of Full Size Images (low altitudes)';   Default: '240';     Desc: 'Height in pixels of full size images when at low altitudes (below the "high" setting above).  Generally best to keep this to a moderate value as it will be used for pre-launch photography.'),
        (Name: 'full_high_width';      VT: vtInteger; Text: 'Width of Full Size Images (high altitudes)';   Default: '640';     Desc: 'Width in pixels of full size images when at high altitudes (above the "high" setting above).  Generally best to use the maximum camera resolution (2592 pixels for the V1 camera, 3280 pixels for the V2 camera)'),
        (Name: 'full_high_height';     VT: vtInteger; Text: 'Height of Full Size Images (high altitudes)';  Default: '480';     Desc: 'Height in pixels of full size images when at high altitudes (above the "high" setting above).  Generally best to use the maximum camera resolution (1944 pixels for the V1 camera, 2464 pixels for the V2 camera)'),
        (Name: 'full_image_period';    VT: vtInteger; Text: 'Period between full-sized images';             Default: '60';      Desc: 'Time in seconds between full-sized images.  Shorter times mean that the SD card will fill more quixckly, however this is unlikely to be an issue for flights of normal length (2-3 hours).' + #13 + #10 + #10 + 'Remember that the camera schedule also includes images for the radio channel(s) so very short times (less than 15 seconds between shots) might not be achievable in practice because the camera might be busy taking imaghes for transmission'),
        (Name: 'landing_prediction';   VT: vtBoolean; Text: 'Enable Landing Prediction';                    Default: 'N';       Desc: 'Enables a landing prediction algorithm that stores wind strength and direction during ascent, and uses this plus parachute data to predict the landing position during descent.  This position is added to the telemetry.' + #13 + #10 + #10 + 'Parachute data is computed dynamically during descent but initial values can be set below.'),
        (Name: 'cd_area';              VT: vtFloat;   Text: 'CD*A value for the parachute';                 Default: '0.66';    Desc: 'Used to help provide the initial landing prediction at burst.  If your parachute is sized for approximately 5m/s landing speed, then just leave this and the weight below at their default values'),
        (Name: 'payload_weight';       VT: vtFloat;   Text: 'Payload Weight';                               Default: '1';       Desc: 'Payload weight in kg.  Used to help provide the initial landing prediction at burst.  If your parachute is sized for approximately 5m/s landing speed, then just leave this and the CD*A figure above at their default values'),
        (Name: 'prediction_id';        VT: vtString;  Text: 'Prediction Payload ID';                        Default: '';        Desc: 'Normally the predicted landing latitude and longitude are simply added to the telemetry.' + #13 + #10 + #10 + 'Alternatively, and for LoRa only at present, they can be sent in a separate sentence for a second "pretend" payload, thus appearing on the live map as a separate location.' + #13 + #10 + #10 + 'For this option, it is best to use the special payload ID "XX" which on the habitat map is drawn as a large "X marks the spot" instead of as a balloon')
    );
    RTTYSettings: array [0..8] of TSetting =
    (
        (Name: 'payload';       VT: vtString;  Text: 'Payload ID';                              Default: 'CHANGEME';    Desc: 'This ID should be unique to your flight and, if you are using multiple trackers and/or radio channels (e.g. RTTY + LoRa) each should be different.' + #13 + #10 + #10 + 'The payload ID is shown on the live HAB map so you can tell where the balloon is.' + #13 + #10 + #10 + 'It also appears on the live imaging (SSDV) page if you are sending images.  Remember that SSDV payload IDs are truncated to 6 characters'),
        (Name: 'frequency';     VT: vtFloat;   Text: 'Transmission Frequency';                  Default: '434.200';     Desc: 'Sets the RTTY frequency.  The frequency should be chosen to avoid conflicts with any other transmissions from your balloon, and also from other balloons flying within 500 miles at the same time (check the habhub launch schedule online).' + #13 + #10 + #10 + 'You MUST check that the frequency is legal to fly in your country (see IR2030 for UK) and that it is in an ISM band or you have a Ham radio licence (e.g. 434MHz is ISM in Europe but needs a licence in the USA)'),
        (Name: 'baud';          VT: vtInteger; Text: 'Transmission Baud Rate';                  Default: '300';         Desc: 'Transmission baud rate.  We recommend 300 baud if you are sending images (600 baud works but has less range), or 50 baud if you are not sending images.'),
        (Name: 'low_width';     VT: vtInteger; Text: 'Width of RTTY Images (low altitudes)';    Default: '320';         Desc: 'Width in pixels of RTTY images when at low altitudes (below the "high" setting above).  Generally best to keep this to a low value as it will be used for pre-launch photography.'),
        (Name: 'low_height';    VT: vtInteger; Text: 'Height of RTTY Images (low altitudes)';   Default: '240';         Desc: 'Height in pixels of RTTY images when at low altitudes (below the "high" setting above).  Generally best to keep this to a low value as it will be used for pre-launch photography.'),
        (Name: 'high_width';    VT: vtInteger; Text: 'Width of RTTY Images (high altitudes)';   Default: '640';         Desc: 'Width in pixels of RTTY images when at high altitudes (above the "high" setting above).  Best to keep in the 500-700 pixel range otherwise it will take a long time to send each image.'),
        (Name: 'high_height';   VT: vtInteger; Text: 'Height of RTTY Images (high altitudes)';  Default: '480';         Desc: 'Height in pixels of RTTY images when at high altitudes (above the "high" setting above).  Best to keep in the 300-400 pixel range otherwise it will take a long time to send each image.'),
        (Name: 'image_period';  VT: vtInteger; Text: 'Period between RTTY images';              Default: '60';          Desc: 'Time in seconds between RTTY images.  Keep this fairly short so that the software has several images to choose from for transmission.' + #13 + #10 + #10 + 'Try to aim for a transmission time of 3-5 minutes using the sizes above, and for there to be 4-10 images taken during that time'),
        (Name: 'info_messages'; VT: vtInteger; Text: 'Number Of Info Messages At Start';        Default: '0';           Desc: 'When the tracker starts, it can send information messages over RTTY.  These contain the Pi IP address (handy if using headless when testing) and free space on the SD card.' + #13 + #10 + #10 + 'You should check that there is sufficient space remaining for images taken during the flight, otherwise imaging will stop when the SD card is full.')
    );
    LoRaSettings: array [0..15] of TSetting =
    (
        (Name: 'Payload';           VT: vtString;  Text: 'Payload ID';                               Default: '';           Desc: 'This ID should be unique to your flight and, if you are using multiple trackers and/or radio channels (e.g. RTTY + LoRa) each should be different.' + #13 + #10 + #10 + 'The payload ID is shown on the live HAB map so you can tell where the balloon is.' + #13 + #10 + #10 + 'It also appears on the live imaging (SSDV) page if you are sending images.  Remember that SSDV payload IDs are truncated to 6 characters'),
        (Name: 'Frequency';         VT: vtFloat;   Text: 'Transmission Frequency';                   Default: '434.200';    Desc: 'Sets the RTTY frequency.  The frequency should be chosen to avoid conflicts with any other transmissions from your balloon, and also from other balloons flying within 500 miles at the same time (check the habhub launch schedule online).' + #13 + #10 + #10 + 'You MUST check that the frequency is legal to fly in your country (see IR2030 for UK) and that it is in an ISM band or you have a Ham radio licence (e.g. 434MHz is ISM in Europe but needs a licence in the USA)'),
        (Name: 'Mode';              VT: vtInteger; Text: 'Transmission Mode';                        Default: '0';          Desc: 'Transmission baud rate.  We recommend 300 baud if you are sending images (600 baud works but has less range), or 50 baud if you are not sending images.'),
        (Name: 'low_width';         VT: vtInteger; Text: 'Width of LoRa Images (low altitudes)';     Default: '320';        Desc: 'Width in pixels of RTTY images when at low altitudes (below the "high" setting above).  Generally best to keep this to a low value as it will be used for pre-launch photography.'),
        (Name: 'low_height';        VT: vtInteger; Text: 'Height of LoRa Images (low altitudes)';    Default: '240';        Desc: 'Height in pixels of RTTY images when at low altitudes (below the "high" setting above).  Generally best to keep this to a low value as it will be used for pre-launch photography.'),
        (Name: 'high_width';        VT: vtInteger; Text: 'Width of LoRa Images (high altitudes)';    Default: '640';        Desc: 'Width in pixels of RTTY images when at high altitudes (above the "high" setting above).  Best to keep in the 500-700 pixel range otherwise it will take a long time to send each image.'),
        (Name: 'high_height';       VT: vtInteger; Text: 'Height of LoRa Images (high altitudes)';   Default: '480';        Desc: 'Height in pixels of RTTY images when at high altitudes (above the "high" setting above).  Best to keep in the 300-400 pixel range otherwise it will take a long time to send each image.'),
        (Name: 'image_period';      VT: vtInteger; Text: 'Period between LoRa images';               Default: '60';         Desc: 'Time in seconds between RTTY images.  Keep this fairly short so that the software has several images to choose from for transmission.' + #13 + #10 + #10 + 'Try to aim for a transmission time of 3-5 minutes using the sizes above, and for there to be 4-10 images taken during that time'),
        (Name: 'image_packets';     VT: vtInteger; Text: 'Ratio of image data vs Telemetry';         Default: '4';          Desc: 'Once above the "high" altitude (see General settings page), the ratio of image packets to telemetry packets is set to this number' + #13 + #10 + #10 + 'Set this higher to improve image throughput, at the expense of less frequent position updates.'),
        (Name: 'Cycle';             VT: vtInteger; Text: 'Cycle time  when using TDM';               Default: '0';          Desc: 'Total number of seconds in the TDM cycle.  Set to zero to disable TDM.  TDM is used for an airborne network (i.e. multiple balloons repeating each other)'),
        (Name: 'Slot';              VT: vtInteger; Text: 'Slot number when using TDM';               Default: '0';          Desc: 'Slot number for telemetry transmission, beginning at 0 (start of cycle) up to "Cycle-1"'),
        (Name: 'Repeat';            VT: vtInteger; Text: 'Repeat slot number when using TDM';        Default: '0';          Desc: 'Slot number for repeating a telemetry transmission from another payload, beginning at 0 (start of cycle) up to "Cycle-1"'),
        (Name: 'Uplink';            VT: vtInteger; Text: 'Uplink repeat slot number when using TDM'; Default: '0';          Desc: 'Slot number for repeating an uplink message from the ground, beginning at 0 (start of cycle) up to "Cycle-1"'),
        (Name: 'Binary';            VT: vtBoolean; Text: 'Uses binary position packets';             Default: 'N';          Desc: 'UNTESTED / UNSUPPORTED - Enables binary packets for shorter transmission times.  Likely to be deprecated in favour of MsgPack format.  Leave uncheced to use ASCII'),
        (Name: 'Calling_Frequency'; VT: vtFloat;   Text: 'Frequency of calling channel';             Default: '';           Desc: 'Sets the frequency of the calling channel - used to notify ground stations of the flight assuming they are set to a standard calling frequency (there is no standard as yet).'),
        (Name: 'Calling_Count';     VT: vtInteger; Text: 'Transmissions between Calling Packets';    Default: '0';          Desc: 'Controls the time in seconds between calling mode transmissions.')
    );
    APRSSettings: array [0..8] of TSetting =
    (
        (Name: 'Callsign';      VT: vtString;   Text: 'APRS Callsign';                      Default: '';        Desc: 'This MUST be your ham radio callsign.' + #13 + #10 + #10 + 'APRS is not legal with a ham radio license, and all APRS transmissions must include the callsign of the person holding the license.' + #13 + #10 + #10 + 'Many countries (e.g. UK) do not allow airborne amateur radio transmissions, so you should check legality before flying.'; KeyField: True),
        (Name: 'ID';            VT: vtInteger;  Text: 'APRS ID';                            Default: '11';      Desc: 'APRS device ID.  This should normally be set to 11 which is the standard for balloons, however if you are flying multiple APRS transmitters at once then each should use a different ID (but the same callsign)'),
        (Name: 'Period';        VT: vtInteger;  Text: 'Period Between Transmissions';       Default: '1';       Desc: 'Time in minutes between APRS transmissions.  For most flights a period of 1 minute is best.'),
        (Name: 'Offset';        VT: vtInteger;  Text: 'Fixed Offset In Seconds';            Default: '0';       Desc: 'To prevent 2 or more transmitters happening to transmit at the same time every minute, each transmission is delayed or advanced by this number of seconds'),
        (Name: 'Random';        VT: vtInteger;  Text: 'Random Offset In Seconds';           Default: '0';       Desc: 'To prevent 2 or more transmitters happening to transmit at the same time every minute, each transmission is delayed or advanced by a random period between 0 and this value-1.  Set to 0 to disable.'),
        (Name: 'HighPath';      VT: vtBoolean;  Text: 'Enable WIDE2-1 at High Altitudes';   Default: 'N';       Desc: 'APRS path at higher altitudes.  Check this to enable WIDE2-1; uncheck (recommended) to use no path'),
        (Name: 'Altitude';      VT: vtInteger;  Text: 'Altitude At Which Path Changes';     Default: '1500';    Desc: 'Above this altitude (in metres), the path is either WIDE2-1 or None (see above setting); below this altitude it is WIDE1-1, WIDE2-1' + #13 + #10 + #10 + 'We recommend setting this to approximately 1000m above ground level'),
        (Name: 'Preemphasis';   VT: vtBoolean;  Text: 'Enable Pre-emphasis of FM signal';   Default: 'N';       Desc: 'Enables 3dB pre-emphasis of the 2200Hz tones in the APRS signal.  Recommended if you are using a receiver that de-emphasises higher frequencies.'),
        (Name: 'Telemetry';     VT: vtBoolean;  Text: 'Include Telemetry in APRS Packets';  Default: 'N';       Desc: 'Enables the addition of GPS satellite count, temperature and battery voltage to APRS packets')
    );

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

procedure TfrmMain.ShowSelection(ALabel: TLabel; Active: Boolean);
var
    Rectangle: TRectangle;
begin
    Rectangle := TRectangle(ALabel.FindStyleResource('Rectangle1Style'));
    if Active then begin
        Rectangle.Stroke.Color := claYellow;
    end else begin
        Rectangle.Stroke.Color := claSilver;
    end;
end;

function BuildSettingName(Prefix, Parameter: String; Channel: Integer): String;
begin
    Result := Prefix + Parameter;

    if Channel >= 0 then begin
        Result := Result + '_' + Channel.ToString;
    end;
end;

procedure TfrmMain.LoadSettings(Settings: array of TSetting; Section: Integer; Prefix: String; Channel: Integer);
var
    i: Integer;
    Parameter: String;
begin
    for i := Low(Settings) to High(Settings) do begin
        Parameter := BuildSettingName(Prefix, Settings[i].Name, Channel);

        FindOrAddSetting(Parameter, Settings[i].Default, False, Section, False);
    end;
end;

procedure TfrmMain.ShowSettings(Settings: array of TSetting; ALabel: TLabel; Prefix: String; Channel: Integer);
var
    i: Integer;
    Parameter: String;
begin
    ShowSelection(lblGeneral, lblGeneral = ALabel);
    ShowSelection(lblRTTY, lblRTTY = ALabel);
    ShowSelection(lblLoRa0, lblLoRa0 = ALabel);
    ShowSelection(lblLoRa1, lblLoRa1 = ALabel);
    ShowSelection(lblAPRS, lblAPRS = ALabel);

    CurrentPageIndex := ALabel.Tag;

    chkEnabled.Visible := ALabel.Tag > 0;
    lblEnabled.Visible := chkEnabled.Visible;

    if chkEnabled.Visible then begin
        chkEnabled.Text := ALabel.Text + ' Enabled';
        chkEnabled.IsChecked := Enabled[ALabel.Tag];
    end;


    CurrentPrefix := Prefix;
    CurrentChannel := Channel;

    SetLength(CurrentSettings, Length(Settings));

    lstSettings.Items.Clear;

    for i := Low(Settings) to High(Settings) do begin
        lstSettings.Items.Add(Settings[i].Text);

        Parameter := BuildSettingName(CurrentPrefix, Settings[i].Name, Channel);

        Settings[i].Index := FindSetting(Parameter);

        CurrentSettings[i] := Settings[i];
    end;

    lstSettings.ItemIndex := 0;
end;

procedure TfrmMain.FormActivate(Sender: TObject);
begin
    if lstSettings.Items.Count = 0 then begin
        if OpenDialog1.Execute then begin
            LoadSettingsFile(OpenDialog1.FileName);
        end else begin
            Application.Terminate;
        end;
    end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
const
    Sections: Array[0..4] of String = ('General', 'RTTY', 'LORA0', 'LORA1', 'APRS');
var
    F: Text;
    Comment: String;
    Section, i: Integer;
begin
    SaveDialog1.FileName := OpenDialog1.FileName;
    if SaveDialog1.Execute then begin
        AssignFile(F, SaveDialog1.FileName);
        SetLineBreakStyle(F, tlbsLF);
        Rewrite(F);

        for Section := 0 to 4 do begin
            WriteLn(F, '[' + Sections[Section] + ']');
            for i := Low(Values) to High(Values) do begin
                if Values[i].Page = Section then begin
                    if Enabled[Section] then Comment := '' else Comment := '#';
                    // if Values[i].CommentedOut then Comment := '#';

                    WriteLn(F, Comment + Values[i].Name + '=' + Values[i].ValueString);
                end;
            end;
            WriteLn(F, '');
        end;

        CloseFile(F);

    end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
    LoadSettings(GeneralSettings, 0, '', -1);
    LoadSettings(RTTYSettings, 1, '', -1);
    LoadSettings(LoRaSettings, 2, 'LORA_', 0);
    LoadSettings(LoRaSettings, 3, 'LORA_', 1);
    LoadSettings(APRSSettings, 4, 'APRS_', -1);
end;

function Split(Delimiter: Char; Str: string; var String1: String; var String2: String): Boolean;
var
    Split: TArray<String>;
begin
    Split := Str.Split([Delimiter]);

    if Length(Split) >= 2 then begin
        String1 := Split[0];
        String2 := Split[1];
        Result := True;
    end else begin
        Result := False;
    end;
end;

function TfrmMain.FindSetting(Parameter: String): Integer;
var
    Index: Integer;
begin
    Result := -1;

    for Index := Low(Values) to High(Values) do begin
        if AnsiCompareText(Values[Index].Name, Parameter) = 0 then begin
            Result := Index;
            Exit;
        end;
    end;
end;

function TfrmMain.GetSettingValue(Parameter: String): String;
var
    Index: Integer;
begin
    Result := '';

    Index := FindSetting(Parameter);

    if Index >= 0 then begin
        // if not Values[Index].CommentedOut then begin
            Result := Values[Index].ValueString;
        // end;
    end;
end;

procedure TfrmMain.chkEnabledChange(Sender: TObject);
begin
    Enabled[CurrentPageIndex] := chkEnabled.IsChecked;
end;

function GetDefaultSection(Parameter: String): Integer;
begin
    if Pos('APRS_', Parameter) > 0 then begin
        Result := 4;
    end else if Pos('LORA_', Parameter) > 0 then begin
        if Pos('_1', Parameter) > 0 then begin
            Result := 3;
        end else begin
            Result := 2;
        end;
    end else begin
        Result := 0;
    end;
end;

procedure TfrmMain.chkValueChange(Sender: TObject);
begin
    if chkValue.IsChecked then begin
        Values[CurrentSettings[lstSettings.ItemIndex].Index].ValueString := 'Y';
    end else begin
        Values[CurrentSettings[lstSettings.ItemIndex].Index].ValueString := 'N';
    end;
end;

procedure TfrmMain.cmbValueChange(Sender: TObject);
begin
    Values[CurrentSettings[lstSettings.ItemIndex].Index].ValueString := cmbValue.Items[cmbValue.ItemIndex];
end;

procedure TfrmMain.edtValueChange(Sender: TObject);
begin
    Values[CurrentSettings[lstSettings.ItemIndex].Index].ValueString := edtValue.Text;
end;

function TfrmMain.FindOrAddSetting(Parameter: String; Value: String; FromFile: Boolean; Section: Integer; CommentOut: Boolean): Integer;
var
    Index: Integer;
begin
    if Section < 0 then begin
        Section := GetDefaultSection(Parameter);
    end;

    Index := FindSetting(Parameter);

    if Index < 0 then begin
        SetLength(Values, Length(Values)+1);
        Index := High(Values);
        with Values[Index] do begin
            Name := Parameter;
            Page := Section;
            ValueString := Value;
        end;
    end;

    with Values[Index] do begin
        if not CommentOut then begin
            ValueString := Value;
        end;

        if FromFile then begin
            // CommentedOut := CommentOut;
        end;

    end;

    Result := Index;
end;

procedure TfrmMain.LoadSettingsFile(FileName: String);
var
    F: TextFile;
    Line, Parameter, Value: String;
    CommentedOut: Boolean;
begin
    // Defaults
    Enabled[1] := True;

    AssignFile(F, FileName);
    Reset(F);

    while not EOF(F) do begin
        ReadLn(F, Line);

        if Split('=', Line, Parameter, Value) then begin
            CommentedOut := Parameter[1] = '#';
            if CommentedOut then begin
                Parameter := Copy(Parameter, 2, Length(Parameter)-1);
                // Value := '';
            end;

            if Parameter = 'Disable_RTTY' then begin
                Enabled[1] := not CharInSet(Value[1], ['Y','y','T','t','1']);
            end else begin
                FindOrAddSetting(Parameter, Value, True, -1, CommentedOut);
            end;
        end;
    end;

    CloseFile(F);

    Enabled[2] := (GetSettingValue('LORA_Frequency_0') <> '') and (GetSettingValue('LORA_Payload_0') <> '') and (GetSettingValue('LORA_Mode_0') <> '');
    Enabled[3] := (GetSettingValue('LORA_Frequency_1') <> '') and (GetSettingValue('LORA_Payload_1') <> '') and (GetSettingValue('LORA_Mode_1') <> '');
    Enabled[4] := GetSettingValue('APRS_Callsign') <> '';

    lblGeneralClick(nil);
end;

procedure TfrmMain.lblGeneralClick(Sender: TObject);
begin
    ShowSettings(GeneralSettings, lblGeneral, '', -1);
end;

procedure TfrmMain.lblRTTYClick(Sender: TObject);
begin
    ShowSettings(RTTYSettings, lblRTTY, '', -1);
end;

procedure TfrmMain.ShowLoRaSettings(ALabel: TLabel; Channel: Integer);
begin
    ShowSettings(LoRaSettings, ALabel, 'LORA_', Channel);
end;

procedure TfrmMain.lblAPRSClick(Sender: TObject);
begin
    ShowSettings(APRSSettings, lblAPRS, 'APRS_', -1);
end;

procedure TfrmMain.lblLoRa0Click(Sender: TObject);
begin
    ShowLoRaSettings(lblLoRa0, 0);
end;

procedure TfrmMain.lblLoRa1Click(Sender: TObject);
begin
    ShowLoRaSettings(lblLoRa1, 1);
end;

procedure TfrmMain.lstSettingsChange(Sender: TObject);
var
    SettingIndex: Integer;
    Parameter, Value: String;
begin
    SettingIndex := lstSettings.ItemIndex;
    if SettingIndex >= 0 then begin
        lblExplanation.Text := CurrentSettings[SettingIndex].Desc;

        chkValue.Visible := CurrentSettings[SettingIndex].VT = vtBoolean;
        edtValue.Visible := CurrentSettings[SettingIndex].VT in [vtString, vtInteger, vtFloat];
        cmbValue.Visible := CurrentSettings[SettingIndex].VT = vtList;

        if CurrentSettings[SettingIndex].VT = vtList then begin
            cmbValue.Items.Delimiter := '^';
            cmbValue.Items.DelimitedText := CurrentSettings[SettingIndex].Options;
        end;


        Value := Values[CurrentSettings[SettingIndex].Index].ValueString;

        case CurrentSettings[SettingIndex].VT of
            vtBoolean:  begin
                if Length(Value) > 0 then begin
                    chkValue.IsChecked := CharInSet(Value[1], ['Y','y','T','t','1']);
                end else begin
                    chkValue.IsChecked := False;
                end;
                chkValue.Text := CurrentSettings[SettingIndex].Text;
            end;
            vtList:     cmbValue.ItemIndex := cmbValue.Items.IndexOf(Value);
            else        edtValue.Text := Value;
        end;
    end;
end;

end.
