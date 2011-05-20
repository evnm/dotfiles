require 'rake'

desc "install dotfiles in user's home directory"
task :install do
  replace_all = false
  Dir['*'].each do |file|
    next if %w[Rakefile README.md LICENSE].include? file

    if File.exist? File.join(ENV['HOME'], ".#{file}")
      if File.identical? file, File.join(ENV['HOME'], ".#{file}")
        puts "Identical #{file} already installed."
      elsif replace_all
        replace_file(file)
      else
        print "File already exists: ~/.#{file}. Overwrite it? [y,n,q,a,?] "
        case $stdin.gets.chomp
        when 'y'
          replace_file(file)
        when 'a'
          replace_all = true
          replace_file(file)
        when 'q'
          exit
        when '?'
          puts "y - Overwrite the file"
          puts "n - Don't overwrite the file"
          puts "q - Don't overwrite this nor all subsequent other files"
          puts "a - Overwrite this and all subsequent other files"
          puts "? - Print help"
          redo
        end
      end
    else link_file(file)
    end
  end
end

# Replace the given dotfile in $HOME with the target file.
def replace_file(file)
  system %Q{rm -rf "$HOME/.#{file}"}
  link_file(file)
end

# Create a symlink to the target file in $HOME.
def link_file(file)
  puts "Linking #{file} to home directory."
  system %Q{ln -s "$PWD/#{file}" "$HOME/.#{file}"}
end

task :default => 'install'
