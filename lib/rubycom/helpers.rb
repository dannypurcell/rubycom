module Rubycom
  module Helpers

    # Arranges each given tag hash such that all tags will line up nicely in vertical columns.
    #
    # @param [Array] tag_list an Array of Hashes which include keys: :name, :tag_name, :text, :types
    # @param [Integer] desc_width the maximum width to use for the description column
    # @return [Array] a list of strings comprised of "#{types}#{separator}#{name||tag_name}#{separator}#{text}"
    # formatted to line up vertically
    def self.format_tags(tag_list, desc_width = 90)
      tag_list = [] if tag_list.nil?
      longest_name = self.get_longest_command_name(tag_list.map { |tag| (tag[:name].nil?) ? tag[:tag_name] : tag[:name] })
      longest_types = self.get_longest_command_name(tag_list.map { |tag| "#{tag[:types]}" })
      longest_combo_name = self.get_longest_command_name(tag_list.map { |tag| "#{tag[:tag_name]}#{tag[:name]}" })
      {
          others: tag_list.select { |tag| !["param", "return"].include?(tag[:tag_name]) }.map { |tag|
            combo_name = "#{tag[:tag_name]}: #{tag[:name]}"
            "#{tag[:types]}#{self.get_separator(tag[:types], longest_types, ' ')}#{self.format_command_summary(combo_name, tag[:text], self.get_separator(combo_name, longest_combo_name), desc_width)}"
          },
          params: tag_list.select { |tag| tag[:tag_name] == "param" }.map { |tag|
            "#{tag[:types]}#{self.get_separator(tag[:types], longest_types, ' ')}#{self.format_command_summary(tag[:name], tag[:text], self.get_separator(tag[:name], longest_name), desc_width)}"
          },
          returns: tag_list.select { |tag| tag[:tag_name] == "return" }.map { |tag|
            "#{tag[:types]}#{self.get_separator(tag[:types], longest_types , ' ')}#{self.format_command_summary(tag[:tag_name], tag[:text], self.get_separator(tag[:tag_name], longest_name), desc_width)}"
          }
      }
    end

    # Arranges each given command_name => command_description with a separator such that all command names and descriptions
    # will line up nicely in vertical columns.
    #
    # @param [Hash] command_doc_hsh a mapping of command names to documentation summaries
    # @param [Integer] desc_width the maximum width to use for the description column
    # @return [Array] a list of strings comprised of "#{command_name}#{separator}#{description}"
    # formatted to line up vertically
    def self.format_command_list(command_doc_hsh, desc_width = 90)
      command_doc_hsh = {} if command_doc_hsh.nil?
      longest_command_name = self.get_longest_command_name(command_doc_hsh.keys)
      command_doc_hsh.map { |command_name, doc|
        self.format_command_summary(command_name, doc, self.get_separator(command_name, longest_command_name), desc_width)
      }
    end

    # Arranges the given command_name and command_description with the separator in a standard format
    #
    # @param [String] command_name the command format
    # @param [String] command_description the description for the given command
    # @param [String] separator optional separator to use
    def self.format_command_summary(command_name, command_description, separator = '  -  ', max_width = 90)
      command_description = '' if command_description.nil?
      $stdout.sync = true
      prefix_space = (' ' * "#{command_name}#{separator}".length) << '            '
      line_width = max_width - prefix_space.length
      "#{command_name}#{separator}#{self.word_wrap(command_description, line_width, prefix_space)}\n"
    end

    # Returns the longest command name in the given set
    #
    # @param [Array] a list of command names to parse
    # @return [String] the longest command name in teh given set of names
    def self.get_longest_command_name(command_names)
      command_names.map { |name| name.to_s }.flatten.max_by(&:size) or ''
    end

    # Creates a separator with the appropriate spacing to line up a command/description pair in a command list
    #
    # @param [String] name the command name to create a doc separator for
    # @param [String] longest_name the longest name which will be shown above or below the given name
    # @param [String] sep the separator to use
    # @return [String] a spaced separator String for use in a command/description list
    def self.get_separator(name, longest_name='', sep='  -  ')
      [].unshift(' ' * (longest_name.to_s.length - name.to_s.length)).join << sep
    end

    def self.word_wrap(text, line_width=80, prefix='')
      ([text.gsub("\n", ' ')].map { |line|
        line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
      } * "\n").gsub("\n", "\n#{prefix}")
    end

  end
end
