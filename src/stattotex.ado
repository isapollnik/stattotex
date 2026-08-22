*! version 0.3  20aug2026
* This program exports numbers in Stata for easy inclusion in LaTeX documents.
* Author: Ian Sapollnik
* Date: August 20, 2026
program define stattotex
	version 10.0
	syntax using/, [STATistic(string)] [name(string)] [replace] [Format(string)] [comment(string)] [record] [FORCEName] [FORCEStat] [STRing] [CLEARall]
	* statistic() and name() are mandatory, except when clearall is used on its own to empty a file.
	if "`name'"=="" & "`statistic'"!="" {
		disp as error "Options statistic() and name() must be specified together."
		error 198
	}
	if "`name'"=="" & "`clearall'"=="" {
		disp as error "Options statistic() and name() are required unless clearall is specified."
		error 198
	}
	* An empty statistic() is only meaningful as an empty string, e.g. a blank significance star.
	if "`name'"!="" & "`statistic'"=="" & "`string'"=="" {
		disp as error "Option statistic() cannot be empty unless the string option is specified."
		error 198
	}
	* string and forcestat both write the statistic as-is, so combining them is ambiguous.
	if "`string'"!="" & "`forcestat'"!="" {
		disp as error "Options string and forcestat may not be combined."
		error 198
	}
	* clearall on its own simply empties the using file. LaTeX still needs the file to exist for \input, so we leave an empty file behind rather than deleting it.
	if "`clearall'"!="" & "`name'"=="" {
		tempname emptytexfile
		file open `emptytexfile' using "`using'", w replace
		file close `emptytexfile'
		disp as text "Cleared all statistics from `using'."
		exit
	}
	* Check to make sure the statistic is a number, or the expression will evaluate to a number. forcestat and string will override this.
	* The statistic is also evaluated here, into a scalar, rather than later on. Everything below this point calls r-class commands (findfile, file read), which wipe out the caller's r() results, so an expression like statistic(r(F)) has to be resolved before any of them run.
	tempname statvalue
	if "`forcestat'"=="" & "`string'"=="" {
		tempname statistic_check
		cap local `statistic_check' = `statistic'
		cap confirm number ``statistic_check''
		if _rc!=0 {
			disp as error "Statistic must be a real number or evaluate to a real number."
			disp as error "Use the string option to export text instead, or the forcestat option if you wish to proceed (highly discouraged)."
			error 498
		}
		scalar `statvalue' = `statistic'
	}
	* Hold the caller's r() results and put them back before exiting, so that consecutive calls such as statistic(r(F)) followed by statistic(r(df_r)) both see the results of the same estimation or test command.
	tempname rhold
	cap _return hold `rhold'
	local returnheld = (_rc==0)
	* These are LaTeX rules, so need to control.
	if "`name'"=="" {
		disp as error "Name cannot be empty."
		error 498
	}
	if "`forcename'"=="" & !regexm("`name'","^[a-zA-Z]*$") {
		disp as error "Name can only contain letters in the English alphabet."
		disp as error "Use forcename option to do this anyways (highly discouraged)."
		error 498
	}
	* Make sure you don't try to overwrite an existing LaTeX symbol/command. This is an imperfect approach, since packages might create extra commands. Computationally this makes the package slower, but is barely noticeable. The forcename option will skip this step, but you risk breaking your LaTeX document if you try to overwrite an existing LaTeX command.
	if "`forcename'"=="" {
		cap qui findfile "stattotex_SYMLIST.txt"
		tempname SYMLIST
		file open `SYMLIST' using "`r(fn)'", r
		file read `SYMLIST' linecur
			while r(eof)==0 {
				file read `SYMLIST' linecur
				tempname potentialLaTeXcmd
				local `potentialLaTeXcmd' = "\" + "`name'"
				if "`macval(linecur)'" == "``potentialLaTeXcmd''" {
					file close `SYMLIST'
					disp as error "``potentialLaTeXcmd'' is already an existing LaTeX command. Using this name will likely break your LaTeX document."
					disp as error "Use forcename option to do this anyways (highly discouraged)."
					error 498
				}
			}
		* Close the handle, otherwise it is left open for the rest of the session.
		file close `SYMLIST'
	}
	tempname statstring
	if "`forcestat'"=="" & "`string'"=="" {
		* If no formatting specified, convert to string as-is.
		if "`format'"=="" {
			local `statstring' = string(`statvalue')
		}
		* Otherwise, apply the specified formatting.
		else {
			local `statstring' = string(`statvalue', "`format'")
			if "``statstring''"=="" {
				disp as error "Option format incorrectly specified. See documentation."
				error 498
			}
		}
	}
	* With string or forcestat, the statistic is written exactly as given.
	else {
		if "`format'"!="" {
			if "`string'"!="" {
				disp as text "Warning: option format incompatible with string, format ignored."
			}
			else {
				disp as text "Warning: option format incompatible with forcestat, format ignored."
			}
		}
		local `statstring' `"`macval(statistic)'"'
	}
	* With string, escape the LaTeX special characters that would otherwise break compilation. Anything the user escaped by hand is protected first and restored afterwards, so manual escaping is never doubled up. Note that \ { } are deliberately left alone so that LaTeX markup (e.g. \textbf{...}) can still be passed through. char(36) is used in place of a literal dollar sign so that Stata does not read it as a global macro.
	if "`string'"!="" {
		local `statstring' = subinstr(`"``statstring''"',"\&",char(1),.)
		local `statstring' = subinstr(`"``statstring''"',"\%",char(2),.)
		local `statstring' = subinstr(`"``statstring''"',char(92)+char(36),char(3),.)
		local `statstring' = subinstr(`"``statstring''"',"\#",char(4),.)
		local `statstring' = subinstr(`"``statstring''"',"\_",char(5),.)
		local `statstring' = subinstr(`"``statstring''"',"&","\&",.)
		local `statstring' = subinstr(`"``statstring''"',"%","\%",.)
		local `statstring' = subinstr(`"``statstring''"',char(36),char(92)+char(36),.)
		local `statstring' = subinstr(`"``statstring''"',"#","\#",.)
		local `statstring' = subinstr(`"``statstring''"',"_","\_",.)
		local `statstring' = subinstr(`"``statstring''"',char(1),"\&",.)
		local `statstring' = subinstr(`"``statstring''"',char(2),"\%",.)
		local `statstring' = subinstr(`"``statstring''"',char(3),char(92)+char(36),.)
		local `statstring' = subinstr(`"``statstring''"',char(4),"\#",.)
		local `statstring' = subinstr(`"``statstring''"',char(5),"\_",.)
	}
	* Add a comment if there is one.
	if "`comment'"!="" {
		local comment = " % " + "`comment'"
		* Record date and time alongside a comment.
		if "`record'"!="" {
			if substr("`comment'",-1,1)!="." {
				local comment = "`comment'" + "."
			}
			local comment = "`comment'" + " " + "Created by stattotex at $S_TIME on $S_DATE."
		}
	}
	* Record date and time if no comment.
	else if "`record'"!="" {
		local comment = " % " + "Created by stattotex at $S_TIME on $S_DATE."
	}
	* Create the string that will be fed to LaTeX.
	tempname statstringfortex
	if "`string'"=="" {
		local `statstringfortex' = subinstr("\newcommand{\ `name'}{" + "``statstring''" + "}", " ", "", .) + "`comment'"
	}
	* Strings can legitimately contain spaces, so only strip the spaces out of the \newcommand{\name} portion of the line.
	else {
		local `statstringfortex' = subinstr("\newcommand{\ `name'}", " ", "", .) + "{" + `"``statstring''"' + "}" + "`comment'"
	}
	* Create a new LaTeX file that will be the final output.
	tempname newtexfile
	tempfile `newtexfile'
	file open `newtexfile' using "``newtexfile''", w
	* If the using LaTeX file already exists, we need to copy its contents over to the new file. If the statistic name has already been used, we either need to skip the line or throw an error if replace has not been specified.
	cap confirm file "`using'"
	local fileexists = (_rc==0)
	* clearall discards everything already in the file rather than copying it over.
	if `fileexists' & "`clearall'"!="" {
		cap erase "`using'"
		if _rc!=0 {
			sleep 200
			erase "`using'"
		}
		disp as text "Cleared all existing statistics from `using'."
	}
	else if `fileexists' {
		tempname oldtexfile
		file open `oldtexfile' using "`using'", r
		* Iterate over the lines of the file.
		file read `oldtexfile' linecur
		while r(eof)==0 {
		    * Check that the name hasn't already been used.
			tempname throwaway
			* Match the {\name} portion of the line. The character class excludes braces so that the match cannot run past the closing brace of the name and into the value, which matters for statistics that contain letters or braces (e.g. those written with the string option).
			local `throwaway' = regexm(`"`macval(linecur)'"',"\{\\[^{}]*\}")
			tempname potentialName
			local `potentialName' = ""
			* Only read regexs(0) if this line actually matched, otherwise it still holds the match from a previous line.
			if ``throwaway''==1 {
				local `potentialName' = substr(regexs(0),3,strlen(regexs(0))-3)
			}
			if "``potentialName''"=="`name'" {
			    * If name has already been used and replace option not specified, then throw error.
				if ("`replace'"=="") {
					file close `oldtexfile'
					file close `newtexfile'
					disp as error "A statistic named '`name'' already exists in `using'. Use replace option to overwrite."
					error 498
				}
			}
			else {
				file write `newtexfile' `"`macval(linecur)'"' _n
			}
			file read `oldtexfile' linecur
		}
		file close `oldtexfile'
		* Sometimes the program works too fast to erase this file, need to give a small pause.
		cap erase "`using'"
		if _rc!=0 {
			sleep 200
			erase "`using'"
		}
	}
	* If the using file does not exist, none of the above is necessary and we'll just create a new file.
	else {
		disp as text "File `using' not found, will be created."
	}
	* Write the new command into the file. Compound quotes so that statistics containing double quotes don't break the write.
	file write `newtexfile' `"``statstringfortex''"' _n
	file close `newtexfile'
	* Copy the temporary file over to its final location.
	copy "``newtexfile''" "`using'", replace
	* Put the caller's r() results back now that the r-class commands above are done with.
	if `returnheld' cap _return restore `rhold'
	disp as text `"Successfully exported the statistic '`name'' with value ``statstring'' to `using'."'
end