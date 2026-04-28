class UsersController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    user = User.find(params[:id])
    authorize user
    render Views::Users::Show.new(user: user)
  end

  def edit
    user = User.find(params[:id])
    authorize user
    render Views::Users::Edit.new(user: user)
  end

  def update
    user = User.find(params[:id])
    authorize user

    result = Users::Operation::Update.call(user: user, params: user_params)

    if result.success?
      redirect_to user_path(user), notice: t("users.operations.update.success")
    else
      user = result[:model] || user
      render Views::Users::Edit.new(user: user), status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation).to_h
  end
end
