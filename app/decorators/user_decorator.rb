# frozen_string_literal: true

class UserDecorator < ApplicationDecorator
  delegate :email, :name, :role, :role?

  def edit_password_link(**options)
    return unless allowed_to? :update?, object

    html_class = options.delete(:class)
    h.link_to edit_password_path, class: html_class do
      h.fa_icon("key", text: t("devise.passwords.edit.change_my_password"))
    end
  end

  def profile_link(**options)
    return unless allowed_to? :update?, object

    html_class = options.delete(:class)
    h.link_to h.edit_user_registration_path, class: html_class do
      h.fa_icon("user", text: User.human_attribute_name(:profile))
    end
  end

  def logout_link(**options)
    html_class = options.delete(:class)
    h.link_to h.destroy_user_session_path, method: :delete, class: html_class do
      h.fa_icon("sign-out-alt", text: t("devise.sessions.sign_out"))
    end
  end
end
