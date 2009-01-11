class BackupsController < ApplicationController
  def new
    @remote_mail = RemoteMail.new

    respond_to do |format|
      format.html
    end
  end

  def create
    @remote_mail = RemoteMail.new( params[:remote_mail] )
    # hack needed to display errors
    @remote_mail.save
    @pop3 = Pop3.new( params[:remote_mail] )
    respond_to do |format|
      if @pop3.valid?
        spawn do
          mail_download( @pop3 )
        end
        format.html { redirect_to :action => :show }
      else
        flash[:notice] = "Problems with backing up mail, invalid input"
        format.html { render :action => :new }
      end
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def check_files_exist( files )
    files.inject( true ) do |boolean, file|
      # this is a huge security flaw
      boolean and file.is_a?( String ) and File.exist?( "#{Pop3::FILE_DIR}/#{file}" )
    end
  end

  def mail_download( pop3 )
    pop3.setup_mailer
    result = pop3.download
    case result[:status]
    when Pop3::OK_FLAG
      Notify.deliver_success( @pop3.email_address, result[:mbox_name] )
    when Pop3::AUTHENTICATION_ERROR_FLAG
      Notify.deliver_authentication_problem( @pop3.email_address )
    when Pop3::TIMEOUT_ERROR_FLAG
      Notify.deliver_timeout_problem( @pop3.email_address )
    end
  end

end
