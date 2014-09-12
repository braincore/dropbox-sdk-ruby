require_relative '../lib/dropbox/client'
require_relative '../lib/dropbox/oauth2'
require_relative '../lib/dropbox/web_auth_no_redirect'
require_relative '../lib/dropbox/oauth2/app_info'
require_relative '../lib/dropbox/client/host_info'
require_relative '../lib/dropbox/client/session'
require_relative '../lib/dropbox'
require_relative '../lib/dropbox/http'
require_relative '../lib/dropbox/error'
require 'pp'
require 'shellwords'

####
# An example app using the Dropbox API Ruby Client
#   This ruby script sets up a basic command line interface (CLI)
#   that prompts a user to authenticate on the web, then
#   allows them to type commands to manipulate their dropbox.
####

# You must use your Dropbox App key and secret to use the API.
# Find this at https://www.dropbox.com/developers

class DropboxCLI
  LOGIN_REQUIRED = %w{folder_list info download upload folder_create preview
    thumbnail copy move delete search account_info}

  def initialize
    begin
      @app_info = Dropbox::API::AppInfo.from_json_file('app_info.json')
      if @app_info.key == '' || @app_info.secret == ''
        fail
      end
    rescue
      puts "You must set your app key and app secret in app_info.json!"
      puts "Find this in your apps page at https://www.dropbox.com/developers/"
      exit
    end
    @client = nil
  end

  def login
    if not @client.nil?
      puts "already logged in!"
    else
      web_auth = Dropbox::API::WebAuthNoRedirect.new(@app_info, 'RubySDK/2.0')
      authorize_url = web_auth.start()
      puts "1. Go to: #{authorize_url}"
      puts "2. Click \"Allow\" (you might have to log in first)."
      puts "3. Copy the authorization code."

      print "Enter the authorization code here: "
      STDOUT.flush
      auth_code = STDIN.gets.strip

      access_token, user_id = web_auth.finish(auth_code)

      @client = Dropbox::API::Client.new(access_token, 'RubySDK/2.0', nil, @app_info.host_info)
      puts "You are logged in.  Your access token is #{access_token}."
    end
  end

  def command_loop
    puts "Enter a command or 'help' or 'exit'"
    command_line = ''
    while command_line.strip != 'exit'
      begin
        execute_dropbox_command(command_line)
      rescue RuntimeError => e
        puts "Command Line Error! #{e.class}: #{e}"
        puts e.backtrace
      end
      print '> '
      command_line = gets.strip
    end
    puts 'goodbye'
    exit(0)
  end

  def execute_dropbox_command(cmd_line)
    command = Shellwords.shellwords cmd_line
    method = command.first
    if LOGIN_REQUIRED.include? method
      if @client
        send(method.to_sym, command)
      else
        puts 'must be logged in; type \'login\' to get started.'
      end
    elsif ['login', 'help'].include? method
      send(method.to_sym)
    else
      if command.first && !command.first.strip.empty?
        puts 'invalid command. type \'help\' to see commands.'
      end
    end
  end

  def logout(command)
    @client = nil
    puts "You are logged out."
  end

  # Gets the list of contents for a folder
  # > folder_list /some/path
  def folder_list(command)
    path = '/' + clean_up(command[1] || '')
    resp = @client.files.folder_list(path)

    resp.contents.each do |item|
      puts item.path
    end
  end

  # Gets metadata for a file or folder
  # > info /some/file.txt
  # > info /some/folder
  def info(command)
    if !command[1] || command[1].empty?
      puts "please specify item to get"
    else
      path = '/' + clean_up(command[1])
      pp @client.files.info(path)
    end
  end

  # Downloads a file and writes it locally
  # > download /dropbox/path.txt localfile.txt
  def download(command)
    if command[1].nil? || command[1].empty?
      puts "please specify item to get"
    elsif command[2].nil? || command[2].empty?
      puts "please specify full local path to dest, i.e. the file to write to"
    elsif File.exists?(command[2])
      puts "error: File #{dest} already exists."
    else
      src = '/' + clean_up(command[1])
      dst = command[2]
      out, metadata = @client.files.download(src)
      pp metadata
      open(dst, 'w') { |f| f.puts out }
      puts "wrote file #{ dst }."
    end
  end

  # Uploads a local file to Dropbox
  # Uses the 'overwrite' conflict policy
  # > upload localfile.txt /dropbox/path.txt
  def upload(command)
    fname = command[1]

    #If the user didn't specify the file name, just use the name of the file on disk
    if command[2]
      new_name = command[2]
    else
      new_name = File.basename(fname)
    end

    if fname && !fname.empty? && File.exists?(fname) && (File.ftype(fname) == 'file') && File.stat(fname).readable?
      pp @client.files.upload(new_name, WriteConflictPolicy.overwrite, open(fname))
    else
      puts "couldn't find the file #{ fname }"
    end
  end

  # Creates a folder
  # > folder_create /new/folder
  def folder_create(command)
    pp @client.files.folder_create(clean_up(command[1]))
  end

  # Gets metadata and a preview for a file
  # > preview /dropbox/path.txt localfile.txt
  def preview(command)
    path = '/' + clean_up(command[1])
    dst = command[2]
    out, metadata = @client.files.preview(path)
    pp metadata
    open(dest, 'w') { |f| f.puts out }
    puts "wrote thumbnail #{ dst }."
  end

  # Gets metadata and a thumbnail for a file
  # > thumbnail /dropbox/path.jpg localpicture.jpg
  def thumbnail(command)
    path = '/' + clean_up(command[1])
    dst = command[2]
    out, metadata = @client.files.thumbnail(path)
    pp metadata
    open(dest, 'w') { |f| f.puts out }
    puts "wrote thumbnail #{ dst }."
  end

  # Copies a file
  # > copy /from/path.txt /to/path.txt
  def copy(command)
    src = clean_up(command[1])
    dest = clean_up(command[2])
    pp @client.files.copy(src, dest)
  end

  # Moves a file
  # > move /from/path.txt /to/path.txt
  def move(command)
    src = clean_up(command[1])
    dest = clean_up(command[2])
    pp @client.files.move(src, dest)
  end

  # Deletes a file
  # > delete /dropbox/path.txt
  def delete(command)
    pp @client.files.delete(clean_up(command[1]))
  end

  # Searches for files and folders with a search string in their names
  # > search mysearchquery
  def search(command)
    resp = @client.files.search('/', clean_up(command[1]))

    for item in resp
      puts item.path
    end
  end

  # Get account info for the current user
  # > account_info
  def account_info(command)
    pp @client.users.info('me')
  end

  def help
    puts "commands are: login #{LOGIN_REQUIRED.join(' ')} help exit"
  end

  def clean_up(str)
    str ? str.gsub(/^\/+/, '') : nil
  end
end

cli = DropboxCLI.new
cli.command_loop
