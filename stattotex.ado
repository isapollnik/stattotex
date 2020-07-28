/*
* @Author: Ian Sapollnik
* @Date:   March 28, 2020
* @Last Modified by:   ChristianKontz
* @Last Modified time: 2020-07-27 21:09:08
*/

* This program exports numbers in Stata for easy inclusion in LaTeX documents
* Author: Ian Sapollnik
* Date: March 28, 2020
program stattotex
	
	syntax using/, ///
		STATistic(string) ///
		name(string) /// 
		[replace] ///
		[Format(string)] ///
		[comment(string)] /// Add a comment
		[record] /// Record date and time alongside a comment
		[FORCEName] ///
		[FORCEStat] /// 
		[STRing] /// Allows strings as statistics
		[RESpect] // Respect existing files (important for symlinks)

	* Check to make sure the statistic is a number, or the expression will evaluate to a number. forcestat will override this
		if "`forcestat'"==""  & "`string'"==""{
			tempname statistic_check
			cap local `statistic_check' = `statistic'
			cap confirm number ``statistic_check''
		if _rc!=0 {
			disp as error "Statistic must be a real number or evaluate to a real number when option str is not specified."
			disp as error "Use the forcestat option if you wish to proceed (highly discouraged)."
			error 498
		}
	}
	* These are LaTeX rules, so need to control.
	if regexm("`name'","[0-9]") {
		disp as error "Name cannot have numeric characters."
		error 498
	}
	if "`name'"=="" {
		disp as error "Name cannot be empty."
		error 498
	}
	if !regexm("`name'","^[a-zA-Z]*$") {
		disp as error "Name can only contain standard letters."
		error 498
	}
	/* Make sure you don't try to overwrite an existing LaTeX symbol/command. This is an imperfect approach,
	 since packages might create extra commands. Computationally this makes the package slower, 
	 but not by too much. The forcename option will skip this step, but you risk breaking your LaTeX 
	 document if you try to overwrite an existing LaTeX command. */
	if "`forcename'"=="" {
		cap qui findfile "stattotex_SYMLIST.txt"
		tempname SYMLIST
		file open `SYMLIST' using "`r(fn)'", r
		file read `SYMLIST' linecur
			while r(eof)==0 {
				file read `SYMLIST' linecur
				if "`macval(linecur)'" == "\" + "`name'" {
					disp as error "This is name is already an existing LaTeX command. Using it this will very likely break your LaTeX document."
					disp as error "Use forcename option to do this anyways (highly discouraged)."
					error 498
				}
			}
	}
	tempname statstring
	if "`forcestat'"=="" & "`string'"=="" {
		* If no formatting specified, convert to string as-is.
		if "`format'"=="" {
			local `statstring' = string(`statistic')
		}
		* Otherwise, apply the specified formatting.
		else {
			local `statstring' = string(`statistic', "`format'")
		}
	}
	else {
		local `statstring' "`statistic'"
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
	if "`string'"=="" local `statstringfortex' = subinstr("\newcommand{\ `name'}{" + "``statstring''" + "}", " ", "", .) + "`comment'"
	if "`string'"!="" local `statstringfortex' = "\newcommand{\\`name'}{{" + "``statstring''" + "}}" + "`comment'"
	* Create a new LaTeX file that will be the final output.
	tempname newtexfile
	tempfile `newtexfile'
	file open `newtexfile' using "``newtexfile''", w
	/* If the using LaTeX file already exists, we need to copy its contents over to the new file. 
	If the name has already been used, we either need to skip the line or throw an error if replace has not been specified. */
	cap confirm file "`using'"
	if _rc==0 {
		if "`respect'"==""{ // do not respect existing files and just replace old file with new file containing old and new content
			tempname oldtexfile
			file open `oldtexfile' using "`using'", r
			* Iterate over the lines of the file.
			file read `oldtexfile' linecurstat
			while r(eof)==0 {
				if regexm(subinstr("`macval(linecur)'", "\newcommand{", "", .),"`name'") {
					if ("`replace'"=="") {
						file close `oldtexfile'
						file close `newtexfile'
						disp as error "Name already exists in `using'. Use replace option to overwrite."
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
		else{ // be mindful of existing files and just append the existing using command line / terminal tools
			 local `statstringfortex' = "\\\newcommand{\\\\`name'}{{" + "``statstring''" + "}}" + "`comment'"
			 if "`c(os)'" == "MacOSX" | "`c(os)'"=="UNIX" | "`c(os)'"=="Unix" {
				! printf "``statstringfortex''" >> "`using'"
				! echo "" >> "`using'"
			 }
			 else { // windows (not 100% sure that works too)
				! printf "``statstringfortex''" >> "`using'"
				! echo "" >> "`using'"
			 }

		}
	}
	else {
		disp as text "File `using' not found, will be created."
		* Write the new command into the file. 
		file write `newtexfile' "%--------------------------------------%" 	_n ///
									"% Preamble for hyphenated strings:" 	_n ///
									"\usepackage[USenglish]{babel}"  		_n /// 
								"%--------------------------------------%" 	_n

	file write `newtexfile' _n "``statstringfortex''" _n
	file close `newtexfile'
	* Copy the temporary file over to its final location.
	cp "``newtexfile''" "`using'"
	}
end
