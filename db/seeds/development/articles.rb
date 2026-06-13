# frozen_string_literal: true

puts ""
puts "📝 Creating articles..."

# ── Helpers ──────────────────────────────────────────────────────────────

def generate_body(title, author_display_name)
  intro_templates = [
    "It begins, as these things often do, with a question. Not the kind you can answer with a quick search or a confident opinion — but the kind that lingers, that unsettles, that refuses to resolve itself neatly.",
    "I have been thinking about this for a long time. Longer than I care to admit. The idea first took root during a conversation I wasn't expecting to have, with someone I wasn't expecting to meet.",
    "Let me start with a confession: I used to believe the opposite of what I'm about to argue. For years, I was convinced that the conventional wisdom was correct. It took a series of quiet revelations to change my mind.",
    "The first time I encountered this idea, I dismissed it entirely. It seemed too simple, too naive — the kind of thing people say when they haven't thought hard enough. I was wrong."
  ]
  body_templates = [
    "What makes this question so difficult is that it resists easy categorization. On one hand, there is the practical dimension — the concrete choices and trade-offs that shape our daily experience. On the other hand, there is something deeper at work: a shift in the underlying assumptions that govern how we think about ourselves and our relationship to the world.",
    "Consider, for a moment, the way we talk about this in ordinary conversation. The language we use reveals something we rarely examine directly — a set of implicit beliefs that structure our thinking before we even begin to reason. When we say that something is 'inevitable,' we are not making a prediction; we are making a choice about where to direct our attention and our effort.",
    "I do not pretend to have definitive answers. What I have, instead, is a conviction — one that has grown stronger with every conversation, every book, every moment of unexpected clarity: that the most important work we can do is to stay with the questions that make us uncomfortable. Not to solve them, necessarily, but to let them work on us.",
    "The common thread running through all of this is something I can only describe as a kind of attention — a willingness to look closely at what we normally rush past. This is not a new idea. It is, in fact, one of the oldest ideas in the history of thought. And yet, in a world that increasingly rewards speed over depth, it has never been more radical."
  ]
  closing_templates = [
    "I will end with a provocation: perhaps the reason this question has persisted for so long is not that we lack the intelligence to answer it, but that answering it would demand something from us that we are not yet ready to give.",
    "What I have tried to offer here is not a conclusion but an orientation — a way of facing the question that does not reduce it to something smaller than it is. The rest, as always, is up to you.",
    "I do not know where this line of thinking will lead. That, I think, is precisely the point. Some paths are worth walking not because they arrive somewhere, but because of who you become along the way."
  ]

  body = ""
  body += "# #{title}\n\n"
  body += "#{intro_templates.sample}\n\n"
  body += "#{body_templates.sample}\n\n"
  body += "#{body_templates.sample}\n\n"
  body += "## Looking Deeper\n\n"
  body += "#{body_templates.sample}\n\n"
  body += "#{closing_templates.sample}\n\n"
  body += "---\n\n"
  body += "*#{author_display_name} is a writer based in Papyro. This article was originally published on #{Date.today.strftime('%B %d, %Y')}.*"
  body
end

def create_seed_article(user:, title:, slug:, excerpt:, body_markdown:, published_at:, with_cover: false)
  # Only create if article doesn't exist (by slug)
  existing = Article.joins(:article_translations)
                    .where(article_translations: { locale: "en", slug: slug })
  return if existing.exists?

  article = user.articles.create!(
    uuid: SecureRandom.uuid,
    original_locale: "en",
    title: title,
    slug: slug,
    excerpt: excerpt,
    published_at: published_at
  )

  # Set the translation status to published
  translation = article.article_translations.find_by!(locale: "en")
  translation.update!(
    status: :published,
    published_at: published_at
  )

  # Set the markdown body via ActionText
  article.body = body_markdown
  article.save!

  # Attach cover image if requested
  if with_cover
    attach_generated_cover(article)
  end

  puts "  ✓ #{title.truncate(60)}"
  article
end

def attach_generated_cover(article)
  colors = [
    [ "#1a1a2e", "#16213e" ],
    [ "#2d3436", "#636e72" ],
    [ "#0c0c1d", "#1a1a3e" ],
    [ "#1b1b2f", "#2d2d44" ],
    [ "#0f0f23", "#1c1c3d" ]
  ]
  bg_color, gradient_color = colors.sample
  width, height = 1200, 600

  tempfile = Tempfile.new([ "cover", ".png" ])

  # Use ImageMagick directly (MiniMagick has compatibility issues with Ruby 4.0)
  system("magick",
    "-size", "#{width}x#{height}",
    "canvas:#{bg_color}",
    "-fill", gradient_color,
    "-draw", "rectangle 0,0,#{width},#{height}",
    tempfile.path)

  article.cover_image.attach(
    io: tempfile,
    filename: "#{article.slug}-cover.png",
    content_type: "image/png"
  )

  tempfile.close
  tempfile.unlink
