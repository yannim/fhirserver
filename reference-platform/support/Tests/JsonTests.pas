unit JsonTests;

interface

Uses
  SysUtils, Classes, Soap.EncdDecd,
  StringSupport, GuidSupport, BytesSupport,
  AdvObjects, AdvJson,
  DUnitX.TestFramework;

Type
  [TextFixture]
  TJsonTests = Class (TObject)
  Private
  Published
    [TestCase]
    procedure TestResource;

    [TestCase]
    procedure TestCustomDoc;
    [TestCase]
    procedure TestCustomDoc2;
  End;

  JsonPatchTestCaseAttribute = class (CustomTestCaseSourceAttribute)
  protected
    function GetCaseInfoArray : TestCaseInfoArray; override;
  end;

  [TextFixture]
  TJsonPatchTests = Class (TObject)
  Private
    tests : TJsonArray;
    engine : TJsonPatchEngine;
  Published
    [SetupFixture] procedure setup;
    [TearDownFixture] procedure teardown;

    [JsonPatchTestCase]
    procedure PatchTest(Name : String);
  End;

function CheckJsonIsSame(filename1, filename2 : String; var msg : string) : boolean;

implementation

{ TJsonTests }

procedure TJsonTests.TestCustomDoc;
var
  json : TJsonObject;
  f : TFileStream;
begin
  f := TFileStream.Create('C:\work\fhir.org\resource-policy.json', fmopenRead + fmShareDenyWrite);
  try
    json := TJSONParser.Parse(f);
    try
      assert.IsNotNull(json);
    finally
      json.Free;
    end;
  finally
    f.Free;
  end;
end;

procedure TJsonTests.TestCustomDoc2;
var
  json : TJsonObject;
  f : TFileStream;
begin
  f := TFileStream.Create('C:\temp\test.json', fmopenRead + fmShareDenyWrite);
  try
    json := TJSONParser.Parse(f);
    try
      assert.IsNotNull(json);
    finally
      json.Free;
    end;
  finally
    f.Free;
  end;
end;

procedure TJsonTests.TestResource;
var
  json : TJsonObject;
  f : TFileStream;
begin
  f := TFileStream.Create('C:\work\org.hl7.fhir\build\publish\account-example.json', fmopenRead + fmShareDenyWrite);
  try
    json := TJSONParser.Parse(f);
    try
      assert.IsNotNull(json);
    finally
      json.Free;
    end;
  finally
    f.Free;
  end;
end;

{ JsonPatchTestCaseAttribute }

function JsonPatchTestCaseAttribute.GetCaseInfoArray: TestCaseInfoArray;
var
  tests : TJsonArray;
  test : TJsonNode;
  i : integer;
  s : String;
begin
  tests := TJSONParser.ParseNode(FileToBytes('C:\work\fhirserver\tests\json-patch-tests.json')) as TJsonArray;
  try
    SetLength(result, tests.Count);
    i := 0;
    for test in tests do
    begin
      s := (test as TJsonObject)['comment'];
      s := s.Substring(0, s.IndexOf(' '));
      result[i].Name := s;
      SetLength(result[i].Values, 1);
      result[i].Values[0] := s;
      inc(i);
    end;
  finally
    tests.free;
  end;
end;

{ TJsonPatchTests }

procedure TJsonPatchTests.PatchTest(Name: String);
var
  t : TJsonNode;
  test, outcome : TJsonObject;
  s : String;
begin
  for t in tests do
  begin
    test := t as TJsonObject;
    s := test['comment'];
    if s.StartsWith(Name) then
    begin
      if test.has('error') then
      begin
        Assert.WillRaise(
          procedure begin
            engine.applyPatch(test.obj['doc'], test.arr['patch']).Free;
          end, Exception);
      end
      else
      begin
        outcome := engine.applyPatch(test.obj['doc'], test.arr['patch']);
        try
          Assert.IsTrue(TJsonNode.compare(outcome, test.obj['expected']))
        finally
          outcome.Free;
        end;
      end;
    end;
  end;
end;

procedure TJsonPatchTests.setup;
begin
  tests := TJSONParser.ParseNode(FileToBytes('C:\work\fhirserver\tests\json-patch-tests.json')) as TJsonArray;
  engine := TJsonPatchEngine.Create;
end;

procedure TJsonPatchTests.teardown;
begin
  engine.Free;
  tests.Free;
end;

function unbase64(text : String) : TBytes;
begin
  result := DecodeBase64(AnsiString(text));
end;

function CompareObjects(path : String; o1, o2 : TJsonObject) : String; forward;

