{smcl}
{* *! version 0.1  10august2020}{...}
{viewerjumpto "Syntax" "stattotex##syntax"}{...}
{viewerjumpto "Description" "stattotex##description"}{...}
{viewerjumpto "Options" "stattotex##options"}{...}
{viewerjumpto "Examples" "stattotex##examples"}{...}
{viewerjumpto "Including results in LaTeX" "stattotex##latex"}{...}
{viewerjumpto "Author" "stattotex##author"}{...}
{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{hi:stattotex} {hline 2}} Exporting values for inclusion in LaTeX.{p_end}
{p2colreset}{...}


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:stattotex}
{cmd:using} {it:{help filename}} {cmd:,} {cmdab:stat:istic}({it:statistic}) {cmd:name}({it:string})
[{it:other options}]

{synoptset 26 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab :Mandatory}
{synopt :{opt stat:istic(#)}}specifies the statistic that you want to output{p_end}
{synopt :{opt name(string)}}assigns a name to your statistic{p_end}

{syntab :Replacing}
{synopt :{opt replace}}replaces a statistic of the same name if it exists. {cmd:stattotex} will throw an error if one exists and this option is not specified{p_end}

{syntab :Formatting}
{synopt :{opth f:ormat(%fmt)}}selects the format for the statistic{p_end}

{syntab :Documentation}
{synopt :{opt record}}records the date and time the statistic was created as a comment in LaTeX{p_end}
{synopt :{opt comment(string)}}records a comment of your choosing in LaTeX{p_end}

{syntab :Advanced}
{synopt :{opt forcen:ame}}forces the name you assign without any checks{p_end}
{synopt :{opt forces:tat}}forces the statistic you assign without any checks{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt stattotex} is a simple Stata program to name and export a value from Stata into a LaTeX document, for easy entry, updating, checking and replicating with minimal errors.

{pstd}
{cmd:stattotex} is compatible with Stata v10.0+. While it may be compatible with earlier versions, it has not been tested in those environments.

{pstd}
In order to utilize the output of {cmd:stattotex}, you must include the file called in {it:{help filename}} at the beginning of your LaTeX document. See {help stattotex##latex:section below} for more details.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}{opt stat:istic(#)} specifies the statistic that you want to output to LaTeX, which can be specified as a number (e.g. 1.234), an expression that evaluates to a number (e.g. 2*3+4), or a Stata macro that evaluates to a number 
(e.g. $mystat). The option also accepts a string, so long as the string has numeric contents (e.g. "1.234") or is an expression that evaluates to
a number (e.g. "2*(3+4)"). If for some reason you want to override these limitations, use the {cmdab:forces:tat} option.

{phang}{opt name(string)} assigns a name to your statistic. The name can only contain letters in the English alphabet, as this is necessary for LaTeX to compile properly. {cmd:stattotex} also ensures that the name is not a default
LaTeX command, such as \beta, unless the {cmdab:forcen:ame} option is also used. NB: while {cmd:stattotex} checks against a list of base LaTeX commands to ensure no conflicts, it cannot control for command names used by
packages in your LaTeX file.

{dlgtab:Replacing}

{phang}{opt replace} tells {cmd:stattotex} to replace an existing statistic in the {it:using} file with the new statistic. This option is {bf:not} telling {cmd:stattotex} to replace the {it:using} file itself -
{cmd:stattotex} already does that by default so long as it does not encounter any errors. Instead this option is for replacing individual statistics within a file.
If a statistic with the same name already exists and {opt replace} is not specified, {cmd:stattotex} will throw an error.

{dlgtab:Formatting}

{phang}{opth f:ormat(%fmt)} formats the statistic using standard Stata syntax. See {help format:formatting help} for details. If the option is not used, {cmd:stattotex} will round to 2 decimal places by default when statistics
have more than 2 decimals.

{dlgtab:Documentation}

{phang}{opt record} records the date and time the statistic was created as a comment in the {it:using} document, and states that the statistic was produced by {cmd:stattotex}. This is useful mainly for transparency/replication purposes. 

{phang}{opt comment(string)} creates a comment of your choosing in the {it:using} document, beside your statistic.

{phang} Options {opt record} and {opt comment(string)} can be specified together without any issues.

{dlgtab:Advanced}

{phang}{opt forcen:ame} overrides {cmd:stattotex}'s default name checking, which ensures your chosen name isn't an existing LaTeX command.

{phang}{opt forces:tat} overrides {cmd:stattotex}'s default statistic checking, which ensures the statistic evaluates to a number. NB: the option {opth f:ormat(%fmt)} will be ignored if {opt forces:tat} is specified.

{phang} Both forcing options can cause your LaTeX document to break before compiling and thus their use is discouraged.


{marker examples}{...}
{title:Examples}

{pstd}The most basic command is this:{p_end}
{phang2}. {stata stattotex using "~/Desktop/stattotexexample.tex", statistic(12345) name(statA) replace}{p_end}
{phang2}This will put the line {it:\newcommand{statA}{12345}} into the file stattotexexample.tex.{p_end}

{pstd}You can choose how you want to format the statistic using normal Stata formatting with the {opt f:ormat(%fmt)} option:{p_end}
{phang2}. {stata stattotex using "~/Desktop/stattotexexample.tex", stat(12345.678) name(statB) replace}{p_end}
{phang2}This will put the line {it:\newcommand{statB}{12345.68}} into the file stattotexexample.tex, because the {opt f:ormat(%fmt)} option was not specified and {cmd:stattotex} rounds to 2 decimal places by default.{p_end}
{phang2}. {stata stattotex using "~/Desktop/stattotexexample.tex", stat(12345.678) name(statB) replace format("%9.3f")}{p_end}
{phang2}Let's try again. This will put the line {it:\newcommand{statB}{12345.678}} into the file stattotexexample.tex.{p_end}
{phang2}. {stata stattotex using "~/Desktop/stattotexexample.tex", stat(12345.003) name(statC) replace f("%9.0fc")}{p_end}
{phang2}This will put the line {it:\newcommand{statC}{12,345}} into the file stattotexexample.tex.{p_end}

{pstd}You can comment of your choice to the statistic using the {opt comment(string)} option. This is useful if you want to note where the statistic came from in your code.{p_end}
{phang2}. {stata stattotex using "~/Desktop/stattotexexample.tex", stat(12345.67) name(statD) replace comment("Created by the stattotex help file.")}{p_end}
{phang2}This will put the line {it:\newcommand{statD}{12345.678} % Created by the stattotex help file.} into the file stattotexexample.tex.{p_end}

{pstd}You can you can also record the exact date and time when your statistic was made using {opt record}.{p_end}
{phang2}. {stata stattotex using "~/Desktop/stattotexexample.tex", stat(3.14) name(statE) replace record}{p_end}
{phang2}This will put the line {it:\newcommand{statE}{3.14} % Created by stattotex at $S_TIME on $S_DATE.} into the file stattotexexample.tex, where $S_TIME and $S_DATE will evaluate to the current time and date.{p_end}


{marker latex}{...}
{title:Including results in LaTeX}

{pstd}To include the output from your stattotex file into your LaTeX document, simply include the line "\input{YOURFILE.tex}" immediately after "\begin{document}".
Then, if you have a statistic called "maincoef", you can call this statistic in LaTeX using "\maincoef".{p_end}

{marker author}{...}
{title:Author}

{pstd}Ian Sapollnik{p_end}
{pstd}Department of Economics and School of Public and International Affairs, Princeton University{p_end}
{pstd}isapollnik@princeton.edu{p_end}
