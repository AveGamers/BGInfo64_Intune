strMsg = ""
strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
Set IPConfigSet = objWMIService.ExecQuery("Select * from Win32_NetworkAdapterConfiguration WHERE IPEnabled = True")

Dim bestMetric
Dim bestMac
bestMetric = 99999
bestMac = ""

For Each IPConfig in IPConfigSet
	' Nur Adapter mit Default Gateway und IPv4-Adresse berücksichtigen
	If Not IsNull(IPConfig.DefaultIPGateway) And Not IsNull(IPConfig.IPAddress) Then
		Dim hasIPv4
		hasIPv4 = False
		Dim i
		For i = LBound(IPConfig.IPAddress) To UBound(IPConfig.IPAddress)
			If InStr(IPConfig.IPAddress(i), ":") = 0 Then
				hasIPv4 = True
				Exit For
			End If
		Next
		If hasIPv4 Then
			Dim metric
			On Error Resume Next
			metric = IPConfig.IPConnectionMetric
			If Err.Number <> 0 Then
				Err.Clear
				metric = 10000
			End If
			On Error GoTo 0
			If IsNull(metric) Or metric = 0 Then metric = 10000
			If metric < bestMetric Then
				bestMetric = metric
				bestMac = IPConfig.MACAddress
			End If
		End If
	End If
Next

strMsg = bestMac

Echo strMsg