class UsersController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    user = User.find(params[:id])
    authorize user

    redirect_to author_path(user.profile.username, locale: I18n.locale), status: :moved_permanently
  end

  def edit
    user = User.find(params[:id])
    authorize user
    render Views::Users::Edit.new(user: user)
  end

  def update
    user = User.find(params[:id])
    authorize user

    result = Users::Operation::Update.new.call(user: user, params: user_params)

    if result.success?
      redirect_to user_path(user), notice: t("users.operations.update.success")
    else
      user = result.failure[:model] || user
      render Views::Users::Edit.new(user: user), status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, profile_attributes: [ :display_name ]).to_h
  end
end
