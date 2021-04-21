*! version 0.2  20apr2021
* This program exports numbers in Stata for easy inclusion in LaTeX documents.
* Author: Ian Sapollnik
* Date: April 20, 2021
program define stattotex
	version 10.0
	syntax using/, STATistic(string) name(string) [replace] [Format(string)] [comment(string)] [record] [FORCEName] [FORCEStat]
	* Check to make sure the statistic is a number, or the expression will evaluate to a number. forcestat will override this
		if "`forcestat'"=="" {
			tempname statistic_check
			cap local `statistic_check' = `statistic'
			cap confirm number ``statistic_check''
		if _rc!=0 {
			disp as error "Statistic must be a real number or evaluate to a real number."
			disp as error "Use the forcestat option if you wish to proceed (highly discouraged)."
			error 498
		}
	}
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
					disp as error "``potentialLaTeXcmd'' is already an existing LaTeX command. Using this name will likely break your LaTeX document."
					disp as error "Use forcename option to do this anyways (highly discouraged)."
					error 498
				}
			}
	}
	tempname statstring
	if "`forcestat'"=="" {
		* If no formatting specified, convert to string as-is.
		if "`format'"=="" {
			local `statstring' = string(`statistic')
		}
		* Otherwise, apply the specified formatting.
		else {
			local `statstring' = string(`statistic', "`format'")
			if "``statstring''"=="" {
				disp as error "Option format incorrectly specified. See documentation."
				error 498
			}
		}
	}
	else {
		if "`format'"!="" {
			disp as text "Warning: option format incompatible with forcestat, format ignored."
		}
		local `statstring' `statistic'
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
	local `statstringfortex' = subinstr("\newcommand{\ `name'}{" + "``statstring''" + "}", " ", "", .) + "`comment'"
	* Create a new LaTeX file that will be the final output.
	tempname newtexfile
	tempfile `newtexfile'
	file open `newtexfile' using "``newtexfile''", w
	* If the using LaTeX file already exists, we need to copy its contents over to the new file. If the statistic name has already been used, we either need to skip the line or throw an error if replace has not been specified.
	cap confirm file "`using'"
	if _rc==0 {
		tempname oldtexfile
		file open `oldtexfile' using "`using'", r
		* Iterate over the lines of the file.
		file read `oldtexfile' linecur
		while r(eof)==0 {
		    * Check that the name hasn't already been used.
			tempname throwaway
			local `throwaway' = regexm("`macval(linecur)'","\{\\([^)]+)[a-zA-Z]+\}")
			tempname potentialName
			local `potentialName' = substr(regexs(0),3,strlen(regexs(0))-3)
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
				file write `newtexfile' "`macval(linecur)'" _n
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
	* Write the new command into the file.
	file write `newtexfile' "``statstringfortex''" _n
	file close `newtexfile'
	* Copy the temporary file over to its final location.
	cp "``newtexfile''" "`using'"
	disp as text "Successfully exported the statistic '`name'' with value ``statstring'' to `using'."
end