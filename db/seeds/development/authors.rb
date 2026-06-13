# frozen_string_literal: true

puts ""
puts "👤 Creating authors..."

authors_data = [
  {
    email: "elena@papyro.local",
    username: "elena_torres",
    display_name: "Elena Torres",
    bio: "Essayist and cultural critic exploring the intersection of technology, memory, and human connection. Former editor at a literary magazine. Based in Barcelona, she writes about how digital life reshapes our inner worlds.",
    location: "Barcelona, Spain",
    website_url: nil,
    x_handle: "elenatorres"
  },
  {
    email: "marcus@papyro.local",
    username: "marcus_chen",
    display_name: "Marcus Chen",
    bio: "Software architect turned writer. I unpack the hidden patterns in systems — both technical and social — and what they reveal about how we think. My work has appeared in Wired, Aeon, and The New Atlantis.",
    location: "Portland, Oregon",
    website_url: "https://marcuschen.dev",
    x_handle: "marcuschen"
  },
  {
    email: "sophie@papyro.local",
    username: "sophie_laurent",
    display_name: "Sophie Laurent",
    bio: "Historian of ideas and occasional poet. I trace the long arcs of thought that shape our present — from medieval mysticism to modern productivity culture. My writing lives at the border of scholarship and storytelling.",
    location: "Paris, France",
    website_url: "https://sophielaurent.fr",
    x_handle: "slaurent"
  },
  {
    email: "ravi@papyro.local",
    username: "ravi_patel",
    display_name: "Ravi Patel",
    bio: "Independent journalist covering climate, migration, and the future of cities. I believe the best stories are found at the margins — in the communities and ecosystems that conventional narratives overlook.",
    location: "Mumbai, India",
    website_url: nil,
    x_handle: "ravipatel"
  }
]

authors_data.each do |data|
  next if User.exists?(email_address: data[:email])

  result = Users::Operation::Create.new.call(
    params: {
      email_address: data[:email],
      password: "password123",
      password_confirmation: "password123",
      profile_attributes: {
        display_name: data[:display_name],
        username: data[:username]
      }
    }
  )

  if result.success?
    user = result.value![:model]
    profile = user.profile

    profile.update!(
      bio: data[:bio],
      location: data[:location],
      website_url: data[:website_url],
      x_handle: data[:x_handle]
    )

    puts "  ✅ #{data[:display_name]} — #{data[:email]}"
  else
    errors = result.failure[:errors] rescue result.failure
    puts "  ❌ Failed to create #{data[:display_name]}: #{errors}"
  end
end

# Collect seed users for use by articles file
@seed_users = User.where(email_address: [
  "elena@papyro.local", "marcus@papyro.local",
  "sophie@papyro.local", "ravi@papyro.local"
]).to_a

puts "  → #{@seed_users.size} authors ready"
