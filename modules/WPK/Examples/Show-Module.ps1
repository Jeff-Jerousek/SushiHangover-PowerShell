New-Grid -Columns 3 -Rows 2 -Resource @{
    'Import-ModuleData' = {
        $modules = @(Get-Module) + @(Get-Module -ListAvailable) | 
            Select-Object Name, Path, ExportedCommands -Unique | 
            Sort-Object Name
        foreach ($m in $modules) {
            New-TreeViewItem -Header $m.Name -DataContext $m -ItemsSource @(
                $m.ExportedCommands.Values | Sort-Object Name
            ) 
        }                            
    }
} {
    New-TreeView -FontSize 24 -Name ModuleTree -ColumnSpan 3 -On_loaded {
        $null = $this.Items.Clear()
        foreach ($i in (& $this.Parent.Resources.'Import-ModuleData')) {
            $this.Items.Add($i)
        }
    } -On_SelectedItemChanged { 
        $remove = Get-ChildControl "Remove" -tree $this.Parent.Children
        if ($this.SelectedItem -is [Management.Automation.CommandInfo] ) {
            $remove.IsEnabled = $false
        } else {
            $remove.IsEnabled = $true
        }
    }
    New-Button -FontSize 18 -Row 1 -Column 0 -Name "Edit" "E_dit" -On_Click {                
        $item = $this.Parent | 
            Get-ChildControl ModuleTree | 
            Select-Object -ExpandProperty SelectedItem
        if ($item -is [Management.Automation.CommandInfo]) {
            $files = Get-Item -ErrorAction SilentlyContinue $item.ScriptBlock.File
        } else {
            $module = $item.DataContext
            $files = Get-ChildItem (Split-Path $module.Path) -Filter '*.ps????'
        }
        foreach ($f in $files) {
            if (-not $f) { continue }
            $null = $psise.CurrentPowerShellTab.Files.Add($f.FullName)
        }
    }
    New-Button -FontSize 18 -Row 1 -Column 1 -Name "Import" "_Import" -On_Click {
        $tree = $this.Parent | 
            Get-ChildControl ModuleTree
        $name = $tree | 
            Select-Object -ExpandProperty SelectedItem | 
            Select-Object -ExpandProperty Header
        Import-Module $name -Force -Global
        $null = $tree.Items.Clear()
        foreach ($i in (& $this.Parent.Resources.'Import-ModuleData')) {
            $tree.Items.Add($i)
        }                
    }
    New-Button -FontSize 18 -Row 1 -Column 2 -Name "Remove" "_Remove" -On_Click {
        $tree = $this.Parent | 
            Get-ChildControl ModuleTree
        $name = $tree | 
            Select-Object -ExpandProperty SelectedItem | 
            Select-Object -ExpandProperty Header
        Remove-Module $name -Force
        
        $null = $tree.Items.Clear()
        foreach ($i in (& $this.Parent.Resources.'Import-ModuleData')) {
            $tree.Items.Add($i)
        }                
    }    
} -show
 
