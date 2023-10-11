function CheckPort {
    param (
        [int]$Port
    )

    $result = Get-Process -Id (Get-NetTCPConnection -LocalPort $Port).OwningProcess

    return $result -ne $null
}

function CheckProcessWithFilter {
    param (
        [string]$QueryFilter
    )

    # Run the Get-CimInstance command with the provided query filter and select the CommandLine property
    $processCommand = Get-CimInstance Win32_Process -Filter $QueryFilter | Select-Object -ExpandProperty CommandLine

    # Check if $processCommand is not null and return the result as a boolean
    return $processCommand -ne $null
}

function CheckLogRotate {
    $result =Get-ScheduledTask | Where-Object { $_.TaskName -like "*Log Rotate*" }
    return $result -ne $null

}

function checkFirewall {
    $fw_rules =Get-NetFirewallRule -DisplayName "PortCL" | Where-Object { 
            $_ | Get-NetFirewallAddressFilter | Where-Object { $_.RemoteAddress -like "103.21.244.0*" -or $_.RemoteAddress -like "103.22.200.0*"}
        }
    return $fw_rules -ne $null
    
}


function setupChecklist {
    return @{
    "1. Center Service"=@{
        "value"=(CheckProcessWithFilter -QueryFilter "name LIKE '%Center.Service.exe%'") -and (checkPort -Port 9202)
        "description"="Run the Center.Service.exe"
    }
    "2. Fighting Service"=@{
        "value"=(CheckProcessWithFilter -QueryFilter "name LIKE '%Fighting.Service.exe%'") -and (checkPort -Port 9209)
        "description"="Run the Fighting.Service.exe"
    }
    "3. Road Service"=@{
        "value"=(CheckProcessWithFilter -QueryFilter "name LIKE '%Road.Service.exe%'")
        "description"="Run the Road.Service.exe"
    }
    "4. Nginx"=@{
        "value"=(CheckProcessWithFilter -QueryFilter "name LIKE '%nginx.exe%'") -and (checkPort -Port 80)
        "description"="Reload the nginx.exe or reset it"
    }
    "5. AntiDDOS Script"=@{
        "value"=(CheckProcessWithFilter -QueryFilter "name LIKE '%python.exe%' and commandline LIKE '%main.py%'")
        "description"="Run the antiDDOS process"
    }
    "6. Log Rotate"=@{
        "value"=(CheckLogRotate)
        "description"="Add the logrotate to server.Define the name 'Log Rotate...'"
    }
    "7. Firewall rule CF 80"=@{
        "value"=(checkFirewall)
        "description"="Check the firewall rule PortCF (need extract name) and check if it allows CF ip"
    }
    }
}


function GUI(){
        # Load the Windows Forms assembly
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

    # Create a form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Checklist Application"
    $form.Size = New-Object System.Drawing.Size(300, 300)
    $form.StartPosition = [Windows.Forms.FormStartPosition]::Manual

    $screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    $screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

    # Calculate the X and Y coordinates for the top-right corner
    $windowX = $screenWidth - $form.Width - 300
    $windowY = 200

    $form.Location = New-Object Drawing.Point($windowX, $windowY)


    # Create a checklist box
    $checkListBox = New-Object System.Windows.Forms.ListView
    $checkListBox.CheckBoxes = $true
    $checkListBox.Size = New-Object System.Drawing.Size(250, 200)
    $checkListBox.Location = New-Object System.Drawing.Point(20, 20)
    $checkListBox.Enabled = $true  # Disable user interaction
    $checkListBox.View = [System.Windows.Forms.View]::Details
    $checkListBox.Columns.Add("Item", 300)
    $checkListBox.ShowItemToolTips=$true
    #$checkListBox.Columns.Add("Description", 150)
    # Create a status strip for the bottom of the form
    $statusStrip = New-Object System.Windows.Forms.StatusStrip
    $statusStrip.Location = New-Object System.Drawing.Point(0, 358)
    $statusStrip.Size = New-Object System.Drawing.Size(300, 22)

    # Create a status label in the status strip
    $statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $statusLabel.Text = "Status: Running setup..."
    $statusStrip.Items.Add($statusLabel)

    # Function to simulate your setup function (returns a hashtable)

    # Function to update the checklist
    function UpdateChecklist {
        $statusLabel.Text = "Status: Running setup..."
    
        $result = setupChecklist
        $sortedKeys = $result.Keys | Sort-Object  # Sort keys alphabetically
        $checkListBox.Items.Clear()
        foreach ($key in $sortedKeys) {
            $value = $result[$key]
            $itemText = "$key"
            $item = New-Object System.Windows.Forms.ListViewItem($itemText)
            $item.ToolTipText= $value['description']
            $item.Checked = $value['value']
            $checkListBox.Items.Add($item)
        }

        $statusLabel.Text = "Status: Last setup at $(Get-Date)"
    }
   

    # Timer to update the checklist every 5 seconds
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 60000  # 5000 milliseconds = 5 seconds
    $timer.Add_Tick({ UpdateChecklist })
    $timer.Start()

    # Add controls to the form
    $form.Controls.Add($checkListBox)
    $form.Controls.Add($statusStrip)

    # Show the form
    UpdateChecklist  # Initial update
    $form.ShowDialog()

    # Dispose of the form and timer when done
    $form.Dispose()
    $timer.Stop()
    $timer.Dispose()

}
GUI
