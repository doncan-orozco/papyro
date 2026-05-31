require "application_system_test_case"

module Authors
  class AuthorProfileLocaleBioTest < ApplicationSystemTestCase
    setup do
      @profile = author_profiles(:one)

      Mobility.with_locale(:en) { @profile.update!(bio: "English bio locale sample") }
      Mobility.with_locale(:es) { @profile.update!(bio: "Spanish bio locale sample") }
    end

    test "public author page renders locale-specific bio" do
      visit author_path(@profile.username, locale: :en)

      assert_text "English bio locale sample"
      assert_no_text "Spanish bio locale sample"

      visit author_path(@profile.username, locale: :es)

      assert_text "Spanish bio locale sample"
      assert_no_text "English bio locale sample"
    end
  end
end
