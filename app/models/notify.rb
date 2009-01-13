class Notify < ActionMailer::Base
  FROM_ADDRESS = "test.otherinbox@gmail.com"
  HOST = "http://backup.nitroleague.com"

  def success(email, backup)
    setup_mail( email )
    @subject = "Your backups are ready"
 
    body[:email] = email       
    body[:backup] = backup
    body[:host] = HOST
  end

  def authentication_problem(email)
    setup_mail( email )
    @subject = "Authentication Problem with backups"

    body[:email]
  end

  def timeout_problem(email)
    setup_mail( email )
    @subject = "Timeout Problem with backups"

    body[:email]
  end

  private
  def setup_mail( email )
    @recipients   = email
    @from         = FROM_ADDRESS
    headers         "Reply-to" => "#{FROM_ADDRESS}"
    @subject      = "Your backups are ready"
    @sent_on      = Time.now
    @content_type = "text/html"
  end
end
