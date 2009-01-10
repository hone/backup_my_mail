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
        @pop3.setup_mailer
        result = @pop3.download

        case result[:status]
        when Pop3::OK_FLAG
          flash[:notice] = "Backup successfully created"
          Notify.deliver_success( @pop3.email_address, { :inbox => result[:mbox_name] } )
          format.html { redirect_to( :action => :show, :mbox => result[:mbox_name] ) }
        when Pop3::AUTHENTICATION_ERROR_FLAG
          flash[:notice] = "Could not create backup due to authentication problems"
          format.html { render :action => :new }
          # TODO add stuff here
        when Pop3::TIMEOUT_ERROR_FLAG
          flash[:notice] = "Could not create backup due to timeout error"
          format.html { render :action => :new }
        end
      else
        flash[:notice] = "Problems with backing up mail, invalid input"
        format.html { render :action => :new }
      end
    end
  end

  def show
    @download = params[:mbox]

    respond_to do |format|
      if @download.nil? or @download.empty? or not check_files_exist( @download )
        flash[:notice] = 'No valid mbox specified'
        format.html { redirect_to( :action => :new ) }
      else
        format.html
      end
    end
  end

  def check_files_exist( files )
    files.inject( true ) do |boolean, file|
      # this is a huge security flaw
      boolean and file.is_a?( String ) and File.exist?( "#{Pop3::FILE_DIR}/#{file}" )
    end
  end

end
