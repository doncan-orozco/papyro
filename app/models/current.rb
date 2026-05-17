class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :locale
end
