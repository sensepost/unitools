<SCRIPT RUNAT=SERVER LANGUAGE=VBSCRIPT>
Const IncludeType = 2 
Dim UploadSizeLimit
Function GetUpload()
Dim Result
Set Result = Nothing
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then 
Dim CT, PosB, Boundary, Length, PosE
CT = Request.ServerVariables("HTTP_Content_Type") 
If LCase(Left(CT, 19)) = "multipart/form-data" Then 
PosB = InStr(LCase(CT), "boundary=") 
If PosB > 0 Then Boundary = Mid(CT, PosB + 9) 
PosB = InStr(LCase(CT), "boundary=") 
If PosB > 0 then 
PosB = InStr(Boundary, ",")
If PosB > 0 Then Boundary = Left(Boundary, PosB - 1)
end if
Length = CLng(Request.ServerVariables("HTTP_Content_Length")) 
If "" & UploadSizeLimit <> "" Then
UploadSizeLimit = CLng(UploadSizeLimit)
If Length > UploadSizeLimit Then
Request.BinaryRead (Length)
Err.Raise 2, "GetUpload", "Upload size " & FormatNumber(Length, 0) & "B exceeds limit of " & FormatNumber(UploadSizeLimit, 0) & "B"
Exit Function
End If
End If
If Length > 0 And Boundary <> "" Then 
Boundary = "--" & Boundary
Dim Head, Binary
Binary = Request.BinaryRead(Length) 
Set Result = SeparateFields(Binary, Boundary)
Binary = Empty 
Else
Err.Raise 10, "GetUpload", "Zero length request ."
End If
Else
Err.Raise 11, "GetUpload", "No file sent."
End If
Else
Err.Raise 1, "GetUpload", "Bad request method."
End If
Set GetUpload = Result
End Function
Function SeparateFields(Binary, Boundary)
Dim PosOpenBoundary, PosCloseBoundary, PosEndOfHeader, isLastBoundary
Dim Fields
Boundary = StringToBinary(Boundary)
PosOpenBoundary = InStrB(Binary, Boundary)
PosCloseBoundary = InStrB(PosOpenBoundary + LenB(Boundary), Binary, Boundary, 0)
Set Fields = CreateObject("Scripting.Dictionary")
Do While (PosOpenBoundary > 0 And PosCloseBoundary > 0 And Not isLastBoundary)
Dim HeaderContent, FieldContent, bFieldContent
Dim Content_Disposition, FormFieldName, SourceFileName, Content_Type
Dim Field, TwoCharsAfterEndBoundary
PosEndOfHeader = InStrB(PosOpenBoundary + Len(Boundary), Binary, StringToBinary(vbCrLf + vbCrLf))
HeaderContent = MidB(Binary, PosOpenBoundary + LenB(Boundary) + 2, PosEndOfHeader - PosOpenBoundary - LenB(Boundary) - 2)
bFieldContent = MidB(Binary, (PosEndOfHeader + 4), PosCloseBoundary - (PosEndOfHeader + 4) - 2)
GetHeadFields BinaryToString(HeaderContent), Content_Disposition, FormFieldName, SourceFileName, Content_Type
Set Field = CreateUploadField() 
Set FieldContent = CreateBinaryData()
FieldContent.ByteArray = bFieldContent
FieldContent.Length = LenB(bFieldContent)
Field.Name = FormFieldName
Field.ContentDisposition = Content_Disposition
Field.FilePath = SourceFileName
Field.FileName = GetFileName(SourceFileName)
Field.ContentType = Content_Type
Field.Length = FieldContent.Length
Set Field.Value = FieldContent
Fields.Add FormFieldName, Field
TwoCharsAfterEndBoundary = BinaryToString(MidB(Binary, PosCloseBoundary + LenB(Boundary), 2))
isLastBoundary = TwoCharsAfterEndBoundary = "--"
If Not isLastBoundary Then 
PosOpenBoundary = PosCloseBoundary
PosCloseBoundary = InStrB(PosOpenBoundary + LenB(Boundary), Binary, Boundary)
End If
Loop
Set SeparateFields = Fields
End Function
Function GetHeadFields(ByVal Head, Content_Disposition, Name, FileName, Content_Type)
Content_Disposition = LTrim(SeparateField(Head, "content-disposition:", ";"))
Name = (SeparateField(Head, "name=", ";")) 
If Left(Name, 1) = """" Then Name = Mid(Name, 2, Len(Name) - 2)
FileName = (SeparateField(Head, "filename=", ";")) 
If Left(FileName, 1) = """" Then FileName = Mid(FileName, 2, Len(FileName) - 2)
Content_Type = LTrim(SeparateField(Head, "content-type:", ";"))
End Function
Function SeparateField(From, ByVal sStart, ByVal sEnd)
Dim PosB, PosE, sFrom
sFrom = LCase(From)
PosB = InStr(sFrom, sStart)
If PosB > 0 Then
PosB = PosB + Len(sStart)
PosE = InStr(PosB, sFrom, sEnd)
If PosE = 0 Then PosE = InStr(PosB, sFrom, vbCrLf)
If PosE = 0 Then PosE = Len(sFrom) + 1
SeparateField = Mid(From, PosB, PosE - PosB)
Else
SeparateField = Empty
End If
End Function
Function GetFileName(FullPath)
Dim Pos, PosF
PosF = 0
For Pos = Len(FullPath) To 1 Step -1
Select Case Mid(FullPath, Pos, 1)
Case "/", "\": PosF = Pos + 1: Pos = 0
End Select
Next
If PosF = 0 Then PosF = 1
GetFileName = Mid(FullPath, PosF)
End Function
Function BinaryToString(Binary)
dim cl1, cl2, cl3, pl1, pl2, pl3
Dim L
cl1 = 1
cl2 = 1
cl3 = 1
L = LenB(Binary)
Do While cl1<=L
pl3 = pl3 & Chr(AscB(MidB(Binary,cl1,1)))
cl1 = cl1 + 1
cl3 = cl3 + 1
if cl3>300 then
pl2 = pl2 & pl3
pl3 = ""
cl3 = 1
cl2 = cl2 + 1
if cl2>200 then
pl1 = pl1 & pl2
pl2 = ""
cl2 = 1
End If
End If
Loop
BinaryToString = pl1 & pl2 & pl3
End Function
Function BinaryToStringold(Binary)
Dim I, S
For I = 1 To LenB(Binary)
S = S & Chr(AscB(MidB(Binary, I, 1)))
Next
BinaryToString = S
End Function
Function StringToBinary(String)
Dim I, B
For I=1 to len(String)
B = B & ChrB(Asc(Mid(String,I,1)))
Next
StringToBinary = B
End Function
Function vbsSaveAs(FileName, ByteArray)
Dim FS, TextStream
Set FS = CreateObject("Scripting.FileSystemObject")
Set TextStream = FS.CreateTextFile(FileName)
TextStream.Write BinaryToString(ByteArray) 
TextStream.Close
End Function
</SCRIPT>
<SCRIPT RUNAT=SERVER LANGUAGE=JSCRIPT>
function CreateUploadField(){ return new uf_Init() }
function uf_Init(){
this.Name = null
this.ContentDisposition = null
this.FileName = null
this.FilePath = null
this.ContentType = null
this.Value = null
this.Length = null
}
function CreateBinaryData(){ return new bin_Init() }
function bin_Init(){
this.ByteArray = null
this.Length = null
this.String = jsBinaryToString
this.SaveAs = jsSaveAs
}
function jsBinaryToString(){
return BinaryToString(this.ByteArray)
}
function jsSaveAs(FileName){
return vbsSaveAs(FileName, this.ByteArray)
}
</SCRIPT>