rescue => e
  puts "    ⚠ Could not attach cover: #{e.message}"
end

# ── Article Definitions ──────────────────────────────────────────────────

# Helper to look up a user by email
def find_user(email)
  @seed_users.find { |u| u.email_address == email }
end

articles_data = [
  # ── Elena Torres (6 articles) ──────────────────────────────────────────
  {
    user_email: "elena@papyro.local",
    title: "The Art of Slow Thinking in a Fast World",
    slug: "art-of-slow-thinking",
    excerpt: "What we lose when we trade contemplation for constant reaction — and how to reclaim the cognitive space that deep thought demands.",
    published_at: 2.days.ago,
    with_cover: true
  },
  {
    user_email: "elena@papyro.local",
    title: "Memory in the Age of Infinite Storage",
    slug: "memory-infinite-storage",
    excerpt: "When every moment can be captured and preserved, the act of remembering changes. But does perfect recall make us wiser, or just more burdened?",
    published_at: 5.days.ago,
    with_cover: false
  },
  {
    user_email: "elena@papyro.local",
    title: "Why Your Best Ideas Come at 3 AM",
    slug: "best-ideas-3am",
    excerpt: "There is something about the liminal hours — that space between midnight and dawn — where the mind finally untethers from the day's demands and finds its own shape.",
    published_at: 8.days.ago,
    with_cover: true
  },
  {
    user_email: "elena@papyro.local",
    title: "The Quiet Radicalism of Boredom",
    slug: "quiet-radicalism-boredom",
    excerpt: "In a culture that treats every empty moment as a problem to be solved, choosing to be bored is an act of resistance. Here's what happens when you let your mind wander.",
    published_at: 12.days.ago,
    with_cover: false
  },
  {
    user_email: "elena@papyro.local",
    title: "Digital Ghosts: What We Leave Behind Online",
    slug: "digital-ghosts",
    excerpt: "The internet never forgets — but should it? On the ethics of digital permanence and the right to be forgotten in an age of total recall.",
    published_at: 18.days.ago,
    with_cover: true
  },
  {
    user_email: "elena@papyro.local",
    title: "Learning to Write by Learning to Listen",
    slug: "learning-to-listen",
    excerpt: "The best writing doesn't come from having something to say. It comes from paying such close attention that the world reveals something you didn't know you needed to hear.",
    published_at: 25.days.ago,
    with_cover: false
  },

  # ── Marcus Chen (6 articles) ───────────────────────────────────────────
  {
    user_email: "marcus@papyro.local",
    title: "Systems Thinking for Everyday Life",
    slug: "systems-thinking-everyday",
    excerpt: "Most problems we face aren't isolated incidents — they're emergent properties of systems we've built. Once you learn to see the interconnections, you can't unsee them.",
    published_at: 3.days.ago,
    with_cover: true
  },
  {
    user_email: "marcus@papyro.local",
    title: "The Hidden Architecture of Software Teams",
    slug: "hidden-architecture-teams",
    excerpt: "Conway's Law states that organizations design systems that mirror their communication structures. After two decades in tech, I've learned this cuts deeper than anyone admits.",
    published_at: 7.days.ago,
    with_cover: false
  },
  {
    user_email: "marcus@papyro.local",
    title: "What Open Source Taught Me About Trust",
    slug: "open-source-trust",
    excerpt: "Building software in public isn't just about transparency — it's about creating structures of accountability that make trust unnecessary. And that's a lesson for everything.",
    published_at: 11.days.ago,
    with_cover: true
  },
  {
    user_email: "marcus@papyro.local",
    title: "Against Technological Determinism",
    slug: "against-technological-determinism",
    excerpt: "We talk about technology as if it has a will of its own — as if AI, social media, and automation are forces of nature. They aren't. We built them. We can build differently.",
    published_at: 16.days.ago,
    with_cover: false
  },
  {
    user_email: "marcus@papyro.local",
    title: "The Beauty of Imperfect Code",
    slug: "beauty-imperfect-code",
    excerpt: "We fetishize clean code, elegant architectures, and perfect abstractions. But the systems that survive are the ones that learn to live with their own messiness.",
    published_at: 22.days.ago,
    with_cover: true
  },
  {
    user_email: "marcus@papyro.local",
    title: "Why Documentation Is an Act of Love",
    slug: "documentation-act-of-love",
    excerpt: "Writing good documentation is the most undervalued skill in technology. It's not about explaining how something works — it's about saying: I thought about the person who comes after me.",
    published_at: 30.days.ago,
    with_cover: false
  },

  # ── Sophie Laurent (6 articles) ────────────────────────────────────────
  {
    user_email: "sophie@papyro.local",
    title: "The Medieval Monks Who Invented Information Science",
    slug: "medieval-monks-information-science",
    excerpt: "Eight centuries before Silicon Valley, Cistercian monks were building some of the most sophisticated information management systems in history. Their story has a lot to teach us.",
    published_at: 4.days.ago,
    with_cover: true
  },
  {
    user_email: "sophie@papyro.local",
    title: "Why We Still Read the Stoics",
    slug: "why-we-read-stoics",
    excerpt: "Two thousand years after Marcus Aurelius wrote his Meditations, we're still reading them. What does this say about the shelf life of wisdom versus the half-life of information?",
    published_at: 9.days.ago,
    with_cover: false
  },
  {
    user_email: "sophie@papyro.local",
    title: "Productivity Culture and the Death of Leisure",
    slug: "productivity-culture-death-leisure",
    excerpt: "We've turned rest into 'recovery' and play into 'skill-building.' When did we forget that some things are worth doing simply because they're worth doing?",
    published_at: 14.days.ago,
    with_cover: true
  },
  {
    user_email: "sophie@papyro.local",
    title: "On Keeping a Commonplace Book",
    slug: "keeping-commonplace-book",
    excerpt: "For centuries, thinkers kept personal anthologies of quotes, ideas, and observations. In an age of bookmarks and read-later apps, what have we lost by outsourcing our memory?",
    published_at: 20.days.ago,
    with_cover: false
  },
  {
    user_email: "sophie@papyro.local",
    title: "The Lost Art of the Letter",
    slug: "lost-art-of-letter",
    excerpt: "Before email, before texts, before status updates — people wrote letters that took weeks to arrive. And somehow, they said more in those pages than we say in a thousand messages.",
    published_at: 27.days.ago,
    with_cover: true
  },
  {
    user_email: "sophie@papyro.local",
    title: "Attention as a Spiritual Practice",
    slug: "attention-spiritual-practice",
    excerpt: "Simone Weil said that attention is the rarest and purest form of generosity. In a world engineered to distract, learning to pay attention might be the most radical thing you can do.",
    published_at: 35.days.ago,
    with_cover: false
  },

  # ── Ravi Patel (6 articles) ────────────────────────────────────────────
  {
    user_email: "ravi@papyro.local",
    title: "The Cities We Deserve",
    slug: "cities-we-deserve",
    excerpt: "Every city is a physical manifestation of its society's values. Look at how a city treats its pedestrians, its public spaces, its poorest neighborhoods — and you'll see what it truly believes.",
    published_at: 6.days.ago,
    with_cover: true
  },
  {
    user_email: "ravi@papyro.local",
    title: "Migration Is Not a Crisis — It's a Story",
    slug: "migration-not-crisis",
    excerpt: "We frame human movement as a problem to be solved. But migration is one of the oldest human stories — and how we tell it shapes everything about how we respond to it.",
    published_at: 10.days.ago,
    with_cover: false
  },
  {
    user_email: "ravi@papyro.local",
    title: "What the Monsoon Teaches About Resilience",
    slug: "monsoon-teaches-resilience",
    excerpt: "Every year, Mumbai prepares for the monsoon. Not by trying to stop the rain — but by learning to live with it. That philosophy has something to teach a world facing climate disruption.",
    published_at: 15.days.ago,
    with_cover: true
  },
  {
    user_email: "ravi@papyro.local",
    title: "The Invisible Infrastructure of Daily Life",
    slug: "invisible-infrastructure",
    excerpt: "The water that comes from your tap, the electricity that powers your screen, the food that appears at the market — none of it is magic. Behind every convenience is a web of human labor.",
    published_at: 21.days.ago,
    with_cover: false
  },
  {
    user_email: "ravi@papyro.local",
    title: "Reporting from the Edge of the Map",
    slug: "reporting-edge-of-map",
    excerpt: "The most important stories don't happen in capitals or conference rooms. They unfold in villages, wetlands, and neighborhoods that most journalists never visit. Here's what I've found there.",
    published_at: 28.days.ago,
    with_cover: true
  },
  {
    user_email: "ravi@papyro.local",
    title: "A Letter to Young Journalists",
    slug: "letter-young-journalists",
    excerpt: "The industry will tell you to build a brand, chase clicks, optimize for engagement. Ignore all of that. The only thing that matters is telling the truth in a way that makes people care.",
    published_at: 40.days.ago,
    with_cover: false
  }
]

# ── Create the articles ──────────────────────────────────────────────────

articles_data.each do |data|
  user = find_user(data[:user_email])
  next unless user

  author_name = user.profile.display_name
  body_markdown = generate_body(data[:title], author_name)

  create_seed_article(
    user: user,
    title: data[:title],
    slug: data[:slug],
    excerpt: data[:excerpt],
    body_markdown: body_markdown,
    published_at: data[:published_at],
    with_cover: data[:with_cover]
  )
end
