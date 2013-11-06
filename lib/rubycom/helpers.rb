module Rubycom
  module Helpers

    # Arranges each given tag hash such that all tags will line up nicely in vertical columns.
    #
    # @param [Array] tag_list an Array of Hashes which include keys: :name, :tag_name, :text, :types
    # @param [Integer] desc_width the maximum width to use for the description column
    # @return [Array] a list of strings comprised of types, separator, name||tag_name, separator, text
    # formatted to line up vertically
    def self.format_tags(tag_list, desc_width = 90)
      tag_list = [] if tag_list.nil?
      raise ArgumentError, "tag_list should be an Array but was a #{tag_list.class}" unless tag_list.class == Array
      tag_list.each { |h|
        raise ArgumentError, "tag #{h} should be a Hash but was a #{h.class}" unless h.class == Hash
        [:name, :tag_name, :text, :types].each { |t| h.fetch(t) }
        types = h[:types]
        raise ArgumentError, "tag[:types] #{types} should be an Array but was #{types.class}" unless types.class == Array
      }

      longest_name = tag_list.map { |tag| (tag[:name].nil?) ? tag[:tag_name] : tag[:name] }.max
      longest_types = tag_list.map { |tag| "#{tag[:types]}" }.max
      longest_combo_name = tag_list.map { |tag| "#{tag[:tag_name]}#{tag[:name]}" }.max
      {
          others: tag_list.select { |tag| !["param", "return"].include?(tag[:tag_name]) }.map { |tag|
            combo_name = (tag[:tag_name].nil? || tag[:tag_name].empty? || tag[:name].nil? || tag[:name].empty?) ? '' : "#{tag[:tag_name]}: #{tag[:name]}"
            "#{(tag[:types].empty?) ? '' : tag[:types]}#{self.get_separator(tag[:types], longest_types, tag[:types].empty? ? nil : ' ')}#{self.format_command_summary(combo_name, tag[:text], self.get_separator(combo_name, longest_combo_name), desc_width)}"
          },
          params: tag_list.select { |tag| tag[:tag_name] == "param" }.map { |tag|
            "#{tag[:types]}#{self.get_separator(tag[:types], longest_types, ' ')}#{self.format_command_summary(tag[:name], tag[:text], self.get_separator(tag[:name], longest_name), desc_width)}"
          },
          returns: tag_list.select { |tag| tag[:tag_name] == "return" }.map { |tag|
            "#{tag[:types]}#{self.get_separator(tag[:types], longest_types, ' ')}#{self.format_command_summary(tag[:tag_name], tag[:text], self.get_separator(tag[:tag_name], longest_name), desc_width)}"
          }
      }
    end

    # Arranges each command_name => command_description in command_doc with a separator such that all command names and
    # descriptions will line up nicely in vertical columns.
    #
    # @param [Hash] command_doc a mapping of command names to documentation summaries
    # @param [Integer] desc_width the maximum width to use for the description column
    # @return [Array] a list of strings comprised of command_name, separator, and description
    # formatted to line up vertically
    def self.format_command_list(command_doc, desc_width = 90, indent ='')
      raise ArgumentError, "command_doc should be a Hash but was a #{command_doc.class}" unless command_doc.class == Hash
      command_doc = {} if command_doc.nil?
      longest_command_name = command_doc.keys.max { |t, n| t.to_s.length <=> n.to_s.length }
      command_doc.map { |command_name, doc|
        self.format_command_summary("#{indent}#{command_name}", doc, self.get_separator(command_name, longest_command_name), desc_width)
      }
    end

    # Creates a separator with the appropriate spacing to line up a command/description pair in a command list
    #
    # @param [String] name the command name to create a doc separator for
    # @param [String] longest_name the longest name which will be shown above or below the given name
    # @param [String] sep the separator to use
    # @return [String] a spaced separator String for use in a command/description list
    def self.get_separator(name, longest_name='', sep='  -  ')
      name = "#{name}" unless name.class == String
      sep = '' if sep.nil?
      longest_name = name if name.size > longest_name.size
      (' ' * (longest_name.to_s.length - name.to_s.length)) << sep
    end

    # Arranges the given command_name and command_description with the separator in a standard format
    #
    # @param [String] command_name the command format
    # @param [String] command_description the description for the given command
    # @param [String] separator optional separator to use
    def self.format_command_summary(command_name, command_description, separator = '  -  ', max_width = 90)
      command_name = '' if command_name.nil?
      command_description = '' if command_description.nil?
      separator = '' if separator == nil
      raise ArgumentError, "command_name and separator #{command_name}#{separator} size should not be greater than max_width: #{max_width} but was #{separator.size + command_name.size}" if command_name.size+separator.size > max_width
      $stdout.sync = true
      prefix_space = (' ' * "#{command_name}#{separator}".length)
      line_width = max_width - prefix_space.length
      "#{command_name}#{separator}#{self.word_wrap(command_description, line_width, prefix_space)}\n"
    end

    # Converts a string longer than line_width to a multiline string where each line is at most line_width long.
    #
    # @param [String] text the text to be wrapped
    # @param [Integer] line_width the maximum length any single line in the string should be, default: 80, minimum: 1
    # @param [String] prefix a prefix to add the the front of any new lines created as a result of the wrap, default: ''
    def self.word_wrap(text, line_width=80, prefix='')
      text = "#{text}" unless text.class == String
      prefix = "#{prefix}" unless prefix.class == String
      line_width = 1 if line_width < 1
      ([text.gsub("\n", ' ')].map { |line|
        line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
      } * "\n").gsub("\n", "\n#{prefix}")
    end

  end
end
