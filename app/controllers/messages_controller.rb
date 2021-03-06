class MessagesController < ApplicationController
  include BeforeActionTrigger
  before_action :require_login, :store_next_url

  def create
    @msg = MessageForm.new(create_message_params)
    if create_message_params.fetch(:username, nil) != current_user.username
      @msg.errors.add(:from_user, 'invalid')
    end
    return unless @msg.valid?

    # Mark user online again when user idles over 90 minutes then comes back
    write_user2cache(current_user.username, current_user.id) unless online?(current_user)

    @lock_send_msg     = true # Default lock send msg
    sent_first_off_msg = true # Default sent first msg regardless receiver existing or not
    to_user            = fetch_user(@msg.to_user)
    sent_first_off_msg = sent_first_offline_msg?(current_user, to_user) if to_user.present?
    @receive_online    = online?(@msg.to_user)

    if @receive_online
      ActionCable.server.broadcast(One2OneChannel.channel_key_name(@msg.to_user),
                                   type:    'message', from_user: current_user.username,
                                   to_user: @msg.to_user, msg: @msg.msg_content)
      @lock_send_msg = false # Unlock send msg
      clear_sent_first_msg(current_user, to_user) if sent_first_off_msg
    elsif !sent_first_off_msg
      send_offline_msg(current_user, to_user, @msg.msg_content) if to_user.present?
    end
  end

  private

  def send_offline_msg(from_user, to_user, msg)
    if under_mail_quota
      if to_user.receive_offline_msg? && !sent_first_offline_msg?(from_user, to_user)
        MessageMailer.send_offline_message(from_user, to_user, msg).deliver_later
        update_number_emails
        mark_sent_first_offline_msg(from_user, to_user)
      end
    else
      unless sent_alert_over_email?
        SystemMailer.send_alert_over_mail_quota(current_number_mails).deliver_now
        mark_send_alert_over
        update_number_emails
      end
    end
  end

  def create_message_params
    params.require(:message).permit(:from_user, :to_user, :msg_content)
  end
end
