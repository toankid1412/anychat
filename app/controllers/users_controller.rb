class UsersController < ApplicationController
  include BeforeActionTrigger
  before_action :store_next_url, :require_login

  def index
    return unless request.post?
    @q     = User.search(params[:q])
    @users = @q.result.page(params.fetch(:page, 1)).per(15)
  end

  def edit; end

  def update
    @user            = current_user
    @user.attributes = update_user_params
    return unless current_user.valid?

    @email_changed = @user.email_changed?
    token          = @user.new_token
    @user.gen_active_email_digest(token) if @email_changed
    return unless @user.save

    if @email_changed
      UserMailer.send_active_email(@user, token).deliver_later
      update_number_emails
    end
  end

  def check_online
    username      = params.fetch(:username, '')
    lock_send_msg = true
    to_user       = fetch_user(username)
    if to_user.present?
      lock_send_msg = sent_first_offline_msg?(current_user, to_user) || !to_user.receive_offline_msg?
    end
    render json: {online:        online?(username),
                  lock_send_msg: lock_send_msg}
  end

  def active_email
    if current_user.valid_active_email_token?(params.fetch(:token, ''))
      current_user.clear_active_email_digest
      flash[:success] = "Email: #{current_user.email} has been confirmed."
      if current_user.receive_offline_msg?
        flash[:success] << ' Now you can receive first message from other guys when offline.'
      else
        flash[:success] << ' You can setup profile to receive first message from other guys when offline.'
      end
      redirect_to rooms_path
    else
      flash[:error] = "Invalid token for #{current_user.email}."
      redirect_to root_path
    end
  end

  private

  def update_user_params
    params.require(:user).permit(:email, :receive_msg_offline)
  end
end
