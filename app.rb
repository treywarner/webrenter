# frozen_string_literal: true

require 'sinatra/base'
require 'logger'
require 'yaml'

# App is the main application where all your logic & routing will go
class App < Sinatra::Base
  set :erb, escape_html: true
  enable :sessions

  attr_reader :logger

  def initialize
    super
    @logger = Logger.new('log/app.log')
  end

  def title
    'Webrenter'
  end

  def projects_root
    if not session[:login]
      session[:flash] = { danger: 'Error: not logged in.' }
      redirect(url('/login'))
    end
    "#{__dir__}/projects/#{session[:login]}"
  end

  def project_dirs
    Dir.children(projects_root).reject { |dir| dir == 'input_files' }.sort_by(&:to_s)
  end
  

  def clear_flash
    session[:flash] = nil
  end

  get '/' do
    logger.info('requesting the index')
    #@flash = session.delete(:flash) || { info: 'Welcome to Summer Institute!' }
    erb :index
  end

  get '/login' do
    @flash = session[:flash]
    erb :login
  end

  post '/login' do
    users=YAML.load(File.read("#{__dir__}/users"))
    account_hash = Digest::SHA256.digest(params[:account])
    if users.any? { |k,v| account_hash == v[1] }
      if users.select { |k,v| account_hash == v[1] }.values[0][2]==Digest::SHA256.digest(params[:password])
        session[:login] = users.select { |k,v| account_hash == v[1] }.keys[0]
        redirect(url('/'))
      end
    elsif users.has_key?(params[:account].to_sym)
      if users[params[:account].to_sym][2]==Digest::SHA256.digest(params[:password])
        session[:login] = params[:account]
        redirect(url('/'))
      else
        session[:flash] = { danger: 'Password incorrect' }
        redirect(url('/login'))
      end
    else
      session[:flash] = { danger: 'Password incorrect' }
      redirect(url('/login'))
    end
  end
      
  get '/logoff' do
    
    session[:login] = nil
    session = {}
    redirect(url('/'))
  end

  get '/signup' do
    erb :signup
  end

  post '/signup' do
    users=YAML.load(File.read("#{__dir__}/users"))
    email_hash = Digest::SHA256.digest(params[:email])
    if users.any? { |k,v| email_hash == v[1] }
      session[:flash] = { danger: 'invalid, address already used' }
      redirect(url('/signup'))
    elsif users.has_key?(params[:account].to_sym)
      session[:flash] = { danger: 'invalid, username already used' }
      redirect(url('/signup'))
    elsif params[:account].match(/\s/)
      session[:flash] = { danger: 'invalid, username cannot contain whitespace' }
      redirect(url('/signup'))
    else
      users[params[:account].to_sym] = [params[:name],email_hash,Digest::SHA256.digest(params[:password])]
      File.open("#{__dir__}/users", 'w') { |f| f.write(YAML.dump(users)) }
      session[:login] = params[:account]
      redirect(url("/"))
    end
  end

  get '/projects_view' do
    if session[:login]
      @project_dirs = project_dirs
      erb :projects_view
    else
      session[:flash] = { danger: "cannot view projects without being logged in." }
      redirect(url("/login"))
    end
  end

  get %r{/projects/(.*)} do
    @url = params[:captures][0]
    session[:login] = 'tom123'
    if @url == 'new' || @url == 'input_files'
      erb :new_project
    else
      @dir = Pathname("#{projects_root}/#{@url}")
      @flash = session.delete(:flash)

      if @dir.directory?
        @project_conts = Dir.children(@dir).reject { |dir| dir == 'input_files' }.sort_by(&:to_s)
        @projects_root = projects_root
        erb :show_project
      elsif @dir.file?
        redirect(url("/editor/#{@url}"))
      else
        session[:flash] = { danger: "#{@dir} does not exist" }
        redirect(url('/'))
      end


    end
  end

  get %r{/editor/(.*)} do
    @url = params[:captures][0]
    @dir = Pathname("#{projects_root}/#{@url}")
    @flash = session.delete(:flash)
    if @dir.directory?
      session[:flash] = { danger: "cannot edit directory." }
      redirect(url('/projects/'))
    elsif @dir.file?
      @value = File.read("#{projects_root}/#{@url}")
      erb :editor, :layout => nil
    else
      session[:flash] = { danger: "#{@dir} does not exist" }
      redirect(url("/projects/#{@url}"))
    end
  end

  post %r{/editor/(.*)} do
    @url = params[:captures][0]
    File.open("#{projects_root}/#{@url}", "w") { |f| f.write request.body.read }
    
  end

  get %r{/view/(.*)} do
    @url = params[:captures][0]
    return File.read("#{projects_root}/#{@url}")
  end

  post '/projects/new' do
    if session[:login]
      dir = "#{params[:name].downcase.gsub(' ', '_')}"
      "#{projects_root}/#{dir}".tap { |d| FileUtils.mkdir_p(d) }

      session[:flash] = { info: "made new project '#{params[:name]}'" }
      redirect(url("/projects/#{dir}"))
    else
      session[:flash] = { danger: "cannot create project without being logged in." }
      redirect(url("/login"))
    end
  end

end
