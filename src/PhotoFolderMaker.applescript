use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit"
use scripting additions

on open droppedItems
	set targetBaseFolder to missing value
	repeat with itemPath in droppedItems
		set posixPath to POSIX path of itemPath
		
		-- extract filename
		set AppleScript's text item delimiters to "/"
		set fileName to last text item of posixPath
		set AppleScript's text item delimiters to "."
		if (count of text items of fileName) > 1 then
			set folderName to (text items 1 thru -2 of fileName) as text
		else
			set folderName to fileName
		end if
		set AppleScript's text item delimiters to ""
		
		-- Prompt user for destination folder only once per drop
		if targetBaseFolder is missing value then
			set targetBaseFolder to choose folder with prompt "作成したフォルダを保存する場所を選んでください："
			set targetBasePath to POSIX path of targetBaseFolder
		end if
		
		set targetFolderPath to targetBasePath & folderName & "_フォルダ"
		
		do shell script "mkdir -p " & quoted form of targetFolderPath
		
		-- Use ASOC to composite icon
		set sharedWorkspace to current application's NSWorkspace's sharedWorkspace()
		set nsPosixPath to (current application's NSString's stringWithString:posixPath)
		set imgURL to (current application's NSURL's fileURLWithPath:nsPosixPath)
		set userImg to (current application's NSImage's alloc()'s initWithContentsOfURL:imgURL)
		
		if userImg is not missing value then
			set tempFolder to "/tmp/test_empty_folder_for_icon_"
			do shell script "mkdir -p " & quoted form of tempFolder
			
			set folderImg to (sharedWorkspace's iconForFile:tempFolder)
			if folderImg is not missing value then
				(folderImg's setSize:{width:512, height:512})
				
				set compositeImg to (current application's NSImage's alloc()'s initWithSize:{width:512, height:512})
				compositeImg's lockFocus()
				
				(folderImg's drawInRect:{origin:{x:0, y:0}, |size|:{width:512, height:512}})
				
				set userSize to userImg's |size|()
				set imgWidth to width of userSize
				set imgHeight to height of userSize
				set aspectRatio to imgWidth / imgHeight
				
				set bboxMax to 384
				
				if aspectRatio > 1.0 then
					set drawWidth to bboxMax
					set drawHeight to bboxMax / aspectRatio
				else
					set drawHeight to bboxMax
					set drawWidth to bboxMax * aspectRatio
				end if
				
				set drawX to (512 - drawWidth) / 2
				set drawY to (512 - drawHeight) / 2 - 15
				
				(userImg's drawInRect:{origin:{x:drawX, y:drawY}, |size|:{width:drawWidth, height:drawHeight}})
				
				compositeImg's unlockFocus()
				
				(sharedWorkspace's setIcon:compositeImg forFile:targetFolderPath options:0)
			end if
		end if
	end repeat
end open

on run
	display dialog "写真ファイルをこのアプリのアイコンにドラッグ＆ドロップすると、指定した場所に、写真が合成されたフォルダアイコンの新規フォルダを作成します。" & return & return & "ドロップしたあとに保存先を選ぶダイアログが表示されます。" buttons {"OK"} default button "OK"
end run

