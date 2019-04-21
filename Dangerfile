IGNORED_FILES = [
  '2018-05-27-do-notation-ruby',
  '2018-09-08-monad-laws-in-ruby',
  '2019-01-12-partial-application-in-ruby'
  'euruko-2018'
]

checked_posts = Dir['_posts/**/*.md', '_slides/**/*.md'].reject do |name|
  IGNORED_POSTS.any? do |ignored_post|
    name.include?(ignored_post)
  end
end

prose.lint_files(
  [
    **checked_posts,
    "_drafts/*.md",
  ]
)
