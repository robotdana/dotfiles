require_relative 'within_temp_dir_helper'
require 'fileutils'
require 'pathname'

module CLIHelper
  module CreateFileHelper
    def create_file(*lines, path:)
      path = self.path(path)
      path.parent.mkpath

      if lines.empty?
        path.write('') unless path.exist?
      else
        if path.exist?
          raise Errno::EEXIST unless path.read.chomp == lines.join("\n").chomp
        else
          path.write(lines.join("\n"))
        end
      end

      path
    end

    def path(relative_path)
      Pathname.pwd.join(relative_path)
    end
    alias_method :file, :path

    def copy_file(*relative_paths)
      relative_paths.each do |relative_path|
        dest = path(relative_path)
        dest.parent.mkpath
        ::FileUtils.cp_r(
          ::File.expand_path(relative_path, "#{__dir__}/../../.."),
          dest.to_s
        )
      end
    end

    def create_dir(path, &block)
      self.path(path).mkpath
      return path unless block_given?

      Dir.chdir(&block)
    end

    def create_symlink(hash)
      hash.each do |link, target|
        link_path = path(link)
        link_path.parent.mkpath

        FileUtils.ln_s(path(target), link_path.to_s)
      end
    end

    def create_file_list(*filenames)
      filenames.each do |filename|
        create_file(path: filename)
      end
    end
  end
end

CLIHelper::WithinTempDir.include(CLIHelper::CreateFileHelper)
