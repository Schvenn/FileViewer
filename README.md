# FileViewer
PowerShell module to view text files, with a file selector menu and the ability to accept file arrays from other sources. Includes search functionality.

Usage: fileviewer (filename) (filearray) (search) -documents -help

	• If no file is provided, a file selection menu is presented.
	• If a file array is provided, the file selection menu is presented, populated with those files.
 	• Search terms can be passed to the file viewer right from the command line, which is especially useful for the filearray option.
	• Use the -documents switch to limit files within the selector to the following extensions: 1st, backup, bat, cmd, doc, htm, html, log, me, ps1, psd1, psm1, temp, temp.

Once inside the viewer, the options include:

Navigation:

    [F]irst page
    [N]ext page
    [+/-]# to move forward or back a specific # of lines
    p[A]ge # to jump to a specific page
    [P]revious page
    [L]ast page

Search:

    [S]earch for a term
    [<] Previous match
    [>] Next match[#]Number to find a specific match number
    [C]lear search term

Exit Commands:

    [D]ump to screen with | MORE and Exit
    [X]Edit using Notepad++, if available. Otherwise, use Notepad.
    [M]enu to open the file selection menu
    [Q]uit
