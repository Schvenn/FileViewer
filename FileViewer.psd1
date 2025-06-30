@{
RootModule = 'FileViewer.psm1'
ModuleVersion = '1.1'
GUID = 'e1a59c2d-6dbe-4f32-bd7b-36eaa0f5b7d2'
Author = 'Schvenn'
CompanyName = 'Plath Consulting Incorporated'
Copyright = '(c) Craig Plath. All rights reserved.'
Description = 'Interactive file viewer with paging, search highlighting, gzip support, directory navigation, and accepts output from other sources, such as Findin.'
PowerShellVersion = '5.1'
FunctionsToExport = @('fileviewer')
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()
FileList = @('FileViewer.psm1', 'license.txt')
PrivateData = @{
PSData = @{
Tags = @('file','viewer','search','paging','gzip','log','cybersecurity','forensics','PowerShell')
LicenseUri = 'https://github.com/Schvenn/FileViewer/blob/main/license.txt'
ProjectUri = 'https://github.com/Schvenn/FileViewer'
ReleaseNotes = 'Initial gallery release. Supports interactive file viewing with search and gzip handling.'
}}}