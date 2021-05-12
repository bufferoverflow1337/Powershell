function Get-ADNestedGroupMember
{
  [CmdletBinding()]
  param
  (
  [Parameter(Mandatory=$true)[string]$Identity,
  [switch]$ShowParent,
  [switch]$ShowDepth,
  [switch]$ShowGroupScope
  )
  
  $overall_list = [System.Collections.ArrayList]@($Identity)
  $current_list = [System.Collections.ArrayList]@($Identity)
  $removal_list = [System.Collections.ArrayList]@()
  $addition_list = [System.Collections.ArrayList]@()
  
  do
  {
    foreach ($group in $current_list)
    {
      #Does the current group have members that are groups?
      $temp_list = Get-ADGroupMember $group | Where-Object {$_.objectClass -eq "group"}
      if ($temp_list -ne 0)
      {
        foreach ($item in $temp_list)
        {
          $addition_list.add($item) | Out-Null
          $overall_list.add($item) | Out-Null
        }
      }
      $removal_list.add($group)
    }
    
    foreach ($group in $addition_list)
    {
      $current_list.add($group) | Out-Null
    }
    
    foreach ($group in $removal_list)
    {
      while ($current_list -contains $group)
      {
        $current_list.remove($group)
      }
      while ($addition_list -contains $group)
      {
        $addition_list.remove($group)
      }
    }
      
    $recursive = if($current_list.count -gt 0) {$true} else {$false}
      
  } while ($recursive)
    
  $table = New-Object System.Data.DataTable("Output")
  
  $member_column = New-Object System.Data.DataColumn "SamAccountName", ([string])
  $group_column = New-Object System.Data.DataColumn "Group", ([string])
  $nested_column = New-Object System.Data.DataColumn "Nested", ([bool])
  $objectclass_column = New-Object System.Data.DataColumn "ObjectClass", ([string])
  $parentgroup_column = New-Object System.Data.DataColumn "ParentGroup", ([string])
  $groupdepth_column = New-Object System.Data.DataColumn "GroupDepth", ([int])
  $groupscope_column = New-Object System.Data.DataColumn "GroupScope", ([string])
  
  $table.columns.add($member_column)
  $table.columns.add($group_column)
  $table.columns.add($nested_column)
  $table.columns.add($objectclass_column)
  
  if ($ShowParent) {$table.columns.add($parentgroup_column)}
  if ($ShowDepth) {$table.columns.add($groupdepth_column)}
  if ($ShowGroupScope) {$table.columns.add($groupscope_column)}
  
  $parent_group = "<top>"
  $group_depth = 0
  
  foreach ($group in $overall_list)
  {
    $member_list = Get-ADGroupMember $group
    foreach ($object in $member_list)
    {
      $newRow = $table.NewRow()
      $newRow["SamAccountName"] = $object.SamAccountName
      if ([string]::IsNullOrEmpty($group.name))
      {
        $newRow["Group"] = $Identity
        $newRow["Nested"] = $false
      }
      else
      {
        $newRow["Group"] = $group.name
        $newRow["Nested"] = $true
      }
      
      $newRow["ObjectClass"] = $object.objectClass
      if ($ShowParent) {$newRow["ParentGroup"] = $parent_group}
      if ($ShowDepth) {$newRow["GroupDepth"] = $group_depth}
      if ($ShowGroupScope -And $objekct.objectClass -ew "group") {$newRow["GroupScope"] = Get-ADGroup $group | Select GroupScope | Convert-String -Example "@{GroupScope\=Global}=Global"}
      
      $table.Rows.Add($newRow)
    }
    $group_depth +=1
    if ($group_depth -eq 1) {$parent_group = $Identity} else {$parent_group = $group.name}
  }
  
  return $table
  
}
