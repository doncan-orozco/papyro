# frozen_string_literal: true

require "application_system_test_case"

class Admin::ArticlesTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    # Login the user
    visit admin_login_path
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password"
    click_on "Sign in"
  end

  test "visiting the articles index" do
    visit admin_articles_path
    assert_selector "h1", text: I18n.t("admin.articles.index.title")
  end

  test "creating a new article" do
    visit admin_articles_path
    click_on I18n.t("admin.articles.index.new_article")

    # Should be on the new article page
    assert_selector "h1", text: I18n.t("admin.articles.new.title")

    # Fill in the form
    fill_in I18n.t("admin.articles.form.title_label"), with: "Test Article"
    fill_in I18n.t("admin.articles.form.slug_label"), with: "test-article"
    fill_in I18n.t("admin.articles.form.excerpt_label"), with: "This is a test excerpt"
    
    # Submit the form
    click_on I18n.t("admin.articles.form.save")

    # Should be back on the index page
    assert_text I18n.t("admin.articles.operations.create.success")
    assert_text "Test Article"
  end

  test "editing an article" do
    article = articles(:one)
    visit admin_articles_path

    # Click edit on the first article
    click_on I18n.t("admin.articles.index.edit"), match: :first

    # Should be on the edit page
    assert_selector "h1", text: I18n.t("admin.articles.edit.title")

    # Update the title
    fill_in I18n.t("admin.articles.form.title_label"), with: "Updated Article Title"
    click_on I18n.t("admin.articles.form.save")

    # Should be back on the index page
    assert_text I18n.t("admin.articles.operations.update.success")
    assert_text "Updated Article Title"
  end

  test "publishing a draft article" do
    visit admin_articles_path

    # Find a draft article and publish it
    within("div.bg-white", match: :first) do
      if has_text?(I18n.t("admin.articles.index.draft"))
        click_on I18n.t("admin.articles.index.publish")
      end
    end

    # Should see success message
    assert_text I18n.t("admin.articles.operations.publish.success")
  end

  test "deleting an article" do
    visit admin_articles_path
    
    # Get the first article title before deleting
    article_title = find("h3", match: :first).text

    # Click delete on the first article
    accept_confirm do
      click_on I18n.t("admin.articles.index.delete"), match: :first
    end

    # Should see success message
    assert_text I18n.t("admin.articles.operations.destroy.success")
  end

  test "canceling article creation" do
    visit new_admin_article_path

    # Click cancel
    click_on I18n.t("admin.articles.form.cancel")

    # Should be back on the index page
    assert_selector "h1", text: I18n.t("admin.articles.index.title")
  end
end
