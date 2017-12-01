require "./spec_helper"

describe "Preloading" do
  it "can disable lazy loading" do
    begin
      lazy_load(enabled: false)

      posts = Post::BaseQuery.new

      expect_raises LuckyRecord::LazyLoadError do
        posts.first.comments
      end
    ensure
      lazy_load(enabled: true)
    end
  end

  it "preloads_queries" do
    begin
      lazy_load(enabled: false)
      post = PostBox.save
      comment = CommentBox.new.post_id(post.id).save!

      posts = Post::BaseQuery.new.preload_comments

      posts.results.first.comments.should eq([comment])
    ensure
      lazy_load(enabled: true)
    end
  end
end

private def lazy_load(enabled)
  LuckyRecord::Model.configure do
    settings.lazy_load_enabled = enabled
  end
end
