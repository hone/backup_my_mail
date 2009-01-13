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

    respond_to do |format|
      if @remote_mail.valid?
        case @remote_mail.mail_type
        when RemoteMail::POP3
          @pop3 = Pop3.new( params[:remote_mail] )
          spawn do
            mail_download_pop3( @pop3 )
          end
        when RemoteMail::IMAP
          @imap = Imap.new( params[:remote_mail] )
          spawn do
            mail_download_imap( @imap )
          end
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

  def mail_download_pop3( pop3 )
    pop3.setup_mailer
    result = pop3.download
    case result[:status]
    when Pop3::OK_FLAG
      Notify.deliver_success( pop3.email_address, result[:mbox_name] )
    when Pop3::AUTHENTICATION_ERROR_FLAG
      Notify.deliver_authentication_problem( pop3.email_address )
    when Pop3::TIMEOUT_ERROR_FLAG
      Notify.deliver_timeout_problem( pop3.email_address )
    end
  end

   def mail_download_imap( imap )
    begin
      status = imap.setup_mailer
      mbox_name = imap.download
      case status
      when RemoteMail::OK_FLAG
        Notify.deliver_success( imap.email_address, mbox_name )
      when RemoteMail::AUTHENTICATION_ERROR_FLAG
        Notify.deliver_authentication_problem( imap.email_address )
      when RemoteMail::TIMEOUT_ERROR_FLAG
        Notify.deliver_timeout_problem( imap.email_address )
      else
        Notify.deliver_timeout_problem( imap.email_address )
      end
    rescue Net::IMAP::NoResponseError
      Notify.deliver_authentication_problem( imap.email_address )
    rescue Errno::ETIMEDOUT
      Notify.deliver_timeout_problem( imap.email_address )
    rescue
      Notify.deliver_timeout_problem( imap.email_address )
    end

   end


end
