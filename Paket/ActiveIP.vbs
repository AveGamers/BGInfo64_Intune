strMsg = ""
strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
Set IPConfigSet = objWMIService.ExecQuery("Select IPAddress, IPSubnet, DefaultIPGateway from Win32_NetworkAdapterConfiguration WHERE IPEnabled = 'True'")

For Each IPConfig in IPConfigSet
	' Nur Adapter mit Default Gateway verarbeiten
	If Not IsNull(IPConfig.DefaultIPGateway) And Not IsNull(IPConfig.IPAddress) And Not IsNull(IPConfig.IPSubnet) Then
		For i = LBound(IPConfig.IPAddress) to UBound(IPConfig.IPAddress)
			' Nur IPv4-Adressen verarbeiten (keine IPv6)
			If Not Instr(IPConfig.IPAddress(i), ":") > 0 Then
				Dim cidr
				cidr = SubnetMaskToCIDR(IPConfig.IPSubnet(i))
				strMsg = strMsg & IPConfig.IPAddress(i) & "/" & cidr & vbcrlf
			End IF
		Next
	End If
Next

' BGInfo erwartet die Ausgabe ohne Zeilenumbruch am Ende
If Len(strMsg) > 0 Then
	' Entferne den letzten vbcrlf
	strMsg = Left(strMsg, Len(strMsg) - 2)
End If

Echo strMsg

' Funktion zur Umwandlung von Subnet-Maske in CIDR-Notation
Function SubnetMaskToCIDR(mask)
	Dim octets, binaryStr, cidrValue
	octets = Split(mask, ".")
	binaryStr = ""
	
	' Konvertiere jedes Oktett in Binär
	For Each octet in octets
		Dim binOctet, num
		num = CInt(octet)
		binOctet = ""
		Dim j
		For j = 7 to 0 Step -1
			If num And (2^j) Then
				binOctet = binOctet & "1"
			Else
				binOctet = binOctet & "0"
			End If
		Next
		binaryStr = binaryStr & binOctet
	Next
	
	' Zähle die Anzahl der 1en
	cidrValue = 0
	For j = 1 to Len(binaryStr)
		If Mid(binaryStr, j, 1) = "1" Then
			cidrValue = cidrValue + 1
		End If
	Next
	
	SubnetMaskToCIDR = cidrValue
End Function