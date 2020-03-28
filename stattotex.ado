* This program exports numbers in Stata for easy inclusion in LaTeX documents
* Author: Ian Sapollnik
* Date: March 27, 2020
program define stattotex
	syntax using/, STATistic(real) name(string) [replace] [Format(string)] [comment(string)] [record] [force]
	* These are LaTeX rules, so need to control.
	if regexm("`name'","[0-9]") {
		disp as error "Name cannot have numeric characters."
		error 498
	}
	if "`name'"=="" {
		disp as error "Name cannot be empty."
		error 498
	}
	if !regexm("`name'", "^[a-zA-Z]*$") {
		disp as error "Name can only contain standard letters."
		error 498
	}
	* Make sure you don't try to overwrite an existing LaTeX symbol/command. This is an imperfect approach, since packages might create extra commands. Computationally this makes the package slower, but not by too much. The "force" option will skip this step, but you risk breaking your LaTeX document if you try to overwrite an existing LaTeX command.
	if "`force'"=="" {
		tempname SYMLIST
		file open `SYMLIST' using "SYMLIST.txt", r
		file read `SYMLIST' linecur
			while r(eof)==0 {
				file read `SYMLIST' linecur
				if "`macval(linecur)'"=="\" + "`name'" {
					disp as error "This is name is already an existing LaTeX command. Using it this will very likely break your LaTeX document. Use force option to do this anyways."
				}
			}
	}
	* If no formatting specified, convert to string as-is.
	if "`format'"=="" {
		local statstring "`statistic'"
	}
	* Otherwise, apply the specified formatting.
	else {
		local statstring = string(`statistic', "`format'")
	}
	* Add a comment if there is one.
	if "`comment'"!="" {
		local comment = " % " + "`comment'"
		* Record date and time alongside a comment.
		if "`record'"!="" {
			local comment = "`comment'" + " " + "Created by stattotex at $S_TIME on $S_DATE."
		}
	}
	* Record date and time alone.
	else if "`record'"!="" {
		local comment = " % " + "Created by stattotex at $S_TIME on $S_DATE."
	}
	* Create the string that will be fed to LaTeX.
	local statstringfortex = subinstr("\newcommand{\ `name'}{" + "`statstring'" + "}", " ", "", .) + "`comment'"
	* Create a new LaTeX file that will be the final output.
	tempname newtexfile
	tempfile `newtexfile'
	file open `newtexfile' using "``newtexfile''", w
	* If the using LaTeX file already exists, we need to copy its contents over to the new file. If the name has already been used, we either need to skip the line or throw an error if replace has not been specified.
	capture confirm file "`using'"
	if _rc==0 {
		tempname oldtexfile
		file open `oldtexfile' using "`using'", r
		* Iterate over the lines of the file.
		file read `oldtexfile' linecur
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
		cap erase "`using'"
		if _rc!=0 {
			sleep 200
			erase "`using'"
		}
	}
	else {
		di "File `using' not found, will be created."
	}
	* Write the new command into the file.
	file write `newtexfile' "`statstringfortex'" _n
	file close `newtexfile'
	* Copy the temporary file over to its final location.
	cp "``newtexfile''" "`using'"
end