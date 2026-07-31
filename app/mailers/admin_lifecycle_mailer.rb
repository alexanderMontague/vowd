class AdminLifecycleMailer < PlatformMailer
  def welcome(admin_user)
    assign_admin_context(admin_user)
    @admin_url = AppHost.wedding_admin_url(@wedding)
    @trial_days = Billing.trial_days

    mail(to: admin_user.email, subject: "Welcome to Vowd — your wedding site is ready")
  end

  def trial_expiring(admin_user, days_left:)
    assign_admin_context(admin_user)
    @days_left = days_left.to_i
    @billing_url = AppHost.wedding_admin_url(@wedding, path: "/admin/billing")
    @trial_ends_at = @wedding.trial_ends_at

    subject = if @days_left <= 1
                "Your Vowd trial ends tomorrow"
              else
                "Your Vowd trial ends in #{@days_left} days"
              end

    mail(to: admin_user.email, subject: subject)
  end

  def schedule_locking(admin_user)
    assign_admin_context(admin_user)
    @admin_url = AppHost.wedding_admin_url(@wedding, path: "/admin/website/essentials")
    @lock_at = @wedding.event_starts_at - Wedding::SCHEDULE_LOCK_LEAD_TIME

    mail(
      to: admin_user.email,
      subject: "Heads up — wedding date & venue lock in 24 hours"
    )
  end

  def wedding_congrats(admin_user)
    assign_admin_context(admin_user)
    @site_url = AppHost.wedding_public_url(@wedding)
    @admin_url = AppHost.wedding_admin_url(@wedding)

    mail(
      to: admin_user.email,
      subject: "Congratulations — #{@wedding.title} is yours forever on Vowd"
    )
  end

  private

  def assign_admin_context(admin_user)
    @admin_user = admin_user
    @wedding = admin_user.wedding
  end
end
