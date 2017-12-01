module LuckyRecord::Queryable(T)
  include Enumerable(T)

  @query : LuckyRecord::QueryBuilder?

  macro included
    def self.all
      new
    end
  end

  def query
    @query ||= LuckyRecord::QueryBuilder
      .new(table: @@table_name)
      .select(@@schema_class.column_names)
  end

  def where(column, value)
    query.where(LuckyRecord::Where::Equal.new(column, value.to_s))
    self
  end

  def order_by(column, direction)
    query.order_by(column, direction)
    self
  end

  def limit(amount)
    query.limit(amount)
    self
  end

  def offset(amount)
    query.offset(amount)
    self
  end

  def find(id)
    id(id).limit(1).first? || raise RecordNotFoundError.new(model: @@table_name, id: id.to_s)
  end

  def first
    query.limit(1)
    results.first
  end

  def count : Int64
    query.count
    exec_scalar.as(Int64)
  end

  def each
    results.each do |result|
      yield result
    end
  end

  getter preload : (Array(Int32) -> Hash(Int32, Array(Comment)))?

  def preload(&block : Array(Int32) -> Hash(Int32, Array(Comment)))
    @preload = block
  end

  # def preload=(&block : Array(Int32) -> Hash(Int32, Array(LuckyRecord::BaseQuery)))
  #   @preload = preload
  # end

  def results
    records = exec_query

    preload.try do |value|
      comments = value.call(records.map(&.id))

      records.each do |record|
        if record.responds_to?(:"_preloaded_comments=")
          record._preloaded_comments = comments[record.id]
        end
      end
    end

    records
    # post_ids = posts.map(&.id)
    # query.preload_me
    # comments = Comment::BaseQuery.new.post_id.in(post_ids).results.group_by(&.post_id)
    # posts.map do |post|
    #   post._preloaded_comments = comments[post.id]
    # end
  end

  private def exec_query
    LuckyRecord::Repo.run do |db|
      db.query query.statement, query.args do |rs|
        @@schema_class.from_rs(rs)
      end
    end
  end

  private def exec_scalar
    LuckyRecord::Repo.run do |db|
      db.scalar query.statement
    end
  end

  def to_sql
    query.to_sql
  end
end
