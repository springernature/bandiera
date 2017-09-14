require 'thread'

module Bandiera
  class CachingFeatureService

    def initialize(delegate, clock = Time)
      @delegate = delegate

      @cached_find_group = Cache.new(clock)
      @cached_fetch_groups = Cache.new(clock)
      @cached_fetch_feature = Cache.new(clock)
      @cached_fetch_group_features = Cache.new(clock)
    end

    def find_group(name)
      @cached_find_group.get_or_update(name) {@delegate.find_group(name)}
    end

    def fetch_groups
      @cached_fetch_groups.get_or_update {@delegate.fetch_groups}
    end

    def fetch_group_features(group)
      @cached_fetch_group_features.get_or_update(group) {@delegate.fetch_group_features(group)}
    end

    def fetch_feature(group, feature_name)
      @cached_fetch_feature.get_or_update([group, feature_name]) {@delegate.fetch_feature(group, feature_name)}
    end

    def add_group(group_name)
      new_group = @delegate.add_group(group_name)

      @cached_find_group.invalidate
      @cached_fetch_groups.invalidate

      new_group
    end

    def add_feature(feature_data)
      new_feature = @delegate.add_feature(feature_data)

      @cached_fetch_feature.invalidate
      @cached_fetch_group_features.invalidate

      new_feature
    end

    def add_features(features_data)
      new_features = @delegate.add_features(features_data)

      @cached_fetch_feature.invalidate
      @cached_fetch_group_features.invalidate

      new_features
    end

    def remove_feature(group, feature_name)
      affected_rows = @delegate.remove_feature(group, feature_name)

      @cached_fetch_feature.invalidate
      @cached_fetch_group_features.invalidate

      affected_rows
    end

    def update_feature(group, feature_name, feature_data)
      updated_feature = @delegate.update_feature(group, feature_name, feature_data)

      @cached_fetch_feature.invalidate
      @cached_fetch_group_features.invalidate

      updated_feature
    end

    private

    CACHE_FOR_SECONDS = 10

    class Cache
      def initialize(clock)
        @clock = clock
        @lock = Mutex.new
        @value = {}
        @cached_times = {}
      end

      def invalidate
        @lock.synchronize {
          @value = {}
          @cached_times = {}
        }
      end

      def get_or_update(key = :value, &block)
        @lock.synchronize {
          now = @clock.now.to_i
          if @value[key] && @cached_times[key] && now < (@cached_times[key] + CACHE_FOR_SECONDS)
            @value[key]
          else
            @value[key] = block.call
            @cached_times[key] = now
            @value[key]
          end
        }
      end
    end

  end
end
