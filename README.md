Rubycom
---------------

&copy; Danny Purcell 2013 | MIT license

Makes creating command line tools as easy as including Rubycom.

When a Module which has included Rubycom is run from the terminal, Rubycom will parse ARGV for a command name,
match the command name to a method in the including module, and run the method with the given arguments.

Features
---------------

Allows the user to write a properly documented module/class and convert it to a command line tool
by simply including Rubycom at the bottom.

* Provides a Command Line Interface for any library simply by stating `include Rubycom` at the bottom.
* Public singleton methods are made accessible from the terminal. Usage documentation is pulled from method comments.
* Method parameters become required CLI arguments. Optional (defaulted) parameters become CLI options.
* Command consoles can be built up by including other modules before including Rubycom.
* Included modules become commands, their public singleton methods become sub-commands.
* Built in tab completion support for all commands.
    * Users may call `./path/to/my_command.rb register_completions` then `source ~/.bash_profile` to register completions.
* Customize Rubycom's functionality by calling `Rubycom.run_command` with custom plugin modules.
* When calling run_command, functionality can be easily modified by providing a custom module for one of the following
keys `:arguments, :discover, :documentation, :source, :parameters, :executor, :output, :interface, :error` in plugins_options.

Installation
---------------

#### Install with Gem
* Available on [Rubygems](https://rubygems.org/gems/rubycom)
* Be sure one of your gem sources is `source 'https://rubygems.org'`
* Run `gem install rubycom`

#### Building locally
* Fork the repository if you wish
* Clone repository locally
    * If using the main repo: `git clone https://github.com/dannypurcell/rubycom.git`
* Run `rake install` if installing for the first time
* If updating to the latest version run the following commands
    * `git checkout master`
    * `git pull origin master`
        * If that causes any problems `git reset --hard origin/master`
    * `rake upgrade`

Usage
---------------

Write your library, document them as you normally would. `include Rubycom` at the bottom.
Optionally `#!/usr/bin/env ruby` at the top.

Now any singleton methods `def self.method_name` will be available to call from the terminal.

Calling `ruby ./path/to/module.rb <command_name>` will automatically discover and run your `<command_name>` singleton method.
If no method is found by the given name, a usage print out will be given including a summary of each command available
and it's description from the corresponding method's comments.

Calling a valid command with incorrect arguments will produce a usage print out for the matched method.
Rubycom will include as much documentation on the command line as you provide in your method comments. Currently Rubycom
only handles YardDoc style comments for discovering the parameter and return documentation. All other commentary will be
included as part of the command description. In the absence of YardDoc annotations, Rubycom will generate a clean usage
text which may work for your method doc even though Rubycom is not specifically parsing it.


#####Special commands

| Command | Description | Options |
| ------- |:-----------:| -------:|
| `ruby ./path/to/module.rb help [command_name]` | Will print out usage for the module or optionally the specified command.||
| `ruby ./path/to/module.rb register_completions ` | Setup bash tab completion ||
| `ruby ./path/to/module.rb tab_complete [text]` | Print a list of possible matches for a given word ||

###Arguments

When using Rubycom's default modules:
* Arguments are automatically parsed from the command line using Rubycom's ArgParse module and converted to Ruby types
by Ruby's core Yaml module.
* Arguments will be passed to your method in order of their appearance on the command line. With smart parsing for
option arguments and flags.
* If you specify a default value for a parameter in your method, then Rubycom will look for a named option argument in
the command line which matches the parameter's name or the first letter in the parameter name if it is unique among the
other method parameters.
* Users may call out option parameters in any order using `--<param_name>=<value>`, `--<param_name> = <value>`, or
`--<param_name> <value>`
    * Rubycom attempts to handle short names for optional parameters so specifying `-<p> <value>` or `-<param> <value>`
        is equivalent to `--<parameter> <value>` if the characters uniquely match a parameter name in the called method.
* Any parameter which is not mentioned in the command line will receive one of the remaining, unnamed arguments in order
of appearance.
* Optional parameters which do not get overridden either by a named optional argument or an available unnamed command line
    argument will be filled by their default as usual.
* If a rest parameter `*param_name` is defined in the method being called, any remaining arguments will be passed to the
    rest parameter after the required and optional parameters are filled.

Raison d'etre
---------------

* Command line scripts written from scratch often include redundant ARGV parsing code, little or no testing, and slim documentation.
  Development speed is important and setting up a properly documented and tested terminal interface takes a while.
* OptionParser and the like help script authors define options for a script.
  They provide structure to the redundant code and slightly easier argument specification.
* Thor and the like provide a framework the script author will extend to create command line tools.
  The Prescriptive approach creates consistency but requires the script author to learn the framework and conform.

While these are things do help, we are still writing redundant code and tightly coupling the functional code to the
interface which presents it. We also lack a generic command line parser which, if available, could help encourage
Rubyists to standardize command line inputs.

So, what to do?

...Ruby is interpreted...use the source.

Rather than making concessions for the presentation and tightly coupling the functional code
to the interface, it would be nice if a script author could simply write their code and attach the interface to it.


How it works
---------------
Rubycom attaches the CLI to the functional code. The author is free to write the functional code as any other.
If a library needs to be accessible from the terminal, just `include Rubycom` at the bottom of the main Module and run
the ruby file.

* Methods are made accessible from the terminal.
* ARGV is parsed for a method to run and arguments.
* Usage documentation is pulled from method comments.
* Method parameters become required CLI arguments.
* Optional (defaulted) parameters become CLI options.
* Tab completion support if the user has registered it for the file.

The result is a library which can be consumed easily from other classes/modules and which is accessible from the command line.

Customizing Rubycom
---------------

Note: The plugin_options hash is currently taking Modules and calling specific methods on them. This will change to a
Symbol => Proc mapping soon. Please log an issue on [GitHub](https://github.com/dannypurcell/rubycom/issues) if you
want this right away.

Rubycom is designed to fit several different ways of calling command line utilities and to respect many of the
strong conventions regarding command line semantics. While Rubycom's default functionality should fit many common use
cases it is also built in a modular fashion such that the core functionality can be easily adapted to fit specific
requirements or user preferences.

* Calling Rubycom via `include Rubycom` will attempt to execute the default functionality.
* Alternately, calling `Rubycom.run_command(base, args=[], plugins_options={})` directly enables the user to inject
custom modules for specific portions of the execution via the plugin_options parameter.

#####Plugin Module Contracts

| Key | Expected Inputs | Expected Outputs |
| -------------- |:---------------:|:----------------:|
| :arguments | ARGV | A data structure representing the arguments, options, and flags |
| :discover | The Module which included Rubycom and a parsed command line | A Method or Module representing the command which should be run  |
| :documentation | The command to run and the :source plugin | The command matched to it's documentation |
| :source | A Module or Method object | The source code for that reference |
| :parameters | A command, a parsed command line, and the command documentation | The command parameters matched to their values for this run |
| :executor | A command to execute and the command parameters matched to their values for this run | The result of a call to the given method with the given parameters |
| :output | The command result | Some output handling action |
| :interface | A command and it's documentation | A string representing the usage text to present in a terminal |
| :error | An Error and a String representing usage text | Some error handling action |


