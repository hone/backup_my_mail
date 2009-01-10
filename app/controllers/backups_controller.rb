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
          format.html { redirect_to( :action => :show, :mbox => { :inbox => result[:mbox_name] } ) }
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
    @downloads = params[:mbox]

    respond_to do |format|
      if @downloads.nil? or @downloads.empty? or not check_files_exist( @downloads.values )
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