function CompareNodes(path : String; n1, n2 : TJsonNode) : String;
var
  s, s1, s2 : String;
  i : integer;
begin
  if n1.ClassName <> n2.ClassName then
    exit('properties differ at '+path+': type '+n1.ClassName+'/'+n2.ClassName)
  else if (n1 is TJsonBoolean) then
  begin
    if ((n1 as TJsonBoolean).value <> (n2 as TJsonBoolean).value) then
      exit('boolean property values differ at '+path+': type '+booltoStr((n1 as TJsonBoolean).value)+'/'+boolToStr((n2 as TJsonBoolean).value))
  end
  else if (n1 is TJsonString) then
  begin
    s1 := (n1 as TJsonString).value;
    s2 := (n2 as TJsonString).value;
    if not (s1.contains('<div') and s2.contains('<div'))  then
      if s1 <> s2 then
        if not SameBytes(unbase64(s1), unbase64(s2)) then
          exit('string property values differ at '+path+': type '+s1+'/'+s2)
  end
  else if (n1 is TJsonNumber) then
  begin
    if ((n1 as TJsonNumber).value <> (n2 as TJsonNumber).value) then
      exit('number property values differ at '+path+': type '+(n1 as TJsonNumber).value+'/'+(n2 as TJsonNumber).value)
  end
  else if (n1 is TJsonObject) then
  begin
    s := CompareObjects(path, (n1 as TJsonObject), (n2 as TJsonObject));
    if s <> '' then
      exit(s)
  end
  else if (n1 is TJsonArray) then
  begin
    if ((n1 as TJsonArray).Count <> (n2 as TJsonArray).Count) then
      exit('array properties differ at '+path+': count '+inttostr((n1 as TJsonArray).Count)+'/'+inttostr((n2 as TJsonArray).Count))
    else
      for I := 0 to (n1 as TJsonArray).Count - 1 do
      begin
        s := compareNodes(path+'['+inttostr(i)+']', (n1 as TJsonArray).Item[i], (n2 as TJsonArray).Item[i]);
        if s <> '' then
          exit(s)
      end;
  end
  else if (n1 is TJsonNull) then
  begin
    // nothing to compare
  end
  else
    exit('unhandled property '+n1.className);
end;

function CompareObjects(path : String; o1, o2 : TJsonObject) : String;
var
  n : String;
  n1, n2 : TJsonNode;
  s : string;
begin
  for n in o1.properties.Keys do
    if (n <> 'fhir_comments') then
    begin
      n1 := o1.properties[n];
      if o2.properties.ContainsKey(n) then
      begin
        s := compareNodes(path+'.'+n, n1, o2.properties[n]);
        if (s <> '') then
          exit(s);
      end
      else
        exit('properties differ at '+path+': missing property '+n);
    end;
  for n in o2.properties.Keys do
    if (n <> 'fhir_comments') then
      if not o1.properties.ContainsKey(n) then
        exit('properties differ at '+path+': missing property '+n);
end;

function CompareJson(filename1, filename2 : String; var msg : string) : boolean;
var
  j1, j2 : TJsonObject;
begin
  j1 := TJSONParser.ParseFile(filename1);
  try
    j2 := TJSONParser.ParseFile(filename2);
    try
      msg := CompareObjects('$', j1, j2);
      result := msg = '';
    finally
      j2.free;
    end;
  finally
    j1.Free;
  end;
end;

function CheckJsonIsSame(filename1, filename2 : String; var msg : string) : boolean;
{$IFDEF DIFF}
var
  j1, j2 : TJsonObject;
  f1, f2, cmd : String;
{$ENDIF}
begin
  result := compareJson(filename1, filename2, msg);
{$IFDEF DIFF}
  if not result then
  begin
    j1 := TJSONParser.ParseFile(filename1);
    j2 := TJSONParser.ParseFile(filename2);
    try

      f1 := MakeTempFilename +'-source.xml';
      f2 := MakeTempFilename +'-dest.xml';
      StringToFile(TJsonWriter.writeObjectStr(j1, true), f1, TEncoding.UTF8);
      StringToFile(TJsonWriter.writeObjectStr(j2, true), f2, TEncoding.UTF8);
      cmd := f1+' '+f2;
      ShellExecute(0, 'open', '"C:\Program Files (x86)\WinMerge\WinMergeU.exe"', PChar(cmd), PChar(ExtractFilePath(f1)), SW_MAXIMIZE);
    finally
      j2.Free;
      j1.Free;
    end;
  end;
{$ENDIF}
end;


initialization
  TDUnitX.RegisterTestFixture(TJsonTests);
  TDUnitX.RegisterTestFixture(TJsonPatchTests);
end.
