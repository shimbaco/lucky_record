require "./spec_helper"

describe "Preloading" do
  it "can disable lazy loading" do
    with_lazy_load(enabled: false) do
      post = PostBox.save

      posts = Post::BaseQuery.new

      expect_raises LuckyRecord::LazyLoadError do
        posts.first.comments
      end
    end
  end

  it "preloads has_many" do
    with_lazy_load(enabled: false) do
      post = PostBox.save
      comment = CommentBox.new.post_id(post.id).save!

      posts = Post::BaseQuery.new.preload_comments

      posts.results.first.comments.should eq([comment])
    end
  end

  it "preloads has_many with custom query" do
    with_lazy_load(enabled: false) do
      post = PostBox.save
      comment = CommentBox.new.post_id(post.id).save!

      posts = Post::BaseQuery.new.preload_comments(
        Comment::BaseQuery.new.id.not(comment.id)
      )

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "works with nested preloads" do
  end

  it "uses an empty array if there are no associated records" do
    with_lazy_load(enabled: false) do
      post = PostBox.save

      posts = Post::BaseQuery.new.preload_comments

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "preloads belongs_to" do
  end
end

private def with_lazy_load(enabled)
  begin
    LuckyRecord::Model.configure do
      settings.lazy_load_enabled = enabled
    end

    yield
  ensure
    LuckyRecord::Model.configure do
      settings.lazy_load_enabled = true
    end
  end
end
