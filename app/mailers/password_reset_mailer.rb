class PasswordResetMailer < PlatformMailer
  def reset(admin_user)
    @admin_user = admin_user
    @wedding = admin_user.wedding
    token = admin_user.generate_token_for(:password_reset)
    @reset_url = AppHost.absolute_url(
      host: AppHost.base_domain,
      path: "/reset-password/#{token}"
    )

    mail(to: admin_user.email, subject: "Reset your Vowd password")
  end
end
