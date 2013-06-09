Rubycom
---------------

&copy; Danny Purcell 2013 | MIT license

Makes creating command line tools as easy as writing a function library.

When a module is run from the terminal and includes Rubycom, Rubycom will parse ARGV for a command name,
match the command name to a public singleton method (self.method_name()) in the including module, and run the method
with the given arguments.

Features
---------------

Allows the user to write a properly documented module/class as a function library and convert it to a command line tool
by simply including Rubycom at the bottom.

* Provides a Command Line Interface for any function library simply by stating `include Rubycom` at the bottom.
* Public singleton methods are made accessible from the terminal. Usage documentation is pulled from method comments.
* Method parameters become required CLI arguments. Optional (defaulted) parameters become CLI options.
* Command consoles can be built up by including other modules before including Rubycom.
* Included modules become commands, their public singleton methods become sub-commands.

Usage
---------------

Write your module of methods, document them as you normally would. `include Rubycom` at the bottom.
Optionally `#!/usr/bin/env ruby` at the top.

Now any singleton methods `def self.method_name` will be available to call from the terminal.

Calling `ruby ./path/to/module.rb <command_name>` will automatically discover and run your `<command_name>` singleton method.
If no method is found by the given name, a usage print out will be given including a summary of each command available
and it's description from the corresponding method's comments.

Calling a valid command with incorrect arguments will produce a usage print out for the matched method.
Rubycom will include as much documentation on the command line as you provide in your method comments. Currently Rubycom
only handles @param and @return annotation style comments for discovering the method comments regarding params and return values.
All other commentary will be included as part of the command description. In the absence of @param or @return comments,
Rubycom will also leave off the corresponding Param: and Return: markers in the usage output.

#####Special commands

| Command | Description | Options |
| ------- |:-----------:| -------:|
| `ruby ./path/to/module.rb help [command_name]` | Will print out usage for the module or optionally the specified command.||
| `ruby ./path/to/module.rb job </path/to/job.yaml>` | Runs the specified job file. See: "Jobs" below. | `--test` Prints the steps and context without running the commands. |


###Arguments

* Arguments are automatically parsed from the command line using Ruby's core Yaml module.
* Arguments will be passed to your method in order of their appearance on the command line.
* If you specify a default value for a parameter in your method, then Rubycom will look for a named argument matching
    the parameter's name.
* Users may call out option parameters in any order using `--<param_name>=<value>` or `--<param_name> <value>`
    * Currently Rubycom does not yet support sort names for optional parameters so specifying `-<param_name>`
        is equivalent to `--<param_name>`
* In the absence of a named option, any optional parameters still unfilled will be filled by unnamed arguments in
    order of appearance.
* Optional parameters which do not get overridden either by a named option specification or an available unnamed
    argument will be filled by their default as usual.
* If a rest parameter `*param_name` is defined in the method being called, any remaining arguments will be passed to the
    rest parameter after the required and optional parameters are filled.

###Jobs

Jobs are a higher order orchestration mechanism for command line utilities. Rubycom provides a simple job runner to every
command line utility. by calling `ruby ./path/to/module.rb job </path/to/job.yaml>` with a valid job yaml. Rubycom will
run your job.

* A valid job file is a Yaml file which specifies a `steps` node and any number of valid numbered child nodes
* Optionally, an `env` node may specified.
    * If specified, `env` should include child nodes which are `key: value` pairs Ex: `working_dir: ./test/rubycom`
    * If an `env` is specified, values may be inserted into commands in the `steps` node as such: `env['key']`
         * Ex: `ruby env[working_dir]/util_test_composite.rb test_composite_command env[test_msg]`
* A valid `steps` child node is a numbered node `1:` with a `cmd:` child node and optionally several context `desc:`
    child nodes.
* A `cmd:` node should specify the command string to run. Ex: `cmd: ls ./test_folder`
* A context node should specify some text to be placed with the node's key in a formatted
    logging context Ex: `desc: Run test_composite_command`

Below is an example job file which demonstrates the format Rubycom supports.

    ---
    env:
      test_msg: Hello World
      test_arg: 123
      working_dir: ./test/rubycom
    steps:
      1:
        desc: Run test_composite_command with environment variable
        cmd: ruby env[working_dir]/util_test_composite.rb test_composite_command env[test_msg]
      2:
        Var: Run UtilTestModule/test_command_options_arr with environment variable
        cmd: ruby env[working_dir]/util_test_composite.rb UtilTestModule test_command_options_arr '["Hello World", world2]'
      3:
        Context: Run test_command_with_args with environment variable
        cmd: ruby env[working_dir]/util_test_module.rb test_command_with_args env[test_msg] env[test_arg]
      4:
        Cmd: Run ls for arbitrary command support
        cmd: ls
      5:
        Arbitrary_Context: Run ls with environment variable
        cmd: ls env[working_dir]


Raison d'etre
---------------

* From scratch command line scripts often include redundant ARGV parsing code, little to no testing, slim documentation.
* OptionParser and the like help script authors define options for a script.
  They provide structure to the redundant code and slightly easier argument parsing.
* Thor and the like provide a framework the script author will extend to create command line tools.
  Prescriptive approach creates consistency but requires the script author to learn the framework and conform.

While these are things are nice, we are still writing redundant code and
tightly coupling the functional code to the interface which presents it.

At it's core a terminal command is a function. Rather than requiring the authors to make concessions for the presentation and
tightly couple the functional code to the interface, it would be nice if the author could simply write a function library
and attach the interface to it.

How it works
---------------
Rubycom attaches the CLI to the functional code. The author is free to write the functional code as any other.
If a set of functions needs to be accessible from the terminal, just `include Rubycom` at the bottom and run the ruby file.

* Public singleton methods are made accessible from the terminal.
* ARGV is parsed for a method to run and arguments.
* Usage documentation is pulled from method comments.
* Method parameters become required CLI arguments.
* Optional (defaulted) parameters become CLI options.

The result is a function library which can be consumed easily from other classes/modules and which is accessible from the command line.

Coming Soon
---------------
* Build a job yaml by running each command in sequence with a special option --job_add <path_to_yaml>[:step_number]
* Edit job files from the command line using special options.
    * --job_update <path_to_yaml>[:step_number]
    * --job_remove <path_to_yaml>[:step_number]