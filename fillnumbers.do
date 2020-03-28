clear all
global output  "C:\Users\iansa\Github\stattotex"

* This do file has examples of how to use stattotex command.

* The most basic command is this:
stattotex using "$output/numbersintext.tex", statistic(12345.678) name(statA) replace
	// produces \newcommand{statA}{12345.678}
/*
using works the same as any other stata command
, statistic() or stat() is mandatory. This is the statistic you want to show up in latex, and must be a real number.
, name() is mandatory. It is the name you want to assign for your statistic. You can later call this in latex as \name. Importantly: you can never put any numeric characters into name() and stattotex will throw an error if you do. This is a latex issue - numbers are not allowed in commands.
, replace is optional. But if the name has already been used in the using file, stattotex will throw an error if you don't use replace. If you include replace, it will overwrite the old command.

This will put the line \newcommand{NAME}{STATISTIC} into the USING file. At the top of the latex file you're using, put in the command \input{USING}. Then, anywhere throughout the file, you can call \NAME to have STATISTIC appear.
*/

* There are also a few optional features to format your statistic. For example, you can choose how you want to format the statistic using normal Stata formatting using the format() or f() option.
stattotex using "$output/numbersintext.tex", stat(12345.678) name(statB) replace format("%9.2f")
	// produces \newcommand{statB}{12345.68}
stattotex using "$output/numbersintext.tex", stat(12345.678) name(statC) replace f("%9.0fc")
	// produces \newcommand{statC}{12,346}

* You can also comment of your choice to the statistic using the comment() option. This is useful if you want to note where the statistic came from in your code.
stattotex using "$output/numbersintext.tex", stat(12345.678) name(statD) replace comment("Look at line 25 of fillnumbers.do")
	// produces \newcommand{statD}{12345.678} % This is a comment. Look at line 25 of fillnumbers.do.

* Finally, you can also record the exact date and time when your statistic was made using record.
stattotex using "$output/numbersintext.tex", stat(12345.678) name(statE) replace record
	// produces \newcommand{statE}{12345.678} % Created by stattotex at $S_TIME on $S_DATE.
	
* Or you can do both.
stattotex using "$output/numbersintext.tex", stat(12345.678) name(statF) record comment("This is a comment") replace
	// produces \newcommand{statF}{12345.678} % This is a comment. Created by stattotex at $S_TIME on $S_DATE.
	
* The best use of this command is with locals. Let's create some fake data to show.
clear
set seed 42
set obs 1000
gen X = runiform()
gen Y = rnormal()
gen Z = X^2 - Y^3
qui sum Z if X>0.6 & Y<=0, meanonly
local meanZ = `r(mean)'
stattotex using "$output/numbersintext.tex", stat(`meanZ') name(meanZ) replace f("%9.2f") record comment("This is the mean Z when X>0.6 & Y<=0.")
	// produces \newcommand{\meanZ}{2.39} % This is the mean Z when X>0.6 & Y<=0. Created by stattotex at 14:33:30 on 28 Mar 2020.

* And you don't even need to input a number directly - you can just put in something that evaluates within the command. For example:
stattotex using "$output/numbersintext.tex", stat(exp(`meanZ'^2-1)/100+3) name(complexexample) replace f("%9.3fc") record
	// produces \newcommand{\complexexample}{4.123} % Created by stattotex at 14:37:19 on 28 Mar 2020.


/* Advanced: LaTeX has a lot of built-in commands. So if you want to name one of 
 your commands "beta", you'll run into issues when you try to compile, as LaTeX 
has already defined the command \beta to mean the greek letter. To prevent this 
issue, the package will stop you from overwriting an existing LaTeX command by 
throwing an error. This is imperfect - you might be using a package that defines
 more commands that aren't included in base LaTeX, so just be cautious about 
this in general. If for some reason you really want to do this, you can use the 
forcename option in stattotex. This is highly discouraged, however. 
Similarly, stattotex will ensure that the statistic you provide is or evaluates 
to a real number. The forcestat option will override this.*/