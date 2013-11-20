require 'i18n'
require 'json'

class FeatureService
  def initialize(opts={})
    @redis = opts.fetch(:redis, Redis.new)
    @ns    = Array(opts.fetch(:ns, 'bandiera'))
  end

  def groups
    @redis.smembers(groups_key)
  end

  def add_group(group)
    @redis.sadd(groups_key, t(group))
  end

  def add_feature(group, feature, enabled, description=nil)
    data = {
      enabled:     enabled,
      description: description,
      flag:        t(feature),
    }
    @redis.multi do
      add_group(group)
      @redis.sadd(group_features_key(group), t(feature))
      @redis.set(feature_key(group, feature), data.to_json)
    end
  end

  def feature(group, feature_name)
    val = @redis.get(feature_key(group, feature_name))
    JSON.parse(val) if val
  end

  def group_features(group)
    feature_ids  = @redis.smembers(group_features_key(group))
    feature_keys = feature_ids.map { |id| feature_key(group, id) }
    feature_data = @redis.mget(*feature_keys)
    feature_data.reject(&:nil?).map { |v| JSON.parse(v) }
  end

  private

  def t(val)
    I18n.transliterate(val.downcase.strip).gsub(/\s+/,'-')
  end

  def groups_key
    key('groups')
  end

  def feature_key(group, id)
    key('feature', t(group), t(id))
  end

  def group_features_key(group)
    key('groups', t(group), 'features')
  end

  def key(*args)
    (@ns + args).join("/")
  end
end
