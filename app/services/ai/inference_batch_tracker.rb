require "json"

class Ai::InferenceBatchTracker
  KEY_PREFIX = "ai:inference_batch".freeze
  DEFAULT_TTL = 2.days

  def self.register_batch(batch_id:, total_jobs:, metadata:, ttl: DEFAULT_TTL)
    return if total_jobs <= 0

    Sidekiq.redis do |conn|
      conn.multi do |multi|
        multi.hmset(
          redis_key(batch_id),
          "remaining", total_jobs,
          "metadata", JSON.dump(metadata)
        )
        multi.expire(redis_key(batch_id), ttl.to_i)
      end
    end
  end

  def self.mark_job_done(batch_id)
    key = redis_key(batch_id)
    payload = nil
    remaining = nil

    Sidekiq.redis do |conn|
      remaining = conn.hincrby(key, "remaining", -1)

      if remaining <= 0
        payload = conn.hgetall(key)
        conn.del(key)
      end
    end

    return if remaining.nil? || remaining.positive? || payload.blank?

    metadata = JSON.parse(payload["metadata"] || "{}")

    Ai::InferenceFinalizeJob.perform_later(**symbolize_keys(metadata))
  end

  def self.redis_key(batch_id)
    "#{KEY_PREFIX}:#{batch_id}"
  end
  private_class_method :redis_key

  def self.symbolize_keys(hash)
    hash.each_with_object({}) do |(key, value), result|
      result[key.to_sym] = value
    end
  end
  private_class_method :symbolize_keys
end

