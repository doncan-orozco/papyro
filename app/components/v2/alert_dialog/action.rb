# frozen_string_literal: true

# shadcn AlertDialogAction: closes (Radix DialogClose, ad:85).
class Components::V2::AlertDialog::Action < Components::V2::Base
  include Components::V2::AlertDialog::ActionButton

  private

  def default_variant = "default"

  def slot_data = { slot: "alert-dialog-action" }
end
