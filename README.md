Rubycom
---------------

&copy; Danny Purcell 2013 | MIT license

Makes creating command line tools as easy as writing a function library.

When a module is run from the terminal and includes Rubycom, Rubycom will parse ARGV for a command name,
match the command name to a public method in the including module, and run the method with the given arguments.

Features
---------------

Allows the user to write a properly documented module/class and convert it to a command line tool
by simply including Rubycom at the bottom.

* Provides a Command Line Interface for any module simply by stating `include Rubycom` at the bottom.
* Public methods are made accessible from the terminal. Usage documentation is pulled from method comments.
* Method parameters become required CLI arguments. Optional (defaulted) parameters become CLI options.
* Command consoles can be built up by including other modules before including Rubycom.


Raison d'etre
---------------

* From scratch command line scripts often include redundant ARGV parsing code, little to no testing, slim documentation.
* OptionParser and the like helps script authors define options for a script.
  They provide structure to the redundant code and slightly easier argument parsing.
* Thor and the like provide a framework the script author will extend to create command line tools.
  Prescriptive approach creates consistency, requires the script author to learn the framework and conform.

While these are things are nice, we are still writing redundant code and
tightly coupling the functional code to the interface which presents it.

At it's core a terminal command is a function. Rather than requiring the authors to make concessions for the presentation and
tightly couple the functional code to the interface, it would be nice if the author could simply write a function library
and attach the interface to it.

How it works
---------------
Rubycom attaches the CLI to the functional code. The author is free to write the functional code as any other.
If a set of functions needs to be accessible from the terminal, just `include Rubycom` at the bottom and run the ruby file.

* Public methods are made accessible from the terminal.
* ARGV is parsed for a method to run and arguments.
* Usage documentation is pulled from method comments.
* Method parameters become required CLI arguments.
* Optional (defaulted) parameters become CLI options.

The result is a function library which can be consumed easily from other classes/modules and which is accessible from the command line.

Coming Soon
---------------
* Included modules become commands, their public methods become sub-commands rather than including their methods in the main module.
* Run Pre-configured sets of commands from a yaml file by calling <script.rb> job <job_yaml>
* Job help/usage output will include descriptions from command for each step
* Build a job yaml by running each command in sequence with a special option --job_add <path_to_yaml>
* Edit job files from the command line using special options.
    * --job_update <path_to_yaml>
    * --job_rm <path_to_yaml>
